-- Supabase Schema + RLS for GoDarna
-- Generated: 2025-08-14

-- Enable required extensions
create extension if not exists "pgcrypto";
create extension if not exists "btree_gist"; -- needed for EXCLUDE USING gist with '='

-- Enums
do $$ begin
  create type user_role as enum ('admin','host','tenant');
exception when duplicate_object then null; end $$;

do $$ begin
  create type booking_status as enum ('pending','confirmed','completed','cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type payment_status as enum ('pending','paid','failed','refunded','cancelled');
exception when duplicate_object then null; end $$;

-- Tables
create table if not exists public.users (
  id uuid primary key,
  email text unique not null,
  first_name text,
  last_name text,
  phone text,
  language text,
  role user_role not null default 'tenant',
  is_email_verified boolean not null default false,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Ensure users.id references auth.users(id) and has no default (align app expectations)
do $$ begin
  -- Drop default if exists
  perform 1 from information_schema.columns
   where table_schema = 'public' and table_name = 'users' and column_name = 'id' and column_default is not null;
  if found then
    execute 'alter table public.users alter column id drop default';
  end if;

  -- Add FK to auth.users if missing
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public' and table_name = 'users'
      and constraint_type = 'FOREIGN KEY' and constraint_name = 'users_id_fkey') then
    execute 'alter table public.users add constraint users_id_fkey foreign key (id) references auth.users(id) on delete cascade';
  end if;
end $$;

-- set_updated_at trigger for users.updated_at
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_users_set_updated_at on public.users;
create trigger trg_users_set_updated_at
before update on public.users
for each row
execute function public.set_updated_at();

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  description text,
  property_type text not null,
  price_per_night numeric(12,2) not null default 0,
  price_per_month numeric(12,2),
  address text,
  city text not null,
  area text,
  latitude double precision not null,
  longitude double precision not null,
  bedrooms int not null default 0,
  bathrooms int not null default 0,
  max_guests int not null default 1,
  amenities jsonb,
  photos text[],
  is_available boolean not null default true,
  is_verified boolean not null default false,
  is_active boolean not null default true,
  rating numeric(3,2) not null default 0,
  review_count int not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  tenant_id uuid not null references public.users(id) on delete cascade,
  host_id uuid not null references public.users(id) on delete cascade,
  check_in timestamp with time zone not null,
  check_out timestamp with time zone not null,
  nights int not null,
  total_price numeric(12,2) not null,
  status booking_status not null default 'pending',
  payment_method text,
  payment_status payment_status not null default 'pending',
  notes text,
  rating numeric(3,2),
  review text,
  review_date timestamp with time zone,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- Ensure valid dates
alter table public.bookings
  drop constraint if exists bookings_check_dates,
  add constraint bookings_check_dates check (check_out > check_in);

-- Prevent overlapping bookings per property unless the existing booking is cancelled
-- We use a half-open range [check_in, check_out) so back-to-back stays are allowed
alter table public.bookings
  drop constraint if exists bookings_no_overlap,
  add constraint bookings_no_overlap
  exclude using gist (
    property_id with =,
    tstzrange(check_in, check_out, '[)') with &&
  )
  where (status <> 'cancelled');

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  amount numeric(12,2) not null,
  payment_method text not null,
  status payment_status not null default 'pending',
  transaction_id text,
  message text,
  details jsonb,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone
);

create table if not exists public.refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id) on delete cascade,
  amount numeric(12,2) not null,
  reason text not null,
  status text not null default 'pending',
  admin_notes text,
  created_at timestamp with time zone not null default now(),
  processed_at timestamp with time zone
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null default 'info',
  data jsonb,
  is_read boolean not null default false,
  created_at timestamp with time zone not null default now()
);

create table if not exists public.user_actions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  action text not null,
  data jsonb,
  timestamp timestamp with time zone not null default now()
);

create table if not exists public.property_views (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  user_id uuid references public.users(id) on delete set null,
  timestamp timestamp with time zone not null default now()
);

-- Indexes
create index if not exists idx_users_email on public.users(email);
create index if not exists idx_properties_host on public.properties(host_id);
create index if not exists idx_properties_city on public.properties(city);
create index if not exists idx_properties_active on public.properties(is_active, is_available);
create index if not exists idx_bookings_property on public.bookings(property_id);
create index if not exists idx_bookings_tenant on public.bookings(tenant_id);
create index if not exists idx_bookings_host on public.bookings(host_id);
create index if not exists idx_bookings_created on public.bookings(created_at);
create index if not exists idx_payments_booking on public.payments(booking_id);
create index if not exists idx_notifications_user on public.notifications(user_id, is_read);
create index if not exists idx_refunds_payment on public.refunds(payment_id);
create index if not exists idx_property_views_property on public.property_views(property_id);

