-- =====================================================
-- سياسات Row-Level Security الشاملة لتطبيق GoDarna
-- الجزء الثاني من النظام الشامل
-- =====================================================

BEGIN;

-- =====================================================
-- 👤 سياسات جدول PROFILES
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "profiles_select_own_or_admin" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_full_access" ON public.profiles;

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
-- 🏠 سياسات جدول LISTINGS
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "listings_select_published_or_own_or_admin" ON public.listings;
DROP POLICY IF EXISTS "listings_insert_host_only" ON public.listings;
DROP POLICY IF EXISTS "listings_update_own_host" ON public.listings;
DROP POLICY IF EXISTS "listings_delete_own_host" ON public.listings;
DROP POLICY IF EXISTS "listings_admin_full_access" ON public.listings;

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
DROP POLICY IF EXISTS "listing_images_select_published_or_own" ON public.listing_images;
DROP POLICY IF EXISTS "listing_images_manage_own_host" ON public.listing_images;

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
DROP POLICY IF EXISTS "bookings_select_related_users" ON public.bookings;
DROP POLICY IF EXISTS "bookings_insert_tenant" ON public.bookings;
DROP POLICY IF EXISTS "bookings_update_tenant_own" ON public.bookings;
DROP POLICY IF EXISTS "bookings_update_host_status" ON public.bookings;
DROP POLICY IF EXISTS "bookings_admin_full_access" ON public.bookings;

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
DROP POLICY IF EXISTS "payments_select_related_users" ON public.payments;
DROP POLICY IF EXISTS "payments_insert_admin_or_host" ON public.payments;
DROP POLICY IF EXISTS "payments_update_admin_only" ON public.payments;

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
-- 💰 سياسات جدول REFUNDS
-- =====================================================

DROP POLICY IF EXISTS "refunds_select_related_users" ON public.refunds;
DROP POLICY IF EXISTS "refunds_insert_related_users" ON public.refunds;
DROP POLICY IF EXISTS "refunds_update_admin_only" ON public.refunds;

CREATE POLICY "refunds_select_related_users" ON public.refunds
  FOR SELECT USING (
    public.is_admin() OR
    EXISTS (
      SELECT 1 FROM public.payments p
      JOIN public.bookings b ON b.id = p.booking_id
      JOIN public.listings l ON l.id = b.listing_id
      WHERE p.id = payment_id AND (
        b.tenant_id = auth.uid() OR 
        l.host_id = auth.uid()
      )
    )
  );

CREATE POLICY "refunds_insert_related_users" ON public.refunds
  FOR INSERT WITH CHECK (
    public.is_admin() OR
    EXISTS (
      SELECT 1 FROM public.payments p
      JOIN public.bookings b ON b.id = p.booking_id
      JOIN public.listings l ON l.id = b.listing_id
      WHERE p.id = payment_id AND (
        b.tenant_id = auth.uid() OR 
        l.host_id = auth.uid()
      )
    )
  );

CREATE POLICY "refunds_update_admin_only" ON public.refunds
  FOR UPDATE USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- =====================================================
-- ⭐ سياسات جدول REVIEWS
-- =====================================================

DROP POLICY IF EXISTS "reviews_select_published_listings" ON public.reviews;
DROP POLICY IF EXISTS "reviews_insert_completed_booking_only" ON public.reviews;
DROP POLICY IF EXISTS "reviews_update_own" ON public.reviews;
DROP POLICY IF EXISTS "reviews_delete_own_or_admin" ON public.reviews;

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
DROP POLICY IF EXISTS "favorites_manage_own" ON public.favorites;
DROP POLICY IF EXISTS "favorites_admin_access" ON public.favorites;

-- سياسات جديدة محسنة
CREATE POLICY "favorites_manage_own" ON public.favorites
  FOR ALL USING (tenant_id = auth.uid())
  WITH CHECK (tenant_id = auth.uid());

CREATE POLICY "favorites_admin_access" ON public.favorites
  FOR ALL USING (public.is_admin());

-- =====================================================
-- 🔔 سياسات جدول NOTIFICATIONS
-- =====================================================

-- إزالة السياسات الموجودة
DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert_admin" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete_own_or_admin" ON public.notifications;

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
DROP POLICY IF EXISTS "chats_update_creator_or_admin" ON public.chats;

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
DROP POLICY IF EXISTS "chat_participants_select_related" ON public.chat_participants;
DROP POLICY IF EXISTS "chat_participants_insert_creator_or_admin" ON public.chat_participants;
DROP POLICY IF EXISTS "chat_participants_delete_creator_or_self" ON public.chat_participants;

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
DROP POLICY IF EXISTS "messages_insert_participant_only" ON public.messages;
DROP POLICY IF EXISTS "messages_update_sender_only" ON public.messages;
DROP POLICY IF EXISTS "messages_delete_sender_or_admin" ON public.messages;

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
-- 📊 سياسات جداول المراقبة
-- =====================================================

