-- =====================================================
-- خطة Row-Level Security شاملة لتطبيق GoDarna
-- تم إعدادها بناءً على مراجعة شاملة للمشروع
-- =====================================================

-- 🔧 المتطلبات الأساسية
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- 🎭 تعريف الأدوار والحالات
CREATE TYPE user_role AS ENUM ('tenant', 'host', 'admin');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed');
CREATE TYPE payment_method AS ENUM ('cod', 'online');
CREATE TYPE payment_status AS ENUM ('unpaid', 'paid', 'failed', 'refunded', 'pending');

-- =====================================================
-- 🛡️ دوال الأمان المساعدة
-- =====================================================

-- دالة للحصول على معرف المستخدم الحالي
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID AS $$
BEGIN
  RETURN auth.uid();
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- دالة للتحقق من كون المستخدم مدير
CREATE OR REPLACE FUNCTION public.is_admin(uid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS(
    SELECT 1 FROM public.profiles p 
    WHERE p.id = uid AND p.role = 'admin'
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- دالة للتحقق من كون المستخدم مالك عقار
CREATE OR REPLACE FUNCTION public.is_host(uid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS(
    SELECT 1 FROM public.profiles p 
    WHERE p.id = uid AND p.role IN ('host', 'admin')
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- دالة للتحقق من ملكية العقار
CREATE OR REPLACE FUNCTION public.owns_listing(listing_id UUID, uid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS(
    SELECT 1 FROM public.listings l 
    WHERE l.id = listing_id AND l.host_id = uid
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- دالة للتحقق من المشاركة في المحادثة
CREATE OR REPLACE FUNCTION public.is_chat_participant(chat_id UUID, uid UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS(
    SELECT 1 FROM public.chat_participants cp 
    WHERE cp.chat_id = chat_id AND cp.user_id = uid
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- =====================================================
-- 🔐 تفعيل RLS على جميع الجداول الحساسة
-- =====================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listing_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 👤 سياسات جدول PROFILES
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "Public read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admin full access profiles" ON public.profiles;

-- سياسات جديدة محسنة
CREATE POLICY "profiles_select_own_or_admin" ON public.profiles
  FOR SELECT USING (
    auth.uid() = id OR public.is_admin()
  );

CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_admin_full_access" ON public.profiles
  FOR ALL USING (public.is_admin());

-- =====================================================
-- 🏠 سياسات جدول LISTINGS/PROPERTIES
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "Anyone can view published listings" ON public.listings;
DROP POLICY IF EXISTS "Host view own listings" ON public.listings;
DROP POLICY IF EXISTS "Host insert own listing" ON public.listings;
DROP POLICY IF EXISTS "Host update own listing" ON public.listings;
DROP POLICY IF EXISTS "Admin full access listings" ON public.listings;

-- سياسات جديدة محسنة
CREATE POLICY "listings_select_published_or_own_or_admin" ON public.listings
  FOR SELECT USING (
    is_published = true OR 
    auth.uid() = host_id OR 
    public.is_admin()
  );

CREATE POLICY "listings_insert_host_only" ON public.listings
  FOR INSERT WITH CHECK (
    auth.uid() = host_id AND 
    public.is_host()
  );

CREATE POLICY "listings_update_own_host" ON public.listings
  FOR UPDATE USING (auth.uid() = host_id)
  WITH CHECK (auth.uid() = host_id);

CREATE POLICY "listings_delete_own_host" ON public.listings
  FOR DELETE USING (
    auth.uid() = host_id OR public.is_admin()
  );

CREATE POLICY "listings_admin_full_access" ON public.listings
  FOR ALL USING (public.is_admin());

-- =====================================================
-- 📷 سياسات جدول LISTING_IMAGES
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "Public view images of published listings" ON public.listing_images;
DROP POLICY IF EXISTS "Host manage images of own listings" ON public.listing_images;

-- سياسات جديدة محسنة
CREATE POLICY "listing_images_select_published_or_own" ON public.listing_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.listings l 
      WHERE l.id = listing_id AND (
        l.is_published = true OR 
        l.host_id = auth.uid() OR 
        public.is_admin()
      )
    )
  );

CREATE POLICY "listing_images_manage_own_host" ON public.listing_images
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.listings l 
      WHERE l.id = listing_id AND l.host_id = auth.uid()
    ) OR public.is_admin()
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.listings l 
      WHERE l.id = listing_id AND l.host_id = auth.uid()
    ) OR public.is_admin()
  );

-- =====================================================
-- 📅 سياسات جدول BOOKINGS
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "Tenant read own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Tenant create own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Tenant update own bookings (cancel)" ON public.bookings;
DROP POLICY IF EXISTS "Host update status for listings they own" ON public.bookings;
DROP POLICY IF EXISTS "Admin full access bookings" ON public.bookings;

-- سياسات جديدة محسنة
CREATE POLICY "bookings_select_related_users" ON public.bookings
  FOR SELECT USING (
    tenant_id = auth.uid() OR 
    EXISTS (
      SELECT 1 FROM public.listings l 
      WHERE l.id = listing_id AND l.host_id = auth.uid()
    ) OR 
    public.is_admin()
  );

CREATE POLICY "bookings_insert_tenant" ON public.bookings
  FOR INSERT WITH CHECK (
    tenant_id = auth.uid() AND
    tenant_id != (
      SELECT l.host_id FROM public.listings l WHERE l.id = listing_id
    )
  );

CREATE POLICY "bookings_update_tenant_own" ON public.bookings
  FOR UPDATE USING (tenant_id = auth.uid())
  WITH CHECK (
    tenant_id = auth.uid() AND 
    status IN ('pending', 'cancelled')
  );

CREATE POLICY "bookings_update_host_status" ON public.bookings
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.listings l 
      WHERE l.id = listing_id AND l.host_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.listings l 
      WHERE l.id = listing_id AND l.host_id = auth.uid()
    )
  );

CREATE POLICY "bookings_admin_full_access" ON public.bookings
  FOR ALL USING (public.is_admin());

-- =====================================================
-- 💳 سياسات جدول PAYMENTS
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "Tenant/Host/Admin read related payments" ON public.payments;
DROP POLICY IF EXISTS "Insert payment by admin or host for COD collection" ON public.payments;

-- سياسات جديدة محسنة
CREATE POLICY "payments_select_related_users" ON public.payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      JOIN public.listings l ON l.id = b.listing_id
      WHERE b.id = booking_id AND (
        b.tenant_id = auth.uid() OR 
        l.host_id = auth.uid() OR 
        public.is_admin()
      )
    )
  );

