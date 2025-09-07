-- =====================================================
-- تشخيص مشكلة عدم ظهور الرسائل في الإشعارات
-- =====================================================

-- 1. فحص وجود جدول الإشعارات وبنيته
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'notifications' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- فحص قيم enum notification_type المتاحة
SELECT 
    t.typname,
    e.enumlabel
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
WHERE t.typname = 'notification_type'
ORDER BY e.enumsortorder;

-- 2. فحص سياسات RLS على جدول الإشعارات
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'notifications';

-- 3. فحص الإشعارات الموجودة
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    data,
    is_read,
    created_at
FROM public.notifications 
ORDER BY created_at DESC 
LIMIT 10;

-- 4. فحص المستخدمين الموجودين وبنية الجدول
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- عرض المستخدمين (بدون full_name)
SELECT 
    id,
    email,
    created_at
FROM public.profiles 
LIMIT 5;

-- 5. محاولة إدراج إشعار رسالة تجريبي (استخدام 'info' بدلاً من 'new_message')
INSERT INTO public.notifications (user_id, title, message, type, data)
SELECT 
    id,
    '💬 رسالة جديدة',
    'هذا اختبار لإشعار رسالة جديدة',
    'info',
    '{"chat_id": "test-chat-id", "sender_id": "test-sender", "message_preview": "رسالة تجريبية"}'::jsonb
FROM public.profiles 
LIMIT 1;

-- 6. التحقق من الإشعار المُدرج
SELECT 
    'تم إدراج إشعار الرسالة بنجاح' as result,
    COUNT(*) as total_notifications
FROM public.notifications 
WHERE type = 'info';

-- 7. فحص إعدادات Realtime
SELECT 
    schemaname,
    tablename,
    replica_identity
FROM pg_tables 
WHERE tablename = 'notifications';

-- 8. تفعيل Realtime إذا لم يكن مفعلاً
ALTER TABLE public.notifications REPLICA IDENTITY FULL;
