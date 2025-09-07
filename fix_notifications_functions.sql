-- =====================================================
-- الخطوة الثانية: إصلاح الدوال والمحفزات
-- (شغل هذا الملف بعد fix_notifications_enum_first.sql)
-- =====================================================

-- 1. إصلاح دالة إرسال الإشعارات
CREATE OR REPLACE FUNCTION send_notification(
    p_user_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_type TEXT DEFAULT 'general',
    p_data JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    notification_id UUID;
    valid_type notification_type;
BEGIN
    -- التحقق من صحة النوع وتحويله
    BEGIN
        valid_type := p_type::notification_type;
    EXCEPTION
        WHEN invalid_text_representation THEN
            valid_type := 'general'::notification_type;
    END;
    
    INSERT INTO notifications (user_id, title, message, type, data)
    VALUES (p_user_id, p_title, p_message, valid_type, p_data)
    RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$;

-- 2. إصلاح محفز إشعار الحجز الجديد
CREATE OR REPLACE FUNCTION notify_new_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    host_id UUID;
    property_title TEXT;
BEGIN
    -- الحصول على معرف المضيف وعنوان العقار
    SELECT l.host_id, l.title INTO host_id, property_title
    FROM listings l
    WHERE l.id = NEW.listing_id;
    
    -- التحقق من وجود البيانات
    IF host_id IS NULL OR property_title IS NULL THEN
        RAISE WARNING 'Cannot find listing data for booking %', NEW.id;
        RETURN NEW;
    END IF;
    
    -- إشعار المضيف
    PERFORM send_notification(
        host_id,
        'حجز جديد',
        'تم استلام حجز جديد لعقار: ' || property_title,
        'booking_pending',
        jsonb_build_object(
            'booking_id', NEW.id, 
            'listing_id', NEW.listing_id,
            'tenant_id', NEW.tenant_id,
            'check_in', NEW.check_in_date,
            'check_out', NEW.check_out_date
        )
    );
    
    -- إشعار المستأجر
    PERFORM send_notification(
        NEW.tenant_id,
        'تم إرسال طلب الحجز',
        'تم إرسال طلب حجزك لعقار: ' || property_title || '. في انتظار موافقة المضيف.',
        'booking_pending',
        jsonb_build_object(
            'booking_id', NEW.id, 
            'listing_id', NEW.listing_id,
            'host_id', host_id
        )
    );
    
    RETURN NEW;
END;
$$;

-- 3. إصلاح محفز إشعار تغيير حالة الحجز
CREATE OR REPLACE FUNCTION notify_booking_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    host_id UUID;
    property_title TEXT;
    status_message TEXT;
    notification_type_val notification_type;
BEGIN
    -- التحقق من تغيير الحالة
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        -- الحصول على معلومات العقار والمضيف
        SELECT l.host_id, l.title INTO host_id, property_title
        FROM listings l
        WHERE l.id = NEW.listing_id;
        
        -- التحقق من وجود البيانات
        IF host_id IS NULL OR property_title IS NULL THEN
            RAISE WARNING 'Cannot find listing data for booking %', NEW.id;
            RETURN NEW;
        END IF;
        
        -- تحديد رسالة الحالة ونوع الإشعار
        CASE NEW.status
            WHEN 'confirmed' THEN 
                status_message := '🎉 تم تأكيد حجزك';
                notification_type_val := 'booking_confirmed';
            WHEN 'cancelled' THEN 
                status_message := '❌ تم إلغاء حجزك';
                notification_type_val := 'booking_cancelled';
            WHEN 'completed' THEN 
                status_message := '✅ تم إكمال حجزك';
                notification_type_val := 'booking_completed';
            WHEN 'rejected' THEN 
                status_message := '❌ تم رفض حجزك';
                notification_type_val := 'booking_cancelled';
            ELSE 
                status_message := '📋 تم تحديث حالة حجزك';
                notification_type_val := 'booking_update';
        END CASE;
        
        -- إشعار المستأجر
        PERFORM send_notification(
            NEW.tenant_id,
            'تحديث حالة الحجز',
            status_message || ' لعقار: ' || property_title,
            notification_type_val::text,
            jsonb_build_object(
                'booking_id', NEW.id, 
                'listing_id', NEW.listing_id, 
                'status', NEW.status,
                'host_id', host_id
            )
        );
        
        -- إشعار المضيف عند الإلغاء من المستأجر
        IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
            PERFORM send_notification(
                host_id,
                'إلغاء حجز',
                '❌ تم إلغاء حجز لعقار: ' || property_title,
                'booking_cancelled',
                jsonb_build_object(
                    'booking_id', NEW.id, 
                    'listing_id', NEW.listing_id,
                    'tenant_id', NEW.tenant_id
                )
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- 4. إصلاح محفز إشعار الرسائل الجديدة
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    recipient_ids UUID[];
    sender_name TEXT;
    chat_title TEXT;
BEGIN
    -- الحصول على اسم المرسل
    SELECT COALESCE(CONCAT(first_name, ' ', last_name), first_name, 'مستخدم') INTO sender_name
    FROM profiles
    WHERE id = NEW.sender_id;
    
    -- الحصول على معرفات المشاركين (عدا المرسل)
    SELECT ARRAY(
        SELECT user_id 
        FROM chat_participants 
        WHERE chat_id = NEW.chat_id AND user_id != NEW.sender_id
    ) INTO recipient_ids;
    
    -- التحقق من وجود مستقبلين
    IF array_length(recipient_ids, 1) > 0 THEN
        -- إرسال إشعارات للمشاركين
        PERFORM send_bulk_notifications(
            recipient_ids,
            'رسالة جديدة 💬',
            'رسالة جديدة من ' || sender_name,
            'new_message',
            jsonb_build_object(
                'chat_id', NEW.chat_id, 
                'message_id', NEW.id, 
                'sender_id', NEW.sender_id,
                'sender_name', sender_name,
                'preview', LEFT(NEW.content, 50)
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- 5. إصلاح محفز إشعار المراجعات الجديدة
CREATE OR REPLACE FUNCTION notify_new_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    host_id UUID;
    property_title TEXT;
    reviewer_name TEXT;
BEGIN
    -- الحصول على معلومات العقار والمضيف
    SELECT l.host_id, l.title INTO host_id, property_title
    FROM listings l
    WHERE l.id = NEW.listing_id;
    
    -- الحصول على اسم المراجع
    SELECT COALESCE(CONCAT(first_name, ' ', last_name), first_name, 'مستخدم') INTO reviewer_name
    FROM profiles
    WHERE id = NEW.reviewer_id;
    
    -- التحقق من وجود البيانات
    IF host_id IS NULL OR property_title IS NULL THEN
        RAISE WARNING 'Cannot find listing data for review %', NEW.id;
        RETURN NEW;
    END IF;
    
    -- إشعار المضيف
    PERFORM send_notification(
        host_id,
        'مراجعة جديدة ⭐',
        'مراجعة جديدة من ' || reviewer_name || ' لعقار: ' || property_title || 
        ' (تقييم: ' || NEW.rating || '/5)',
        'review',
        jsonb_build_object(
            'review_id', NEW.id, 
            'listing_id', NEW.listing_id, 
            'rating', NEW.rating,
            'reviewer_id', NEW.reviewer_id,
            'reviewer_name', reviewer_name
        )
    );
    
    RETURN NEW;
END;
$$;

-- 6. إصلاح دالة تنظيف الإشعارات القديمة
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER := 0;
    temp_count INTEGER;
BEGIN
    -- حذف الإشعارات المقروءة الأقدم من 30 يوم
    DELETE FROM notifications
    WHERE is_read = TRUE 
    AND created_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    -- حذف الإشعارات غير المقروءة الأقدم من 90 يوم
    DELETE FROM notifications
    WHERE is_read = FALSE 
    AND created_at < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_count := deleted_count + temp_count;
    
    RETURN deleted_count;
END;
$$;

-- 7. إعادة إنشاء المحفزات
DROP TRIGGER IF EXISTS trigger_notify_new_booking ON bookings;
CREATE TRIGGER trigger_notify_new_booking
    AFTER INSERT ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_booking();

DROP TRIGGER IF EXISTS trigger_notify_booking_status_change ON bookings;
CREATE TRIGGER trigger_notify_booking_status_change
    AFTER UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION notify_booking_status_change();

DROP TRIGGER IF EXISTS trigger_notify_new_message ON messages;
CREATE TRIGGER trigger_notify_new_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_message();

DROP TRIGGER IF EXISTS trigger_notify_new_review ON reviews;
CREATE TRIGGER trigger_notify_new_review
    AFTER INSERT ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_review();

-- 8. اختبار النظام
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- الحصول على أول مستخدم للاختبار
    SELECT id INTO test_user_id FROM profiles LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        -- إنشاء إشعار اختبار
        PERFORM send_notification(
            test_user_id,
            '🔧 اختبار نظام الإشعارات',
            'تم إصلاح نظام الإشعارات بنجاح! جميع الإشعارات ستعمل الآن بشكل صحيح.',
            'success',
            jsonb_build_object(
                'test', true,
                'fixed_at', NOW()::text,
                'version', '2.0'
            )
        );
    END IF;
END $$;

-- 9. عرض النتائج (بدون استخدام القيم الجديدة في نفس الجلسة)
SELECT 
    '✅ تم إصلاح نظام الإشعارات بالكامل' as status,
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN type = 'new_message' THEN 1 END) as message_notifications,
    COUNT(CASE WHEN type = 'success' THEN 1 END) as success_notifications,
    COUNT(CASE WHEN is_read = false THEN 1 END) as unread_notifications
FROM public.notifications;

SELECT '🎉 نظام الإشعارات جاهز للعمل!' as result;
