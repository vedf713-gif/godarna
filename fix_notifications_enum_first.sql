-- =====================================================
-- الخطوة الأولى: إضافة قيم enum الجديدة فقط
-- =====================================================

-- إضافة القيم المفقودة للـ enum (يجب تشغيلها منفصلة)
DO $$ BEGIN
    ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'booking_confirmed';
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'booking_cancelled';
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'booking_pending';
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'booking_completed';
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'new_review';
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'general';
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- عرض القيم المحدثة
SELECT 
    'تم إضافة قيم enum الجديدة:' as info,
    string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) as available_types
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid 
WHERE t.typname = 'notification_type';

SELECT '✅ الخطوة الأولى مكتملة - شغل الآن fix_notifications_functions.sql' as next_step;
