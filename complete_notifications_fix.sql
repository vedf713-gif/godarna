-- =====================================================
-- حل شامل لمشكلة الإشعارات في GoDarna
-- =====================================================

-- 1. إنشاء enum notification_type إذا لم يكن موجوداً
DO $$ BEGIN
    CREATE TYPE public.notification_type AS ENUM (
        'info', 
        'warning', 
        'error', 
        'success', 
        'new_message', 
        'booking_update', 
        'payment', 
        'review'
    );
EXCEPTION
    WHEN duplicate_object THEN 
        -- إضافة قيم جديدة إذا كان النوع موجوداً
        ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'new_message';
        ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'booking_update';
        ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'payment';
        ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'review';
END $$;

-- 2. إنشاء جدول notifications إذا لم يكن موجوداً
CREATE TABLE IF NOT EXISTS public.notifications (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    type public.notification_type NOT NULL DEFAULT 'info'::notification_type,
    data jsonb NULL DEFAULT '{}'::jsonb,
    is_read boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT notifications_pkey PRIMARY KEY (id),
    CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles (id) ON DELETE CASCADE
);

-- 3. إنشاء الفهارس للأداء
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications USING btree (is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications USING btree (created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications USING btree (type);

-- 4. تفعيل RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 5. إزالة السياسات القديمة
DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert_authenticated" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert_admin" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete_own" ON public.notifications;

-- 6. إنشاء سياسات RLS صحيحة
CREATE POLICY "notifications_select_own" ON public.notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own" ON public.notifications
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- السماح لأي مستخدم مسجل بإدراج إشعارات (للرسائل والتفاعلات)
CREATE POLICY "notifications_insert_authenticated" ON public.notifications
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "notifications_delete_own" ON public.notifications
    FOR DELETE USING (user_id = auth.uid());

-- 7. تفعيل Realtime
ALTER TABLE public.notifications REPLICA IDENTITY FULL;

-- 8. اختبار النظام
INSERT INTO public.notifications (user_id, title, message, type, data)
SELECT 
    id,
    '🎉 نظام الإشعارات جاهز',
    'تم إعداد نظام الإشعارات بنجاح وهو جاهز للاستخدام',
    'success',
    json_build_object(
        'setup_complete', true,
        'timestamp', NOW()::text,
        'version', '1.0'
    )::jsonb
FROM public.profiles 
LIMIT 1;

-- 9. عرض النتائج
SELECT 
    'تم إعداد نظام الإشعارات بنجاح' as status,
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN type = 'new_message' THEN 1 END) as message_notifications,
    COUNT(CASE WHEN is_read = false THEN 1 END) as unread_notifications
FROM public.notifications;

-- 10. عرض قيم enum المتاحة
SELECT 
    'قيم notification_type المتاحة:' as info,
    string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) as available_types
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
WHERE t.typname = 'notification_type';

SELECT '✅ تم حل مشكلة الإشعارات بالكامل' as result;
