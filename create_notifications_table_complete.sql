-- =====================================================
-- إنشاء جدول الإشعارات الكامل مع الفهارس والسياسات
-- =====================================================

-- إنشاء enum notification_type إذا لم يكن موجوداً
DO $$ BEGIN
    CREATE TYPE public.notification_type AS ENUM ('info', 'warning', 'error', 'success', 'new_message', 'booking_update', 'payment', 'review');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- حذف الجدول إذا كان موجوداً (للتطوير فقط)
-- DROP TABLE IF EXISTS public.notifications CASCADE;

-- إنشاء جدول الإشعارات
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
) TABLESPACE pg_default;

-- إنشاء الفهارس للأداء المحسن
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications USING btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications USING btree (is_read) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications USING btree (created_at) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications USING btree (type) TABLESPACE pg_default;

-- تفعيل RLS على الجدول
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert_authenticated" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete_own" ON public.notifications;

-- إنشاء سياسات RLS محسنة
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

-- اختبار النظام
INSERT INTO public.notifications (user_id, title, message, type, data)
SELECT 
    id,
    'مرحباً بك في جودارنا',
    'تم إنشاء نظام الإشعارات بنجاح',
    'success',
    '{"welcome": true, "version": "1.0"}'::jsonb
FROM public.profiles 
LIMIT 1;

-- عرض النتيجة
SELECT 
    'تم إنشاء جدول الإشعارات والفهارس والسياسات بنجاح' as result,
    COUNT(*) as notifications_count
FROM public.notifications;
