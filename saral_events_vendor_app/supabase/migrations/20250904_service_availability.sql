create table if not exists public.service_availability (
  service_id uuid not null references public.services(id) on delete cascade,
  date timestamptz not null,
  morning_available boolean not null default true,
  afternoon_available boolean not null default true,
  evening_available boolean not null default true,
  night_available boolean not null default true,
  custom_start text null,
  custom_end   text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_availability_pk primary key (service_id, date)
);

create index if not exists idx_service_availability_service on public.service_availability(service_id);
create index if not exists idx_service_availability_date on public.service_availability(date);

create trigger update_service_availability_updated_at
before update on public.service_availability
for each row execute function update_updated_at_column();

alter table public.service_availability enable row level security;

drop policy if exists sa_all_select on public.service_availability;
drop policy if exists sa_all_insert on public.service_availability;
drop policy if exists sa_all_update on public.service_availability;
drop policy if exists sa_all_delete on public.service_availability;

create policy sa_all_select on public.service_availability for select using (true);
create policy sa_all_insert on public.service_availability for insert with check (true);
create policy sa_all_update on public.service_availability for update using (true);
create policy sa_all_delete on public.service_availability for delete using (true);
