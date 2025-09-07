-- =====================================================
-- إصلاح مشكلة سياسات الأمان لجدول الحجوزات
-- حل مبسط بدون استخدام دوال is_admin() مخصصة
-- =====================================================

BEGIN;

-- 1. حذف جميع السياسات الموجودة للبدء من الصفر
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
  DROP POLICY IF EXISTS "bookings_select_policy" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_insert_policy" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_update_tenant_policy" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_update_host_policy" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_admin_policy" ON public.bookings;
  RAISE NOTICE 'تم حذف جميع السياسات الموجودة';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'تم تجاهل بعض السياسات غير الموجودة';
END
$$;

-- 2. التأكد من تفعيل RLS
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 3. سياسة القراءة - بسيطة ومباشرة
CREATE POLICY "bookings_read" ON public.bookings
  FOR SELECT USING (
    -- المستأجر يمكنه رؤية حجوزاته
    tenant_id = auth.uid() OR 
    -- المضيف يمكنه رؤية حجوزات عقاراته
    host_id = auth.uid() OR
    -- المضيف يمكنه رؤية حجوزات عقاراته عبر جدول listings
    EXISTS (
      SELECT 1 FROM public.listings l 
      WHERE l.id = listing_id AND l.host_id = auth.uid()
    ) OR
    -- الأدمن يمكنه رؤية كل شيء (فحص مباشر بدون دالة)
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

-- 4. سياسة الإدراج - للمستأجرين فقط
CREATE POLICY "bookings_create" ON public.bookings
  FOR INSERT WITH CHECK (
    -- المستخدم مسجل دخول
    auth.uid() IS NOT NULL AND
    -- المستخدم هو المستأجر المحدد في البيانات
    tenant_id = auth.uid()
  );

-- 5. سياسة التحديث للمستأجر - يمكن إلغاء حجوزاته فقط
CREATE POLICY "bookings_update_by_tenant" ON public.bookings
  FOR UPDATE USING (
    tenant_id = auth.uid()
  )
  WITH CHECK (
    tenant_id = auth.uid() AND 
    status IN ('pending', 'cancelled')
  );

-- 6. سياسة التحديث للمضيف - يمكن تغيير حالة حجوزات عقاراته
CREATE POLICY "bookings_update_by_host" ON public.bookings
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

-- 7. سياسة شاملة للأدمن - فحص مباشر بدون دالة
CREATE POLICY "bookings_admin_all" ON public.bookings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

-- 8. إنشاء محفز للتحقق من صحة البيانات
CREATE OR REPLACE FUNCTION public.validate_booking_data()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- التحقق من صحة التواريخ
  IF NEW.end_date <= NEW.start_date THEN
    RAISE EXCEPTION 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية';
  END IF;
  
  -- التحقق من أن المستخدم لا يحجز عقاره الخاص (إن أمكن)
  IF EXISTS (
    SELECT 1 FROM public.listings l 
    WHERE l.id = NEW.listing_id AND l.host_id = NEW.tenant_id
  ) THEN
    RAISE EXCEPTION 'لا يمكن حجز عقارك الخاص';
  END IF;
  
  RETURN NEW;
END;
$$;

-- 9. إنشاء المحفز
DROP TRIGGER IF EXISTS validate_booking_data_trigger ON public.bookings;
CREATE TRIGGER validate_booking_data_trigger
  BEFORE INSERT OR UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_booking_data();

-- 10. فهارس محسنة للأداء
CREATE INDEX IF NOT EXISTS idx_bookings_tenant_host 
  ON public.bookings(tenant_id, host_id) 
  WHERE tenant_id IS NOT NULL OR host_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_bookings_listing_status 
  ON public.bookings(listing_id, status) 
  WHERE listing_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_bookings_dates_status 
  ON public.bookings(start_date, end_date, status);

-- 11. منح الصلاحيات
GRANT SELECT, INSERT, UPDATE ON public.bookings TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

COMMIT;

-- 12. عرض السياسات الجديدة للتأكيد
SELECT 
  policyname,
  cmd,
  permissive,
  qual IS NOT NULL as has_using_clause,
  with_check IS NOT NULL as has_with_check_clause
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'bookings'
ORDER BY policyname;

-- رسالة النجاح
SELECT '✅ تم إصلاح سياسات RLS للحجوزات بنجاح بدون دوال مخصصة!' as result;