-- Role helper functions
create or replace function public.current_user_id()
returns uuid language sql stable as $$
  select auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where u.id = auth.uid() and u.role = 'admin'
  );
$$;

create or replace function public.is_host()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where u.id = auth.uid() and u.role = 'host'
  );
$$;

create or replace function public.is_tenant()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where u.id = auth.uid() and u.role = 'tenant'
  );
$$;

-- Enable RLS
alter table public.users enable row level security;
alter table public.properties enable row level security;
alter table public.bookings enable row level security;
alter table public.payments enable row level security;
alter table public.refunds enable row level security;
alter table public.notifications enable row level security;
alter table public.user_actions enable row level security;
alter table public.property_views enable row level security;

-- RLS Policies
-- users
-- Safety: drop any admin-wide users policies that can cause recursion
drop policy if exists "admin_can_select_all" on public.users;
drop policy if exists "admin_can_update_all" on public.users;
drop policy if exists "admin_can_insert" on public.users;
drop policy if exists users_select on public.users;
create policy users_select on public.users
for select using (
  id = auth.uid()
);

drop policy if exists users_insert on public.users;
create policy users_insert on public.users
for insert with check (id = auth.uid());

drop policy if exists users_update on public.users;
create policy users_update on public.users
for update using (
  id = auth.uid()
) with check (
  id = auth.uid()
);

drop policy if exists users_delete on public.users;
create policy users_delete on public.users
for delete using (id = auth.uid());

-- properties
drop policy if exists properties_select on public.properties;
create policy properties_select on public.properties
for select using (
  is_admin() or is_host() or is_tenant()
);

drop policy if exists properties_insert on public.properties;
create policy properties_insert on public.properties
for insert with check (
  is_admin() or (is_host() and host_id = auth.uid())
);

drop policy if exists properties_update on public.properties;
create policy properties_update on public.properties
for update using (
  is_admin() or host_id = auth.uid()
) with check (
  is_admin() or host_id = auth.uid()
);

drop policy if exists properties_delete on public.properties;
create policy properties_delete on public.properties
for delete using (is_admin() or host_id = auth.uid());

-- bookings
drop policy if exists bookings_select on public.bookings;
create policy bookings_select on public.bookings
for select using (
  is_admin() or tenant_id = auth.uid() or host_id = auth.uid()
);

drop policy if exists bookings_insert on public.bookings;
create policy bookings_insert on public.bookings
for insert with check (
  is_admin() or tenant_id = auth.uid()
);

drop policy if exists bookings_update on public.bookings;
create policy bookings_update on public.bookings
for update using (
  is_admin() or tenant_id = auth.uid() or host_id = auth.uid()
) with check (
  is_admin() or tenant_id = auth.uid() or host_id = auth.uid()
);

drop policy if exists bookings_delete on public.bookings;
create policy bookings_delete on public.bookings
for delete using (is_admin());

-- payments
drop policy if exists payments_select on public.payments;
create policy payments_select on public.payments
for select using (
  is_admin() or
  exists (
    select 1 from public.bookings b
    where b.id = payments.booking_id
      and (b.tenant_id = auth.uid() or b.host_id = auth.uid())
  )
);

drop policy if exists payments_insert on public.payments;
create policy payments_insert on public.payments
for insert with check (
  is_admin() or
  exists (
    select 1 from public.bookings b
    where b.id = booking_id
      and (b.tenant_id = auth.uid() or b.host_id = auth.uid())
  )
);

drop policy if exists payments_update on public.payments;
create policy payments_update on public.payments
for update using (
  is_admin() or
  exists (
    select 1 from public.bookings b
    where b.id = payments.booking_id
      and (b.tenant_id = auth.uid() or b.host_id = auth.uid())
  )
) with check (true);

-- refunds
drop policy if exists refunds_select on public.refunds;
create policy refunds_select on public.refunds
for select using (
  is_admin() or
  exists (
    select 1 from public.payments p
    join public.bookings b on b.id = p.booking_id
    where p.id = refunds.payment_id
      and (b.tenant_id = auth.uid() or b.host_id = auth.uid())
  )
);

drop policy if exists refunds_insert on public.refunds;
create policy refunds_insert on public.refunds
for insert with check (
  is_admin() or
  exists (
    select 1 from public.payments p
    join public.bookings b on b.id = p.booking_id
    where p.id = payment_id
      and (b.tenant_id = auth.uid() or b.host_id = auth.uid())
  )
);

