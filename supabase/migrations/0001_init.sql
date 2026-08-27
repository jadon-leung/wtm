-- WTM phase 1 schema
-- Auth is handled by Supabase's built-in `auth.users`. Everything below is
-- app-owned data that hangs off `auth.users.id`.

create extension if not exists "pgcrypto";

-- ============================================================================
-- Enums
-- ============================================================================

create type budget_tier as enum ('low', 'medium', 'high', 'no_preference');
create type activity_type as enum ('food', 'drinks', 'outdoors', 'entertainment', 'culture', 'active', 'nightlife');
create type group_status as enum ('forming', 'active', 'completed', 'archived');
create type group_member_role as enum ('owner', 'member');
create type itinerary_status as enum ('draft', 'generating', 'ready', 'failed');
create type venue_source as enum ('google_places', 'yelp');
create type feedback_action as enum ('accepted', 'rejected', 'swapped');

-- ============================================================================
-- profiles
-- One row per auth.users row. Phone is captured post-signup and is
-- independent of whatever auth method was used (per the decoupled-auth
-- decision), so it lives here rather than being inferred from auth identity.
-- ============================================================================

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  phone text,
  email text,
  avatar_url text,
  is_guest boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- preferences
-- One standing preference set per user (phase 1). Revisit if we ever need
-- per-group overrides.
-- ============================================================================

create table preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references profiles (id) on delete cascade,
  cuisines text[] not null default '{}',
  budget_tier budget_tier not null default 'no_preference',
  activity_types activity_type[] not null default '{}',
  dietary_restrictions text[] not null default '{}',
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- groups / group_members
-- ============================================================================

create table groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  status group_status not null default 'forming',
  created_by uuid not null references profiles (id),
  invite_code text not null unique default encode(gen_random_bytes(6), 'base64'),
  created_at timestamptz not null default now()
);

