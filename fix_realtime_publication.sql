-- =====================================================
-- 🔧 إصلاح سريع لتفعيل Realtime Publications
-- =====================================================

-- إضافة الجداول للـ realtime publication مع معالجة الأخطاء
DO $$
BEGIN
    -- profiles
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
        RAISE NOTICE '✅ تم إضافة profiles للـ realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ profiles مُضاف مسبقاً للـ realtime';
    WHEN undefined_table THEN
        RAISE NOTICE '❌ جدول profiles غير موجود';
    END;
    
    -- listings
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE listings;
        RAISE NOTICE '✅ تم إضافة listings للـ realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ listings مُضاف مسبقاً للـ realtime';
    WHEN undefined_table THEN
        RAISE NOTICE '❌ جدول listings غير موجود';
    END;
    
    -- bookings
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
        RAISE NOTICE '✅ تم إضافة bookings للـ realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ bookings مُضاف مسبقاً للـ realtime';
    WHEN undefined_table THEN
        RAISE NOTICE '❌ جدول bookings غير موجود';
    END;
    
    -- notifications
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
        RAISE NOTICE '✅ تم إضافة notifications للـ realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ notifications مُضاف مسبقاً للـ realtime';
    WHEN undefined_table THEN
        RAISE NOTICE '❌ جدول notifications غير موجود';
    END;
    
    -- messages
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE messages;
        RAISE NOTICE '✅ تم إضافة messages للـ realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ messages مُضاف مسبقاً للـ realtime';
    WHEN undefined_table THEN
        RAISE NOTICE '❌ جدول messages غير موجود';
    END;
    
    -- favorites
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE favorites;
        RAISE NOTICE '✅ تم إضافة favorites للـ realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ favorites مُضاف مسبقاً للـ realtime';
    WHEN undefined_table THEN
        RAISE NOTICE '❌ جدول favorites غير موجود';
    END;
    
    -- reviews
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE reviews;
        RAISE NOTICE '✅ تم إضافة reviews للـ realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ reviews مُضاف مسبقاً للـ realtime';
    WHEN undefined_table THEN
        RAISE NOTICE '❌ جدول reviews غير موجود';
    END;
    
    -- payments
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE payments;
        RAISE NOTICE '✅ تم إضافة payments للـ realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ payments مُضاف مسبقاً للـ realtime';
    WHEN undefined_table THEN
        RAISE NOTICE '❌ جدول payments غير موجود';
    END;
    
    -- chats
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE chats;
        RAISE NOTICE '✅ تم إضافة chats للـ realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ chats مُضاف مسبقاً للـ realtime';
    WHEN undefined_table THEN
        RAISE NOTICE '❌ جدول chats غير موجود';
    END;
    
    -- chat_participants
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE chat_participants;
        RAISE NOTICE '✅ تم إضافة chat_participants للـ realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ chat_participants مُضاف مسبقاً للـ realtime';
    WHEN undefined_table THEN
        RAISE NOTICE '❌ جدول chat_participants غير موجود';
    END;
    
    RAISE NOTICE '🎉 تم إكمال إعداد Realtime Publications';
END $$;

-- التحقق من النتائج
SELECT 
    'Realtime Publications Status' as status,
    tablename,
    '✅ مُفعل' as realtime_status
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
AND tablename IN (
    'profiles', 'listings', 'bookings', 'notifications', 
    'messages', 'favorites', 'reviews', 'payments', 
    'chats', 'chat_participants'
)
ORDER BY tablename;
