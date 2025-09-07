-- =====================================================
-- إصلاح مشكلة سياسات الأمان لجدول الحجوزات
-- يحل مشكلة PostgrestException: new row violates RLS policy
-- =====================================================

BEGIN;

-- 1. حذف جميع إصدارات دالة is_admin() المكررة بشكل شامل
DO $$
DECLARE
    func_record RECORD;
BEGIN
  -- حذف جميع الدوال المحتملة بجميع أشكالها
  FOR func_record IN
    SELECT proname, oidvectortypes(proargtypes) as args
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND proname = 'is_admin'
  LOOP
    BEGIN
      EXECUTE format('DROP FUNCTION IF EXISTS public.is_admin(%s) CASCADE', func_record.args);
      RAISE NOTICE 'حُذفت الدالة: is_admin(%)', func_record.args;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE 'تعذر حذف الدالة: is_admin(%) - %', func_record.args, SQLERRM;
    END;
  END LOOP;
  
  -- حذف إضافي للتأكد
  BEGIN
    DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
    DROP FUNCTION IF EXISTS public.is_admin(UUID) CASCADE;
    DROP FUNCTION IF EXISTS public.is_admin(uuid) CASCADE;
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
  
  RAISE NOTICE 'تم تنظيف جميع إصدارات دالة is_admin()';
END
$$;

-- إنشاء دالة is_admin() موحدة وواضحة
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- 2. إزالة السياسات الموجودة بأمان
DO $$
BEGIN
  DROP POLICY IF EXISTS "bookings_select_related_users" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_insert_tenant" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_update_tenant_own" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_update_host_status" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_admin_full_access" ON public.bookings;
  DROP POLICY IF EXISTS "Users can view their own bookings" ON public.bookings;
  DROP POLICY IF EXISTS "Tenants can create bookings" ON public.bookings;
  DROP POLICY IF EXISTS "Hosts can update their property bookings" ON public.bookings;
  RAISE NOTICE 'تم حذف السياسات الموجودة بنجاح';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'تم تجاهل بعض السياسات غير الموجودة';
END
$$;

-- 3. التأكد من تفعيل RLS على الجدول
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 4. إنشاء سياسات جديدة مبسطة ومتوافقة

-- سياسة القراءة: يمكن للمستأجر والمضيف والأدمن قراءة الحجوزات المتعلقة بهم
CREATE POLICY "bookings_select_policy" ON public.bookings
  FOR SELECT USING (
    tenant_id = auth.uid() OR 
    host_id = auth.uid() OR
    public.is_admin() OR
    EXISTS (
      SELECT 1 FROM public.listings l 
      WHERE l.id = listing_id AND l.host_id = auth.uid()
    )
  );

-- سياسة الإدراج: المستأجرون فقط يمكنهم إنشاء حجوزات
-- مع التأكد من أنهم لا يحجزون عقاراتهم الخاصة
CREATE POLICY "bookings_insert_policy" ON public.bookings
  FOR INSERT WITH CHECK (
    -- المستخدم مسجل دخول
    auth.uid() IS NOT NULL AND
    -- المستخدم هو المستأجر
    tenant_id = auth.uid() AND
    -- المستخدم لا يحجز عقاره الخاص (إن وجد)
    (
      NOT EXISTS (
        SELECT 1 FROM public.listings l 
        WHERE l.id = listing_id AND l.host_id = auth.uid()
      ) OR
      public.is_admin()
    )
  );

-- سياسة التحديث للمستأجر: يمكن للمستأجر تحديث حجوزاته (الغاء فقط)
CREATE POLICY "bookings_update_tenant_policy" ON public.bookings
  FOR UPDATE USING (tenant_id = auth.uid())
  WITH CHECK (
    tenant_id = auth.uid() AND 
    status IN ('pending', 'cancelled')
  );

-- سياسة التحديث للمضيف: يمكن للمضيف تحديث حالة الحجوزات لعقاراته
CREATE POLICY "bookings_update_host_policy" ON public.bookings
  FOR UPDATE USING (
    host_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.listings l 
      WHERE l.id = listing_id AND l.host_id = auth.uid()
    )
  )
  WITH CHECK (
    status IN ('pending', 'confirmed', 'cancelled', 'completed')
  );

-- سياسة شاملة للأدمن
CREATE POLICY "bookings_admin_policy" ON public.bookings
  FOR ALL USING (public.is_admin());

-- 5. إنشاء دالة مساعدة للتحقق من صحة الحجز
CREATE OR REPLACE FUNCTION public.validate_booking_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- التحقق من أن المستخدم لا يحجز عقاره الخاص
  IF EXISTS (
    SELECT 1 FROM public.listings l 
    WHERE l.id = NEW.listing_id AND l.host_id = NEW.tenant_id
  ) THEN
    RAISE EXCEPTION 'لا يمكن حجز عقارك الخاص';
  END IF;
  
  -- التحقق من صحة التواريخ
  IF NEW.end_date <= NEW.start_date THEN
    RAISE EXCEPTION 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية';
  END IF;
  
  RETURN NEW;
END;
$$;

-- 6. إنشاء المحفز للتحقق من صحة البيانات
DROP TRIGGER IF EXISTS validate_booking_trigger ON public.bookings;
CREATE TRIGGER validate_booking_trigger
  BEFORE INSERT ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_booking_insert();

-- 7. إنشاء فهارس إضافية للأداء
CREATE INDEX IF NOT EXISTS idx_bookings_auth_user 
  ON public.bookings(tenant_id, host_id) 
  WHERE tenant_id IS NOT NULL OR host_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_bookings_listing_dates 
  ON public.bookings(listing_id, start_date, end_date) 
  WHERE listing_id IS NOT NULL;

-- 8. منح الصلاحيات اللازمة
GRANT SELECT, INSERT, UPDATE ON public.bookings TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

COMMIT;

-- 9. عرض السياسات الجديدة للتحقق
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
WHERE schemaname = 'public' AND tablename = 'bookings'
ORDER BY policyname;

-- 10. رسالة نجاح
SELECT 'تم إصلاح سياسات الأمان لجدول الحجوزات بنجاح! ✅' as status;