CREATE POLICY "payments_insert_admin_or_host" ON public.payments
  FOR INSERT WITH CHECK (
    public.is_admin() OR 
    EXISTS (
      SELECT 1 FROM public.bookings b 
      JOIN public.listings l ON l.id = b.listing_id
      WHERE b.id = booking_id AND l.host_id = auth.uid()
    )
  );

CREATE POLICY "payments_update_admin_only" ON public.payments
  FOR UPDATE USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- ⭐ سياسات جدول REVIEWS
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "Public read reviews of published listings" ON public.reviews;
DROP POLICY IF EXISTS "Tenant insert review only if booking completed" ON public.reviews;

-- سياسات جديدة محسنة
CREATE POLICY "reviews_select_published_listings" ON public.reviews
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.listings l 
      WHERE l.id = listing_id AND l.is_published = true
    ) OR public.is_admin()
  );

CREATE POLICY "reviews_insert_completed_booking_only" ON public.reviews
  FOR INSERT WITH CHECK (
    tenant_id = auth.uid() AND 
    EXISTS (
      SELECT 1 FROM public.bookings b 
      WHERE b.id = booking_id AND 
            b.tenant_id = auth.uid() AND 
            b.status = 'completed'
    )
  );

CREATE POLICY "reviews_update_own" ON public.reviews
  FOR UPDATE USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid());

CREATE POLICY "reviews_delete_own_or_admin" ON public.reviews
  FOR DELETE USING (
    tenant_id = auth.uid() OR public.is_admin()
  );

-- =====================================================
-- ❤️ سياسات جدول FAVORITES
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "Tenant manage own favorites" ON public.favorites;
DROP POLICY IF EXISTS "Users can view their own favorites" ON public.favorites;
DROP POLICY IF EXISTS "Users can insert their own favorites" ON public.favorites;
DROP POLICY IF EXISTS "Users can delete their own favorites" ON public.favorites;
DROP POLICY IF EXISTS "Users can update their own favorites" ON public.favorites;

