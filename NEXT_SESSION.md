# Next Session

_Written 2026-09-07, right after provider search/filters shipped. Updated 2026-09-08 after seed data shipped, and 2026-09-09 after the auth screen redesign + Google Sign-In scaffolding. See `PROJECT_STATUS.md` for the full done/remaining picture — this file is just the actionable punch list for picking up work next._

## 1. Seed/demo data — done (2026-09-08)

`backend/src/main/resources/db/migration/V15__seed_demo_data.sql` — 7 providers (5 APPROVED, 1 PENDING, 1 REJECTED), 12 services, 2 customers, 1 admin, 8 bookings across every status, 2 reviews. All seeded users log in with password `Demo1234!`. Verified against a live migration run, the full backend test suite, and the running app on both Chrome and a physical Android phone.

## 2. Google Sign-In — code is done, needs YOUR Google Cloud setup before it actually works

All the code is written and compiles/analyzes clean, and everything except the final Google-side handshake has been verified live (backend rejects cleanly with a clear error when unconfigured, the mobile button shows a clear "not set up yet" toast instead of silently failing). It cannot be fully tested end-to-end until you create real credentials, since that's a real identity check against Google's servers - nothing about that step can be faked or stubbed locally.

**What was built:**
- Backend: `V16__add_google_auth_to_users.sql` (adds `auth_provider`/`google_sub` to `users`, makes `password_hash` nullable), `POST /api/auth/google` (verifies the ID token via `GoogleTokenService`, creates or links a user, returns the same JWT shape as login/register).
- Mobile: `AppConfig.googleOAuthClientId` (build-time config, empty by default), `GoogleAuthService` (wraps the `google_sign_in` package, platform-aware for web vs. native), a "Continue with Google" button on both the Login screen and Register's role-choice step.

**What YOU need to do in Google Cloud Console** (console.cloud.google.com) before it will actually work, even locally:
1. Create a project (or use an existing one).
2. Configure the OAuth consent screen (External is fine for testing; add your own Google account as a test user while the app is unpublished).
3. Create an OAuth 2.0 Client ID of type **"Web application"**. For local dev, add `http://localhost:5000` (or whatever port `flutter run -d chrome` picks) under **Authorized JavaScript origins** - this is the client ID that matters; copy it, it's the one value used everywhere (see below).
4. Create a second OAuth 2.0 Client ID of type **"Android"**:
   - Package name: `com.kazilink.kazilink_rwanda`
   - SHA-1 (debug keystore, already generated on this machine): `3E:93:27:22:33:A0:E5:D7:CF:96:7F:84:5E:5F:EC:E9:08:36:F5:BB`
   - This client ID itself is never used in code - Android just needs it registered against that package name + fingerprint for sign-in to be allowed at all. Before ever shipping a signed release build, add the **release keystore's** SHA-1 here too (or Android sign-in will fail on real release builds even though it works in debug).
   - (No iOS client needed - this project has no `ios/` folder.)

**Where the Web client ID goes** - the SAME value, in exactly two places:
- Backend: `GOOGLE_OAUTH_CLIENT_ID` in `backend/.env` (see `.env.example`).
- Mobile: pass it via `--dart-define` on every run/build - e.g. `flutter run -d chrome --dart-define=GOOGLE_OAUTH_CLIENT_ID=xxxx.apps.googleusercontent.com`. This is exactly why nothing in the mobile or backend code needs to change between local dev and production - only this one value, supplied at run/build time, differs.

## 3. Deployment (needs a decision before code)

Nothing exists yet: no backend Dockerfile, no CI, no hosting picked, `docker-compose.yml` only covers local Postgres.

Decide first:
- **Backend hosting** — Render, Railway, Fly.io, or a plain VPS all fit a small Spring Boot + Postgres app.
- **Database hosting** — managed Postgres from the same provider, or self-hosted alongside the backend.
- **Flutter target** — ship as a web build (simplest to demo via a link), an Android APK, or both.
- **Secrets** — how `JWT_SECRET`, `DB_PASSWORD`, and the Brevo API key reach the hosted backend without landing in git.

Once those are picked, the concrete tasks are: write `backend/Dockerfile`, wire environment variables for the chosen host, and (if shipping Flutter web) point its API base URL at the deployed backend instead of `localhost:8081`.

## 4. Minor: pre-existing flaky test

`mobile/test/widget_test.dart` ("App boots logged-out and lands on the login screen") fails with a `pumpAndSettle` timeout. Confirmed on a clean checkout - not caused by the search/filters work. Low priority; `flutter analyze` and the other 22 Flutter tests are unaffected.

## Notes from the last session

- Docker Desktop, Postgres, and the backend (port 8081) may still be running locally from live-testing seed data - check before assuming a clean environment.
- A throwaway test customer account exists in the dev database: `test.search.customer@example.com`. The dev DB also has assorted manually-created test accounts (`bob_*`, `dave*@fasha.rw`, `admin@fasha.rw`, etc.) from earlier manual testing — unrelated to the V15 seed data, which deliberately used a `demo.admin@fasha.rw` email to avoid colliding with the existing `admin@fasha.rw`.
- If running on a physical Android device over USB, run `adb reverse tcp:8081 tcp:8081` once after connecting so the app can reach the local backend.
- Found and fixed a real leaked secret while working here: `backend/.env.example` had a genuine Brevo API key and personal email committed (in `bfcd8ec`). Removed from the file (`e1ff9c2`), but it still exists in git history - the repo is private on GitHub so exposure is limited, but the key should still be rotated in Brevo's dashboard.
