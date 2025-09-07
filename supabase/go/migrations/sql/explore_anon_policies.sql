-- إعداد صلاحيات التصفح بدون تسجيل (anon) في Supabase
-- شغّل هذا الملف في SQL Editor داخل لوحة تحكم Supabase

-- 1) منح صلاحية استخدام مخطط public لدور anon (مطلوب لبعض البيئات)
grant usage on schema public to anon;

-- 2) تفعيل RLS وسياسة قراءة عامة على جدول العقارات properties
alter table if exists public.properties enable row level security;
-- احذف السياسة إن كانت موجودة مسبقاً لتفادي التكرار
drop policy if exists "public_can_view_active_available_properties" on public.properties;
create policy "public_can_view_active_available_properties"
on public.properties
for select
to anon
using (is_active = true and is_available = true);

-- 3) (اختياري) جداول أخرى تُقرأ في وضع التصفح: amenities/cities ... عدّل حسب حاجتك
-- amenities (تنفيذ مشروط بوجود الجدول)
do $$
begin
  if to_regclass('public.amenities') is not null then
    execute 'alter table public.amenities enable row level security';
    execute 'drop policy if exists "public_can_view_amenities" on public.amenities';
    execute 'create policy "public_can_view_amenities" on public.amenities for select to anon using (true)';
  end if;
end$$;

-- cities
do $$
begin
  if to_regclass('public.cities') is not null then
    execute 'alter table public.cities enable row level security';
    execute 'drop policy if exists "public_can_view_cities" on public.cities';
    execute 'create policy "public_can_view_cities" on public.cities for select to anon using (true)';
  end if;
end$$;

-- 4) سياسة قراءة عامة لصور التخزين في البكت images (في حال إبقاء البكت Private)
-- ملاحظة: storage.objects مفعّل عليه RLS افتراضياً
-- إن كنت تريد جعل البكت images Public من لوحة التحكم، يمكن الاستغناء عن هذه السياسة
drop policy if exists "public_read_images" on storage.objects;
create policy "public_read_images"
on storage.objects
for select
to anon
using (bucket_id = 'images');

-- 5) (اختياري) في حال لديك Views أو RPCs للتصفح العام، امنح صلاحيات التنفيذ لanon
-- grant execute on function public.your_rpc_name(...) to anon;