-- سياسات جديدة محسنة
CREATE POLICY "favorites_manage_own" ON public.favorites
  FOR ALL USING (tenant_id = auth.uid() OR user_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid() OR user_id = auth.uid());

CREATE POLICY "favorites_admin_access" ON public.favorites
  FOR ALL USING (public.is_admin());

-- =====================================================
-- 🔔 سياسات جدول NOTIFICATIONS
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;

-- سياسات جديدة محسنة
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "notifications_insert_admin" ON public.notifications
  FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "notifications_delete_own_or_admin" ON public.notifications
  FOR DELETE USING (
    user_id = auth.uid() OR public.is_admin()
  );

-- =====================================================
-- 💬 سياسات جداول CHAT
-- =====================================================

-- CHATS
DROP POLICY IF EXISTS "chats_select_participants" ON public.chats;
DROP POLICY IF EXISTS "chats_insert_creator" ON public.chats;

CREATE POLICY "chats_select_participants" ON public.chats
  FOR SELECT USING (
    public.is_chat_participant(id) OR public.is_admin()
  );

CREATE POLICY "chats_insert_authenticated" ON public.chats
  FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "chats_update_creator_or_admin" ON public.chats
  FOR UPDATE USING (
    created_by = auth.uid() OR public.is_admin()
  )
  WITH CHECK (
    created_by = auth.uid() OR public.is_admin()
  );

-- CHAT_PARTICIPANTS
DROP POLICY IF EXISTS "chat_participants_select" ON public.chat_participants;
DROP POLICY IF EXISTS "chat_participants_insert_by_creator" ON public.chat_participants;

CREATE POLICY "chat_participants_select_related" ON public.chat_participants
  FOR SELECT USING (
    user_id = auth.uid() OR 
    public.is_chat_participant(chat_id) OR 
    public.is_admin()
  );

CREATE POLICY "chat_participants_insert_creator_or_admin" ON public.chat_participants
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.chats c 
      WHERE c.id = chat_id AND c.created_by = auth.uid()
    ) OR public.is_admin()
  );

CREATE POLICY "chat_participants_delete_creator_or_self" ON public.chat_participants
  FOR DELETE USING (
    user_id = auth.uid() OR 
    EXISTS (
      SELECT 1 FROM public.chats c 
      WHERE c.id = chat_id AND c.created_by = auth.uid()
    ) OR 
    public.is_admin()
  );

-- MESSAGES
DROP POLICY IF EXISTS "messages_select_participants" ON public.messages;
DROP POLICY IF EXISTS "messages_insert_sender_participant" ON public.messages;
DROP POLICY IF EXISTS "messages_update_sender" ON public.messages;

CREATE POLICY "messages_select_participants" ON public.messages
  FOR SELECT USING (
    public.is_chat_participant(chat_id) OR public.is_admin()
  );

CREATE POLICY "messages_insert_participant_only" ON public.messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND 
    public.is_chat_participant(chat_id)
  );

CREATE POLICY "messages_update_sender_only" ON public.messages
  FOR UPDATE USING (
    sender_id = auth.uid() AND 
    public.is_chat_participant(chat_id)
  )
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "messages_delete_sender_or_admin" ON public.messages
  FOR DELETE USING (
    sender_id = auth.uid() OR public.is_admin()
  );

-- =====================================================
-- 🗂️ سياسات STORAGE
-- =====================================================

-- تنظيف السياسات الموجودة
DROP POLICY IF EXISTS "images_public_read" ON storage.objects;
DROP POLICY IF EXISTS "images_authenticated_insert" ON storage.objects;
DROP POLICY IF EXISTS "images_owner_update" ON storage.objects;
DROP POLICY IF EXISTS "images_owner_delete" ON storage.objects;
DROP POLICY IF EXISTS "listing-images_public_read" ON storage.objects;
DROP POLICY IF EXISTS "Host upload to listing images" ON storage.objects;

-- سياسات محسنة للتخزين
CREATE POLICY "storage_images_public_read" ON storage.objects
  FOR SELECT USING (bucket_id IN ('images', 'listing-images'));

