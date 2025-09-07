-- التحقق من وجود المستخدم في جدول chat_participants
SELECT 
  cp.chat_id,
  cp.user_id,
  p.email,
  c.id as chat_exists
FROM public.chat_participants cp
JOIN public.profiles p ON p.id = cp.user_id
LEFT JOIN public.chats c ON c.id = cp.chat_id
WHERE cp.chat_id = '777ba723-cff0-4bda-b0cf-76016b475878'
   OR cp.user_id = 'd85bee0c-7410-4697-8636-c1c596dc1bc2';

-- التحقق من وجود الدردشة نفسها
SELECT * FROM public.chats WHERE id = '777ba723-cff0-4bda-b0cf-76016b475878';

-- إضافة المستخدم للدردشة إذا لم يكن موجوداً
INSERT INTO public.chat_participants (chat_id, user_id)
VALUES ('777ba723-cff0-4bda-b0cf-76016b475878', 'd85bee0c-7410-4697-8636-c1c596dc1bc2')
ON CONFLICT (chat_id, user_id) DO NOTHING;
