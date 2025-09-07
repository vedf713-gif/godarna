-- =====================================================
-- إصلاح مشكلة الإشعارات - السماح بالإدراج للمستخدمين
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert_admin" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete_own_or_admin" ON public.notifications;

-- سياسات جديدة تسمح بالإدراج للمستخدمين العاديين
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

-- تفعيل RLS على جدول الإشعارات
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- اختبار إدراج إشعار (استبدل USER_ID_HERE بمعرف المستخدم الفعلي)
-- للحصول على معرف المستخدم الحالي، استخدم: SELECT auth.uid();
-- أو استخدم معرف مستخدم موجود من جدول profiles

-- طريقة 1: استخدام معرف المستخدم الحالي (إذا كنت مسجل دخول)
DO $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NOT NULL THEN
        INSERT INTO public.notifications (user_id, title, message, type, data)
        VALUES (
            current_user_id,
            'اختبار الإشعار',
            'هذا إشعار تجريبي للتأكد من عمل النظام',
            'info',
            '{"test": true}'::jsonb
        );
        RAISE NOTICE 'تم إدراج الإشعار بنجاح للمستخدم: %', current_user_id;
    ELSE
        RAISE NOTICE 'لا يوجد مستخدم مسجل دخول. استخدم الطريقة البديلة أدناه.';
    END IF;
END $$;

-- طريقة 2: استخدام أول مستخدم موجود في النظام
-- INSERT INTO public.notifications (user_id, title, message, type, data)
-- SELECT 
--     id,
--     'اختبار الإشعار',
--     'هذا إشعار تجريبي للتأكد من عمل النظام',
--     'info',
--     '{"test": true}'::jsonb
-- FROM public.profiles 
-- LIMIT 1;

SELECT 'تم إصلاح سياسات الإشعارات بنجاح' as result;