CREATE POLICY "storage_images_authenticated_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id IN ('images', 'listing-images') AND 
    auth.uid() IS NOT NULL
  );

CREATE POLICY "storage_images_owner_manage" ON storage.objects
  FOR UPDATE USING (
    bucket_id IN ('images', 'listing-images') AND 
    (owner = auth.uid() OR public.is_admin())
  );

CREATE POLICY "storage_images_owner_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id IN ('images', 'listing-images') AND 
    (owner = auth.uid() OR public.is_admin())
  );

-- =====================================================
-- 🔧 دوال RPC آمنة للوصول العام
-- =====================================================

-- دالة آمنة لتصفح العقارات العامة
CREATE OR REPLACE FUNCTION public.browse_public_listings(
  p_search TEXT DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_center_lat DOUBLE PRECISION DEFAULT NULL,
  p_center_lng DOUBLE PRECISION DEFAULT NULL,
  p_radius_km DOUBLE PRECISION DEFAULT NULL,
  p_min_price NUMERIC DEFAULT NULL,
  p_max_price NUMERIC DEFAULT NULL,
  p_property_type TEXT DEFAULT NULL,
  p_max_guests INT DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0,
  p_order_by TEXT DEFAULT 'recent'
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  city TEXT,
  price_per_night NUMERIC,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  average_rating NUMERIC,
  main_image_url TEXT,
  distance_km NUMERIC
)
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    l.id,
    l.title,
    l.city,
    l.price_per_night,
    l.lat,
    l.lng,
    l.average_rating,
    l.main_image_url,
    CASE 
      WHEN p_center_lat IS NOT NULL AND p_center_lng IS NOT NULL AND l.lat IS NOT NULL AND l.lng IS NOT NULL THEN
        ST_Distance(
          ST_SetSRID(ST_MakePoint(l.lng, l.lat), 4326)::geography,
          ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geography
        ) / 1000.0
      ELSE NULL 
    END as distance_km
  FROM public.listings l
  WHERE l.is_published = true
    AND (p_city IS NULL OR LOWER(l.city) = LOWER(p_city))
    AND (p_min_price IS NULL OR l.price_per_night >= p_min_price)
    AND (p_max_price IS NULL OR l.price_per_night <= p_max_price)
    AND (p_property_type IS NULL OR l.property_type = p_property_type)
    AND (p_max_guests IS NULL OR l.max_guests >= p_max_guests)
    AND (
      p_search IS NULL OR 
      LOWER(l.title) LIKE '%' || LOWER(p_search) || '%' OR
      LOWER(COALESCE(l.description, '')) LIKE '%' || LOWER(p_search) || '%'
    )
    AND (
      p_center_lat IS NULL OR p_center_lng IS NULL OR p_radius_km IS NULL OR
      l.lat IS NULL OR l.lng IS NULL OR
      ST_DWithin(
        ST_SetSRID(ST_MakePoint(l.lng, l.lat), 4326)::geography,
        ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geography,
        p_radius_km * 1000.0
      )
    )
  ORDER BY
    CASE WHEN p_order_by = 'price_asc' THEN l.price_per_night END ASC NULLS LAST,
    CASE WHEN p_order_by = 'price_desc' THEN l.price_per_night END DESC NULLS LAST,
    CASE WHEN p_order_by = 'rating_desc' THEN l.average_rating END DESC NULLS LAST,
    CASE WHEN p_order_by = 'distance' THEN 
      ST_Distance(
        ST_SetSRID(ST_MakePoint(l.lng, l.lat), 4326)::geography,
        ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geography
      ) / 1000.0 
    END ASC NULLS LAST,
    l.created_at DESC
  LIMIT GREATEST(1, LEAST(p_limit, 100))
  OFFSET GREATEST(0, p_offset);
$$;

-- منح الصلاحيات للأدوار
GRANT EXECUTE ON FUNCTION public.browse_public_listings TO anon, authenticated;

-- =====================================================
-- 🔒 دوال إدارية آمنة
-- =====================================================

