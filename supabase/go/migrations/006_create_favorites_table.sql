-- إنشاء جدول المفضلة
CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- فهرس فريد لمنع تكرار المفضلة لنفس المستخدم والعقار
    UNIQUE(user_id, property_id)
);

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_property_id ON public.favorites(property_id);
CREATE INDEX IF NOT EXISTS idx_favorites_created_at ON public.favorites(created_at);

-- تحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_favorites_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_favorites_updated_at
    BEFORE UPDATE ON public.favorites
    FOR EACH ROW
    EXECUTE FUNCTION update_favorites_updated_at();

-- سياسات الأمان (RLS)
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- سياسة القراءة: المستخدم يمكنه قراءة مفضلته فقط
CREATE POLICY "Users can view their own favorites" ON public.favorites
    FOR SELECT USING (auth.uid() = user_id);

-- سياسة الإدراج: المستخدم يمكنه إضافة مفضلة لنفسه فقط
CREATE POLICY "Users can insert their own favorites" ON public.favorites
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- سياسة الحذف: المستخدم يمكنه حذف مفضلته فقط
CREATE POLICY "Users can delete their own favorites" ON public.favorites
    FOR DELETE USING (auth.uid() = user_id);

-- سياسة التحديث: المستخدم يمكنه تحديث مفضلته فقط
CREATE POLICY "Users can update their own favorites" ON public.favorites
    FOR UPDATE USING (auth.uid() = user_id);

-- إنشاء دالة للحصول على المفضلة مع تفاصيل العقار
CREATE OR REPLACE FUNCTION get_user_favorites(user_uuid UUID DEFAULT auth.uid())
RETURNS TABLE (
    id UUID,
    property_id UUID,
    property_title TEXT,
    property_description TEXT,
    property_price DECIMAL,
    property_city TEXT,
    property_photos TEXT[],
    property_type TEXT,
    property_bedrooms INTEGER,
    property_bathrooms INTEGER,
    property_area DECIMAL,
    created_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.property_id,
        p.title,
        p.description,
        p.price,
        p.city,
        p.photos,
        p.type,
        p.bedrooms,
        p.bathrooms,
        p.area,
        f.created_at
    FROM public.favorites f
    JOIN public.properties p ON f.property_id = p.id
    WHERE f.user_id = user_uuid
    ORDER BY f.created_at DESC;
END;
$$;

-- منح الصلاحيات للمستخدمين المصادق عليهم
GRANT SELECT, INSERT, UPDATE, DELETE ON public.favorites TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_favorites(UUID) TO authenticated;

-- تعليق على الجدول
COMMENT ON TABLE public.favorites IS 'جدول المفضلة - يحتوي على العقارات المفضلة للمستخدمين';
COMMENT ON COLUMN public.favorites.user_id IS 'معرف المستخدم';
COMMENT ON COLUMN public.favorites.property_id IS 'معرف العقار';
COMMENT ON COLUMN public.favorites.created_at IS 'تاريخ الإضافة للمفضلة';
COMMENT ON COLUMN public.favorites.updated_at IS 'تاريخ آخر تحديث';
