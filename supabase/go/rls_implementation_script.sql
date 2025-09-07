-- =====================================================
-- سكريبت تطبيق Row-Level Security - GoDarna
-- يجب تشغيله على قاعدة البيانات مباشرة
-- =====================================================

-- 🔧 التحقق من المتطلبات الأساسية
DO $$
BEGIN
  -- التحقق من وجود الامتدادات المطلوبة
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp') THEN
    RAISE EXCEPTION 'Extension uuid-ossp is required but not installed';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    RAISE EXCEPTION 'Extension pgcrypto is required but not installed';
  END IF;
  
  RAISE NOTICE 'All required extensions are installed ✅';
END
$$;

-- =====================================================
-- 🛡️ إنشاء الدوال الأمنية المساعدة
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
  IF uid IS NULL THEN
    RETURN false;
  END IF;
  
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
  IF uid IS NULL THEN
    RETURN false;
  END IF;
  
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
  IF uid IS NULL OR listing_id IS NULL THEN
    RETURN false;
  END IF;
  
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
  IF uid IS NULL OR chat_id IS NULL THEN
    RETURN false;
  END IF;
  
  RETURN EXISTS(
    SELECT 1 FROM public.chat_participants cp 
    WHERE cp.chat_id = chat_id AND cp.user_id = uid
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- =====================================================
-- 🔐 تفعيل RLS على جميع الجداول
-- =====================================================

DO $$
DECLARE
  table_name TEXT;
  tables_to_secure TEXT[] := ARRAY[
    'profiles', 'listings', 'listing_images', 'bookings', 
    'payments', 'reviews', 'favorites', 'notifications',
    'chats', 'chat_participants', 'messages'
  ];
BEGIN
  FOREACH table_name IN ARRAY tables_to_secure
  LOOP
    -- التحقق من وجود الجدول
    IF EXISTS (SELECT 1 FROM information_schema.tables 
               WHERE table_schema = 'public' AND table_name = table_name) THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_name);
      RAISE NOTICE 'RLS enabled on table: %', table_name;
    ELSE
      RAISE WARNING 'Table % does not exist, skipping RLS enablement', table_name;
    END IF;
  END LOOP;
END
$$;

-- =====================================================
-- 👤 تطبيق سياسات جدول PROFILES
-- =====================================================

-- إزالة السياسات الموجودة بأمان
DO $$
BEGIN
  DROP POLICY IF EXISTS "Public read own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Users update own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Admin full access profiles" ON public.profiles;
  DROP POLICY IF EXISTS "profiles_select_own_or_admin" ON public.profiles;
  DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
  DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
  DROP POLICY IF EXISTS "profiles_admin_full_access" ON public.profiles;
  RAISE NOTICE 'Cleaned up existing policies for profiles table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

-- إنشاء السياسات الجديدة
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
-- 🏠 تطبيق سياسات جدول LISTINGS
-- =====================================================

-- إزالة السياسات الموجودة بأمان
DO $$
BEGIN
  DROP POLICY IF EXISTS "Anyone can view published listings" ON public.listings;
  DROP POLICY IF EXISTS "Host view own listings" ON public.listings;
  DROP POLICY IF EXISTS "Host insert own listing" ON public.listings;
  DROP POLICY IF EXISTS "Host update own listing" ON public.listings;
  DROP POLICY IF EXISTS "Admin full access listings" ON public.listings;
  DROP POLICY IF EXISTS "listings_select_published_or_own_or_admin" ON public.listings;
  DROP POLICY IF EXISTS "listings_insert_host_only" ON public.listings;
  DROP POLICY IF EXISTS "listings_update_own_host" ON public.listings;
  DROP POLICY IF EXISTS "listings_delete_own_host" ON public.listings;
  DROP POLICY IF EXISTS "listings_admin_full_access" ON public.listings;
  RAISE NOTICE 'Cleaned up existing policies for listings table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

-- إنشاء السياسات الجديدة
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
-- 📅 تطبيق سياسات جدول BOOKINGS
-- =====================================================

-- إزالة السياسات الموجودة بأمان
DO $$
BEGIN
  DROP POLICY IF EXISTS "Tenant read own bookings" ON public.bookings;
  DROP POLICY IF EXISTS "Tenant create own bookings" ON public.bookings;
  DROP POLICY IF EXISTS "Tenant update own bookings (cancel)" ON public.bookings;
  DROP POLICY IF EXISTS "Host update status for listings they own" ON public.bookings;
  DROP POLICY IF EXISTS "Admin full access bookings" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_select_related_users" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_insert_tenant" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_update_tenant_own" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_update_host_status" ON public.bookings;
  DROP POLICY IF EXISTS "bookings_admin_full_access" ON public.bookings;
  RAISE NOTICE 'Cleaned up existing policies for bookings table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

-- إنشاء السياسات الجديدة
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
-- 💳 تطبيق سياسات جدول PAYMENTS
-- =====================================================