create table group_members (
  group_id uuid not null references groups (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  role group_member_role not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- ============================================================================
-- venues
-- Cached place data. Written only by the itinerary engine (service_role),
-- refreshed on a TTL rather than fetched live on every view.
-- ============================================================================

create table venues (
  id uuid primary key default gen_random_uuid(),
  source venue_source not null,
  external_id text not null,
  name text not null,
  category text not null,
  price_level smallint,
  rating numeric(2, 1),
  address text,
  lat double precision,
  lng double precision,
  hours jsonb,
  photo_urls text[] not null default '{}',
  cached_at timestamptz not null default now(),
  unique (source, external_id)
);

-- ============================================================================
-- itineraries / itinerary_stops / itinerary_stop_alternates
-- `itinerary_stop_alternates` isn't in the brief's data model list but is
-- needed to make "swap this stop" cheap: the engine returns ranked
-- alternates per slot up front, we persist them, and a swap is just
-- promoting an alternate rather than a synchronous re-query of the engine.
-- ============================================================================

create table itineraries (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups (id) on delete cascade,
  status itinerary_status not null default 'draft',
  generated_at timestamptz,
  created_at timestamptz not null default now()
);

create table itinerary_stops (
  id uuid primary key default gen_random_uuid(),
  itinerary_id uuid not null references itineraries (id) on delete cascade,
  venue_id uuid not null references venues (id),
  stop_order smallint not null,
  time_slot tstzrange not null,
  created_at timestamptz not null default now(),
  unique (itinerary_id, stop_order)
);

create table itinerary_stop_alternates (
  id uuid primary key default gen_random_uuid(),
  itinerary_stop_id uuid not null references itinerary_stops (id) on delete cascade,
  venue_id uuid not null references venues (id),
  rank smallint not null,
  score numeric,
  unique (itinerary_stop_id, rank)
);

-- ============================================================================
-- votes / feedback
-- ============================================================================

create table itinerary_stop_feedback (
  id uuid primary key default gen_random_uuid(),
  itinerary_stop_id uuid not null references itinerary_stops (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  action feedback_action not null,
  created_at timestamptz not null default now(),
  unique (itinerary_stop_id, user_id)
);

-- ============================================================================
-- helper: is the current user a member of a given group?
-- Used throughout RLS instead of repeating the join everywhere.
-- ============================================================================

create function is_group_member(target_group_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from group_members
    where group_id = target_group_id
      and user_id = auth.uid()
  );
$$;

-- Auto-add a group's creator as its owner member. Runs as security definer
-- so it isn't blocked by group_members RLS (which intentionally has no
-- authenticated INSERT policy — see join_group_with_invite_code below).
create function add_creator_as_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into group_members (group_id, user_id, role)
  values (new.id, new.created_by, 'owner');
  return new;
end;
$$;

create trigger groups_add_creator_as_owner
  after insert on groups
  for each row execute function add_creator_as_owner();

-- ============================================================================
-- RLS
-- ============================================================================

alter table profiles enable row level security;
alter table preferences enable row level security;
alter table groups enable row level security;
alter table group_members enable row level security;
alter table venues enable row level security;
alter table itineraries enable row level security;
alter table itinerary_stops enable row level security;
alter table itinerary_stop_alternates enable row level security;
alter table itinerary_stop_feedback enable row level security;

-- profiles: read your own profile plus profiles of anyone you share a group
-- with (so group screens can show member names/avatars); only edit your own.
create policy "profiles_select_self_or_groupmate" on profiles
  for select using (
    id = auth.uid()
    or exists (
      select 1 from group_members gm1
      join group_members gm2 on gm1.group_id = gm2.group_id
      where gm1.user_id = auth.uid() and gm2.user_id = profiles.id
    )
  );

create policy "profiles_update_self" on profiles
  for update using (id = auth.uid());

create policy "profiles_insert_self" on profiles
  for insert with check (id = auth.uid());

-- preferences: fully private to the owning user. The itinerary engine reads
-- these with the service_role key (bypasses RLS), so group members never
-- need direct read access to each other's raw preferences.
create policy "preferences_owner_all" on preferences
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- groups: members can see the group; any authenticated user can create one
-- (becoming its creator); only the owner can update it.
create policy "groups_select_member" on groups
  for select using (is_group_member(id));

create policy "groups_insert_authenticated" on groups
  for insert with check (created_by = auth.uid());

create policy "groups_update_owner" on groups
  for update using (
    exists (
      select 1 from group_members
      where group_id = groups.id and user_id = auth.uid() and role = 'owner'
    )
  );

-- group_members: members can see the roster; joining happens through the
-- join_group_with_invite_code() RPC below rather than a direct insert
-- policy, so an invite code can be validated server-side before granting
-- membership.
create policy "group_members_select_member" on group_members
  for select using (is_group_member(group_id));

-- venues: not sensitive, just cached place data; readable by anyone signed
-- in (including guests via anonymous auth). Writes are engine-only
-- (service_role), so there are intentionally no insert/update policies here.
create policy "venues_select_authenticated" on venues
  for select using (auth.role() = 'authenticated');

-- itineraries / stops / alternates: visible to group members. Written by the
-- itinerary engine via service_role, so again no authenticated write
-- policies.
create policy "itineraries_select_member" on itineraries
  for select using (is_group_member(group_id));

create policy "itinerary_stops_select_member" on itinerary_stops
  for select using (
    exists (
      select 1 from itineraries
      where itineraries.id = itinerary_stops.itinerary_id
        and is_group_member(itineraries.group_id)
    )
  );

create policy "itinerary_stop_alternates_select_member" on itinerary_stop_alternates
  for select using (
    exists (
      select 1 from itinerary_stops
      join itineraries on itineraries.id = itinerary_stops.itinerary_id
      where itinerary_stops.id = itinerary_stop_alternates.itinerary_stop_id
        and is_group_member(itineraries.group_id)
    )
  );

-- feedback: group members can see who accepted/rejected/swapped what
-- (useful for phase-1 itinerary UI); everyone can only write their own vote.
create policy "itinerary_stop_feedback_select_member" on itinerary_stop_feedback
  for select using (
    exists (
      select 1 from itinerary_stops
      join itineraries on itineraries.id = itinerary_stops.itinerary_id
      where itinerary_stops.id = itinerary_stop_feedback.itinerary_stop_id
        and is_group_member(itineraries.group_id)
    )
  );

create policy "itinerary_stop_feedback_insert_self" on itinerary_stop_feedback
  for insert with check (user_id = auth.uid());

create policy "itinerary_stop_feedback_update_self" on itinerary_stop_feedback
  for update using (user_id = auth.uid());

-- ============================================================================
-- RPCs
-- ============================================================================

-- Joining a group happens here (rather than an INSERT policy on
-- group_members) so the invite code is checked server-side atomically with
-- membership creation.
create function join_group_with_invite_code(code text)
returns groups
language plpgsql
security definer
set search_path = public
as $$
declare
  target_group groups;
begin
  select * into target_group from groups where invite_code = code;

  if target_group.id is null then
    raise exception 'invalid_invite_code';
  end if;

  insert into group_members (group_id, user_id, role)
  values (target_group.id, auth.uid(), 'member')
  on conflict (group_id, user_id) do nothing;

  return target_group;
end;
$$;

-- Lets a signed-out or anonymous (guest) session preview an itinerary from
-- an invite link without being a group member. Returns null if the code
-- doesn't resolve to a group with a ready itinerary yet. security definer
-- so it can read past the itineraries/itinerary_stops RLS policies above.
create function preview_itinerary_by_invite_code(code text)
returns table (
  group_name text,
  itinerary_id uuid,
  itinerary_status itinerary_status,
  stop_id uuid,
  stop_order smallint,
  time_slot tstzrange,
  venue_name text,
  venue_category text,
  venue_rating numeric
)
language sql
security definer
set search_path = public
stable
as $$
  select
    g.name,
    i.id,
    i.status,
    s.id,
    s.stop_order,
    s.time_slot,
    v.name,
    v.category,
    v.rating
  from groups g
  join itineraries i on i.group_id = g.id
  join itinerary_stops s on s.itinerary_id = i.id
  join venues v on v.id = s.venue_id
  where g.invite_code = code
  order by s.stop_order;
$$;

-- ============================================================================
-- housekeeping trigger: keep preferences.updated_at current
-- ============================================================================

create function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger preferences_set_updated_at
  before update on preferences
  for each row execute function set_updated_at();

create trigger profiles_set_updated_at
  before update on profiles
  for each row execute function set_updated_at();
