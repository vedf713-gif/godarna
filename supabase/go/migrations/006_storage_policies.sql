-- 006_storage_policies.sql
-- Create images bucket and RLS policies for uploads/reads/deletes

-- Ensure bucket exists
insert into storage.buckets (id, name, public)
values ('images', 'images', true)
on conflict (id) do nothing;

-- Policies on storage.objects
-- Note: RLS is enabled by default on storage.objects

-- Public read for images bucket
drop policy if exists "images_public_read" on storage.objects;
create policy "images_public_read"
  on storage.objects
  for select
  using (bucket_id = 'images');

-- Authenticated users can upload to images bucket
drop policy if exists "images_authenticated_insert" on storage.objects;
create policy "images_authenticated_insert"
  on storage.objects
  for insert
  with check (
    bucket_id = 'images' and auth.uid() is not null
  );

-- Allow owners to update/delete their own files
drop policy if exists "images_owner_update" on storage.objects;
create policy "images_owner_update"
  on storage.objects
  for update
  using (bucket_id = 'images' and owner = auth.uid());

drop policy if exists "images_owner_delete" on storage.objects;
create policy "images_owner_delete"
  on storage.objects
  for delete
  using (bucket_id = 'images' and owner = auth.uid());
