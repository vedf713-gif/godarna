-- إصلاح أسماء أعمدة جدول الحجوزات لتوحيد التسمية
-- تغيير من check_in/check_out إلى start_date/end_date

-- 1. إزالة القيود والفهارس المرتبطة بالأعمدة القديمة
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_check_dates;
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_check_bounds;
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_no_overlap;

DROP INDEX IF EXISTS idx_bookings_check_in;
DROP INDEX IF EXISTS idx_bookings_check_out;
DROP INDEX IF EXISTS idx_bookings_checkin;
DROP INDEX IF EXISTS idx_bookings_checkout;

-- 2. إعادة تسمية الأعمدة إذا كانت موجودة بالأسماء القديمة
DO $$
BEGIN
    -- تحقق من وجود العمود check_in وإعادة تسميته
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_in') THEN
        ALTER TABLE public.bookings RENAME COLUMN check_in TO start_date;
    END IF;
    
    -- تحقق من وجود العمود check_out وإعادة تسميته
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_out') THEN
        ALTER TABLE public.bookings RENAME COLUMN check_out TO end_date;
    END IF;
    
    -- تحقق من وجود العمود check_in_date وإعادة تسميته
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_in_date') THEN
        ALTER TABLE public.bookings RENAME COLUMN check_in_date TO start_date;
    END IF;
    
    -- تحقق من وجود العمود check_out_date وإعادة تسميته
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_out_date') THEN
        ALTER TABLE public.bookings RENAME COLUMN check_out_date TO end_date;
    END IF;
END $$;

-- 3. التأكد من وجود الأعمدة بالأسماء الصحيحة
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ;

ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ;

-- 4. إعادة إنشاء القيود
ALTER TABLE public.bookings
ADD CONSTRAINT bookings_check_dates CHECK (end_date > start_date);

-- 5. إعادة إنشاء عمود المدى الزمني
ALTER TABLE public.bookings DROP COLUMN IF EXISTS ts_range;
ALTER TABLE public.bookings
ADD COLUMN ts_range TSTZRANGE GENERATED ALWAYS AS (tstzrange(start_date, end_date, '[)')) STORED;

-- 6. إعادة إنشاء قيد منع التداخل
ALTER TABLE public.bookings
ADD CONSTRAINT bookings_no_overlap
EXCLUDE USING gist (
  listing_id WITH =,
  ts_range WITH &&
) WHERE (status <> 'cancelled');

-- 7. إعادة إنشاء الفهارس
CREATE INDEX IF NOT EXISTS idx_bookings_start_date ON public.bookings(start_date);
CREATE INDEX IF NOT EXISTS idx_bookings_end_date ON public.bookings(end_date);
CREATE INDEX IF NOT EXISTS idx_bookings_listing_id ON public.bookings(listing_id);
CREATE INDEX IF NOT EXISTS idx_bookings_tenant_id ON public.bookings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_bookings_host_id ON public.bookings(host_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);

-- 8. تحديث الدوال المرتبطة
CREATE OR REPLACE FUNCTION public.bookings_compute_nights()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.start_date IS NOT NULL AND NEW.end_date IS NOT NULL THEN
    IF NEW.end_date <= NEW.start_date THEN
      RAISE EXCEPTION 'end_date must be greater than start_date';
    END IF;
    NEW.nights := GREATEST(1, CEIL(EXTRACT(EPOCH FROM (NEW.end_date - NEW.start_date)) / 86400.0));
  END IF;
  RETURN NEW;
END; $$;

-- 9. تحديث المحفزات
DROP TRIGGER IF EXISTS trg_bookings_compute_nights ON public.bookings;
DROP TRIGGER IF EXISTS trg_bookings_compute_nights_upd ON public.bookings;

CREATE TRIGGER trg_bookings_compute_nights
  BEFORE INSERT ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.bookings_compute_nights();

CREATE TRIGGER trg_bookings_compute_nights_upd
  BEFORE UPDATE OF start_date, end_date ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.bookings_compute_nights();

-- 10. تحديث دالة التحقق من التوفر
CREATE OR REPLACE FUNCTION public.is_period_available(
  p_property_id uuid,
  p_from timestamptz,
  p_to timestamptz
) RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT NOT EXISTS (
    SELECT 1
    FROM public.bookings b
    WHERE b.listing_id = p_property_id
      AND b.status <> 'cancelled'
      AND b.end_date > p_from
      AND b.start_date < p_to
  );
$$;

-- 11. دالة للحصول على الحجوزات المتداخلة
CREATE OR REPLACE FUNCTION public.get_overlapping_bookings(
  p_property_id uuid,
  p_from timestamptz,
  p_to timestamptz
) RETURNS TABLE (
  start_date timestamptz,
  end_date timestamptz
)
LANGUAGE sql
STABLE
AS $$
  SELECT b.start_date, b.end_date
  FROM public.bookings b
  WHERE b.listing_id = p_property_id
    AND b.status <> 'cancelled'
    AND b.end_date > p_from
    AND b.start_date < p_to
  ORDER BY b.start_date;
$$;

COMMENT ON TABLE public.bookings IS 'جدول الحجوزات مع الأعمدة الموحدة: start_date و end_date';