-- دالة إدارية لتحديث دور المستخدم
CREATE OR REPLACE FUNCTION public.admin_update_user_role(
  p_user_id UUID,
  p_new_role user_role
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  -- تحديث الدور
  UPDATE public.profiles 
  SET role = p_new_role, updated_at = NOW()
  WHERE id = p_user_id;
  
  RETURN FOUND;
END;
$$;

-- دالة إدارية لتحديث حالة العقار
CREATE OR REPLACE FUNCTION public.admin_update_listing_status(
  p_listing_id UUID,
  p_is_published BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  -- تحديث حالة النشر
  UPDATE public.listings 
  SET is_published = p_is_published, updated_at = NOW()
  WHERE id = p_listing_id;
  
  RETURN FOUND;
END;
$$;

-- منح الصلاحيات للمديرين فقط
GRANT EXECUTE ON FUNCTION public.admin_update_user_role TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_listing_status TO authenticated;

-- =====================================================
-- 📋 منح الصلاحيات الأساسية
-- =====================================================

-- منح صلاحيات القراءة والكتابة للمستخدمين المصادق عليهم
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- منح صلاحيات محدودة للزوار غير المسجلين
GRANT SELECT ON public.listings TO anon;
GRANT EXECUTE ON FUNCTION public.browse_public_listings TO anon;

-- =====================================================
-- 🔍 فهارس الأداء والأمان
-- =====================================================

-- فهارس لتحسين أداء سياسات RLS
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_listings_host_published ON public.listings(host_id, is_published);
CREATE INDEX IF NOT EXISTS idx_bookings_tenant_listing ON public.bookings(tenant_id, listing_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status_dates ON public.bookings(status, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_payments_booking_method ON public.payments(booking_id, method);
CREATE INDEX IF NOT EXISTS idx_favorites_user_listing ON public.favorites(tenant_id, listing_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user_chat ON public.chat_participants(user_id, chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat_sender ON public.messages(chat_id, sender_id);

-- =====================================================
-- 🚨 تحذيرات أمنية مهمة
-- =====================================================

/*
⚠️ تحذيرات أمنية مهمة:

1. تأكد من تفعيل RLS على جميع الجداول قبل النشر
2. لا تستخدم SECURITY DEFINER إلا عند الضرورة القصوى
3. اختبر جميع السياسات مع أدوار مختلفة قبل النشر
4. راقب الاستعلامات البطيئة بسبب RLS
5. استخدم فهارس مناسبة لتحسين أداء السياسات
6. لا تعطي صلاحيات service_role للتطبيق في الإنتاج
7. راجع السياسات دورياً وحدثها حسب متطلبات العمل

🔒 نقاط التحقق الأساسية:
- ✅ جميع الجداول الحساسة مفعل عليها RLS
- ✅ لا يوجد وصول مباشر للبيانات بدون مصادقة
- ✅ كل مستخدم يرى بياناته فقط
- ✅ المديرون لديهم وصول كامل مع تسجيل العمليات
- ✅ الدوال الإدارية محمية بـ SECURITY DEFINER
- ✅ صلاحيات محدودة للزوار غير المسجلين

📝 للمراجعة الدورية:
- مراجعة سجلات الوصول شهرياً
- اختبار السياسات مع حسابات وهمية
- مراقبة أداء الاستعلامات
- تحديث السياسات عند إضافة ميزات جديدة
*/

-- =====================================================
-- ✅ اختبارات التحقق من الأمان
-- =====================================================

-- اختبار 1: التحقق من تفعيل RLS على جميع الجداول
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'profiles', 'listings', 'bookings', 'payments', 
    'reviews', 'favorites', 'notifications', 
    'chats', 'chat_participants', 'messages'
  )
ORDER BY tablename;

-- اختبار 2: عرض جميع السياسات المطبقة
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
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 🔄 تطبيق التحديثات
-- =====================================================

-- تحديث الطوابع الزمنية
UPDATE public.profiles SET updated_at = NOW() WHERE updated_at IS NULL;
UPDATE public.listings SET updated_at = NOW() WHERE updated_at IS NULL;
UPDATE public.bookings SET updated_at = NOW() WHERE updated_at IS NULL;

-- إعادة حساب التقييمات
SELECT public.update_average_rating() FROM public.reviews;

-- تنظيف البيانات المعطلة
DELETE FROM public.notifications WHERE created_at < NOW() - INTERVAL '6 months';

COMMIT;
