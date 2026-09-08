# Next Session

_Written 2026-09-07, right after provider search/filters shipped. Updated 2026-09-08 after seed data shipped. See `PROJECT_STATUS.md` for the full done/remaining picture — this file is just the actionable punch list for picking up work next._

## 1. Seed/demo data — done (2026-09-08)

`backend/src/main/resources/db/migration/V15__seed_demo_data.sql` — 7 providers (5 APPROVED, 1 PENDING, 1 REJECTED), 12 services, 2 customers, 1 admin, 8 bookings across every status, 2 reviews. All seeded users log in with password `Demo1234!`. Verified against a live migration run, the full backend test suite, and the running app on both Chrome and a physical Android phone.

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

- Docker Desktop, Postgres, and the backend (port 8081) may still be running locally from live-testing seed data - check before assuming a clean environment.
- A throwaway test customer account exists in the dev database: `test.search.customer@example.com`. The dev DB also has assorted manually-created test accounts (`bob_*`, `dave*@fasha.rw`, `admin@fasha.rw`, etc.) from earlier manual testing — unrelated to the V15 seed data, which deliberately used a `demo.admin@fasha.rw` email to avoid colliding with the existing `admin@fasha.rw`.
- If running on a physical Android device over USB, run `adb reverse tcp:8081 tcp:8081` once after connecting so the app can reach the local backend.
