# WTM

iOS hangout/date planning app — phase 1 scaffold. See the project brief for
product scope; this file covers how the pieces fit together and how to get
running locally.

## Layout

```
project.yml                  XcodeGen spec — the source of truth for the Xcode project
Config/                      xcconfig files; copy Secrets.xcconfig.example -> Secrets.xcconfig
App/                         The WTM app target: composition root only (AppState, RootView, MainTabView)
Packages/
  WTMCore/                   Models, Supabase client, service protocols + live/mock implementations
  Onboarding/                Sign in with Apple / email / phone
  Preferences/               Cuisine/budget/activity/dietary preference form
  Groups/                    Create/join groups, roster, invite codes
  ItineraryPlanner/          Itinerary view, stop swapping (currently backed by MockItineraryService)
  Profile/                   Edit profile, sign out
supabase/
  migrations/0001_init.sql   Phase 1 schema + RLS
  README.md                  Schema design notes and assumptions
```

Feature packages depend only on `WTMCore`, never on each other — cross-feature
navigation (e.g. Groups -> ItineraryPlanner) is composed in `App/Sources/MainTabView.swift`
via closures, not package-to-package imports.

## Setup

1. `brew install xcodegen` (one-time)
2. `cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig` and fill in your
   Supabase project's URL/anon key (Supabase dashboard -> Project Settings -> API)
3. `supabase link --project-ref <ref> && supabase db push` (see `supabase/README.md`)
4. `xcodegen generate` — regenerate this any time `project.yml` or the file
   layout changes; `WTM.xcodeproj` itself is gitignored
5. Open `WTM.xcodeproj` and run

## Notes

- Deployment target is iOS 17 (SwiftData + Observation). Swift 6 strict
  concurrency is on for every target.
- `ServiceContainer.live` wires real Supabase-backed services for
  auth/preferences/groups/profile. `itinerary` stays on `MockItineraryService`
  in *both* `.live` and `.mock` containers — there's no itinerary engine to
  call yet (it's a separate Python service per the architecture doc). Swap
  in a real implementation of `ItineraryServicing` once that service exists.
- Views read cross-cutting dependencies via `@Environment(\.services)`
  (`ServiceContainer`, defined in WTMCore) and take navigation callbacks as
  explicit closures — that split is what keeps feature packages decoupled
  from each other while still sharing one dependency container.
- Every package builds clean under Swift 6 strict concurrency; verify with
  `xcodebuild -scheme <PackageName> -destination 'generic/platform=iOS Simulator' build`
  from inside `Packages/<PackageName>` (plain `swift build` won't work for the
  iOS-only feature packages since they don't declare a macOS platform).
