-- =====================================================
-- إصلاح enum notification_type لإضافة قيم الرسائل
-- =====================================================

-- إضافة قيم جديدة لـ enum notification_type
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'new_message';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'booking_update';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'payment';
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'review';

-- عرض جميع قيم enum المتاحة الآن
SELECT 
    t.typname as enum_name,
    e.enumlabel as available_values
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
WHERE t.typname = 'notification_type'
ORDER BY e.enumsortorder;

-- COMMIT التغييرات قبل استخدام القيم الجديدة
COMMIT;

SELECT 'تم إضافة قيم enum جديدة - يمكن الآن استخدام new_message' as result;
