# Next Session

_Written 2026-09-07, right after provider search/filters shipped. See `PROJECT_STATUS.md` for the full done/remaining picture — this file is just the actionable punch list for picking up work next._

## 1. Seed/demo data (recommended starting point)

Only `categories` has real seed data (`backend/src/main/resources/db/migration/V5__seed_categories.sql`). A fresh database has zero providers, services, bookings, or reviews — the app looks empty on first run.

**Approach:** either a new Flyway migration (`V15__seed_demo_data.sql`) inserting a handful of realistic `users` (role PROVIDER, pre-verified), `provider_profiles` (APPROVED), `service_listings` per category, plus a few `bookings` in different statuses and matching `reviews` — or a `@Profile("dev")` `CommandLineRunner` that does the same thing in code, if the data should never touch a production database. Flyway is simpler and matches how categories were already seeded; the `CommandLineRunner` route is safer to guarantee it can never run against a real deployment.

Passwords for any seeded users need real bcrypt hashes (see `AuthService`/`PasswordEncoder` for how existing users are hashed) - can't just insert plaintext.

## 2. Deployment (needs a decision before code)

Nothing exists yet: no backend Dockerfile, no CI, no hosting picked, `docker-compose.yml` only covers local Postgres.

Decide first:
- **Backend hosting** — Render, Railway, Fly.io, or a plain VPS all fit a small Spring Boot + Postgres app.
- **Database hosting** — managed Postgres from the same provider, or self-hosted alongside the backend.
- **Flutter target** — ship as a web build (simplest to demo via a link), an Android APK, or both.
- **Secrets** — how `JWT_SECRET`, `DB_PASSWORD`, and the Brevo API key reach the hosted backend without landing in git.

Once those are picked, the concrete tasks are: write `backend/Dockerfile`, wire environment variables for the chosen host, and (if shipping Flutter web) point its API base URL at the deployed backend instead of `localhost:8081`.

## 3. Minor: pre-existing flaky test

`mobile/test/widget_test.dart` ("App boots logged-out and lands on the login screen") fails with a `pumpAndSettle` timeout. Confirmed on a clean checkout - not caused by the search/filters work. Low priority; `flutter analyze` and the other 22 Flutter tests are unaffected.

## Notes from the last session

- Docker Desktop, Postgres, and the backend (port 8081) may still be running locally from live-testing search/filters - check before assuming a clean environment.
- A throwaway test customer account exists in the dev database: `test.search.customer@example.com`.