-- إزالة السياسات الموجودة بأمان
DO $$
BEGIN
  DROP POLICY IF EXISTS "Tenant/Host/Admin read related payments" ON public.payments;
  DROP POLICY IF EXISTS "Insert payment by admin or host for COD collection" ON public.payments;
  DROP POLICY IF EXISTS "payments_select_related_users" ON public.payments;
  DROP POLICY IF EXISTS "payments_insert_admin_or_host" ON public.payments;
  DROP POLICY IF EXISTS "payments_update_admin_only" ON public.payments;
  RAISE NOTICE 'Cleaned up existing policies for payments table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

-- إنشاء السياسات الجديدة
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
-- ⭐ تطبيق سياسات جدول REVIEWS
-- =====================================================

-- إزالة السياسات الموجودة بأمان
DO $$
BEGIN
  DROP POLICY IF EXISTS "Public read reviews of published listings" ON public.reviews;
  DROP POLICY IF EXISTS "Tenant insert review only if booking completed" ON public.reviews;
  DROP POLICY IF EXISTS "reviews_select_published_listings" ON public.reviews;
  DROP POLICY IF EXISTS "reviews_insert_completed_booking_only" ON public.reviews;
  DROP POLICY IF EXISTS "reviews_update_own" ON public.reviews;
  DROP POLICY IF EXISTS "reviews_delete_own_or_admin" ON public.reviews;
  RAISE NOTICE 'Cleaned up existing policies for reviews table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

-- إنشاء السياسات الجديدة
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
-- ❤️ تطبيق سياسات جدول FAVORITES
-- =====================================================

-- إزالة السياسات الموجودة بأمان
DO $$
BEGIN
  DROP POLICY IF EXISTS "Tenant manage own favorites" ON public.favorites;
  DROP POLICY IF EXISTS "Users can view their own favorites" ON public.favorites;
  DROP POLICY IF EXISTS "Users can insert their own favorites" ON public.favorites;
  DROP POLICY IF EXISTS "Users can delete their own favorites" ON public.favorites;
  DROP POLICY IF EXISTS "Users can update their own favorites" ON public.favorites;
  DROP POLICY IF EXISTS "favorites_manage_own" ON public.favorites;
  DROP POLICY IF EXISTS "favorites_admin_access" ON public.favorites;
  RAISE NOTICE 'Cleaned up existing policies for favorites table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

-- إنشاء السياسات الجديدة
CREATE POLICY "favorites_manage_own" ON public.favorites
  FOR ALL USING (
    (tenant_id IS NOT NULL AND tenant_id = auth.uid()) OR 
    (user_id IS NOT NULL AND user_id = auth.uid()) OR
    public.is_admin()
  )
  WITH CHECK (
    (tenant_id IS NOT NULL AND tenant_id = auth.uid()) OR 
    (user_id IS NOT NULL AND user_id = auth.uid()) OR
    public.is_admin()
  );

-- =====================================================
-- 🔔 تطبيق سياسات جدول NOTIFICATIONS
-- =====================================================

-- إزالة السياسات الموجودة بأمان
DO $$
BEGIN
  DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
  DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
  DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
  DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
  DROP POLICY IF EXISTS "notifications_insert_admin" ON public.notifications;
  DROP POLICY IF EXISTS "notifications_delete_own_or_admin" ON public.notifications;
  RAISE NOTICE 'Cleaned up existing policies for notifications table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

-- إنشاء السياسات الجديدة
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
-- 💬 تطبيق سياسات جداول CHAT
-- =====================================================

-- CHATS
DO $$
BEGIN
  DROP POLICY IF EXISTS "chats_select_participants" ON public.chats;
  DROP POLICY IF EXISTS "chats_insert_creator" ON public.chats;
  DROP POLICY IF EXISTS "chats_insert_authenticated" ON public.chats;
  DROP POLICY IF EXISTS "chats_update_creator_or_admin" ON public.chats;
  RAISE NOTICE 'Cleaned up existing policies for chats table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

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
DO $$
BEGIN
  DROP POLICY IF EXISTS "chat_participants_select" ON public.chat_participants;
  DROP POLICY IF EXISTS "chat_participants_insert_by_creator" ON public.chat_participants;
  DROP POLICY IF EXISTS "chat_participants_select_related" ON public.chat_participants;
  DROP POLICY IF EXISTS "chat_participants_insert_creator_or_admin" ON public.chat_participants;
  DROP POLICY IF EXISTS "chat_participants_delete_creator_or_self" ON public.chat_participants;
  RAISE NOTICE 'Cleaned up existing policies for chat_participants table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

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
DO $$
BEGIN
  DROP POLICY IF EXISTS "messages_select_participants" ON public.messages;
  DROP POLICY IF EXISTS "messages_insert_sender_participant" ON public.messages;
  DROP POLICY IF EXISTS "messages_update_sender" ON public.messages;
  DROP POLICY IF EXISTS "messages_insert_participant_only" ON public.messages;
  DROP POLICY IF EXISTS "messages_update_sender_only" ON public.messages;
  DROP POLICY IF EXISTS "messages_delete_sender_or_admin" ON public.messages;
  RAISE NOTICE 'Cleaned up existing policies for messages table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

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
-- 🗂️ تطبيق سياسات STORAGE
-- =====================================================

