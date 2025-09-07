-- Geo Search: PostGIS enable + RPC with ST_DWithin
-- Run this in Supabase SQL editor or psql connected to your database.

-- 1) Enable PostGIS extension (one-time)
create extension if not exists postgis;

-- 2) Add generated geography column from lon/lat + GIST index
alter table public.properties
  add column if not exists geom geography(Point,4326)
  generated always as (
    case 
      when latitude is not null and longitude is not null 
      then ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography 
      else null 
    end
  ) stored;

create index if not exists idx_properties_geom_gist
  on public.properties using gist (geom);

-- 3) RPC that supports geo filtering and returns distance_km
create or replace function public.rpc_public_properties(
  p_search text default null,
  p_city text default null,
  p_property_type text default null,
  p_center_lat double precision default null,
  p_center_lng double precision default null,
  p_radius_km double precision default null,
  p_min_price numeric default null,
  p_max_price numeric default null,
  p_max_guests int default null,
  p_limit int default 20,
  p_offset int default 0,
  p_order_by text default 'recent'
)
returns table (
  id uuid,
  title text,
  city text,
  price_per_night numeric,
  latitude double precision,
  longitude double precision,
  rating double precision,
  photo text,
  distance_km double precision
)
language sql
stable
as $$
  with base as (
    select 
      p.id,
      p.title,
      p.city,
      p.price_per_night,
      p.latitude,
      p.longitude,
      p.rating,
      -- Use first photo from array if present
      (case when p.photos is not null and array_length(p.photos, 1) >= 1
            then p.photos[1]
            else null
       end) as photo,
      case 
        when p_center_lat is not null and p_center_lng is not null and p_radius_km is not null
          then ST_Distance(
            p.geog,
            ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geography
          ) / 1000.0
        else null
      end as distance_km
    from public.properties p
    where 
      (p_search is null or p.title ilike '%' || p_search || '%' or p.city ilike '%' || p_search || '%')
      and (p_city is null or p.city = p_city)
      and (p_property_type is null or p.property_type = p_property_type)
      and (p_min_price is null or p.price_per_night >= p_min_price)
      and (p_max_price is null or p.price_per_night <= p_max_price)
      and (p_max_guests is null or p.max_guests >= p_max_guests)
      and (
        -- Geo range only when all params provided
        p_center_lat is null or p_center_lng is null or p_radius_km is null
        or ST_DWithin(
             p.geog,
             ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geography,
             p_radius_km * 1000.0
           )
      )
  )
  select
    id,
    title,
    city,
    price_per_night,
    latitude,
    longitude,
    rating,
    photo,
    distance_km
  from base
  order by
    case when p_order_by = 'price_asc' then price_per_night end asc nulls last,
    case when p_order_by = 'price_desc' then price_per_night end desc nulls last,
    case when p_order_by = 'rating_desc' then rating end desc nulls last,
    case when p_order_by = 'distance_asc' then distance_km end asc nulls last,
    case when p_order_by = 'recent' then id end desc
  limit p_limit
  offset p_offset;
$$;

-- 4) Optional RLS policy (adjust for your needs)
-- If RLS is enabled on properties, ensure read access including geog.
-- WARNING: The following is permissive; tighten it as needed for production.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_tables
    WHERE schemaname = 'public' AND tablename = 'properties'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public' AND tablename = 'properties' AND policyname = 'properties_read_public'
    ) THEN
      EXECUTE 'CREATE POLICY properties_read_public ON public.properties FOR SELECT USING (true)';
    END IF;
  END IF;
END$$;

-- 5) Grant execute on function to common roles
grant execute on function public.rpc_public_properties(
  text, text, text, double precision, double precision, double precision,
  numeric, numeric, int, int, int, text
) to anon, authenticated, service_role;
