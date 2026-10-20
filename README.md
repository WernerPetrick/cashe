# Cashe

A wallet whose money only unlocks at a chosen place, optionally within a time window, after you've stayed there long enough. Built for the Appwrite Databases Hackathon on PostgreSQL + PostGIS.

| Path | What |
| --- | --- |
| `apps/api` | Rails 8.1 API (owns every rule: ledger, geofence, dwell, time windows) |
| `apps/mobile` | Flutter app (sign-in, input, location, results) |
| `packages/api_contract` | OpenAPI spec, the only shared contract between apps |
| `docs/adr` | Architecture decision records |
| `scripts` | Setup, demo seeding, GPX routes |

## Prerequisites

- [rbenv](https://github.com/rbenv/rbenv) with Ruby **4.0.7** (`rbenv install 4.0.7`)
- [FVM](https://fvm.app) with Flutter **3.47.7** (`fvm install`, which reads `.fvmrc`)
- Docker (for local PostgreSQL 18 + PostGIS 3.6)

## Getting started

```bash
# Local database (host port 5433)
docker compose up -d db

# API
cd apps/api
bin/setup --skip-server
bin/rails server
bin/rails test
bundle exec rubocop

# Mobile
cd apps/mobile
fvm flutter pub get
fvm flutter test
fvm flutter analyze
fvm flutter run --dart-define=FLAVOR=dev --dart-define=API_URL=http://10.0.2.2:3000
```

See `CLAUDE.md` for architecture, conventions and the roadmap.
