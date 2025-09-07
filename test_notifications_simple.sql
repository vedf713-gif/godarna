-- اختبار بسيط للإشعارات باستخدام مستخدم موجود
-- أولاً: عرض المستخدمين الموجودين
SELECT id, email, full_name FROM public.profiles LIMIT 5;

-- ثانياً: إدراج إشعار لأول مستخدم موجود
INSERT INTO public.notifications (user_id, title, message, type, data)
SELECT 
    id,
    'اختبار الإشعار',
    'هذا إشعار تجريبي للتأكد من عمل النظام',
    'info',
    '{"test": true}'::jsonb
FROM public.profiles 
LIMIT 1;

-- ثالثاً: التحقق من الإشعار المُدرج
SELECT * FROM public.notifications ORDER BY created_at DESC LIMIT 1;