-- إزالة السياسات الموجودة بأمان
DO $$
BEGIN
  DROP POLICY IF EXISTS "images_public_read" ON storage.objects;
  DROP POLICY IF EXISTS "images_authenticated_insert" ON storage.objects;
  DROP POLICY IF EXISTS "images_owner_update" ON storage.objects;
  DROP POLICY IF EXISTS "images_owner_delete" ON storage.objects;
  DROP POLICY IF EXISTS "listing-images_public_read" ON storage.objects;
  DROP POLICY IF EXISTS "Host upload to listing images" ON storage.objects;
  DROP POLICY IF EXISTS "storage_images_public_read" ON storage.objects;
  DROP POLICY IF EXISTS "storage_images_authenticated_upload" ON storage.objects;
  DROP POLICY IF EXISTS "storage_images_owner_manage" ON storage.objects;
  DROP POLICY IF EXISTS "storage_images_owner_delete" ON storage.objects;
  RAISE NOTICE 'Cleaned up existing policies for storage.objects table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Some policies may not exist, continuing...';
END
$$;

-- إنشاء السياسات الجديدة
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
-- 🔍 إنشاء الفهارس المطلوبة
-- =====================================================

-- فهارس لتحسين أداء سياسات RLS
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_profiles_role 
  ON public.profiles(role) WHERE role IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_listings_host_published 
  ON public.listings(host_id, is_published) WHERE host_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_bookings_tenant_listing 
  ON public.bookings(tenant_id, listing_id) WHERE tenant_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_bookings_status_dates 
  ON public.bookings(status, start_date, end_date) WHERE status IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payments_booking_method 
  ON public.payments(booking_id, method) WHERE booking_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_favorites_user_listing 
  ON public.favorites(tenant_id, listing_id) WHERE tenant_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_read 
  ON public.notifications(user_id, is_read) WHERE user_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_chat_participants_user_chat 
  ON public.chat_participants(user_id, chat_id) WHERE user_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_messages_chat_sender 
  ON public.messages(chat_id, sender_id) WHERE chat_id IS NOT NULL;

-- =====================================================
-- ✅ التحقق من نجاح التطبيق
-- =====================================================

DO $$
DECLARE
  table_count INTEGER;
  policy_count INTEGER;
  function_count INTEGER;
BEGIN
  -- عد الجداول المفعل عليها RLS
  SELECT COUNT(*) INTO table_count
  FROM pg_tables pt
  JOIN pg_class pc ON pc.relname = pt.tablename
  WHERE pt.schemaname = 'public' 
    AND pc.relrowsecurity = true
    AND pt.tablename IN (
      'profiles', 'listings', 'bookings', 'payments', 
      'reviews', 'favorites', 'notifications',
      'chats', 'chat_participants', 'messages'
    );
  
  -- عد السياسات المطبقة
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies 
  WHERE schemaname = 'public';
  
  -- عد الدوال الأمنية
  SELECT COUNT(*) INTO function_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' 
    AND p.proname IN ('is_admin', 'is_host', 'owns_listing', 'is_chat_participant', 'current_user_id');
  
  RAISE NOTICE '====================================';
  RAISE NOTICE '✅ RLS Implementation Summary:';
  RAISE NOTICE '📊 Tables with RLS enabled: %', table_count;
  RAISE NOTICE '🛡️ Security policies created: %', policy_count;
  RAISE NOTICE '🔧 Security functions created: %', function_count;
  RAISE NOTICE '====================================';
  
  IF table_count >= 10 AND policy_count >= 20 AND function_count >= 5 THEN
    RAISE NOTICE '🎉 RLS implementation completed successfully!';
  ELSE
    RAISE WARNING '⚠️ Some components may be missing. Please review the implementation.';
  END IF;
END
$$;

-- =====================================================
-- 🧪 اختبارات التحقق الأساسية
-- =====================================================

-- اختبار 1: التحقق من تفعيل RLS
SELECT 
  'RLS Status Check' as test_name,
  schemaname,
  tablename,
  CASE WHEN rowsecurity THEN '✅ Enabled' ELSE '❌ Disabled' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'profiles', 'listings', 'bookings', 'payments', 
    'reviews', 'favorites', 'notifications', 
    'chats', 'chat_participants', 'messages'
  )
ORDER BY tablename;

-- اختبار 2: عرض السياسات المطبقة
SELECT 
  'Policy Summary' as test_name,
  tablename,
  COUNT(*) as policy_count,
  array_agg(policyname ORDER BY policyname) as policies
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- اختبار 3: التحقق من الدوال الأمنية
SELECT 
  'Security Functions Check' as test_name,
  proname as function_name,
  CASE WHEN prosecdef THEN '🔒 SECURITY DEFINER' ELSE '🔓 INVOKER' END as security_type
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' 
  AND p.proname IN ('is_admin', 'is_host', 'owns_listing', 'is_chat_participant', 'current_user_id')
ORDER BY proname;

RAISE NOTICE '🔒 RLS Implementation Script completed successfully!';
RAISE NOTICE '📋 Please review the test results above and run security_audit_checklist.md';
RAISE NOTICE '🚀 Ready for deployment after thorough testing!';

COMMIT;
