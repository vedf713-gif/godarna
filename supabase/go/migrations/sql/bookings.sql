-- Bookings schema and constraints for Supabase (Postgres)
-- Safe to re-run (idempotent where possible)

-- 1) Required extension for EXCLUDE constraints on ranges
create extension if not exists btree_gist;

-- 2) Table definition
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  property_id text not null,
  tenant_id text,
  host_id text,
  check_in timestamptz not null,
  check_out timestamptz not null,
  nights int,
  total_price numeric,
  status text not null default 'pending',
  payment_method text,
  payment_status text default 'pending',
  notes text,
  rating numeric,
  review text,
  review_date timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3) Generated range column used for overlap checks
alter table public.bookings
  add column if not exists ts_range tstzrange
  generated always as (tstzrange(check_in, check_out, '[)')) stored;

-- 4) Helpful indexes
create index if not exists idx_bookings_property on public.bookings(property_id);
create index if not exists idx_bookings_check_in on public.bookings(check_in);
create index if not exists idx_bookings_check_out on public.bookings(check_out);
create index if not exists idx_bookings_status on public.bookings(status);

-- 5) Exclusion constraint to prevent overlaps for the same property
-- Allows back-to-back bookings (inclusive start, exclusive end via '[)')
-- Skip cancelled bookings from the constraint using WHERE clause
alter table public.bookings
  drop constraint if exists bookings_no_overlap;

alter table public.bookings
  add constraint bookings_no_overlap
  exclude using gist (
    property_id with =,
    ts_range with &&
  )
  where (status <> 'cancelled');

-- 6) Trigger to keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_bookings_set_updated_at on public.bookings;
create trigger trg_bookings_set_updated_at
before update on public.bookings
for each row execute function public.set_updated_at();

-- 7) Safety check: check_in must be before check_out
alter table public.bookings
  drop constraint if exists bookings_check_bounds;

alter table public.bookings
  add constraint bookings_check_bounds
  check (check_in < check_out);

-- 8) Availability helper: returns true if the requested period does NOT overlap any non-cancelled booking
create or replace function public.is_period_available(
  p_property_id uuid,
  p_start timestamptz,
  p_end timestamptz
) returns boolean
language sql
stable
as $$
  select not exists (
    select 1
    from public.bookings b
    where b.property_id = p_property_id
      and b.status <> 'cancelled'
      and b.ts_range && tstzrange(p_start, p_end, '[)')
  );
$$;

-- 9) Fetch booked ranges within a window (for calendar UI)
create or replace function public.get_booked_ranges(
  p_property_id uuid,
  p_from timestamptz,
  p_to timestamptz
) returns table (
  check_in timestamptz,
  check_out timestamptz
)
language sql
stable
as $$
  select b.check_in, b.check_out
  from public.bookings b
  where b.property_id = p_property_id
    and b.status <> 'cancelled'
    and b.check_out > p_from
    and b.check_in < p_to
  order by b.check_in;
$$;
