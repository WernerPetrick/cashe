# 0001 — Toolchain and local database

- Status: accepted
- Date: 2026-10-20

## Context

Cashe is a monorepo with a Rails API and a Flutter app that must each build independently. Versions need to be pinned so local, CI and demo builds match.

## Decision

- **Ruby 4.0.7** managed with **rbenv** (`.ruby-version` at the repo root and in `apps/api`).
- **Rails 8.1.4** in API-only mode, generated without Action Cable, Active Storage, Action Mailbox, Action Text, Jbuilder, Kamal, Thruster or the Rails Docker/CI templates (CI lives in `.github/workflows`, path-filtered per app).
- **Flutter 3.47.7** (latest 3.47 stable) managed with **FVM**, pinned in `.fvmrc`.
- **PostgreSQL 18 + PostGIS 3.6** (`postgis/postgis:18-3.6`) via Docker Compose for development, exposed on host port **5433** to avoid clashing with a locally installed Postgres on 5432.
- Rails uses `activerecord-postgis-adapter` 11.1 (adapter `postgis`). Production reads `DATABASE_URL`, `CACHE_DATABASE_URL` and `QUEUE_DATABASE_URL`.

## Consequences

- Switching to Appwrite's managed PostgreSQL is a config change. Before Phase 4, confirm Appwrite's Postgres/PostGIS versions and align the Docker image if they differ.
- Whether Solid Cache and Solid Queue get separate databases on the Appwrite Starter tier is decided in Phase 4.
