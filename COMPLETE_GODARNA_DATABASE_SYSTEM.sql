-- =====================================================
-- نظام قاعدة البيانات الشامل لتطبيق GoDarna
-- تم إنشاؤه بناءً على مراجعة شاملة لجميع ملفات المشروع
-- يشمل: Schema + RLS + Functions + Triggers + Indexes
-- =====================================================

BEGIN;

-- 🔧 المتطلبات الأساسية والإضافات
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- 🎭 تعريف الأنواع المخصصة
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('tenant', 'host', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE payment_method AS ENUM ('cash_on_delivery', 'online');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('unpaid', 'paid', 'failed', 'refunded', 'pending');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE property_type AS ENUM ('apartment', 'villa', 'riad', 'studio', 'kasbah', 'village_house', 'desert_camp', 'eco_lodge', 'guesthouse', 'hotel', 'resort');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE notification_type AS ENUM ('info', 'warning', 'error', 'success', 'booking', 'payment', 'review', 'system');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =====================================================
-- 👤 جدول المستخدمين (PROFILES)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  avatar TEXT,
  role user_role NOT NULL DEFAULT 'tenant',
  is_email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  language TEXT DEFAULT 'ar',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- إنشاء view لـ users بعد إنشاء جدول profiles
CREATE OR REPLACE VIEW public.users AS 
SELECT * FROM public.profiles;

-- =====================================================
-- 🏠 جدول العقارات (LISTINGS)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  property_type property_type NOT NULL,
  price_per_night NUMERIC(12,2) NOT NULL DEFAULT 0,
  price_per_month NUMERIC(12,2),
  address TEXT,
  region TEXT,
  city TEXT NOT NULL,
  area TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  geog GEOGRAPHY(Point, 4326),
  bedrooms INTEGER NOT NULL DEFAULT 0,
  bathrooms INTEGER NOT NULL DEFAULT 0,
  max_guests INTEGER NOT NULL DEFAULT 1,
  amenities JSONB DEFAULT '[]'::jsonb,
  photos TEXT[] DEFAULT '{}',
  main_image_url TEXT,
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  average_rating NUMERIC(3,2) NOT NULL DEFAULT 0,
  review_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  additional_info JSONB DEFAULT '{}'::jsonb
);

-- إنشاء view لـ properties بعد إنشاء جدول listings مع إضافة عمود rating
CREATE OR REPLACE VIEW public.properties AS 
SELECT *, average_rating as rating FROM public.listings;

-- =====================================================
-- 📷 جدول صور العقارات
-- =====================================================
CREATE TABLE IF NOT EXISTS public.listing_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- 📅 جدول الحجوزات
-- =====================================================
CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  nights INTEGER,
  total_price NUMERIC(12,2) NOT NULL,
  status booking_status NOT NULL DEFAULT 'pending',
  payment_method payment_method,
  payment_status payment_status NOT NULL DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- إضافة عمود المدى الزمني للتحقق من التداخل
  ts_range TSTZRANGE GENERATED ALWAYS AS (tstzrange(start_date, end_date, '[)')) STORED,
  
  -- قيود التحقق
  CONSTRAINT bookings_check_dates CHECK (end_date > start_date),
  CONSTRAINT bookings_check_tenant_host CHECK (tenant_id != host_id)
);

-- منع تداخل الحجوزات لنفس العقار
ALTER TABLE public.bookings
  DROP CONSTRAINT IF EXISTS bookings_no_overlap;
ALTER TABLE public.bookings
  ADD CONSTRAINT bookings_no_overlap
  EXCLUDE USING gist (
    listing_id WITH =,
    ts_range WITH &&
  )
  WHERE (status != 'cancelled');

-- =====================================================
-- 💳 جدول المدفوعات
-- =====================================================
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL,
  method payment_method NOT NULL,
  status payment_status NOT NULL DEFAULT 'pending',
  transaction_id TEXT,
  message TEXT,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- =====================================================
-- 💰 جدول المبالغ المستردة
-- =====================================================
CREATE TABLE IF NOT EXISTS public.refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  admin_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- =====================================================
-- ⭐ جدول التقييمات
-- =====================================================
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating NUMERIC(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- تأكد من تقييم واحد لكل حجز
  UNIQUE(booking_id)
);

-- =====================================================
-- ❤️ جدول المفضلة
-- =====================================================
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- منع التكرار
  UNIQUE(tenant_id, listing_id)
);

-- =====================================================
-- 🔔 جدول الإشعارات
-- =====================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type notification_type NOT NULL DEFAULT 'info',
  data JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- 💬 جداول المحادثات