-- USER_ACTIONS
DROP POLICY IF EXISTS "user_actions_select_own_or_admin" ON public.user_actions;
DROP POLICY IF EXISTS "user_actions_insert_own_or_admin" ON public.user_actions;

CREATE POLICY "user_actions_select_own_or_admin" ON public.user_actions
  FOR SELECT USING (
    user_id = auth.uid() OR public.is_admin()
  );

CREATE POLICY "user_actions_insert_own_or_admin" ON public.user_actions
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR public.is_admin()
  );

-- PROPERTY_VIEWS
DROP POLICY IF EXISTS "property_views_select_all" ON public.property_views;
DROP POLICY IF EXISTS "property_views_insert_all" ON public.property_views;

CREATE POLICY "property_views_select_all" ON public.property_views
  FOR SELECT USING (true);

CREATE POLICY "property_views_insert_all" ON public.property_views
  FOR INSERT WITH CHECK (true);

-- SECURITY_LOGS
DROP POLICY IF EXISTS "security_logs_admin_only" ON public.security_logs;

CREATE POLICY "security_logs_admin_only" ON public.security_logs
  FOR ALL USING (public.is_admin());

-- =====================================================
-- 🗂️ سياسات STORAGE
-- =====================================================

-- تنظيف السياسات الموجودة
DROP POLICY IF EXISTS "images_public_read" ON storage.objects;
DROP POLICY IF EXISTS "images_authenticated_insert" ON storage.objects;
DROP POLICY IF EXISTS "images_owner_update" ON storage.objects;
DROP POLICY IF EXISTS "images_owner_delete" ON storage.objects;
DROP POLICY IF EXISTS "listing-images_public_read" ON storage.objects;

-- سياسات محسنة للتخزين
CREATE POLICY "storage_images_public_read" ON storage.objects
  FOR SELECT USING (bucket_id IN ('images', 'listing-images', 'property-photos'));

CREATE POLICY "storage_images_authenticated_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id IN ('images', 'listing-images', 'property-photos') AND 
    auth.uid() IS NOT NULL
  );

CREATE POLICY "storage_images_owner_manage" ON storage.objects
  FOR UPDATE USING (
    bucket_id IN ('images', 'listing-images', 'property-photos') AND 
    (owner = auth.uid() OR public.is_admin())
  );

CREATE POLICY "storage_images_owner_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id IN ('images', 'listing-images', 'property-photos') AND 
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
    AND (p_property_type IS NULL OR l.property_type::text = p_property_type)
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

-- دالة للتحقق من توفر العقار في فترة معينة
CREATE OR REPLACE FUNCTION public.is_listing_available(
  p_listing_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT EXISTS (
    SELECT 1
    FROM public.bookings b
    WHERE b.listing_id = p_listing_id
      AND b.status != 'cancelled'
      AND b.ts_range && tstzrange(p_start_date, p_end_date, '[)')
  );
$$;

-- دالة لحساب السعر الإجمالي للحجز
CREATE OR REPLACE FUNCTION public.calculate_booking_total(
  p_listing_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS NUMERIC
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    GREATEST(1, CEIL(EXTRACT(EPOCH FROM (p_end_date - p_start_date)) / 86400.0)) * 
    COALESCE(l.price_per_night, 0)
  FROM public.listings l
  WHERE l.id = p_listing_id AND l.is_published = true;
$$;

-- =====================================================
-- 📋 منح الصلاحيات الأساسية
-- =====================================================

-- منح صلاحيات القراءة والكتابة للمستخدمين المصادق عليهم
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- منح صلاحيات محدودة للزوار غير المسجلين
GRANT SELECT ON public.listings TO anon;
GRANT EXECUTE ON FUNCTION public.browse_public_listings TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_listing_available TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_booking_total TO authenticated;

-- =====================================================
-- 🏪 إنشاء buckets التخزين
-- =====================================================

-- إنشاء bucket للصور العامة
INSERT INTO storage.buckets (id, name, public)
VALUES ('images', 'images', true)
ON CONFLICT (id) DO NOTHING;

-- إنشاء bucket لصور العقارات
INSERT INTO storage.buckets (id, name, public)
VALUES ('property-photos', 'property-photos', true)
ON CONFLICT (id) DO NOTHING;

-- إنشاء bucket لصور المستخدمين
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

COMMIT;
