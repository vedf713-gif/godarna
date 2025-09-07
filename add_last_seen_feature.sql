-- =====================================================
-- إضافة ميزة آخر ظهور للمستخدمين في نظام الدردشة
-- =====================================================

-- 1. إضافة عمود last_seen لجدول profiles (المستخدمين) إذا لم يكن موجوداً
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'last_seen'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN last_seen TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

-- 2. إنشاء دالة لتحديث آخر ظهور للمستخدم
CREATE OR REPLACE FUNCTION public.update_user_last_seen(user_id UUID DEFAULT auth.uid())
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles 
  SET last_seen = NOW() 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. إنشاء دالة للحصول على معلومات المستخدم مع آخر ظهور
CREATE OR REPLACE FUNCTION public.get_user_info(user_id UUID)
RETURNS JSON AS $$
DECLARE
  user_info JSON;
BEGIN
  SELECT json_build_object(
    'id', u.id,
    'full_name', u.full_name,
    'avatar_url', u.avatar_url,
    'last_seen', u.last_seen,
    'is_online', (u.last_seen > NOW() - INTERVAL '5 minutes')
  ) INTO user_info
  FROM public.users u
  WHERE u.id = user_id;
  
  RETURN user_info;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. إنشاء دالة للحصول على معلومات المشاركين في الدردشة
CREATE OR REPLACE FUNCTION public.get_chat_participants_info(chat_id UUID)
RETURNS JSON AS $$
DECLARE
  participants JSON;
BEGIN
  SELECT json_agg(
    json_build_object(
      'id', u.id,
      'full_name', u.full_name,
      'avatar_url', u.avatar_url,
      'last_seen', u.last_seen,
      'is_online', (u.last_seen > NOW() - INTERVAL '5 minutes')
    )
  ) INTO participants
  FROM public.chat_participants cp
  JOIN public.users u ON cp.user_id = u.id
  WHERE cp.chat_id = chat_id;
  
  RETURN participants;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. إنشاء RPC endpoint لتحديث آخر ظهور
CREATE OR REPLACE FUNCTION public.rpc_update_last_seen()
RETURNS JSON AS $$
BEGIN
  PERFORM public.update_user_last_seen();
  
  RETURN json_build_object(
    'success', true,
    'last_seen', NOW()
  );
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'error', SQLERRM
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. منح الصلاحيات المناسبة
GRANT EXECUTE ON FUNCTION public.update_user_last_seen(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_info(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_chat_participants_info(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_update_last_seen() TO authenticated;

-- 7. إنشاء trigger لتحديث آخر ظهور تلقائياً عند إرسال رسالة
CREATE OR REPLACE FUNCTION public.trigger_update_last_seen()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.update_user_last_seen(NEW.sender_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء trigger على جدول الرسائل
DROP TRIGGER IF EXISTS messages_update_last_seen ON public.messages;
CREATE TRIGGER messages_update_last_seen
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_update_last_seen();

-- 8. تحديث آخر ظهور لجميع المستخدمين الحاليين
UPDATE public.profiles SET last_seen = NOW() WHERE last_seen IS NULL;