-- =====================================================
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT,
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.chat_participants (
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (chat_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'text',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  seen_at TIMESTAMPTZ
);

-- =====================================================
-- 📊 جداول المراقبة والتحليلات
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.property_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ip_address INET,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.security_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  details JSONB DEFAULT '{}'::jsonb,
  ip_address INET,
  user_agent TEXT,
  risk_score INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- 🔍 الفهارس لتحسين الأداء
-- =====================================================

-- فهارس جدول المستخدمين
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_active ON public.profiles(is_active);

-- فهارس جدول العقارات
CREATE INDEX IF NOT EXISTS idx_listings_host_id ON public.listings(host_id);
CREATE INDEX IF NOT EXISTS idx_listings_city ON public.listings(city);
CREATE INDEX IF NOT EXISTS idx_listings_published ON public.listings(is_published);
CREATE INDEX IF NOT EXISTS idx_listings_available ON public.listings(is_available);
CREATE INDEX IF NOT EXISTS idx_listings_price ON public.listings(price_per_night);
CREATE INDEX IF NOT EXISTS idx_listings_rating ON public.listings(average_rating);
CREATE INDEX IF NOT EXISTS idx_listings_geog_gist ON public.listings USING gist(geog);
CREATE INDEX IF NOT EXISTS idx_listings_property_type ON public.listings(property_type);

-- فهارس جدول الحجوزات
CREATE INDEX IF NOT EXISTS idx_bookings_listing_id ON public.bookings(listing_id);
CREATE INDEX IF NOT EXISTS idx_bookings_tenant_id ON public.bookings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_bookings_host_id ON public.bookings(host_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_dates ON public.bookings(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_bookings_created_at ON public.bookings(created_at);

-- فهارس جدول المدفوعات
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON public.payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_method ON public.payments(method);

-- فهارس جدول المفضلة
CREATE INDEX IF NOT EXISTS idx_favorites_tenant_id ON public.favorites(tenant_id);
CREATE INDEX IF NOT EXISTS idx_favorites_listing_id ON public.favorites(listing_id);

-- فهارس جدول الإشعارات
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);

-- فهارس جداول المحادثات
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON public.messages(chat_id, created_at);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user_id ON public.chat_participants(user_id);

-- فهارس جداول المراقبة
CREATE INDEX IF NOT EXISTS idx_user_actions_user_id ON public.user_actions(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_property_views_listing_id ON public.property_views(listing_id);
CREATE INDEX IF NOT EXISTS idx_security_logs_event_type ON public.security_logs(event_type, created_at);
CREATE INDEX IF NOT EXISTS idx_security_logs_risk_score ON public.security_logs(risk_score DESC);

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
-- 🔧 دوال المحفزات والأتمتة
-- =====================================================

-- دالة تحديث updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- دالة حساب عدد الليالي
CREATE OR REPLACE FUNCTION public.bookings_compute_nights()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.start_date IS NOT NULL AND NEW.end_date IS NOT NULL THEN
    IF NEW.end_date <= NEW.start_date THEN
      RAISE EXCEPTION 'end_date must be greater than start_date';
    END IF;
    NEW.nights := GREATEST(1, CEIL(EXTRACT(EPOCH FROM (NEW.end_date - NEW.start_date)) / 86400.0));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- دالة إعادة حساب تقييم العقار
CREATE OR REPLACE FUNCTION public.update_listing_rating(p_listing_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.listings 
  SET 
    average_rating = COALESCE((
      SELECT AVG(rating)::NUMERIC(3,2) 
      FROM public.reviews 
      WHERE listing_id = p_listing_id
    ), 0),
    review_count = COALESCE((
      SELECT COUNT(*) 
      FROM public.reviews 
      WHERE listing_id = p_listing_id
    ), 0)
  WHERE id = p_listing_id;
END;
$$ LANGUAGE plpgsql;

-- دالة تحديث الموقع الجغرافي
CREATE OR REPLACE FUNCTION public.update_listing_geog()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL THEN
    NEW.geog := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326)::geography;
  ELSE
    NEW.geog := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- دالة إضافة منشئ المحادثة كمشارك
CREATE OR REPLACE FUNCTION public.add_chat_creator_as_participant()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.chat_participants(chat_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'owner')
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 🔄 المحفزات (TRIGGERS)
-- =====================================================

-- محفز تحديث updated_at للمستخدمين
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- محفز تحديث updated_at للعقارات
DROP TRIGGER IF EXISTS trg_listings_updated_at ON public.listings;
CREATE TRIGGER trg_listings_updated_at
  BEFORE UPDATE ON public.listings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- محفز تحديث الموقع الجغرافي للعقارات
DROP TRIGGER IF EXISTS trg_listings_geog ON public.listings;
CREATE TRIGGER trg_listings_geog
  BEFORE INSERT OR UPDATE OF lat, lng ON public.listings
  FOR EACH ROW EXECUTE FUNCTION public.update_listing_geog();

-- محفز تحديث updated_at للحجوزات
DROP TRIGGER IF EXISTS trg_bookings_updated_at ON public.bookings;
CREATE TRIGGER trg_bookings_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- محفز حساب عدد الليالي
DROP TRIGGER IF EXISTS trg_bookings_compute_nights ON public.bookings;
CREATE TRIGGER trg_bookings_compute_nights
  BEFORE INSERT OR UPDATE OF start_date, end_date ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.bookings_compute_nights();

-- دالة محفز تحديث تقييم العقار
CREATE OR REPLACE FUNCTION public.trigger_update_listing_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.update_listing_rating(OLD.listing_id);
    RETURN OLD;
  ELSE
    PERFORM public.update_listing_rating(NEW.listing_id);
    RETURN NEW;
  END IF;
END;
$$;

-- محفز تحديث تقييم العقار عند إضافة/تعديل/حذف تقييم
DROP TRIGGER IF EXISTS trg_reviews_update_rating ON public.reviews;
CREATE TRIGGER trg_reviews_update_rating
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.trigger_update_listing_rating();

-- محفز إضافة منشئ المحادثة كمشارك
DROP TRIGGER IF EXISTS trg_chats_add_creator ON public.chats;
CREATE TRIGGER trg_chats_add_creator
  AFTER INSERT ON public.chats
  FOR EACH ROW EXECUTE FUNCTION public.add_chat_creator_as_participant();

-- =====================================================
-- 🔐 تفعيل RLS على جميع الجداول
-- =====================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listing_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_logs ENABLE ROW LEVEL SECURITY;

COMMIT;
