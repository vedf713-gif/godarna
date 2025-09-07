-- =====================================================
-- اختبار استخدام new_message بعد إضافة enum
-- =====================================================

-- اختبار إدراج إشعار بنوع new_message
INSERT INTO public.notifications (user_id, title, message, type, data)
SELECT 
    id,
    '💬 رسالة جديدة',
    'اختبار إشعار رسالة بعد إضافة enum',
    'new_message',
    '{"chat_id": "test-chat", "sender_id": "test-user"}'::jsonb
FROM public.profiles 
LIMIT 1;

-- التحقق من الإشعار المُدرج
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    data,
    created_at
FROM public.notifications 
WHERE type = 'new_message'
ORDER BY created_at DESC 
LIMIT 1;

SELECT 'تم اختبار new_message بنجاح' as result;
