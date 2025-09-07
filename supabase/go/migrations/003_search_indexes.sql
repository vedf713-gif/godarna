-- 003_search_indexes.sql
-- Text search and composite indexes for properties and bookings

-- Ensure pg_trgm is enabled (idempotent)
create extension if not exists pg_trgm;

-- Trigram GIN indexes for fuzzy search
create index if not exists idx_properties_title_trgm on public.properties using gin (lower(title) gin_trgm_ops);
create index if not exists idx_properties_city_trgm on public.properties using gin (lower(city) gin_trgm_ops);
create index if not exists idx_properties_description_trgm on public.properties using gin (lower(coalesce(description, '')) gin_trgm_ops);

-- Composite index for common filters and ordering
create index if not exists idx_properties_filter on public.properties (city, is_active, is_available, price_per_night);

-- Helpful indexes on created_at for recency ordering
create index if not exists idx_properties_created_at on public.properties(created_at desc);

-- Range-related indexes for bookings analytics (optional)
create index if not exists idx_bookings_checkin on public.bookings(check_in);
create index if not exists idx_bookings_checkout on public.bookings(check_out);
