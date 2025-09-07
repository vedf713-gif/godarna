-- 002_extensions_and_geo.sql
-- Enable extensions and add geospatial support

-- Enable extensions (idempotent)
create extension if not exists postgis;
create extension if not exists pg_trgm;
create extension if not exists btree_gist;

-- Add geog column to properties for spatial queries
alter table public.properties
  add column if not exists geog geography(Point, 4326);

-- Backfill geog from existing latitude/longitude when null
update public.properties
set geog = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
where geog is null and latitude is not null and longitude is not null;

-- Ensure geog is always in sync on write
create or replace function public.properties_set_geog()
returns trigger
language plpgsql
as $$
begin
  if NEW.latitude is not null and NEW.longitude is not null then
    NEW.geog := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
  else
    NEW.geog := null;
  end if;
  return NEW;
end; $$;

-- Upsert triggers (drop if exist then create)
drop trigger if exists trg_properties_set_geog_ins on public.properties;
drop trigger if exists trg_properties_set_geog_upd on public.properties;
create trigger trg_properties_set_geog_ins
  before insert on public.properties
  for each row execute function public.properties_set_geog();
create trigger trg_properties_set_geog_upd
  before update of latitude, longitude on public.properties
  for each row execute function public.properties_set_geog();

-- Spatial index for fast radius queries
create index if not exists idx_properties_geog_gist on public.properties using gist(geog);
