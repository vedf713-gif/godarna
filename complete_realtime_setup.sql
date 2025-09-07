-- =====================================================
-- 🔄 إعداد نظام Realtime الشامل لتطبيق GoDarna
-- =====================================================

-- 1. تفعيل Realtime للجداول الأساسية
DO $$
BEGIN
    -- إضافة الجداول للـ realtime publication
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
    EXCEPTION WHEN duplicate_object THEN
        NULL; -- الجدول مُضاف مسبقاً
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE listings;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE messages;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE favorites;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE reviews;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE payments;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE chats;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE chat_participants;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
END $$;

-- 2. إنشاء أنواع البيانات المخصصة أولاً
DO $$
BEGIN
    -- إنشاء نوع الإشعارات
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
    END IF;
    
    -- إنشاء نوع حالة الحجز إذا لم يكن موجود
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status') THEN
        CREATE TYPE booking_status AS ENUM (
            'pending',
            'confirmed',
            'cancelled',
            'completed'
        );
    END IF;
END $$;

-- 3. التحقق من وجود الجداول المطلوبة
DO $$
BEGIN
    -- التحقق من جدول الإشعارات
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notifications') THEN
        CREATE TABLE notifications (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            type notification_type DEFAULT 'general',
            data JSONB DEFAULT '{}',
            read BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- إنشاء فهارس للأداء
        CREATE INDEX idx_notifications_user_id ON notifications(user_id);
        CREATE INDEX idx_notifications_read ON notifications(read);
        CREATE INDEX idx_notifications_created_at ON notifications(created_at);
        
        -- تفعيل RLS
        ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- 3. إصلاح سياسات RLS للإشعارات
DROP POLICY IF EXISTS "notifications_select_own" ON notifications;
DROP POLICY IF EXISTS "notifications_insert_authenticated" ON notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON notifications;
DROP POLICY IF EXISTS "notifications_delete_own" ON notifications;

-- سياسات جديدة محسنة
CREATE POLICY "notifications_select_own" ON notifications
FOR SELECT TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "notifications_insert_authenticated" ON notifications
FOR INSERT TO authenticated
WITH CHECK (true); -- السماح لأي مستخدم مصادق عليه بإرسال إشعارات

CREATE POLICY "notifications_update_own" ON notifications
FOR UPDATE TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "notifications_delete_own" ON notifications
FOR DELETE TO authenticated
USING (user_id = auth.uid());

-- 4. دالة إرسال الإشعارات المحسنة
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
BEGIN
    INSERT INTO notifications (user_id, title, message, type, data)
    VALUES (p_user_id, p_title, p_message, p_type::notification_type, p_data)
    RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$;

-- 5. دالة إرسال إشعارات متعددة
CREATE OR REPLACE FUNCTION send_bulk_notifications(
    p_user_ids UUID[],
    p_title TEXT,
    p_message TEXT,
    p_type notification_type DEFAULT 'general',
    p_data JSONB DEFAULT '{}'
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_id UUID;
    count INTEGER := 0;
BEGIN
    FOREACH user_id IN ARRAY p_user_ids
    LOOP
        INSERT INTO notifications (user_id, title, message, type, data)
        VALUES (user_id, p_title, p_message, p_type, p_data);
        count := count + 1;
    END LOOP;
    
    RETURN count;
END;
$$;

-- 6. محفزات الإشعارات التلقائية

-- محفز إشعار الحجز الجديد
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
    
    -- إشعار المضيف
    PERFORM send_notification(
        host_id,
        'حجز جديد',
        'تم استلام حجز جديد لعقار: ' || property_title,
        'booking_confirmed',
        jsonb_build_object('booking_id', NEW.id, 'listing_id', NEW.listing_id)
    );
    
    -- إشعار المستأجر
    PERFORM send_notification(
        NEW.tenant_id,
        'تم إرسال طلب الحجز',
        'تم إرسال طلب حجزك لعقار: ' || property_title,
        'booking_confirmed',
        jsonb_build_object('booking_id', NEW.id, 'listing_id', NEW.listing_id)
    );
    
    RETURN NEW;
END;
$$;

-- محفز إشعار تغيير حالة الحجز
CREATE OR REPLACE FUNCTION notify_booking_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    property_title TEXT;
    status_message TEXT;
BEGIN
    -- التحقق من تغيير الحالة
    IF OLD.status != NEW.status THEN
        -- الحصول على عنوان العقار
        SELECT l.title INTO property_title
        FROM listings l
        WHERE l.id = NEW.listing_id;
        
        -- تحديد رسالة الحالة
        CASE NEW.status
            WHEN 'confirmed' THEN status_message := 'تم تأكيد حجزك';
            WHEN 'cancelled' THEN status_message := 'تم إلغاء حجزك';
            WHEN 'completed' THEN status_message := 'تم إكمال حجزك';
            ELSE status_message := 'تم تحديث حالة حجزك';
        END CASE;
        
        -- إشعار المستأجر
        PERFORM send_notification(
            NEW.tenant_id,
            'تحديث حالة الحجز',
            status_message || ' لعقار: ' || property_title,
            ('booking_' || NEW.status)::notification_type,
            jsonb_build_object('booking_id', NEW.id, 'listing_id', NEW.listing_id, 'status', NEW.status)
        );
        
        -- إشعار المضيف إذا كان الإلغاء من المستأجر
        IF NEW.status = 'cancelled' THEN
            SELECT l.host_id INTO host_id
            FROM listings l
            WHERE l.id = NEW.listing_id;
            
            PERFORM send_notification(
                host_id,
                'إلغاء حجز',
                'تم إلغاء حجز لعقار: ' || property_title,
                'booking_cancelled',
                jsonb_build_object('booking_id', NEW.id, 'listing_id', NEW.listing_id)
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- محفز إشعار الرسائل الجديدة
CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    recipient_ids UUID[];
    participant_id UUID;
    sender_name TEXT;
BEGIN
    -- الحصول على اسم المرسل
    SELECT full_name INTO sender_name
    FROM profiles
    WHERE id = NEW.sender_id;
    
    -- الحصول على معرفات المشاركين (عدا المرسل)
    SELECT ARRAY(
        SELECT user_id 
        FROM chat_participants 
        WHERE chat_id = NEW.chat_id AND user_id != NEW.sender_id
    ) INTO recipient_ids;
    
    -- إرسال إشعارات للمشاركين
    PERFORM send_bulk_notifications(
        recipient_ids,
        'رسالة جديدة',
        'رسالة جديدة من ' || COALESCE(sender_name, 'مستخدم'),
        'new_message',
        jsonb_build_object('chat_id', NEW.chat_id, 'message_id', NEW.id, 'sender_id', NEW.sender_id)
    );
    
    RETURN NEW;
END;
$$;

-- محفز إشعار المراجعات الجديدة
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
    SELECT full_name INTO reviewer_name
    FROM profiles
    WHERE id = NEW.reviewer_id;
    
    -- إشعار المضيف
    PERFORM send_notification(
        host_id,
        'مراجعة جديدة',
        'مراجعة جديدة من ' || COALESCE(reviewer_name, 'مستخدم') || ' لعقار: ' || property_title,
        'new_review',
        jsonb_build_object('review_id', NEW.id, 'listing_id', NEW.listing_id, 'rating', NEW.rating)
    );
    
    RETURN NEW;
END;
$$;

-- 7. إنشاء المحفزات
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

-- 8. دالة تنظيف الإشعارات القديمة
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- حذف الإشعارات المقروءة الأقدم من 30 يوم
    DELETE FROM notifications
    WHERE read = TRUE 
    AND created_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- حذف الإشعارات غير المقروءة الأقدم من 90 يوم
    DELETE FROM notifications
    WHERE read = FALSE 
    AND created_at < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS deleted_count = deleted_count + ROW_COUNT;
    
    RETURN deleted_count;
END;
$$;

-- 9. دالة إحصائيات الإشعارات
CREATE OR REPLACE FUNCTION get_notification_stats(p_user_id UUID)
RETURNS TABLE(
    total_count BIGINT,
    unread_count BIGINT,
    today_count BIGINT,
    week_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_count,
        COUNT(*) FILTER (WHERE read = FALSE) as unread_count,
        COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE) as today_count,
        COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as week_count
    FROM notifications
    WHERE user_id = p_user_id;
END;
$$;

-- 10. دالة تحديد الإشعارات كمقروءة
CREATE OR REPLACE FUNCTION mark_notifications_as_read(
    p_user_id UUID,
    p_notification_ids UUID[] DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    IF p_notification_ids IS NULL THEN
        -- تحديد جميع الإشعارات كمقروءة
        UPDATE notifications
        SET read = TRUE, updated_at = NOW()
        WHERE user_id = p_user_id AND read = FALSE;
    ELSE
        -- تحديد إشعارات محددة كمقروءة
        UPDATE notifications
        SET read = TRUE, updated_at = NOW()
        WHERE user_id = p_user_id 
        AND id = ANY(p_notification_ids)
        AND read = FALSE;
    END IF;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$;

-- 11. التحقق من إعدادات Realtime
DO $$
BEGIN
    -- التحقق من أن الجداول مضافة للـ realtime
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
    END IF;
    
    RAISE NOTICE 'تم إعداد نظام Realtime والإشعارات بنجاح';
END $$;

-- 12. منح الصلاحيات
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT EXECUTE ON FUNCTION send_notification TO authenticated;
GRANT EXECUTE ON FUNCTION send_bulk_notifications TO authenticated;
GRANT EXECUTE ON FUNCTION get_notification_stats TO authenticated;
GRANT EXECUTE ON FUNCTION mark_notifications_as_read TO authenticated;

-- =====================================================
-- ✅ تم إكمال إعداد نظام Realtime والإشعارات الشامل
-- =====================================================

/*
الميزات المضافة:
1. ✅ تفعيل Realtime لجميع الجداول المطلوبة
2. ✅ إنشاء/تحديث جدول الإشعارات مع الفهارس
3. ✅ سياسات RLS محسنة وآمنة
4. ✅ دوال إرسال الإشعارات (فردية ومتعددة)
5. ✅ محفزات تلقائية للإشعارات:
   - الحجوزات الجديدة
   - تغيير حالة الحجز
   - الرسائل الجديدة
   - المراجعات الجديدة
6. ✅ دالة تنظيف الإشعارات القديمة
7. ✅ دالة إحصائيات الإشعارات
8. ✅ دالة تحديد الإشعارات كمقروءة
9. ✅ منح الصلاحيات المناسبة

النظام الآن جاهز للعمل مع Realtime بكفاءة عالية!
*/
