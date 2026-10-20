# CLAUDE.md — Cashe

This file gives Claude Code the context and rules for working in this repository. Read it fully before making changes.

## What we're building

Cashe is a wallet whose money only unlocks at a chosen place, optionally within a time window, after the user has stayed there long enough. It is a solo entry for the Appwrite Databases Hackathon, built on Appwrite's managed PostgreSQL with PostGIS.

Two modes share one unlock engine:

- **Personal goal:** a user funds their own wallet (e.g. bicycle savings that only unlock at Mike's Bikes).
- **Gifted funds:** a sender funds a wallet for someone else, restricted to a place and optionally a time window (e.g. a parent's pocket money that only works at the school tuckshop during recess, or a friend's coffee at a favourite café). The recipient claims it through a one-time link (ADR 0002); an unclaimed gift can be cancelled by the sender and refunds automatically after 3 days. The sender may set an expiry date; unspent money then refunds to the sender. A blank expiry means the money stays in the recipient's wallet until spent.

A wallet unlocks only when all three pass:

1. The user is inside the place's geofence (`ST_DWithin`).
2. The current time is inside an allowed time window (if the wallet has any).
3. The user has dwelled inside the zone for the place's `dwell_seconds`.

### Out of scope (do not build unless asked)

- Real money movement or any payments partner. Money is a simulated Postgres ledger.
- A merchant-facing page or app.
- QR codes, NFC, BLE beacons or other physical presence proofs.
- Play Integrity / App Attest (post-hackathon).

## Repository layout

```text
cashe/
├── apps/
│   ├── api/                      # Rails 8 API (API-only)
│   │   ├── app/
│   │   │   ├── controllers/api/v1/
│   │   │   ├── models/           # persistence, associations, validations, scopes only
│   │   │   ├── services/         # one public `call` per class: Unlocks::Evaluate, Ledger::Spend
│   │   │   ├── policies/         # who may see or change a wallet
│   │   │   ├── queries/          # geofence and balance queries
│   │   │   ├── serializers/
│   │   │   ├── jobs/             # Solid Queue jobs
│   │   │   └── values/           # Coordinates, Money, DwellProgress, Result
│   │   ├── config/
│   │   ├── db/                   # migrations, schema, seeds (demo places)
│   │   ├── lib/appwrite_auth/    # JWT verification adapter
│   │   └── test/
│   └── mobile/                   # Flutter app
│       ├── lib/
│       │   ├── app/              # router, theme, bootstrap
│       │   ├── core/             # api client, auth, location, errors
│       │   └── features/
│       │       ├── auth/
│       │       ├── wallets/
│       │       ├── places/
│       │       └── unlock/       # dwell screen + ping loop
│       │           ├── data/
│       │           ├── domain/
│       │           └── presentation/
│       └── test/
├── packages/
│   └── api_contract/             # OpenAPI spec — single source of truth for the API
├── docs/
│   ├── adr/                      # architecture decision records
│   └── demo-script.md
├── scripts/                      # setup, seed demo data, gpx/ routes
├── .github/workflows/            # api.yml, mobile.yml (path-filtered)
├── docker-compose.yml            # local Postgres + PostGIS
├── .fvmrc                        # pinned Flutter version
├── .ruby-version
└── README.md
```

Each app must stay independently buildable. Never import across `apps/`; the only shared contract is `packages/api_contract`.

## Tech stack

| Layer | Choice |
| --- | --- |
| Mobile | Flutter (latest stable, pinned with FVM), Riverpod, `go_router`, `freezed` + `json_serializable`, `geolocator`, `flutter_map`, `appwrite` SDK |
| API | Rails 8, API-only mode |
| Database | Appwrite managed PostgreSQL + PostGIS (prod); `postgis/postgis` in Docker (dev) |
| Spatial | `activerecord-postgis-adapter` + RGeo |
| Jobs | Solid Queue (no Redis) |
| Auth | Appwrite Auth; Rails verifies the JWT via the `appwrite` Ruby gem |
| Tests | Minitest + `committee` (responses checked against the OpenAPI spec) (Rails); `flutter_test` + `mocktail` |
| Lint | RuboCop (`rubocop-rails-omakase` + Sandi Metz metrics below); `flutter_lints` |
| CI | GitHub Actions, path-filtered per app |

Check the latest stable versions of gems and packages before adding them; do not guess version numbers.

## Commands

> Keep this section accurate. Toolchain: rbenv (Ruby 4.0.7, `.ruby-version`), FVM (Flutter 3.47.7, `.fvmrc`). See ADR 0001.

```bash
# Local database (PostGIS on host port 5433)
docker compose up -d db

# API (from apps/api)
bin/setup --skip-server
bin/rails db:prepare
bin/rails server
bin/rails test
bundle exec rubocop

# Mobile (from apps/mobile)
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run --dart-define=FLAVOR=dev --dart-define=API_URL=http://10.0.2.2:3000
fvm flutter test
fvm flutter analyze
```

The API's schema is `db/structure.sql` (it holds the ledger's append-only trigger, which `schema.rb` can't). Migrating dumps it with `pg_dump` and tests load it with `psql`, so both must be at least as new as the database server. With Homebrew's `libpq` (PostgreSQL 18 tools): `export PATH="/opt/homebrew/opt/libpq/bin:$PATH"`.

Request tests check every response against `packages/api_contract/openapi.yaml` with `assert_contract :status` (committee), so an endpoint change fails its tests until the spec is updated too.

Always run the relevant tests and linters before saying a task is done.

## Architecture

- **Flutter app** signs in with Appwrite Auth, collects input and location, and shows results. It is never trusted with money or unlock decisions.
- **Rails API** owns every rule: wallets, ledger, geofence checks, time windows, dwell tracking, expiry jobs.
- **Appwrite Auth** handles sign-in and issues short-lived JWTs.
- **PostgreSQL + PostGIS** stores all data. Only Rails touches it.

### Auth flow

1. The app signs in with Appwrite Auth and requests a JWT.
2. Every API request sends `Authorization: Bearer <jwt>`.
3. Rails verifies the JWT by calling Appwrite (`lib/appwrite_auth`), caches the result briefly keyed by token, and finds or creates the matching `users` row.
4. The app refreshes the JWT before expiry.

The Appwrite server API key lives only in Rails credentials. Never put it in the app or commit it.

### Unlock flow

1. The user opens a wallet's unlock screen; the app starts a foreground location stream.
2. Every 10–15 seconds the app posts a presence ping (lat, lng, accuracy, mock-location flag).
3. Rails rejects mock locations, poor accuracy (> 50 m) and impossible jumps (speed check).
4. Rails checks `ST_DWithin` against the place and the time window.
5. Rails opens or extends a presence session; leaving the zone or a gap in pings ends it.
6. When the session reaches `dwell_seconds`, Rails creates an unlock with a short spend window (10 minutes, configurable).
7. Spends during the window are written to the ledger in a locked transaction; afterwards the wallet locks again.

## Data model

| Table | Key columns | Notes |
| --- | --- | --- |
| `users` | `appwrite_user_id` (unique), `display_name`, `role` (adult/child) | Mirrors Appwrite Auth; no passwords |
| `places` | `name`, `location` (geography point, SRID 4326), `radius_m`, `dwell_seconds` | GiST index on `location` |
| `wallets` | `kind` (goal/gift), `owner_id`, `funder_id`, `place_id`, `name`, `currency`, `status` (pending/active/cancelled/expired), `expires_at`, `target_cents`, `claim_token_digest`, `claim_expires_at`, `claimed_at` | Goal: owner = funder. Gift: owner is null until claimed; `expires_at` set by sender, null = never expires |
| `time_windows` | `wallet_id`, `days_of_week` (int array), `starts_at`, `ends_at`, `time_zone` | None = any time |
| `ledger_entries` | `wallet_id`, `amount_cents` (signed), `kind` (deposit/spend/refund), `idempotency_key` (unique) | Append-only |
| `presence_sessions` | `wallet_id`, `user_id`, `entered_at`, `last_ping_at`, `unlocked_at`, `ended_at` | Timestamps only |
| `unlocks` | `wallet_id`, `presence_session_id`, `unlocked_until` | Active spend window |

### Ledger rules (non-negotiable)

- Never store a balance column. Balance = `SUM(amount_cents)` per wallet.
- Never update or delete ledger entries; corrections are new entries.
- Every money write runs in one transaction with the wallet row locked (`lock!` / `SELECT … FOR UPDATE`) and rejects a resulting negative balance.
- Every write carries a unique `idempotency_key`.
- Money is integer cents with one currency per wallet. Never use floats for money.

### Privacy rules (non-negotiable)

- Never persist raw coordinates. Use them for the check, then discard. Do not log them.
- Location is requested in the foreground only, and only on the unlock screen.
- A funder never sees the recipient's location — only that money was spent and the place name.
- A claim token is stored only as a digest and works once.

## API

Versioned JSON under `/api/v1`. Keep `packages/api_contract/openapi.yaml` updated in the same change as any endpoint change.

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/session` | Exchange Appwrite JWT for the Rails user (creates on first call) |
| GET | `/me` | Current user |
| GET | `/places?near=lat,lng` | Places near a point |
| POST | `/places` | Create a place |
| GET | `/wallets` | Wallets I own or funded, with computed balances |
| POST | `/wallets` | Create a goal or gift (place + time windows + optional expiry) |
| GET | `/wallets/:id` | Detail, unlock rules, recent ledger entries |
| POST | `/wallets/:id/deposits` | Simulated top-up (funder only) |
| POST | `/wallets/:id/presence_pings` | Location ping → dwell progress or unlock (owner only) |
| POST | `/wallets/:id/spends` | Spend during an active unlock (owner only) |
| GET | `/wallets/:id/ledger_entries` | Paged history |
| POST | `/wallets/:id/cancellation` | Cancel an unclaimed gift and refund it (funder only) |
| POST | `/gift_claims` | Claim a gift with its one-time token |

Presence ping response:

```json
{ "status": "dwelling", "inside_zone": true, "in_time_window": true, "dwell_progress_seconds": 45, "dwell_required_seconds": 120, "unlocked_until": null }
```

`status` ∈ `outside_zone`, `outside_time_window`, `dwelling`, `unlocked`, `rejected`.

Errors always use: `{ "error": { "code": "…", "message": "…" } }`.

Rate-limit pings and spends with Rails 8's built-in `rate_limit`.

## Rails conventions

### Sandi Metz's rules (enforced in CI)

| Rule | RuboCop |
| --- | --- |
| Classes ≤ 100 lines | `Metrics/ClassLength: Max: 100` |
| Methods ≤ 5 lines | `Metrics/MethodLength: Max: 5` |
| ≤ 4 parameters, hash/keyword options count | `Metrics/ParameterLists: Max: 4, CountKeywordArgs: true` |
| Controllers instantiate one object; each action hands one object to one serializer | Code review |

Breaking a rule requires a short written reason in the commit or PR description. Do not disable cops inline without one.

### Other practices

- **Thin models:** associations, validations, scopes only. Business rules live in `app/services`, one public `call` per class.
- **Tell, don't ask:** `wallet.spend(money)` rather than inspecting fields from outside.
- **Value objects** for concepts with rules: `Coordinates`, `Money`, `DwellProgress`, `Result`.
- **Dependency injection** for anything external (clock, Appwrite client, geofence query). Inject `clock:`; never call `Time.current` directly inside rules.
- **Explicit results:** services return `Result` (success, value, error code) for expected failures; raise only for bugs.
- **Let the database enforce invariants:** constraints, unique indexes, PostGIS for distance, row locks for money.
- **Policies** are checked in every controller action, with a request test for each forbidden case.

Example service shape:

```ruby
module Unlocks
  class Evaluate
    def initialize(geofence: Geofence.new, clock: Time)
      @geofence = geofence
      @clock = clock
    end

    def call(session:, coordinates:)
      return Result.failure(:outside_zone) unless inside?(session, coordinates)
      return Result.failure(:outside_time_window) unless in_window?(session)

      DwellProgress.new(session: session, now: @clock.current).to_result
    end

    private

    def inside?(session, coordinates)
      @geofence.contains?(session.wallet.place, coordinates)
    end

    def in_window?(session)
      session.wallet.time_windows.open_at?(@clock.current)
    end
  end
end
```

## Flutter conventions

- Feature-first folders, each split into `data` → `domain` → `presentation`. Widgets never call the API directly.
- Riverpod for state; `go_router` for routing, guarded by auth state.
- Immutable models with `freezed` + `json_serializable`; no hand-written `fromJson`.
- Extract a widget once a `build` method passes ~40 lines; prefer `const` constructors.
- The API client returns typed results; map errors to user-facing messages in one place.
- One `LocationService` in `core/` wraps `geolocator`, explains why it needs permission, and streams only while the unlock screen is open.
- Flavors via `--dart-define`: `dev` (emulator, short dwell times, mock-location check relaxed) and `prod`.

## Testing

- Write tests first for the unlock engine and the ledger, with fixed clocks and fixed coordinates.
- A request test for every endpoint, including auth failures and forbidden cases; validate responses against the OpenAPI spec.
- Flutter: unit tests for use cases, widget tests for each unlock screen state, one integration test of the happy path.
- Never mark a task done with failing tests or lint errors.

## Working agreements for Claude Code

- Work phase by phase (see Roadmap). Do not start a phase until the previous gate passes.
- Don't commit, push or take any GitHub actions (PRs, `gh` commands, triggering workflows); the developer does all of that. Leave changes uncommitted and, when a task is done, summarise them with a suggested conventional commit message (`feat(api): …`, `fix(mobile): …`).
- Record real decisions as ADRs in `docs/adr/NNNN-title.md`.
- Ask before adding a new gem or package not listed here, changing the data model's ledger or privacy rules, or touching CI and deployment config.
- Never commit secrets. Use Rails credentials and `.env` files that are gitignored.
- Keep this file's Commands section accurate as the project evolves.

## Roadmap

Each phase ends at a gate that must pass before the next starts.

**Phase 0 — Foundations**
Monorepo, local Postgres + PostGIS in Docker, Rails 8 API and Flutter skeletons, CI. Free Appwrite project for Auth; the app signs in and Rails verifies the JWT.
*Gate: the app signs in and Rails returns `/me`.*

**Phase 1 — Core engine**
Migrations, models, value objects; ledger with locked transactions and idempotency keys. Unlock engine (geofence, time window, dwell), test-first with fixed clocks; all API endpoints.
*Gate: engine and ledger tests green; a request test for every endpoint.*

**Phase 2 — App flows**
Create goals and gifts, pick a place on the map, set time windows and expiry, simulated top-ups. Unlock screen with ping loop and dwell progress; spend and history views.
*Gate: the happy path works end to end on the emulator.*

**Phase 3 — Hardening**
Mock-location, accuracy and speed checks; rate limits; funder and owner policies. Solid Queue jobs for session expiry and gift refunds; privacy review.
*Gate: a spoofed ping is rejected on screen.*

**Phase 4 — Demo and submit**
Upgrade to Appwrite Pro, create the Starter PostgreSQL database, deploy Rails, seed demo places. GPX routes, one real-world clip, README, architecture slide, submission video.

If time runs short, trim Phase 3 but keep mock-location rejection (it is a demo moment).

## Costs

- Develop against local Docker Postgres; Rails reads `DATABASE_URL`, so switching to Appwrite is a config change.
- Use a Free Appwrite project for Auth during development (free projects pause after a week of inactivity).
- Managed PostgreSQL requires Appwrite Pro. The Starter tier ($10/month) is covered by Pro's $10 monthly compute credits. Upgrade only in Phase 4 and set a budget cap first.

## Demo

The demo tells the tuckshop story in about three minutes: a parent creates a $10 gift for the school tuckshop on weekdays 10:30–11:00; an emulator GPX route walks the child into the zone; the dwell bar fills (30 s on the demo place); the wallet unlocks and the child spends $3; a mock-location jump is rejected on screen; a quick cut to the Mike's Bikes savings goal. Seed demo places with `scripts/seed_demo`, including one centred on the developer's desk. Keep GPX routes in `scripts/gpx/`.

## Open decisions

- Hackathon submission deadline (sets dates on the roadmap).
- Spend window length after an unlock (assumed 10 minutes).

## Post-hackathon (do not build now)

- Payments partner: virtual cards (e.g. Stripe Issuing) with the unlock engine answering real-time authorization webhooks.
- Device integrity: Play Integrity and App Attest.
- Optional merchant-side presence proof (rotating QR or NFC).
- Parent-managed child accounts (a parent creates a child login and gifts to it directly).
- Locking a gift to a recipient's phone number or email.
- Licensing and compliance advice before holding real funds.
