-- =====================================================
-- الحل النهائي والدائم لنظام الدردشة في GoDarna
-- =====================================================

-- 1. إصلاح دالة is_chat_participant (إذا لم تكن مُصلحة بعد)
DROP POLICY IF EXISTS "messages_select_participants" ON public.messages;
DROP POLICY IF EXISTS "messages_insert_participant_only" ON public.messages;
DROP POLICY IF EXISTS "messages_update_sender_only" ON public.messages;
DROP POLICY IF EXISTS "messages_delete_sender_or_admin" ON public.messages;

DROP FUNCTION IF EXISTS public.is_chat_participant(uuid, uuid);

CREATE OR REPLACE FUNCTION public.is_chat_participant(p_chat_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
  IF p_user_id IS NULL OR p_chat_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  RETURN EXISTS(
    SELECT 1 FROM public.chat_participants cp 
    WHERE cp.chat_id = p_chat_id AND cp.user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2. دالة ذكية لإنشاء الدردشة والمشاركين تلقائياً من معرف الحجز
CREATE OR REPLACE FUNCTION public.ensure_booking_chat(p_booking_id UUID)
RETURNS UUID AS $$
DECLARE
  v_chat_id UUID;
  v_tenant_id UUID;
  v_host_id UUID;
  v_listing_id UUID;
BEGIN
  -- استخراج معرف الدردشة من معرف الحجز
  v_chat_id := p_booking_id;
  
  -- الحصول على معرفات المستأجر والمضيف من جدول الحجوزات
  SELECT tenant_id, listing_id INTO v_tenant_id, v_listing_id
  FROM public.bookings 
  WHERE id = p_booking_id;
  
  -- الحصول على معرف المضيف من جدول العقارات
  SELECT host_id INTO v_host_id
  FROM public.listings 
  WHERE id = v_listing_id;
  
  -- إنشاء الدردشة إذا لم تكن موجودة
  INSERT INTO public.chats (id, created_by, created_at)
  VALUES (v_chat_id, v_tenant_id, NOW())
  ON CONFLICT (id) DO NOTHING;
  
  -- إضافة المستأجر للدردشة
  INSERT INTO public.chat_participants (chat_id, user_id)
  VALUES (v_chat_id, v_tenant_id)
  ON CONFLICT (chat_id, user_id) DO NOTHING;
  
  -- إضافة المضيف للدردشة
  IF v_host_id IS NOT NULL THEN
    INSERT INTO public.chat_participants (chat_id, user_id)
    VALUES (v_chat_id, v_host_id)
    ON CONFLICT (chat_id, user_id) DO NOTHING;
  END IF;
  
  RETURN v_chat_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. دالة لضمان مشاركة المستخدم في الدردشة
CREATE OR REPLACE FUNCTION public.ensure_user_in_chat(p_chat_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
  -- التأكد من وجود الدردشة
  IF NOT EXISTS (SELECT 1 FROM public.chats WHERE id = p_chat_id) THEN
    -- محاولة إنشاء الدردشة من معرف الحجز
    PERFORM public.ensure_booking_chat(p_chat_id);
  END IF;
  
  -- إضافة المستخدم للدردشة إذا لم يكن موجوداً
  INSERT INTO public.chat_participants (chat_id, user_id)
  VALUES (p_chat_id, p_user_id)
  ON CONFLICT (chat_id, user_id) DO NOTHING;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. دالة آمنة لإرسال الرسائل مع إنشاء الدردشة تلقائياً
CREATE OR REPLACE FUNCTION public.send_message_safe(
  p_chat_id UUID,
  p_content TEXT,
  p_sender_id UUID DEFAULT auth.uid()
) RETURNS UUID AS $$
DECLARE
  v_message_id UUID;
BEGIN
  -- ضمان وجود المستخدم في الدردشة
  PERFORM public.ensure_user_in_chat(p_chat_id, p_sender_id);
  
  -- إرسال الرسالة
  INSERT INTO public.messages (chat_id, sender_id, content)
  VALUES (p_chat_id, p_sender_id, p_content)
  RETURNING id INTO v_message_id;
  
  RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. إعادة إنشاء سياسات RLS للرسائل
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

-- 6. سياسة RLS للمشاركين في الدردشة (للسماح بالإضافة التلقائية)
DROP POLICY IF EXISTS "chat_participants_manage" ON public.chat_participants;
CREATE POLICY "chat_participants_manage" ON public.chat_participants
  FOR ALL USING (
    user_id = auth.uid() OR 
    public.is_admin() OR
    -- السماح للدوال الآمنة بإضافة المشاركين
    current_setting('role') = 'service_role'
  );

-- 7. منح صلاحيات للدوال الآمنة
GRANT EXECUTE ON FUNCTION public.ensure_booking_chat(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_user_in_chat(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_message_safe(UUID, TEXT, UUID) TO authenticated;

-- 8. إنشاء RPC endpoints آمنة للاستخدام من التطبيق
CREATE OR REPLACE FUNCTION public.rpc_send_message(
  chat_id UUID,
  content TEXT
) RETURNS JSON AS $$
DECLARE
  v_message_id UUID;
  v_result JSON;
BEGIN
  -- إرسال الرسالة باستخدام الدالة الآمنة
  v_message_id := public.send_message_safe(chat_id, content);
  
  -- إرجاع نتيجة JSON
  SELECT json_build_object(
    'success', true,
    'message_id', v_message_id,
    'chat_id', chat_id,
    'sender_id', auth.uid(),
    'content', content,
    'created_at', NOW()
  ) INTO v_result;
  
  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.rpc_send_message(UUID, TEXT) TO authenticated;

-- =====================================================
-- تنظيف البيانات الموجودة وإصلاحها
-- =====================================================

-- إضافة جميع المستخدمين الحاليين لدردشاتهم
DO $$
DECLARE
  booking_record RECORD;
BEGIN
  FOR booking_record IN 
    SELECT DISTINCT id, tenant_id FROM public.bookings 
  LOOP
    PERFORM public.ensure_booking_chat(booking_record.id);
  END LOOP;
END $$;
