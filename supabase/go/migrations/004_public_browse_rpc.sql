-- 004_public_browse_rpc.sql
-- Public browsing via secure RPC (SECURITY DEFINER)

-- The function exposes only safe fields for public browsing and enforces filters inside SQL
-- It bypasses RLS by using SECURITY DEFINER but restricts output and conditions strictly

-- Drop old overload to avoid PostgREST ambiguity (PGRST203)
drop function if exists public.rpc_public_properties(
  text, text, double precision, double precision, double precision, numeric, numeric, int, int, text
);

create or replace function public.rpc_public_properties(
  p_search text default null,
  p_city text default null,
  p_center_lat double precision default null,
  p_center_lng double precision default null,
  p_radius_km double precision default null,
  p_min_price numeric default null,
  p_max_price numeric default null,
  p_property_type text default null,
  p_max_guests int default null,
  p_limit int default 20,
  p_offset int default 0,
  p_order_by text default 'recent' -- recent|price_asc|price_desc|rating_desc|distance
)
returns table (
  id uuid,
  title text,
  city text,
  price_per_night numeric,
  latitude double precision,
  longitude double precision,
  rating numeric,
  photo text,
  distance_km numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with base as (
    select 
      pr.id,
      pr.title,
      pr.city,
      pr.price_per_night,
      pr.latitude,
      pr.longitude,
      pr.rating,
      (case when pr.photos is not null and array_length(pr.photos, 1) > 0 then pr.photos[1] else null end) as photo,
      (case 
        when p_center_lat is not null and p_center_lng is not null and pr.geog is not null then
          ST_Distance(
            pr.geog,
            ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geography
          ) / 1000.0
        else null end
      ) as distance_km
    from public.properties pr
    where pr.is_active = true
      and pr.is_available = true
      and (p_city is null or lower(pr.city) = lower(p_city))
      and (p_min_price is null or pr.price_per_night >= p_min_price)
      and (p_max_price is null or pr.price_per_night <= p_max_price)
      and (p_property_type is null or lower(pr.property_type) = lower(p_property_type))
      and (p_max_guests is null or pr.max_guests >= p_max_guests)
      and (
        p_search is null or
        lower(pr.title) like '%' || lower(p_search) || '%' or
        lower(coalesce(pr.description, '')) like '%' || lower(p_search) || '%'
      )
      and (
        p_center_lat is null or p_center_lng is null or p_radius_km is null or pr.geog is null or
        ST_DWithin(
          pr.geog,
          ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geography,
          p_radius_km * 1000.0
        )
      )
  )
  select * from base
  order by
    case when p_order_by = 'price_asc' then null else 0 end,
    case when p_order_by = 'price_desc' then null else 0 end,
    case when p_order_by = 'rating_desc' then null else 0 end,
    case when p_order_by = 'distance' and distance_km is not null then null else 0 end,
    case when p_order_by = 'recent' then 1 else 0 end,
    -- Actual ordering clauses
    case when p_order_by = 'price_asc' then price_per_night end asc nulls last,
    case when p_order_by = 'price_desc' then price_per_night end desc nulls last,
    case when p_order_by = 'rating_desc' then rating end desc nulls last,
    case when p_order_by = 'distance' then distance_km end asc nulls last,
    -- default recent by created_at desc (tie-breaker: not available in projection, so reuse id/time ordering via subquery)
    id desc
  limit greatest(1, least(p_limit, 100))
  offset greatest(0, p_offset);
$$;

-- Ownership and permissions
alter function public.rpc_public_properties(text, text, double precision, double precision, double precision, numeric, numeric, text, int, int, int, text) owner to postgres;
grant execute on function public.rpc_public_properties(text, text, double precision, double precision, double precision, numeric, numeric, text, int, int, int, text) to anon;
