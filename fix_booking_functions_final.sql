-- إصلاح شامل لجميع الدوال والمحفزات في نظام الحجز
-- لاستخدام start_date و end_date بدلاً من check_in_date و check_out_date

-- =====================================================
-- 1. حذف جميع المحفزات القديمة
-- =====================================================

DROP TRIGGER IF EXISTS bookings_touch_updated ON public.bookings;
DROP TRIGGER IF EXISTS trg_bookings_compute_nights ON public.bookings;
DROP TRIGGER IF EXISTS trg_bookings_compute_nights_upd ON public.bookings;
DROP TRIGGER IF EXISTS trg_bookings_updated_at ON public.bookings;
DROP TRIGGER IF EXISTS trigger_notify_booking_status_change ON public.bookings;
DROP TRIGGER IF EXISTS trigger_notify_new_booking ON public.bookings;
DROP TRIGGER IF EXISTS validate_booking_trigger ON public.bookings;

-- =====================================================
-- 2. حذف الدوال القديمة (المتعلقة بالحجوزات فقط)
-- =====================================================

DROP FUNCTION IF EXISTS public.bookings_compute_nights();
DROP FUNCTION IF EXISTS public.notify_new_booking();
DROP FUNCTION IF EXISTS public.notify_booking_status_change();
DROP FUNCTION IF EXISTS public.validate_booking_insert();
-- لا نحذف set_updated_at و touch_updated_at لأنها مستخدمة في جداول أخرى

-- =====================================================
-- 3. إنشاء الدوال المحدثة
-- =====================================================

-- لا نحتاج إنشاء touch_updated_at و set_updated_at لأنها موجودة ومستخدمة في جداول أخرى

-- دالة حساب عدد الليالي
CREATE OR REPLACE FUNCTION public.bookings_compute_nights()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- حساب عدد الليالي بناءً على start_date و end_date
  NEW.nights := EXTRACT(EPOCH FROM (NEW.end_date - NEW.start_date)) / 86400;
  RETURN NEW;
END; $$;

-- دالة التحقق من صحة الحجز
CREATE OR REPLACE FUNCTION public.validate_booking_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- التحقق من أن تاريخ النهاية بعد تاريخ البداية
  IF NEW.end_date <= NEW.start_date THEN
    RAISE EXCEPTION 'تاريخ انتهاء الحجز يجب أن يكون بعد تاريخ البداية';
  END IF;
  
  -- التحقق من أن المستأجر ليس هو المضيف
  IF NEW.tenant_id = NEW.host_id THEN
    RAISE EXCEPTION 'لا يمكن للمضيف حجز عقاره الخاص';
  END IF;
  
  RETURN NEW;
END; $$;

-- دالة إشعار الحجز الجديد (محدثة)
CREATE OR REPLACE FUNCTION public.notify_new_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- إرسال إشعار للمضيف
  INSERT INTO public.notifications (
    user_id,
    type,
    title,
    message,
    data
  ) VALUES (
    NEW.host_id,
    'booking_pending',
    'طلب حجز جديد',
    'تم استلام طلب حجز جديد لعقارك',
    jsonb_build_object(
        'booking_id', NEW.id, 
        'listing_id', NEW.listing_id,
        'tenant_id', NEW.tenant_id,
        'start_date', NEW.start_date,
        'end_date', NEW.end_date,
        'total_price', NEW.total_price
    )
  );
  
  RETURN NEW;
END; $$;

