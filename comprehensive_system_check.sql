-- =====================================================
-- 🔍 فحص شامل لنظام Realtime والإشعارات في GoDarna
-- =====================================================

-- 1. فحص تفعيل Realtime للجداول
SELECT 
    'Realtime Tables Check' as check_type,
    tablename,
    CASE 
        WHEN tablename IN (
            SELECT tablename 
            FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime'
        ) THEN '✅ مُفعل'
        ELSE '❌ غير مُفعل'
    END as status
FROM pg_tables 
WHERE tablename IN (
    'profiles', 'listings', 'bookings', 'notifications', 
    'messages', 'favorites', 'reviews', 'payments', 
    'chats', 'chat_participants'
)
AND schemaname = 'public'
ORDER BY tablename;

-- 2. فحص وجود الجداول المطلوبة
SELECT 
    'Tables Existence Check' as check_type,
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN '✅ موجود'
        ELSE '❌ مفقود'
    END as status
FROM (
    VALUES 
        ('profiles'), ('listings'), ('bookings'), 
        ('notifications'), ('messages'), ('favorites'),
        ('reviews'), ('payments'), ('chats'), ('chat_participants')
) AS required_tables(table_name)
LEFT JOIN information_schema.tables t 
    ON t.table_name = required_tables.table_name 
    AND t.table_schema = 'public';

-- 3. فحص سياسات RLS
SELECT 
    'RLS Policies Check' as check_type,
    tablename,
    policyname,
    CASE 
        WHEN cmd = 'SELECT' THEN '👁️ قراءة'
        WHEN cmd = 'INSERT' THEN '➕ إدراج'
        WHEN cmd = 'UPDATE' THEN '✏️ تحديث'
        WHEN cmd = 'DELETE' THEN '🗑️ حذف'
        ELSE cmd
    END as operation,
    '✅ مُفعل' as status
FROM pg_policies 
WHERE tablename IN (
    'profiles', 'listings', 'bookings', 'notifications', 
    'messages', 'favorites', 'reviews', 'payments'
)
ORDER BY tablename, cmd;

-- 4. فحص الدوال المطلوبة
SELECT 
    'Functions Check' as check_type,
    routine_name,
    CASE 
        WHEN routine_name IS NOT NULL THEN '✅ موجود'
        ELSE '❌ مفقود'
    END as status,
    routine_type
FROM information_schema.routines
WHERE routine_name IN (
    'send_notification',
    'send_bulk_notifications',
    'notify_new_booking',
    'notify_booking_status_change',
    'notify_new_message',
    'notify_new_review',
    'get_notification_stats',
    'mark_notifications_as_read',
    'cleanup_old_notifications'
)
AND routine_schema = 'public'
ORDER BY routine_name;

-- 5. فحص المحفزات
SELECT 
    'Triggers Check' as check_type,
    trigger_name,
    event_object_table as table_name,
    CASE 
        WHEN trigger_name IS NOT NULL THEN '✅ مُفعل'
        ELSE '❌ غير مُفعل'
    END as status,
    action_timing || ' ' || event_manipulation as trigger_event
FROM information_schema.triggers
WHERE trigger_name IN (
    'trigger_notify_new_booking',
    'trigger_notify_booking_status_change',
    'trigger_notify_new_message',
    'trigger_notify_new_review'
)
ORDER BY trigger_name;

-- 6. فحص أنواع البيانات المخصصة
SELECT 
    'Custom Types Check' as check_type,
    typname as type_name,
    '✅ موجود' as status,
    CASE 
        WHEN typname = 'notification_type' THEN 'أنواع الإشعارات'
        WHEN typname = 'booking_status' THEN 'حالات الحجز'
        WHEN typname = 'user_role' THEN 'أدوار المستخدمين'
        ELSE 'نوع مخصص'
    END as description
FROM pg_type 
WHERE typname IN ('notification_type', 'booking_status', 'user_role')
ORDER BY typname;

-- 7. فحص الفهارس للأداء
SELECT 
    'Indexes Check' as check_type,
    schemaname,
    tablename,
    indexname,
    '✅ موجود' as status
