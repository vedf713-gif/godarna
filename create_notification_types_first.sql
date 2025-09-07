-- =====================================================
-- 🔧 إنشاء أنواع البيانات المخصصة أولاً
-- =====================================================

-- إنشاء نوع الإشعارات
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        CREATE TYPE notification_type AS ENUM (
            'general',
            'booking_confirmed',
            'booking_cancelled',
            'booking_completed',
            'new_message',
            'new_review',
            'payment_received',
            'payment_failed',
            'property_approved',
            'property_rejected'
        );
        RAISE NOTICE '✅ تم إنشاء نوع notification_type';
    ELSE
        RAISE NOTICE '⚠️ نوع notification_type موجود مسبقاً';
    END IF;
END $$;

-- إنشاء نوع حالة الحجز
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status') THEN
        CREATE TYPE booking_status AS ENUM (
            'pending',
            'confirmed',
            'cancelled',
            'completed'
        );
        RAISE NOTICE '✅ تم إنشاء نوع booking_status';
    ELSE
        RAISE NOTICE '⚠️ نوع booking_status موجود مسبقاً';
    END IF;
END $$;

-- إنشاء نوع أدوار المستخدمين
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM (
            'tenant',
            'host',
            'admin'
        );
        RAISE NOTICE '✅ تم إنشاء نوع user_role';
    ELSE
        RAISE NOTICE '⚠️ نوع user_role موجود مسبقاً';
    END IF;
END $$;

-- إنشاء نوع طرق الدفع
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
        CREATE TYPE payment_method AS ENUM (
            'credit_card',
            'bank_transfer',
            'cash',
            'paypal'
        );
        RAISE NOTICE '✅ تم إنشاء نوع payment_method';
    ELSE
        RAISE NOTICE '⚠️ نوع payment_method موجود مسبقاً';
    END IF;
END $$;

-- إنشاء نوع حالة الدفع
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
        CREATE TYPE payment_status AS ENUM (
            'pending',
            'completed',
            'failed',
            'refunded'
        );
        RAISE NOTICE '✅ تم إنشاء نوع payment_status';
    ELSE
        RAISE NOTICE '⚠️ نوع payment_status موجود مسبقاً';
    END IF;
END $$;

-- التحقق من النتائج
SELECT 
    'Custom Types Status' as check_type,
    typname as type_name,
    '✅ موجود' as status
FROM pg_type 
WHERE typname IN (
    'notification_type', 
    'booking_status', 
    'user_role', 
    'payment_method', 
    'payment_status'
)
ORDER BY typname;

RAISE NOTICE '🎉 تم إكمال إنشاء جميع الأنواع المخصصة';