-- دالة إشعار تغيير حالة الحجز (محدثة)
CREATE OR REPLACE FUNCTION public.notify_booking_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    notification_type_val TEXT;
BEGIN
  -- إشعار المستأجر بتغيير الحالة
  IF OLD.status != NEW.status THEN
    -- تحديد نوع الإشعار بناءً على الحالة الجديدة
    CASE NEW.status
        WHEN 'confirmed' THEN 
            notification_type_val := 'booking_confirmed';
        WHEN 'cancelled' THEN 
            notification_type_val := 'booking_cancelled';
        WHEN 'completed' THEN 
            notification_type_val := 'booking_completed';
        WHEN 'rejected' THEN 
            notification_type_val := 'booking_cancelled';
        ELSE 
            notification_type_val := 'general';
    END CASE;
    
    INSERT INTO public.notifications (
      user_id,
      type,
      title,
      message,
      data
    ) VALUES (
      NEW.tenant_id,
      notification_type_val,
      'تحديث حالة الحجز',
      'تم تحديث حالة حجزك إلى: ' || NEW.status,
      jsonb_build_object(
          'booking_id', NEW.id,
          'old_status', OLD.status,
          'new_status', NEW.status,
          'start_date', NEW.start_date,
          'end_date', NEW.end_date
      )
    );
  END IF;
  
  RETURN NEW;
END; $$;

-- =====================================================
-- 4. إعادة إنشاء المحفزات
-- =====================================================

-- محفز تحديث updated_at
CREATE TRIGGER bookings_touch_updated 
  BEFORE UPDATE ON public.bookings 
  FOR EACH ROW 
  EXECUTE FUNCTION touch_updated_at();

-- محفز حساب الليالي عند الإدراج
CREATE TRIGGER trg_bookings_compute_nights 
  BEFORE INSERT ON public.bookings 
  FOR EACH ROW 
  EXECUTE FUNCTION bookings_compute_nights();

-- محفز حساب الليالي عند التحديث
CREATE TRIGGER trg_bookings_compute_nights_upd 
  BEFORE UPDATE OF start_date, end_date ON public.bookings 
  FOR EACH ROW 
  EXECUTE FUNCTION bookings_compute_nights();

-- محفز تحديث updated_at
CREATE TRIGGER trg_bookings_updated_at 
  BEFORE UPDATE ON public.bookings 
  FOR EACH ROW 
  EXECUTE FUNCTION set_updated_at();

-- محفز إشعار تغيير الحالة
CREATE TRIGGER trigger_notify_booking_status_change 
  AFTER UPDATE ON public.bookings 
  FOR EACH ROW 
  EXECUTE FUNCTION notify_booking_status_change();

-- محفز إشعار الحجز الجديد
CREATE TRIGGER trigger_notify_new_booking 
  AFTER INSERT ON public.bookings 
  FOR EACH ROW 
  EXECUTE FUNCTION notify_new_booking();

-- محفز التحقق من صحة الحجز
CREATE TRIGGER validate_booking_trigger 
  BEFORE INSERT ON public.bookings 
  FOR EACH ROW 
  EXECUTE FUNCTION validate_booking_insert();

-- =====================================================
-- 5. تنظيف البيانات القديمة (إن وجدت)
-- =====================================================

-- إزالة أي أعمدة قديمة إن وجدت
DO $$
BEGIN
    -- حذف check_in_date إن وجد
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_in_date') THEN
        -- نقل البيانات أولاً
        UPDATE public.bookings 
        SET start_date = check_in_date 
        WHERE start_date IS NULL AND check_in_date IS NOT NULL;
        
        -- حذف العمود
        ALTER TABLE public.bookings DROP COLUMN check_in_date;
    END IF;
    
    -- حذف check_out_date إن وجد
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_out_date') THEN
        -- نقل البيانات أولاً
        UPDATE public.bookings 
        SET end_date = check_out_date 
        WHERE end_date IS NULL AND check_out_date IS NOT NULL;
        
        -- حذف العمود
        ALTER TABLE public.bookings DROP COLUMN check_out_date;
    END IF;
    
    -- حذف أي أعمدة أخرى قديمة
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_in') THEN
        ALTER TABLE public.bookings DROP COLUMN check_in;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'bookings' AND column_name = 'check_out') THEN
        ALTER TABLE public.bookings DROP COLUMN check_out;
    END IF;
END $$;

-- =====================================================
-- 6. التحقق من النتائج
-- =====================================================

-- عرض هيكل الجدول النهائي
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'bookings' 
ORDER BY ordinal_position;

-- عرض المحفزات النشطة
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'bookings';

COMMENT ON TABLE public.bookings IS 'جدول الحجوزات - تم تحديثه لاستخدام start_date و end_date';
