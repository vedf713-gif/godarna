-- دالة لإنشاء الدردشة وإضافة المشاركين تلقائياً
CREATE OR REPLACE FUNCTION public.ensure_chat_exists(
  p_chat_id UUID,
  p_tenant_id UUID,
  p_host_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  -- إنشاء الدردشة إذا لم تكن موجودة
  INSERT INTO public.chats (id, created_by, created_at)
  VALUES (p_chat_id, p_tenant_id, NOW())
  ON CONFLICT (id) DO NOTHING;
  
  -- إضافة المستأجر للدردشة
  INSERT INTO public.chat_participants (chat_id, user_id)
  VALUES (p_chat_id, p_tenant_id)
  ON CONFLICT (chat_id, user_id) DO NOTHING;
  
  -- إضافة المضيف للدردشة
  INSERT INTO public.chat_participants (chat_id, user_id)
  VALUES (p_chat_id, p_host_id)
  ON CONFLICT (chat_id, user_id) DO NOTHING;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة لإضافة مستخدم للدردشة الموجودة
CREATE OR REPLACE FUNCTION public.add_user_to_chat(
  p_chat_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  -- التأكد من وجود الدردشة
  IF NOT EXISTS (SELECT 1 FROM public.chats WHERE id = p_chat_id) THEN
    INSERT INTO public.chats (id, created_by, created_at) 
    VALUES (p_chat_id, p_user_id, NOW());
  END IF;
  
  -- إضافة المستخدم للدردشة
  INSERT INTO public.chat_participants (chat_id, user_id)
  VALUES (p_chat_id, p_user_id)
  ON CONFLICT (chat_id, user_id) DO NOTHING;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- إضافة المستخدم الحالي للدردشة المحددة
SELECT public.add_user_to_chat(
  '777ba723-cff0-4bda-b0cf-76016b475878'::UUID,
  'd85bee0c-7410-4697-8636-c1c596dc1bc2'::UUID
);