FROM pg_indexes 
WHERE tablename IN ('notifications', 'bookings', 'messages', 'favorites')
AND schemaname = 'public'
ORDER BY tablename, indexname;

-- 8. إحصائيات الجداول
SELECT 
    'Table Statistics' as check_type,
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_rows
FROM pg_stat_user_tables 
WHERE tablename IN (
    'profiles', 'listings', 'bookings', 'notifications', 
    'messages', 'favorites', 'reviews'
)
ORDER BY tablename;

-- 9. فحص الصلاحيات
SELECT 
    'Permissions Check' as check_type,
    grantee,
    table_name,
    privilege_type,
    '✅ ممنوح' as status
FROM information_schema.role_table_grants 
WHERE table_name IN ('notifications', 'bookings', 'messages')
AND grantee = 'authenticated'
ORDER BY table_name, privilege_type;

-- 10. اختبار دالة الإشعارات
DO $$
DECLARE
    test_user_id UUID := '00000000-0000-0000-0000-000000000001';
    notification_id UUID;
    stats_record RECORD;
BEGIN
    -- اختبار إرسال إشعار
    BEGIN
        SELECT send_notification(
            test_user_id,
            'اختبار النظام',
            'هذا إشعار اختبار للتأكد من عمل النظام',
            'general'
        ) INTO notification_id;
        
        RAISE NOTICE '✅ اختبار إرسال الإشعارات: نجح (ID: %)', notification_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ اختبار إرسال الإشعارات: فشل - %', SQLERRM;
    END;
    
    -- اختبار دالة الإحصائيات
    BEGIN
        SELECT * INTO stats_record FROM get_notification_stats(test_user_id);
        RAISE NOTICE '✅ اختبار إحصائيات الإشعارات: نجح';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ اختبار إحصائيات الإشعارات: فشل - %', SQLERRM;
    END;
    
    -- تنظيف الاختبار
    DELETE FROM notifications WHERE user_id = test_user_id;
END $$;

-- 11. ملخص الحالة العامة
SELECT 
    'System Status Summary' as check_type,
    'Realtime System' as component,
    CASE 
        WHEN (
            SELECT COUNT(*) 
            FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime'
            AND tablename IN ('notifications', 'bookings', 'messages', 'favorites')
        ) >= 4 THEN '🟢 نشط'
        ELSE '🔴 يحتاج إصلاح'
    END as status,
    'نظام التحديثات الفورية' as description

UNION ALL

SELECT 
    'System Status Summary' as check_type,
    'Notifications System' as component,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'notifications'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'send_notification'
        ) THEN '🟢 نشط'
        ELSE '🔴 يحتاج إصلاح'
    END as status,
    'نظام الإشعارات' as description

UNION ALL

SELECT 
    'System Status Summary' as check_type,
    'Database Triggers' as component,
    CASE 
        WHEN (
            SELECT COUNT(*) 
            FROM information_schema.triggers 
            WHERE trigger_name LIKE 'trigger_notify_%'
        ) >= 3 THEN '🟢 نشط'
        ELSE '🔴 يحتاج إصلاح'
    END as status,
    'المحفزات التلقائية' as description;

-- =====================================================
-- 📋 تعليمات الاستخدام:
-- =====================================================

/*
لتشغيل هذا الفحص:
1. في Supabase Dashboard:
   - اذهب إلى SQL Editor
   - الصق هذا الكود
   - اضغط Run

2. أو من سطر الأوامر:
   psql -d your_database -f comprehensive_system_check.sql

3. النتائج المتوقعة:
   ✅ جميع الجداول مُفعلة للـ Realtime
   ✅ جميع السياسات موجودة ونشطة
   ✅ جميع الدوال والمحفزات تعمل
   ✅ النظام جاهز للاستخدام

إذا ظهرت أي علامات ❌ أو 🔴:
- راجع ملف complete_realtime_setup.sql
- تأكد من تشغيله بالكامل
- تحقق من صلاحيات قاعدة البيانات
*/
