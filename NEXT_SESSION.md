# Next Session

_Written 2026-09-07; updated through 2026-09-14 (customer UI redesign, Docker/Redis/CI, push notifications). See `PROJECT_STATUS.md` for the full done/remaining picture — this file is just the actionable punch list, specifically the things that need YOUR action (an external account/credential only you can create) before they work._

## 1. Google Sign-In — code is done, needs YOUR Google Cloud setup before it actually works

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

## 2. Push notifications — code is done, needs YOUR Firebase project before it actually works

Same shape as Google Sign-In above, built 2026-09-14 - see `PROJECT_STATUS.md`'s "Push notifications" section for the full list of what shipped. Verified live that the whole pipeline works correctly and gracefully falls back to logging when unconfigured; the one thing that can't be tested without your own Firebase project is an actual push arriving on a real device.

**What YOU need to do in the Firebase console** (console.firebase.google.com) before it will actually work:
1. Create a project (or use an existing one - can be the SAME Google Cloud project as Google Sign-In above, Firebase projects and GCP projects are the same underlying thing).
2. Add an app for each platform you want push on:
   - **Web app**: register app nickname, Firebase gives you back `apiKey`/`appId`/`messagingSenderId`/`projectId` - copy all four.
   - **Android app**: package name `com.kazilink.kazilink_rwanda`. You do NOT need to download `google-services.json` or add the Google Services Gradle plugin - this project deliberately reads the same four config values via `--dart-define` instead (see AppConfig's doc comment for why: the usual `google-services.json` approach makes the Android **build itself** fail without it, which would break `flutter build`/`flutter run` for anyone before this is set up).
3. **Service account key** (for the BACKEND to send pushes, separate from the app config above): Project Settings > Service Accounts > "Generate new private key" - downloads a JSON file. Keep this file secret (it's a real credential, same sensitivity as a database password) and never commit it.

**Where the values go:**
- Backend: `FIREBASE_CREDENTIALS_PATH` in `backend/.env` (see `.env.example`) - the absolute path to wherever you saved the downloaded service-account JSON file.
- Mobile: the four `--dart-define`s, e.g. `flutter run -d chrome --dart-define=FIREBASE_API_KEY=xxx --dart-define=FIREBASE_APP_ID=xxx --dart-define=FIREBASE_MESSAGING_SENDER_ID=xxx --dart-define=FIREBASE_PROJECT_ID=xxx` (same values, every platform - Firebase's web/Android configs for one project share the same messagingSenderId/projectId; apiKey/appId can differ per platform app if you registered more than one).

## 3. Deployment (needs a decision before code)

Progress so far: the backend is containerized (`backend/Dockerfile`, `docker-compose.yml --profile full`) and CI (`.github/workflows/ci.yml`) runs the full test suite plus a Docker build check on every push - both verified green on real GitHub Actions. What's still missing:

- **Backend hosting** — Render, Railway, Fly.io, or a plain VPS all fit a small Spring Boot + Postgres + Redis app; the existing `backend/Dockerfile` should work as-is on any of them.
- **Database/Redis hosting** — managed Postgres + Redis from the same provider, or self-hosted alongside the backend.
- **Flutter target** — ship as a web build (simplest to demo via a link), an Android APK, or both.
- **Secrets** — how `JWT_SECRET`, `DB_PASSWORD`, the Brevo API key, and (once set up) the Google/Firebase credentials above reach the hosted backend without landing in git.
- **CD** — once a host is picked, add a deploy step to `ci.yml` (or a separate workflow) that ships a green `main` build automatically, rather than deploying by hand.

Once those are picked, the concrete tasks are: wire environment variables for the chosen host, and (if shipping Flutter web) point its API base URL at the deployed backend instead of `localhost:8081`.

## Notes from the last session (2026-09-14)

- Postgres (`:5433`), Redis (`:6379`), and the backend (`:8081`, in Docker) may still be running locally - check before assuming a clean environment. `docker compose --profile full up -d` brings up the whole stack; `docker compose up -d` (no profile) brings up just Postgres+Redis for running the backend directly via `mvnw`/your IDE instead.
- A throwaway test customer account exists in the dev database: `test.search.customer@example.com`. The dev DB also has assorted manually-created test accounts (`bob_*`/`jean.uwimana@example.com`/`dave*@fasha.rw`/`admin@fasha.rw`, etc.) from earlier manual testing — unrelated to the V15 seed data, which deliberately used a `demo.admin@fasha.rw` email to avoid colliding with the existing `admin@fasha.rw`.
- If running on a physical Android device over USB, run `adb reverse tcp:8081 tcp:8081` once after connecting so the app can reach the local backend.
- Found and fixed a real leaked secret while working here: `backend/.env.example` had a genuine Brevo API key and personal email committed (in `bfcd8ec`). Removed from the file (`e1ff9c2`), but it still exists in git history - the repo is private on GitHub so exposure is limited, but the key should still be rotated in Brevo's dashboard.
