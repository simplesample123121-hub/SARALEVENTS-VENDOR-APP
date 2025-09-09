-- Invitations & RSVP Schema (run in Supabase SQL Editor)

create extension if not exists "pgcrypto";

create table if not exists invitations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  event_date date,
  event_time text,
  venue_name text,
  address text,
  cover_image_url text,
  gallery_urls text[] default '{}',
  slug text not null unique,
  visibility text not null default 'unlisted' check (visibility in ('public','unlisted','private')),
  rsvp_limit int,
  rsvp_count int default 0,
  theme text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists invitation_rsvps (
  id uuid primary key default gen_random_uuid(),
  invitation_id uuid not null references invitations(id) on delete cascade,
  name text,
  email text,
  phone text,
  status text not null default 'yes' check (status in ('yes','no','maybe')),
  guests_count int,
  note text,
  created_at timestamptz default now()
);

-- RLS
alter table invitations enable row level security;
alter table invitation_rsvps enable row level security;

-- Owners can do anything on their invitations
drop policy if exists "owners manage invitations" on invitations;
create policy "owners manage invitations" on invitations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Public can read public/unlisted invitations (by slug)
drop policy if exists "read public and unlisted invitations" on invitations;
create policy "read public and unlisted invitations" on invitations
  for select using (visibility in ('public','unlisted'));

-- Anyone can create RSVP for a public/unlisted invitation
drop policy if exists "anyone can create rsvp" on invitation_rsvps;
create policy "anyone can create rsvp" on invitation_rsvps
  for insert with check (
    exists (
      select 1 from invitations i
      where i.id = invitation_id and i.visibility in ('public','unlisted')
    )
  );

-- Owners can view RSVPs for their invitations
drop policy if exists "owners read rsvps" on invitation_rsvps;
create policy "owners read rsvps" on invitation_rsvps
  for select using (
    exists (
      select 1 from invitations i
      where i.id = invitation_id and i.user_id = auth.uid()
    )
  );

-- Optional: update rsvp_count via trigger
create or replace function sync_invite_rsvp_count() returns trigger as $$
declare
  v_invitation_id uuid;
begin
  v_invitation_id := coalesce(new.invitation_id, old.invitation_id);
  update invitations set rsvp_count = (
    select count(*) from invitation_rsvps r where r.invitation_id = v_invitation_id
  ), updated_at = now() where id = v_invitation_id;
  return null;
end;
$$ language plpgsql;

drop trigger if exists trg_invite_rsvp_count on invitation_rsvps;
create trigger trg_invite_rsvp_count after insert or delete or update on invitation_rsvps
  for each row execute function sync_invite_rsvp_count();


