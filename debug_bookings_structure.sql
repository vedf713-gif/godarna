-- فحص وإصلاح هيكل جدول الحجوزات
-- هذا الملف سيفحص الهيكل الحالي ويصلح أي مشاكل

-- 1. فحص الأعمدة الموجودة في جدول bookings
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'bookings' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. فحص المحفزات (triggers) المرتبطة بجدول bookings
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'bookings' AND event_object_schema = 'public';

-- 3. فحص الدوال المرتبطة بجدول bookings
SELECT routine_name, routine_definition
FROM information_schema.routines 
WHERE routine_definition LIKE '%bookings%' AND routine_schema = 'public';

-- 4. إصلاح شامل للجدول
DO $$
BEGIN
    -- حذف المحفزات القديمة التي قد تسبب المشكلة
    DROP TRIGGER IF EXISTS bookings_touch_updated ON public.bookings;
    DROP TRIGGER IF EXISTS trg_bookings_compute_nights ON public.bookings;
    DROP TRIGGER IF EXISTS trg_bookings_compute_nights_upd ON public.bookings;
    DROP TRIGGER IF EXISTS bookings_new_notification ON public.bookings;
    DROP TRIGGER IF EXISTS bookings_status_notification ON public.bookings;
    
    -- حذف الدوال القديمة
    DROP FUNCTION IF EXISTS public.bookings_compute_nights() CASCADE;
    DROP FUNCTION IF EXISTS public.handle_booking_notification() CASCADE;
    
    -- التأكد من وجود الأعمدة الصحيحة
    -- إضافة start_date إذا لم يكن موجوداً
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bookings' AND column_name = 'start_date') THEN
        ALTER TABLE public.bookings ADD COLUMN start_date TIMESTAMPTZ;
    END IF;
    
    -- إضافة end_date إذا لم يكن موجوداً
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'bookings' AND column_name = 'end_date') THEN
        ALTER TABLE public.bookings ADD COLUMN end_date TIMESTAMPTZ;
    END IF;
    
    -- نسخ البيانات من الأعمدة القديمة إذا كانت موجودة
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_in') THEN
        UPDATE public.bookings SET start_date = check_in WHERE start_date IS NULL;
        ALTER TABLE public.bookings DROP COLUMN check_in;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_out') THEN
        UPDATE public.bookings SET end_date = check_out WHERE end_date IS NULL;
        ALTER TABLE public.bookings DROP COLUMN check_out;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_in_date') THEN
        UPDATE public.bookings SET start_date = check_in_date WHERE start_date IS NULL;
        ALTER TABLE public.bookings DROP COLUMN check_in_date;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_out_date') THEN
        UPDATE public.bookings SET end_date = check_out_date WHERE end_date IS NULL;
        ALTER TABLE public.bookings DROP COLUMN check_out_date;
    END IF;
    
    -- التأكد من أن الأعمدة مطلوبة
    ALTER TABLE public.bookings ALTER COLUMN start_date SET NOT NULL;
    ALTER TABLE public.bookings ALTER COLUMN end_date SET NOT NULL;
    
    RAISE NOTICE 'تم إصلاح هيكل جدول bookings بنجاح';
END $$;

-- 5. إعادة إنشاء الدوال المحدثة
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

-- 6. إعادة إنشاء المحفزات
CREATE TRIGGER trg_bookings_compute_nights
  BEFORE INSERT ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.bookings_compute_nights();

CREATE TRIGGER trg_bookings_compute_nights_upd
  BEFORE UPDATE OF start_date, end_date ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.bookings_compute_nights();

-- 7. إنشاء دالة تحديث الوقت وإعادة إنشاء trigger التحديث
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END; $$;

CREATE TRIGGER bookings_touch_updated
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- 8. إعادة إنشاء القيود
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_check_dates;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_check_dates 
  CHECK (end_date > start_date);

-- 9. إعادة إنشاء عمود المدى الزمني
ALTER TABLE public.bookings DROP COLUMN IF EXISTS ts_range;
ALTER TABLE public.bookings ADD COLUMN ts_range TSTZRANGE 
  GENERATED ALWAYS AS (tstzrange(start_date, end_date, '[)')) STORED;

-- 10. إعادة إنشاء قيد منع التداخل
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_no_overlap;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_no_overlap
  EXCLUDE USING gist (
    listing_id WITH =,
    ts_range WITH &&
  ) WHERE (status <> 'cancelled');

-- 11. فحص نهائي للتأكد من الإصلاح
SELECT 'تم الإصلاح بنجاح - الأعمدة الموجودة:' as status;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'bookings' AND table_schema = 'public'
AND column_name IN ('start_date', 'end_date')
ORDER BY column_name;
