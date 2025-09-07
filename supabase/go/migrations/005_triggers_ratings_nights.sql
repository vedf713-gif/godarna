-- 005_triggers_ratings_nights.sql
-- Triggers for computing nights and maintaining property ratings

-- Compute nights on insert/update
create or replace function public.bookings_compute_nights()
returns trigger
language plpgsql
as $$
begin
  if NEW.check_in is not null and NEW.check_out is not null then
    if NEW.check_out <= NEW.check_in then
      raise exception 'check_out must be greater than check_in';
    end if;
    NEW.nights := GREATEST(1, CEIL(EXTRACT(EPOCH FROM (NEW.check_out - NEW.check_in)) / 86400.0));
  end if;
  return NEW;
end; $$;

drop trigger if exists trg_bookings_compute_nights_ins on public.bookings;
drop trigger if exists trg_bookings_compute_nights_upd on public.bookings;
create trigger trg_bookings_compute_nights_ins
  before insert on public.bookings
  for each row execute function public.bookings_compute_nights();
create trigger trg_bookings_compute_nights_upd
  before update of check_in, check_out on public.bookings
  for each row execute function public.bookings_compute_nights();

-- Maintain property rating and review_count based on bookings with rating
create or replace function public.properties_recalc_rating(p_property_id uuid)
returns void
language sql
as $$
  update public.properties p
  set rating = coalesce(sub.avg_rating, 0),
      review_count = coalesce(sub.cnt, 0)
  from (
    select b.property_id, avg(b.rating)::numeric(3,2) as avg_rating, count(*) as cnt
    from public.bookings b
    where b.property_id = p_property_id and b.rating is not null
    group by b.property_id
  ) sub
  where p.id = p_property_id;
$$;

create or replace function public.bookings_after_rating_change()
returns trigger
language plpgsql
as $$
begin
  perform public.properties_recalc_rating(coalesce(NEW.property_id, OLD.property_id));
  return NEW;
end; $$;

drop trigger if exists trg_bookings_rating_aiud on public.bookings;
create trigger trg_bookings_rating_aiud
  after insert or update of rating or delete on public.bookings
  for each row execute function public.bookings_after_rating_change();

-- Prevent host from booking their own property
create or replace function public.bookings_validate_tenant_host()
returns trigger
language plpgsql
as $$
begin
  if NEW.tenant_id = NEW.host_id then
    raise exception 'tenant cannot be the same as host';
  end if;
  return NEW;
end; $$;

drop trigger if exists trg_bookings_validate_tenant_host on public.bookings;
create trigger trg_bookings_validate_tenant_host
  before insert on public.bookings
  for each row execute function public.bookings_validate_tenant_host();
