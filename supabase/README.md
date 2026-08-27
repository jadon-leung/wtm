# Supabase schema (phase 1)

## Setup

```
brew install supabase/tap/supabase   # if you don't have the CLI
supabase init                        # if this repo isn't linked to a project yet
supabase link --project-ref <your-project-ref>
supabase db push                     # applies migrations/0001_init.sql
```

Then fill in `Config/Secrets.xcconfig` (see top-level README) with the
project's URL and anon key.

## Design notes / assumptions beyond the brief's literal data model

- **`itinerary_stop_alternates`** — not in the brief's table list, but needed
  so "swap this stop" is a local promote-an-alternate operation instead of a
  synchronous call back to the itinerary engine. The engine writes ranked
  alternates alongside the primary stop when it generates an itinerary.
- **`profiles` vs `auth.users`** — Supabase's `auth.users` is not directly
  queryable/joinable from the client under RLS, so app-owned fields (name,
  phone, avatar) live in a `profiles` table keyed 1:1 on `auth.users.id`.
  Phone is a plain nullable column here, not tied to the auth method used to
  sign in, per the decoupled-auth decision in the brief.
- **`preferences` is one row per user**, not per group — the brief describes
  it as a standing user attribute. If you later want per-group preference
  overrides, that's an additive table (`group_preference_overrides`), not a
  change to this one.
- **Guest preview flow** — rather than encoding "this session came from
  invite code X" into RLS (which needs custom JWT claims and is fiddly),
  guest/unauthenticated preview goes through the
  `preview_itinerary_by_invite_code(code)` RPC, a `security definer`
  function that reads past RLS and returns a flattened, read-only view of
  the itinerary. The client can call this with no session at all. Full
  group membership (and therefore direct table access via RLS) only kicks
  in once someone actually joins via `join_group_with_invite_code`, which
  requires a real (possibly anonymous) auth session.
- **Anonymous auth for guests** — the brief's guest flow ("see the itinerary
  before creating an account") is assumed to use Supabase's anonymous
  sign-in (`signInAnonymously`) once the guest wants to do anything beyond
  the RPC preview (e.g. the app needs *some* `auth.uid()` to attach later).
  This isn't enabled by default on a new project — turn it on under
  Authentication → Providers → Anonymous Sign-Ins.
- **Writes to `venues`, `itineraries`, `itinerary_stops`,
  `itinerary_stop_alternates`** are intentionally not covered by any
  authenticated RLS policy — only `SELECT`. The itinerary engine is a
  separate trusted service that writes with the `service_role` key, which
  bypasses RLS entirely. If the engine ever needs to run as a normal
  authenticated user, these policies need revisiting.
- **`is_group_member()`** is a `security definer` helper so group-scoped
  `SELECT` policies elsewhere don't each need to repeat (and risk
  diverging on) the same join.
- **`add_creator_as_owner()` trigger** — `group_members` has no authenticated
  `INSERT` policy at all (joining only happens through
  `join_group_with_invite_code`), which would make it impossible for a
  group's creator to become a member. This `AFTER INSERT ON groups` trigger
  adds them as `owner` automatically, as a `security definer` so it isn't
  blocked by that same RLS gap.

## Things this migration does not set up (flagged, not decided)

- Push notifications for invites (phase 1 scope per the brief) need either a
  Supabase Edge Function that calls APNs directly, or a third-party push
  provider (OneSignal, etc.) — not wired up here.
- Realtime subscriptions (e.g. live itinerary status while the engine is
  generating) aren't enabled on any table yet. Supabase Realtime works off
  these tables as-is once you turn on replication for them; no schema
  change needed, just a decision on which tables should be broadcast.