drop policy if exists refunds_update on public.refunds;
create policy refunds_update on public.refunds
for update using (is_admin()) with check (is_admin());

-- notifications
drop policy if exists notifications_select on public.notifications;
create policy notifications_select on public.notifications
for select using (is_admin() or user_id = auth.uid());

drop policy if exists notifications_insert on public.notifications;
create policy notifications_insert on public.notifications
for insert with check (is_admin() or user_id = auth.uid());

-- ==========================================================
-- Admin RPCs (SECURITY DEFINER) - safe, no recursion on users RLS
-- ==========================================================

-- List users with search + pagination
create or replace function public.admin_list_users(
  p_search text default '',
  p_limit int default 20,
  p_offset int default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_items jsonb;
  v_total int;
begin
  if not is_admin() then
    raise exception 'forbidden';
  end if;

  with filtered as (
    select u.id, u.email, u.first_name, u.last_name, u.phone, u.language,
           u.role, u.is_active, u.created_at, u.updated_at
    from public.users u
    where coalesce(p_search,'') = ''
       or (
         u.email ilike '%'||p_search||'%' or
         coalesce(u.first_name,'') ilike '%'||p_search||'%' or
         coalesce(u.last_name,'') ilike '%'||p_search||'%' or
         coalesce(u.phone,'') ilike '%'||p_search||'%'
       )
  )
  select jsonb_agg(to_jsonb(f)) into v_items
  from (
    select * from filtered
    order by created_at desc
    limit p_limit offset p_offset
  ) f;

  select count(*) into v_total from filtered;

  return jsonb_build_object(
    'items', coalesce(v_items, '[]'::jsonb),
    'total', v_total
  );
end;
$$;

-- Set user role
create or replace function public.admin_set_user_role(
  p_user_id uuid,
  p_role public.user_role
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if not is_admin() then
    raise exception 'forbidden';
  end if;

  update public.users
     set role = p_role
   where id = p_user_id;

  insert into public.user_actions(user_id, action, data)
  values (auth.uid(), 'admin_set_user_role', jsonb_build_object('target_user', p_user_id, 'role', p_role));

  return jsonb_build_object('ok', true);
end;
$$;

-- Activate/Deactivate user
create or replace function public.admin_set_user_active(
  p_user_id uuid,
  p_is_active boolean
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if not is_admin() then
    raise exception 'forbidden';
  end if;

  update public.users
     set is_active = p_is_active
   where id = p_user_id;

  insert into public.user_actions(user_id, action, data)
  values (auth.uid(), 'admin_set_user_active', jsonb_build_object('target_user', p_user_id, 'is_active', p_is_active));

  return jsonb_build_object('ok', true);
end;
$$;

-- Grants for RPCs
grant execute on function public.admin_list_users(text,int,int) to authenticated;
grant execute on function public.admin_set_user_role(uuid, public.user_role) to authenticated;
grant execute on function public.admin_set_user_active(uuid, boolean) to authenticated;

-- ==========================================================
-- Admin RPCs for bookings
-- ==========================================================

-- List bookings with optional search (property title, tenant/host email), status, and date window
create or replace function public.admin_list_bookings(
  p_search text default '',
  p_status public.booking_status default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_limit int default 20,
  p_offset int default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_items jsonb;
  v_total int;
begin
  if not is_admin() then
    raise exception 'forbidden';
  end if;

  with base as (
    select b.*, p.title as property_title, ut.email as tenant_email, uh.email as host_email
    from public.bookings b
    join public.properties p on p.id = b.property_id
    left join public.users ut on ut.id = b.tenant_id
    left join public.users uh on uh.id = b.host_id
    where (coalesce(p_search,'') = '' or
           p.title ilike '%'||p_search||'%' or
           coalesce(ut.email,'') ilike '%'||p_search||'%' or
           coalesce(uh.email,'') ilike '%'||p_search||'%')
      and (p_status is null or b.status = p_status)
      and (p_from is null or b.check_out > p_from)
      and (p_to is null or b.check_in < p_to)
  )
  select jsonb_agg(to_jsonb(b)) into v_items
  from (
    select * from base
    order by b.created_at desc
    limit p_limit offset p_offset
  ) b;

  select count(*) into v_total from base;

  return jsonb_build_object('items', coalesce(v_items, '[]'::jsonb), 'total', v_total);
end;
$$;

-- Change booking status
create or replace function public.admin_set_booking_status(
  p_booking_id uuid,
  p_status public.booking_status
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if not is_admin() then
    raise exception 'forbidden';
  end if;

  update public.bookings set status = p_status where id = p_booking_id;

  insert into public.user_actions(user_id, action, data)
  values (auth.uid(), 'admin_set_booking_status', jsonb_build_object('booking_id', p_booking_id, 'status', p_status::text));

  return jsonb_build_object('ok', true);
end;
$$;

grant execute on function public.admin_list_bookings(text, public.booking_status, timestamptz, timestamptz, int, int) to authenticated;
grant execute on function public.admin_set_booking_status(uuid, public.booking_status) to authenticated;

drop policy if exists notifications_update on public.notifications;
create policy notifications_update on public.notifications
for update using (is_admin() or user_id = auth.uid())
with check (true);

for select using (is_admin() or user_id = auth.uid());

drop policy if exists user_actions_insert on public.user_actions;
create policy user_actions_insert on public.user_actions
for insert with check (user_id = auth.uid() or is_admin());

-- property_views
drop policy if exists property_views_select on public.property_views;
create policy property_views_select on public.property_views
for select using (is_admin() or is_host() or is_tenant());

drop policy if exists property_views_insert on public.property_views;
create policy property_views_insert on public.property_views
for insert with check (true);

  -- ==========================================================
  -- Privileges: fix 42501 (permission denied for schema public)
  -- ==========================================================
  -- Execute grants as the schema owner to avoid 42501
  set role postgres;

  -- Allow Supabase client roles to use the public schema
  grant usage on schema public to authenticated;
  
  -- Grant table privileges
  grant select, insert, update, delete on all tables in schema public to authenticated;
  
  -- Grant sequence privileges (for tables using sequences/defaults)
  grant usage, select, update on all sequences in schema public to authenticated;
  
  -- Ensure future tables/sequences inherit the same default privileges
  alter default privileges for role postgres in schema public
    grant select, insert, update, delete on tables to authenticated;
  alter default privileges for role postgres in schema public
    grant usage, select, update on sequences to authenticated;

  -- Revoke any previously granted privileges from anon for safety
  revoke usage on schema public from anon;
  revoke select, insert, update, delete on all tables in schema public from anon;
  revoke usage, select, update on all sequences in schema public from anon;
  alter default privileges for role postgres in schema public revoke select on tables from anon;

-- ==========================================================
-- Supabase Storage: bucket and RLS policies for property-photos
-- ==========================================================
-- Create bucket if not exists (public for serving images via public URLs)
do $$ begin
  if not exists (select 1 from storage.buckets where id = 'property-photos') then
    insert into storage.buckets (id, name, public) values ('property-photos', 'property-photos', true);
  end if;
end $$;

-- Storage policies require ownership of storage.objects (usually supabase_admin).
-- Wrap with an owner guard to avoid 42501 locally; run in Supabase SQL Editor to apply.
do $$
declare
  _owner text;
begin
  -- Determine actual owner of storage.objects
  select r.rolname into _owner
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  join pg_roles r on r.oid = c.relowner
  where n.nspname = 'storage' and c.relname = 'objects';

  if _owner = current_user then
    -- Enable RLS on storage.objects (usually enabled by default)
    alter table if exists storage.objects enable row level security;

    -- Public read for this bucket (bucket is public, but RLS still governs reads)
    drop policy if exists storage_property_photos_select on storage.objects;
    create policy storage_property_photos_select on storage.objects
    for select
    using (
      bucket_id = 'property-photos'
    );

    -- Authenticated users can upload to this bucket
    drop policy if exists storage_property_photos_insert on storage.objects;
    create policy storage_property_photos_insert on storage.objects
    for insert to authenticated
    with check (
      bucket_id = 'property-photos'
    );

    -- Owners can update their own objects in this bucket
    drop policy if exists storage_property_photos_update on storage.objects;
    create policy storage_property_photos_update on storage.objects
    for update to authenticated
    using (
      bucket_id = 'property-photos' and owner = auth.uid()
    ) with check (
      bucket_id = 'property-photos' and owner = auth.uid()
    );

    -- Owners can delete their own objects in this bucket
    drop policy if exists storage_property_photos_delete on storage.objects;
    create policy storage_property_photos_delete on storage.objects
    for delete to authenticated
    using (
      bucket_id = 'property-photos' and owner = auth.uid()
    );
  else
    raise notice 'Skipping storage.objects policy changes: current_user % is not the owner (%)', current_user, coalesce(_owner, 'unknown');
  end if;
end$$;
