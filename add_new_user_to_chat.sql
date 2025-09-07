-- إضافة المستخدم الجديد للدردشة المحددة
SELECT public.add_user_to_chat(
  '777ba723-cff0-4bda-b0cf-76016b475878'::UUID,
  '8793e333-7cd2-42de-99dc-2a8873a88b82'::UUID
);

-- التحقق من إضافة المستخدم بنجاح
SELECT 
  cp.chat_id,
  cp.user_id,
  p.email,
  c.id as chat_exists
FROM public.chat_participants cp
JOIN public.profiles p ON p.id = cp.user_id
LEFT JOIN public.chats c ON c.id = cp.chat_id
WHERE cp.chat_id = '777ba723-cff0-4bda-b0cf-76016b475878';
