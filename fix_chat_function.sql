-- إصلاح دالة is_chat_participant لحل مشكلة التضارب في أسماء المعاملات

-- حذف السياسات التي تعتمد على الدالة أولاً
DROP POLICY IF EXISTS "messages_select_participants" ON public.messages;
DROP POLICY IF EXISTS "messages_insert_participant_only" ON public.messages;
DROP POLICY IF EXISTS "messages_update_sender_only" ON public.messages;
DROP POLICY IF EXISTS "messages_delete_sender_or_admin" ON public.messages;

-- حذف الدالة الحالية
DROP FUNCTION IF EXISTS public.is_chat_participant(uuid, uuid);

-- إنشاء الدالة بأسماء معاملات جديدة لتجنب التضارب
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

-- تحديث سياسات RLS للرسائل لاستخدام الدالة المُصلحة
DROP POLICY IF EXISTS "messages_select_participants" ON public.messages;
DROP POLICY IF EXISTS "messages_insert_participant_only" ON public.messages;
DROP POLICY IF EXISTS "messages_update_sender_only" ON public.messages;
DROP POLICY IF EXISTS "messages_delete_sender_or_admin" ON public.messages;

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
