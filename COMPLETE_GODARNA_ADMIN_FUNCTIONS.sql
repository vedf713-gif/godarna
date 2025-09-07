-- =====================================================
-- دوال إدارية شاملة لتطبيق GoDarna
-- الجزء الثالث من النظام الشامل
-- =====================================================

BEGIN;

-- =====================================================
-- 🔒 دوال إدارية آمنة
-- =====================================================

-- دالة إدارية لتحديث دور المستخدم
CREATE OR REPLACE FUNCTION public.admin_update_user_role(
  p_user_id UUID,
  p_new_role user_role
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  -- تحديث الدور
  UPDATE public.profiles 
  SET role = p_new_role, updated_at = NOW()
  WHERE id = p_user_id;
  
  -- تسجيل العملية
  INSERT INTO public.user_actions(user_id, action, data)
  VALUES (auth.uid(), 'admin_update_user_role', 
    jsonb_build_object('target_user', p_user_id, 'new_role', p_new_role));
  
  RETURN FOUND;
END;
$$;

-- دالة إدارية لتحديث حالة العقار
CREATE OR REPLACE FUNCTION public.admin_update_listing_status(
  p_listing_id UUID,
  p_is_published BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  -- تحديث حالة النشر
  UPDATE public.listings 
  SET is_published = p_is_published, updated_at = NOW()
  WHERE id = p_listing_id;
  
  -- تسجيل العملية
  INSERT INTO public.user_actions(user_id, action, data)
  VALUES (auth.uid(), 'admin_update_listing_status', 
    jsonb_build_object('listing_id', p_listing_id, 'is_published', p_is_published));
  
  RETURN FOUND;
END;
$$;

-- دالة إدارية لتحديث حالة الحجز
CREATE OR REPLACE FUNCTION public.admin_update_booking_status(
  p_booking_id UUID,
  p_status booking_status
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  -- تحديث حالة الحجز
  UPDATE public.bookings 
  SET status = p_status, updated_at = NOW()
  WHERE id = p_booking_id;
  
  -- تسجيل العملية
  INSERT INTO public.user_actions(user_id, action, data)
  VALUES (auth.uid(), 'admin_update_booking_status', 
    jsonb_build_object('booking_id', p_booking_id, 'status', p_status));
  
  RETURN FOUND;
END;
$$;

-- دالة إدارية لتعطيل/تفعيل المستخدم
CREATE OR REPLACE FUNCTION public.admin_set_user_active(
  p_user_id UUID,
  p_is_active BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  -- تحديث حالة المستخدم
  UPDATE public.profiles 
  SET is_active = p_is_active, updated_at = NOW()
  WHERE id = p_user_id;
  
  -- تسجيل العملية
  INSERT INTO public.user_actions(user_id, action, data)
  VALUES (auth.uid(), 'admin_set_user_active', 
    jsonb_build_object('target_user', p_user_id, 'is_active', p_is_active));
  
  RETURN FOUND;
END;
$$;

-- =====================================================
-- 📊 دوال التقارير الإدارية
-- =====================================================

-- دالة لإحصائيات المستخدمين
CREATE OR REPLACE FUNCTION public.admin_get_user_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  SELECT jsonb_build_object(
    'total_users', COUNT(*),
    'active_users', COUNT(*) FILTER (WHERE is_active = true),
    'tenants', COUNT(*) FILTER (WHERE role = 'tenant'),
    'hosts', COUNT(*) FILTER (WHERE role = 'host'),
    'admins', COUNT(*) FILTER (WHERE role = 'admin'),
    'verified_users', COUNT(*) FILTER (WHERE is_email_verified = true)
  ) INTO result
  FROM public.profiles;
  
  RETURN result;
END;
$$;

-- دالة لإحصائيات العقارات
CREATE OR REPLACE FUNCTION public.admin_get_listing_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  SELECT jsonb_build_object(
    'total_listings', COUNT(*),
    'published_listings', COUNT(*) FILTER (WHERE is_published = true),
    'available_listings', COUNT(*) FILTER (WHERE is_available = true),
    'verified_listings', COUNT(*) FILTER (WHERE is_verified = true),
    'avg_price_per_night', ROUND(AVG(price_per_night), 2),
    'avg_rating', ROUND(AVG(average_rating), 2)
  ) INTO result
  FROM public.listings;
  
  RETURN result;
END;
$$;

-- دالة لإحصائيات الحجوزات
CREATE OR REPLACE FUNCTION public.admin_get_booking_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  SELECT jsonb_build_object(
    'total_bookings', COUNT(*),
    'pending_bookings', COUNT(*) FILTER (WHERE status = 'pending'),
    'confirmed_bookings', COUNT(*) FILTER (WHERE status = 'confirmed'),
    'completed_bookings', COUNT(*) FILTER (WHERE status = 'completed'),
    'cancelled_bookings', COUNT(*) FILTER (WHERE status = 'cancelled'),
    'total_revenue', COALESCE(SUM(total_price) FILTER (WHERE status = 'completed'), 0),
    'avg_booking_value', ROUND(AVG(total_price), 2)
  ) INTO result
  FROM public.bookings;
  
  RETURN result;
END;
$$;

-- =====================================================
-- 🔍 دوال البحث الإدارية
-- =====================================================

-- دالة البحث في المستخدمين
CREATE OR REPLACE FUNCTION public.admin_search_users(
  p_search TEXT DEFAULT '',
  p_role user_role DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_items JSONB;
  v_total INT;
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  WITH filtered AS (
    SELECT p.id, p.email, p.first_name, p.last_name, p.phone, 
           p.role, p.is_active, p.is_email_verified, p.created_at, p.updated_at
    FROM public.profiles p
    WHERE (COALESCE(p_search, '') = '' OR
           p.email ILIKE '%' || p_search || '%' OR
           COALESCE(p.first_name, '') ILIKE '%' || p_search || '%' OR
           COALESCE(p.last_name, '') ILIKE '%' || p_search || '%' OR
           COALESCE(p.phone, '') ILIKE '%' || p_search || '%')
      AND (p_role IS NULL OR p.role = p_role)
      AND (p_is_active IS NULL OR p.is_active = p_is_active)
  )
  SELECT jsonb_agg(to_jsonb(f)) INTO v_items
  FROM (
    SELECT * FROM filtered
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) f;
  
  SELECT COUNT(*) INTO v_total FROM filtered;
  
  RETURN jsonb_build_object(
    'items', COALESCE(v_items, '[]'::jsonb),
    'total', v_total,
    'limit', p_limit,
    'offset', p_offset
  );
END;
$$;

-- دالة البحث في العقارات
CREATE OR REPLACE FUNCTION public.admin_search_listings(
  p_search TEXT DEFAULT '',
  p_city TEXT DEFAULT NULL,
  p_property_type property_type DEFAULT NULL,
  p_is_published BOOLEAN DEFAULT NULL,
  p_is_verified BOOLEAN DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_items JSONB;
  v_total INT;
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  WITH filtered AS (
    SELECT l.id, l.title, l.city, l.property_type, l.price_per_night,
           l.is_published, l.is_verified, l.average_rating, l.review_count,
           l.created_at, p.email as host_email
    FROM public.listings l
    JOIN public.profiles p ON p.id = l.host_id
    WHERE (COALESCE(p_search, '') = '' OR
           l.title ILIKE '%' || p_search || '%' OR
           COALESCE(l.description, '') ILIKE '%' || p_search || '%' OR
           p.email ILIKE '%' || p_search || '%')
      AND (p_city IS NULL OR l.city ILIKE '%' || p_city || '%')
      AND (p_property_type IS NULL OR l.property_type = p_property_type)
      AND (p_is_published IS NULL OR l.is_published = p_is_published)
      AND (p_is_verified IS NULL OR l.is_verified = p_is_verified)
  )
  SELECT jsonb_agg(to_jsonb(f)) INTO v_items
  FROM (
    SELECT * FROM filtered
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) f;
  
  SELECT COUNT(*) INTO v_total FROM filtered;
  
  RETURN jsonb_build_object(
    'items', COALESCE(v_items, '[]'::jsonb),
    'total', v_total,
    'limit', p_limit,
    'offset', p_offset
  );
END;
$$;

-- دالة البحث في الحجوزات
CREATE OR REPLACE FUNCTION public.admin_search_bookings(
  p_search TEXT DEFAULT '',
  p_status booking_status DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NULL,
  p_to_date TIMESTAMPTZ DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_items JSONB;
  v_total INT;
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  WITH filtered AS (
    SELECT b.id, b.start_date, b.end_date, b.nights, b.total_price,
           b.status, b.payment_status, b.created_at,
           l.title as listing_title, l.city as listing_city,
           pt.email as tenant_email, ph.email as host_email
    FROM public.bookings b
    JOIN public.listings l ON l.id = b.listing_id
    JOIN public.profiles pt ON pt.id = b.tenant_id
    JOIN public.profiles ph ON ph.id = b.host_id
    WHERE (COALESCE(p_search, '') = '' OR
           l.title ILIKE '%' || p_search || '%' OR
           pt.email ILIKE '%' || p_search || '%' OR
           ph.email ILIKE '%' || p_search || '%')
      AND (p_status IS NULL OR b.status = p_status)
      AND (p_from_date IS NULL OR b.start_date >= p_from_date)
      AND (p_to_date IS NULL OR b.end_date <= p_to_date)
  )
  SELECT jsonb_agg(to_jsonb(f)) INTO v_items
  FROM (
    SELECT * FROM filtered
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) f;
  
  SELECT COUNT(*) INTO v_total FROM filtered;
  
  RETURN jsonb_build_object(
    'items', COALESCE(v_items, '[]'::jsonb),
    'total', v_total,
    'limit', p_limit,
    'offset', p_offset
  );
END;
$$;

-- =====================================================
-- 🚨 دوال الأمان والمراقبة
-- =====================================================

-- دالة تسجيل الأحداث الأمنية
CREATE OR REPLACE FUNCTION public.log_security_event(
  p_event_type TEXT,
  p_details JSONB DEFAULT '{}'::jsonb,
  p_risk_score INTEGER DEFAULT 0
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.security_logs(
    event_type, user_id, details, risk_score, created_at
  ) VALUES (
    p_event_type, auth.uid(), p_details, p_risk_score, NOW()
  );
END;
$$;

-- دالة للحصول على الأحداث الأمنية المشبوهة
CREATE OR REPLACE FUNCTION public.admin_get_suspicious_activities(
  p_min_risk_score INTEGER DEFAULT 5,
  p_limit INT DEFAULT 50
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_items JSONB;
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', sl.id,
      'event_type', sl.event_type,
      'user_email', COALESCE(p.email, 'Unknown'),
      'details', sl.details,
      'risk_score', sl.risk_score,
      'ip_address', sl.ip_address,
      'created_at', sl.created_at
    )
  ) INTO v_items
  FROM public.security_logs sl
  LEFT JOIN public.profiles p ON p.id = sl.user_id
  WHERE sl.risk_score >= p_min_risk_score
  ORDER BY sl.created_at DESC, sl.risk_score DESC
  LIMIT p_limit;
  
  RETURN COALESCE(v_items, '[]'::jsonb);
END;
$$;

-- دالة لحظر المستخدم مؤقتاً
CREATE OR REPLACE FUNCTION public.admin_suspend_user(
  p_user_id UUID,
  p_reason TEXT,
  p_duration_hours INTEGER DEFAULT 24
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  -- تعطيل المستخدم
  UPDATE public.profiles 
  SET is_active = false, updated_at = NOW()
  WHERE id = p_user_id;
  
  -- تسجيل العملية
  INSERT INTO public.user_actions(user_id, action, data)
  VALUES (auth.uid(), 'admin_suspend_user', 
    jsonb_build_object(
      'target_user', p_user_id, 
      'reason', p_reason,
      'duration_hours', p_duration_hours
    ));
  
  -- تسجيل حدث أمني
  PERFORM public.log_security_event(
    'user_suspended',
    jsonb_build_object(
      'suspended_user', p_user_id,
      'reason', p_reason,
      'duration_hours', p_duration_hours
    ),
    8
  );
  
  RETURN FOUND;
END;
$$;

-- =====================================================
-- 📈 دوال التحليلات المتقدمة
-- =====================================================

-- دالة للحصول على إحصائيات الإيرادات الشهرية
CREATE OR REPLACE FUNCTION public.admin_get_monthly_revenue(
  p_months INTEGER DEFAULT 12
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  SELECT jsonb_agg(
    jsonb_build_object(
      'month', month_year,
      'total_bookings', total_bookings,
      'completed_bookings', completed_bookings,
      'total_revenue', total_revenue,
      'avg_booking_value', avg_booking_value
    )
  ) INTO v_result
  FROM (
    SELECT 
      TO_CHAR(DATE_TRUNC('month', b.created_at), 'YYYY-MM') as month_year,
      COUNT(*) as total_bookings,
      COUNT(*) FILTER (WHERE b.status = 'completed') as completed_bookings,
      COALESCE(SUM(b.total_price) FILTER (WHERE b.status = 'completed'), 0) as total_revenue,
      ROUND(AVG(b.total_price) FILTER (WHERE b.status = 'completed'), 2) as avg_booking_value
    FROM public.bookings b
    WHERE b.created_at >= NOW() - INTERVAL '1 month' * p_months
    GROUP BY DATE_TRUNC('month', b.created_at)
    ORDER BY month_year DESC
  ) monthly_stats;
  
  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- دالة للحصول على أفضل العقارات أداءً
CREATE OR REPLACE FUNCTION public.admin_get_top_performing_listings(
  p_limit INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- التحقق من كون المستدعي مدير
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;
  
  SELECT jsonb_agg(
    jsonb_build_object(
      'listing_id', l.id,
      'title', l.title,
      'city', l.city,
      'host_email', p.email,
      'total_bookings', booking_stats.total_bookings,
      'total_revenue', booking_stats.total_revenue,
      'average_rating', l.average_rating,
      'review_count', l.review_count
    )
  ) INTO v_result
  FROM public.listings l
  JOIN public.profiles p ON p.id = l.host_id
  JOIN (
    SELECT 
      b.listing_id,
      COUNT(*) as total_bookings,
      COALESCE(SUM(b.total_price) FILTER (WHERE b.status = 'completed'), 0) as total_revenue
    FROM public.bookings b
    GROUP BY b.listing_id
  ) booking_stats ON booking_stats.listing_id = l.id
  WHERE l.is_published = true
  ORDER BY booking_stats.total_revenue DESC, booking_stats.total_bookings DESC
  LIMIT p_limit;
  
  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- =====================================================
-- 📋 منح الصلاحيات للدوال الإدارية
-- =====================================================

-- منح الصلاحيات للمديرين فقط
GRANT EXECUTE ON FUNCTION public.admin_update_user_role TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_listing_status TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_booking_status TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_user_active TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_user_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_listing_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_booking_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_search_users TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_search_listings TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_search_bookings TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_security_event TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_suspicious_activities TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_suspend_user TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_monthly_revenue TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_top_performing_listings TO authenticated;

COMMIT;
