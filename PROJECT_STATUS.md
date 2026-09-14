# Fasha — Project Status

_Originally snapshotted 2026-09-07 by auditing the actual codebase (controllers, screens, migrations, tests) against the project's plan; updated as work lands. This file is the current source of truth for what's done and what's left — README.md describes the shipped product, not day-to-day progress._

## TL;DR

The originally planned MVP is **functionally complete and exceeded** — every planned feature works end-to-end, plus features that went beyond the original plan (chat, notifications, onboarding, Google Sign-In, push notifications) got built too. What's left is **deployment**, plus two external setup steps (Google Cloud OAuth credentials, a Firebase project) before Google Sign-In and push notifications actually work.

---

## ✅ Completed

### Backend (Spring Boot) — all endpoints verified present in controllers
| Feature | Endpoints |
|---|---|
| Auth | register, login, google, refresh (rotating refresh tokens - see Security below), logout, forgot-password, reset-password, verify-email, resend-verification (OTP-based, emailed via Brevo). login/register/google/refresh now all return `phone`/`profileImageUrl` too, not just GET /api/users/me. |
| Categories | public list (only `is_active` ones), admin list includes hidden + per-category provider/booking counts, hide/show toggle |
| Provider profiles | public browse (by category and/or free-text search across name/location/description) and detail, both now excluding a provider whose owning account is SUSPENDED and any service the provider has hidden; get/update own profile (now incl. category/years of experience); own business photo upload; **KYC documents** — upload ID/trade-certificate/selfie, submit for review, owner-or-admin-only streaming download; **earnings** — completed-jobs summary + list (This month/All time) |
| Services | provider CRUD on own listings, plus duration and a visibility toggle (`PATCH .../visibility`) excluding a hidden service from customer-facing browse/search |
| Bookings | create, list, detail, accept/reject/start/complete/cancel — full state machine enforced in `BookingService`; price is snapshotted at creation so later service-price edits don't rewrite past bookings; work-note update while IN_PROGRESS; **photos** — upload/list/download per booking, viewable only by that booking's own customer or provider (no admin access) |
| Reviews | create (customer, only on completed bookings), list by provider |
| Admin | category CRUD + hide/show toggle, provider approval (approve/reject) — queue now flags whether KYC documents were submitted, **account management** (`AdminUserController`: list/suspend/resume/delete for any customer or provider account, guarded — delete refused if the account has booking history), overview stats + **dashboard charts** (bookings trend, providers-by-category, user growth), **audit log** (`AdminAuditController` - every mutating admin action recorded with who/what/when) |
| Notifications | list, unread count, mark read / mark all read |
| Chat | per-booking message list + send, delivered live to connected clients over a WebSocket (**not in original MVP scope — built anyway**) |
| User | get/update own profile, change password, upload avatar |

- 148 backend unit/service tests passing (`./mvnw test`, with Postgres AND Redis running - `BackendApplicationTests.contextLoads` needs a live database, same as the app itself).
- Role-based authorization (`@PreAuthorize` + ownership checks) covers every mutating endpoint.
- Flyway owns the schema (32 migrations), `ddl-auto: validate`.

### Security hardening (2026-09-11)
- **Refresh-token rotation**: access tokens are now short-lived (15 min, was 24h - `app.jwt.expiration-ms`), paired with a long-lived (30 day) refresh token stored server-side as a SHA-256 hash (`refresh_tokens` table, `RefreshTokenService`). Each refresh is single-use and rotates to a new pair; presenting an already-used (stolen) refresh token revokes every other live session for that user (reuse detection). The Flutter app's `ApiClient` interceptor transparently refreshes on a 401 and retries the original request - no screen has to know about it.
- **Login rate-limiting / account lockout**: `LoginAttemptService` locks an email out for 15 minutes after 5 failed login attempts. Redis-backed as of 2026-09-14 (see below) - was originally in-memory.
- **Admin audit log**: `admin_audit_log` table + `AdminAuditService.record(...)`, called from every admin mutation (approve/reject, suspend/resume/delete, category create/update/delete/visibility). Viewable in the app via the Overview screen's "Activity log" tile.
- **Security response headers**: CSP (`default-src 'none'`), HSTS, `Referrer-Policy: no-referrer` added in `SecurityConfig` (X-Content-Type-Options/X-Frame-Options were already on by Spring Security's own defaults).
- JWT is HS256, signed with a secret from `app.jwt.secret`/`JWT_SECRET` (dev-only default falls back if unset - **must** be overridden with a real random secret before any real deployment). Passwords are bcrypt-hashed (`BCryptPasswordEncoder`).

### Security hardening (2026-09-14, alongside the customer redesign below)
- **File-upload content sniffing** (`FileSignature`, `common/`): KYC documents, booking photos, and avatars previously trusted the client-supplied `Content-Type` header alone - `SecureFileStorageService`/`AvatarStorageService` now also check the file's actual leading bytes match a real JPEG/PNG/WEBP/PDF signature, closing a mislabeled-file upload bypass. Covered by `FileSignatureTest`.
- **Rate limiting beyond login** (`common/RateLimiter`): generalized from `LoginAttemptService`'s original in-memory pattern (both are now Redis-backed - see below) and applied to `POST /api/bookings` and `POST /api/bookings/{id}/reviews` - 10 per hour per customer, abuse prevention rather than a real usage ceiling.
- Review comments are now capped at 1000 characters (`CreateReviewRequest`) - previously unbounded.
- **Known web-specific trade-off**: now that the app also runs via `flutter run -d web-server`/`chrome` (verified working this session), `flutter_secure_storage`'s encrypted-storage guarantee doesn't hold on the web target - it falls back to browser storage, which is reachable by XSS. Mobile/desktop builds are unaffected. Documented in `AuthSessionStorage`'s doc comment; not something a code change fixes on its own (the real mitigation is the app's existing CSP-equivalent hygiene plus never deploying the web build to an origin that also serves untrusted content).

### Mobile (Flutter) — screens confirmed present and wired into `app_router.dart`
| Group | Screens |
|---|---|
| Auth | Splash, Onboarding (3-slide, shown once/device), Login, Register, Forgot Password, Reset Password (OTP), Verify Email — all five form screens share a common `AuthHeader` (logo + title + subtitle); Login and Register also offer "Continue with Google" |
| Customer | **Dedicated 4-tab bottom nav** (Home/Explore/Bookings/Profile, see Customer Experience Redesign below - previously shared Home/Profile with every role). Home: categories grid + active-booking banner + top-rated section. Explore: provider search/filters (Filters sheet: district/price/rating). Provider Detail: favorite heart, selectable services, reviews preview + "See all" (All Reviews screen). Request Service: address + time-window fields. Bookings: Active/Past tabs, each card opening the Booking Tracker (real per-stage timeline) instead of inline-only actions. Cancel/Leave-a-review/Review-posted are now their own confirmation screens (previously instant-cancel / toast-and-pop). |
| Provider | **Dedicated 4-tab bottom nav** (Jobs/Services/Reviews/Profile, see Provider Tools below). Jobs: `ProviderDashboardScreen` (stat row + inline incoming requests), Request Detail (countdown + accept/reject), Active Job (work note + photos + mark complete), "see all" Incoming Requests. Services: My Services (visibility toggle + duration), Add/Edit Service. Reviews: provider-facing reviews list. Profile: shared Profile tab, plus Business Profile (name/category/location/experience/photo) and Get Verified (KYC upload) reachable from it. Also: Completed Jobs & Earnings screen. |
| Admin | **Dedicated 5-tab bottom nav** (Overview/Providers/Customers/Categories/Profile - `AppShell` is role-aware, see below) replacing the old "everything pushed from Home" navigation. Overview: live stat row + **3 dashboard charts** (bookings trend, providers-by-category, user growth - `fl_chart`, categorical palette validated with the dataviz skill's script) + "Needs your action" pending-provider queue + Activity log link. Providers: status filter chips (All/Pending/Approved/Rejected) over every provider, each card with approve/reject (pending only) AND suspend/resume/delete for the owner account. Customers: same suspend/resume/delete account management. Categories: Add/Edit/hide-show toggle with per-category provider/booking counts. Activity log: read-only audit trail. |
| Shared | Profile (includes "Settings": appearance/theme, edit profile, change password, logout — merged, no separate Settings screen), Chat, Notifications, Write Review |

- `flutter analyze`: clean, 0 issues.
- **Role-aware bottom navigation**: `AppShell` (`core/router/app_shell.dart`) reads the logged-in user's role and shows 4 tabs (Home/Explore/Bookings/Profile) for customer, 4 for provider (Jobs/Services/Reviews/Profile), 5 for admin - one `StatefulShellRoute` with a fixed 9-branch set underneath either way, so switching role never means switching navigation architecture.
- Light/dark/system theming: **done** — `ThemeModeController` persists choice via SharedPreferences, toggle lives in Profile screen, both `ThemeData.light`/`.dark` fully built (Kigali Green palette, Plus Jakarta Sans). Verified live in both modes, including the new admin dashboard charts. README §15 had this unchecked — it's stale.
- Loading/error/empty states: consistently implemented via Riverpod `AsyncValue.when(...)` across every screen sampled.
- 5 Flutter test files (validators, auth form validation, provider profile validation, service form validation, a widget smoke test) - all pass, including `widget_test.dart`'s smoke test, previously mislabeled "pre-existing flaky". Root-caused and fixed 2026-09-14 (see CI section below): it wasn't flaky, it was always broken - `onboardingCompletedProvider` reads `SharedPreferences`, which never resolves in a plain widget test without `SharedPreferences.setMockInitialValues(...)`, so the router's redirect logic sat stuck thinking onboarding state was still loading forever, no matter how long the test waited on `SplashScreen`'s perpetually-animating spinner.

- Provider search/filtering: a debounced text search box (matches business name, location, and description) plus category filter chips on `ProviderListScreen`, reachable either from a category tile on Home or a new "Search providers" bar above it. Backend combines `categoryId` and `search` with AND. Verified live against the running app and API.

### Extras beyond the original plan
- Real-time chat per booking (WebSocket-delivered, see the dated section below)
- Notifications feature
- First-run onboarding carousel
- Email-based OTP verification/reset (the original plan assumed no email server at all — dev-mode token display)
- Google Sign-In (see Partially done - code complete, needs Google Cloud credentials to actually run)
- Push notifications (see Partially done - code complete, needs a Firebase project to actually run)

### Avatar-on-login fix (2026-09-11)
Previously `profileImageUrl`/`phone` were only returned by `GET /api/users/me`, so a freshly logged-in session (or a new device/platform) showed no avatar until the Profile tab was opened once. Fixed by including both fields directly in `AuthResponse` for register/login/google/refresh - `AuthUser`'s Dart model already had the (nullable) fields, so no mobile-side parsing change was needed, just the backend DTO.

### Provider Tools (2026-09-12) — built from a Claude-Design mockup (D1-D8)
A full provider-side feature set, built to match an 8-screen mockup the user shared, closing gaps a prior audit found were previously missing entirely (not just unstyled). Four security/compliance decisions were confirmed with the user before building (see git log for the exact questions/answers):

| Screen | What shipped |
|---|---|
| D1 Provider dashboard | Provider role now gets its own **4-tab bottom nav** (Jobs/Services/Reviews/Profile) instead of sharing Home/Profile with customers. "Jobs" is a real dashboard: live stat row (new requests/in-progress/rating) + the incoming-requests list inline, reusing a shared `RequestCard` widget. |
| D2 Request detail | New screen, reached by tapping a request card - a live "RESPOND WITHIN hh:mm:ss" countdown (**UI-only nudge**, confirmed with user - no backend auto-expiry), full request details, and the customer's attached photos. |
| D3 Active job | New screen for an IN_PROGRESS booking - a work note the customer sees (`PATCH /bookings/{id}/work-note`), photo uploads, then "Mark job as completed". |
| D4/D5 My services | Services now have a `duration` (1-2 hrs/half day/full day) and a provider-controlled **visibility toggle** (`PATCH .../services/{id}/visibility`) - a hidden service is excluded from customer search/detail, mirroring how hidden categories already worked. Confirmed with user: provider-only control, no admin override. |
| D6 Edit profile | Added optional `category`/`years of experience` fields, and the profile-photo camera button now actually uploads (previously silently a no-op). |
| D7 Get verified | Full KYC flow, confirmed with user - provider uploads a National ID/passport (required), optional trade certificate, and a selfie holding their ID (required), then submits for review. Files are stored **privately** (new `SecureFileStorageService`, a directory sibling to the public `uploads/`, never registered as a static resource) - viewable only by the owning provider or an admin, through an authenticated streaming endpoint. Admin's provider queue shows a "View verification documents" action once submitted. |
| D8 Completed jobs & earnings | New screen summing a provider's COMPLETED bookings (This month/All time), each with its review if the customer left one. Booking price is now **snapshotted at creation time** (`bookings.price`) rather than always looked up live, so a provider editing a service's price later can't retroactively change past earnings. |
| (new, not in the mockup) Reviews tab | A provider-facing "my reviews" screen - reuses the existing public reviews endpoint with the provider's own id. |

Booking photos (D2/D3) are stored the same privately as KYC documents, but scoped narrower per user's explicit decision: viewable only by that booking's own customer or provider - **no admin access at all**, same trust boundary as their existing per-booking chat.

### Customer Experience Redesign (2026-09-14) — built from a Claude-Design mockup (B1-B7, C1-C7)
A full customer-side rebuild, matching a 14-screen mockup ("Customer Discovery" B1-B7 + "Booking Lifecycle" C1-C7) the user shared, the same treatment Provider Tools (above) gave the provider side. User confirmed three scope decisions before building: build favorites for real (not just a UI heart), add structured review tags to the schema, and switch the customer bottom nav from 2 tabs to 4.

| Screen | What shipped |
|---|---|
| Nav | Customer bottom nav is now **Home/Explore/Bookings/Profile** (was Home/Profile) - two new `StatefulShellBranch`es (indices 7/8, same pattern the provider role's own extra branches already use) promote the existing provider-browse screen and the old pushed "My Bookings" route into tabs. |
| B1 Home | Adds an "active booking" banner (first ACCEPTED/IN_PROGRESS booking, if any) and a "Top rated near you" section - both computed from data the app already fetches, no new endpoints. |
| B2 All Categories | Unchanged this round (already reasonable) - not part of this pass. |
| B3/B4 Explore + Filters | `ProviderListScreen` rebuilt around a shared `ProviderCard` widget; new `FiltersSheet` (district chips, max-price slider, min-rating chips) wired to two new `GET /api/providers` query params (`minRating`, `maxPrice` - see backend). District has no backend field (`ProviderProfile.location` is free text) so it's matched client-side, same as typing it into search would do. |
| B5 Provider Profile | Favorite heart (real, persisted - `favorite_providers` table), stats row, services became a selectable list feeding a bottom-pinned total+"Request service" bar instead of navigating away on tap. |
| B6 All Reviews (new) | Rating-breakdown bars + Newest/Highest-rated sort, reusing the new shared `ReviewCard` (shows each review's tags). |
| B7 Request Service | Address field + time-window chips (Morning/Afternoon/Evening) added to the form, both new `bookings` columns; card layout with a char counter and bottom-pinned total+"Send request" bar. |
| C1 Request Sent (new) | Replaces the old toast+redirect after submitting a request with an actual confirmation screen. |
| C2 My Bookings | Active/Past tabs; the booking card (extracted to a shared `BookingCard` widget) now opens the new Booking Tracker instead of just showing inline actions. |
| C3 Booking Tracker (new) | A real per-stage timeline (Requested/Accepted/Started/Completed/Reviewed, each with its own timestamp) driven by a new `booking_status_history` table - `bookings.updated_at` alone can't produce this since it's overwritten on every transition. **Known limitation**: bookings that existed before this migration only have a backfilled REQUESTED entry (their earlier transitions were never recorded), so their timeline shows gaps - verified live, this is a one-time data-migration artifact, not a bug in new bookings going forward. |
| C4 Chat | Not touched this round - already close to the mockup's bubble/timestamp style per review. Read receipts (✓✓) would need a new `read` field on messages plus UI work - **explicitly deferred**, not silently dropped. |
| C5 Cancel Confirmation (new) | Replaces the previous instant, no-confirmation cancel with a real confirmation screen + optional reason (`bookings.cancellation_reason`, new column). |
| C6 Leave a Review | "What stood out?" tag chips (`review_tags` table - On time/Fair price/Clean work/Polite), alongside the existing rating+comment. |
| C7 Review Posted (new) | Replaces toast+pop after submitting a review; "Book again" goes to the provider's profile rather than trying to reconstruct a stale `ServiceListing` from the `Booking` object (which doesn't carry every field a fresh request needs, and the provider's services may have changed since). |

Also fixed while building this: `ReviewService.createReview` previously notified no one - a provider now gets a notification when a customer reviews them, matching how every other booking-lifecycle event already worked.

Verified live end-to-end via Claude-in-Chrome (Flutter web, `flutter run -d web-server`) against the running backend+Postgres, logged in as the seeded customer: favoriting a provider, filtering by rating, requesting a service with address+time-window, the resulting Booking Tracker showing the real new timestamp, My Bookings' tabs, and a tagged review all the way through to that provider's All Reviews screen. One real bug was caught this way (not by `flutter analyze`, which doesn't type-check widget layout): the theme's default `FilledButton` is full-width, which crashes as a bare (non-`Expanded`) child of a `Row` - hit in two new bottom-bars, fixed with an explicit `minimumSize`, same fix `request_card.dart`'s existing `compactButtonStyle` already documents for the identical problem.

### Seed/demo data
`V15__seed_demo_data.sql` — 7 providers (5 APPROVED across 5 categories, 1 PENDING, 1 REJECTED so the admin approval screens have real cases), 12 services, 2 customers, 1 admin (`demo.admin@fasha.rw`), and 8 bookings covering every state in the booking state machine, with 2 matching reviews. All seeded users share the password `Demo1234!` (a real BCrypt hash, not a placeholder). Verified live: login, provider search, admin pending/rejected listings, and rating aggregation all checked out against a fresh migration run plus the full backend test suite (96 tests).

---

## ⚠️ Partially done

| Item | State | Gap |
|---|---|---|
| Google Sign-In | Fully coded on both backend (`POST /api/auth/google`, `V16__add_google_auth_to_users.sql`) and mobile (`GoogleAuthService`, "Continue with Google" on Login and Register) - compiles clean, `flutter analyze` clean, all 96 backend tests pass, and the failure paths (unconfigured backend, unconfigured mobile build) were verified live to fail with a clear message instead of crashing or silently doing nothing | Needs a real Google Cloud project + OAuth Client IDs (Web + Android) created in Google Cloud Console - only you can do this (it needs your Google account). See `NEXT_SESSION.md` item 2 for the exact steps, including this machine's debug keystore SHA-1. Until then, `GOOGLE_OAUTH_CLIENT_ID` stays unset and the feature is inert everywhere but not broken. |
| Push notifications | Same shape as Google Sign-In, same day this was built (2026-09-14) - see the dated section below for what shipped. Fully coded on both backend (`V33__create_device_tokens.sql`, `POST`/`DELETE /api/device-tokens`, `PushNotificationService`) and mobile (`PushNotificationService`, wired into `AuthController`'s login/register/logout) - `flutter analyze` clean, 153 backend tests pass, verified live end-to-end (see below) that a real notification event correctly reaches a registered device token's send attempt and gracefully no-ops when Firebase isn't configured, rather than either crashing or silently doing nothing. | Needs a real Firebase project + a downloaded service-account JSON key - only you can do this (it needs your Google account). See `NEXT_SESSION.md` for the exact steps. Until then, `FIREBASE_CREDENTIALS_PATH`/`FIREBASE_API_KEY` (etc.) stay unset and the feature is inert everywhere but not broken - the in-app notification list (polling) still works exactly as before. |

### Backend containerization (2026-09-14)
`backend/Dockerfile` (multi-stage: `eclipse-temurin:21-jdk-alpine` build stage → `eclipse-temurin:21-jre-alpine` runtime, runs as a non-root user) + `backend/.dockerignore`. Root `docker-compose.yml` gained an optional `backend` service, gated behind `--profile full` so the normal day-to-day dev loop (run the backend directly via `mvnw`/IDE for hot-reload) is unaffected - `docker compose up -d` still starts only Postgres. `docker compose --profile full up -d` starts the whole stack from a clean image build.

This surfaced one real config gap: `application.yml`'s datasource URL was hardcoded to `localhost`, which only works when the backend runs on the host talking to Postgres's published port - it breaks when the backend ALSO runs in a container, since "localhost" then means the backend container itself. Added a `DB_HOST` env var (defaults to `localhost`, unchanged for existing local-dev workflow; the compose `backend` service sets it to `postgres`, resolved via Docker's internal DNS).

Verified live: built the image, brought up the full stack, confirmed the container connected to Postgres as `jdbc:postgresql://postgres:5432/kazilink`, ran all 32 Flyway migrations, and served real traffic - `GET /api/categories` and `POST /api/auth/login` (bcrypt + JWT signing) both worked correctly from outside the container, and the already-running Flutter web app worked against it with zero changes (the container is a drop-in replacement for the host-run process). All 145 backend tests still pass with the `DB_HOST` change.

Uploaded files (`uploads/`, `secure-uploads/`) are on named Docker volumes so they survive a container recreate. `JWT_SECRET`/Brevo/Google env vars are passed through from the environment (or a `.env` file next to `docker-compose.yml`) - the compose file's own default `JWT_SECRET` is dev-only and **must** be overridden for anything beyond trying the container out locally.

### Redis (2026-09-14)
`LoginAttemptService` and `RateLimiter` moved from an in-memory `ConcurrentHashMap` to Redis (`spring-boot-starter-data-redis`, `StringRedisTemplate`) - both had documented this as the known trade-off of the in-memory approach (state resets on every app restart; wouldn't work correctly across more than one backend instance behind a load balancer, since each instance would have its own independent counter). Fixed-window counters via Redis's `INCR` + an `EXPIRE` set only on the first increment - the key's own TTL *is* the window, nothing to clean up by hand. `redis` is a **default** `docker-compose.yml` service (unlike `backend`, not gated behind `--profile full`) since the backend needs it reachable whether it's running in Compose or directly on the host via `mvnw`.

One deliberate behavior refinement while migrating `LoginAttemptService`: the failed-attempt counter now expires after 15 minutes of no new failures (a rolling window), rather than persisting forever until an actual lockout or successful login like the in-memory version did - the more standard brute-force-protection shape, and it avoids Redis quietly accumulating one key per email address anyone has ever mistyped a password for.

Both classes' unit tests were rewritten against a small in-memory fake of the handful of Redis calls each makes (real behavioral coverage of the counting/lockout/TTL logic, not just "was the template called") rather than pulling in Testcontainers or an embedded-Redis library - this machine is Windows, where embedded-Redis Java libraries have a history of not reliably shipping a working `redis-server` binary.

Verified live end-to-end against the rebuilt Docker container: 5 failed logins actually locks the account (`429 Too many failed login attempts`), and - the actual point of this change - **the lockout survives a full container restart** (`docker restart kazilink-backend`), which it would NOT have with the old in-memory version. All 148 backend tests pass (145 + 3 new `RateLimiterTest` cases; `LoginAttemptServiceTest`'s existing 6 were rewritten in place, not added to).

### CI (2026-09-14)
`.github/workflows/ci.yml` - two jobs, both run on every push/PR to `main`:
- **backend**: real Postgres + Redis service containers (not mocks - matches what `./mvnw test` actually needs locally), runs the full backend test suite, then does a `docker build ./backend` (no push - no registry configured yet, see Deployment below) purely to catch a broken Dockerfile/pom.xml combination before it's a surprise at actual deploy time.
- **mobile**: `flutter analyze` + `flutter test`, Flutter pinned to 3.29.3 (matching `pubspec.yaml`'s `sdk: ^3.7.2` constraint) rather than floating on "stable", so an upstream Flutter release can't silently break CI.

Setting this up surfaced that `widget_test.dart`'s "pre-existing flaky" smoke test wasn't flaky at all - it was unconditionally broken, and would have made this CI red on literally every run. Root-caused and fixed (see Mobile section above) rather than skipped/excluded, since a CI check that's known-red gets ignored, which defeats the point of having it.

It also caught a second real bug on its very first real run: `backend/mvnw` was committed with its executable bit off (mode `100644`) - invisible on Windows (this project's dev machine, no executable-bit concept on that filesystem), but `./mvnw` fails outright with "Permission denied" on an actual Unix checkout, which is exactly what happened. Fixed with `git update-index --chmod=+x backend/mvnw` (changes the mode Git itself tracks, independent of the local filesystem). Both jobs verified fully green on real GitHub Actions after that fix - not just locally.

### Push notifications (2026-09-14)
Real FCM push notifications alongside the existing in-app notification list, same "optional third-party integration, inert until configured" pattern `BrevoEmailService`/Google Sign-In already use in this codebase - see the "Partially done" table above.

**Backend**: `V33__create_device_tokens.sql` (`device_tokens` table - `token` itself is the unique key, not `(user, token)`, so a device that gets re-registered under a different logged-in user MOVES rather than duplicates - see the migration's own comment for why). New `push` package: `DeviceTokenController`/`Service`/`Repository` (`POST`/`DELETE /api/device-tokens`), and `PushNotificationService` (Firebase Admin SDK, lazily initialized on first use so the app boots fine whether or not `FIREBASE_CREDENTIALS_PATH` is set). Wired into `NotificationService.create()` - every existing in-app notification (booking accepted, review posted, ...) now also attempts a real push, for free, with no changes needed at any of its call sites. A stale token (Firebase reports `UNREGISTERED` - app uninstalled, or replaced by a newer token) gets deleted automatically instead of retried forever.

**Mobile**: `firebase_core`/`firebase_messaging`, configured via `--dart-define` (`FIREBASE_API_KEY` etc. on `AppConfig`) rather than the usual `flutterfire configure`-generated `google-services.json`/`firebase_options.dart` - those make the Android **build itself** fail without a real Firebase project already set up, which would have broken `flutter build`/`flutter run` for anyone before push notifications are configured. Verified live: `flutter build apk --debug` succeeds with the real `firebase_messaging` package present and zero Firebase config files anywhere in the repo. New `PushNotificationService` (mobile) registers/unregisters this device's token, called directly from `AuthController`'s login/register/loginWithGoogle (register) and logout (unregister) - not via an external listener, on purpose: an earlier draft used a `ref.listen` in `main.dart` instead, which had a real ordering bug (it fired AFTER the session's auth token was already cleared from storage, so the unregister request would have gone out unauthenticated and been rejected). Matches the existing precedent of `AuthController.logout()` already calling `GoogleAuthService.signOut()` directly for the same kind of cleanup.

Verified live end-to-end against the (rebuilt) Docker container, not just unit tests: registered a real device-token row for the seeded customer via the API, had the seeded provider accept one of their bookings (a real `NotificationService.create()` call site), and confirmed in the logs - on a background thread, not blocking the request - `Firebase not configured - would have pushed to 1 device(s) for user ...: Request accepted`. Also confirmed the Android build itself isn't affected (`flutter build apk --debug`, succeeds cleanly) and pinned `ndkVersion` in `android/app/build.gradle.kts` to what `firebase_messaging` (and every other native plugin already in this project) actually declares needing, clearing a build warning that would otherwise show on every single build. 153 backend tests pass (148 + 5 new: `PushNotificationServiceTest`, `DeviceTokenServiceTest`), `flutter analyze` clean.

### Real-time chat via WebSockets (2026-09-14)
Replaced `ChatScreen`'s 4-second `Timer.periodic` poll with a real WebSocket connection, so a reply arrives on screen the instant the other party sends it.

**Backend**: new `ChatWebSocketHandler` (a raw `TextWebSocketHandler`, not Spring's STOMP broker - this app has exactly one kind of subscription, "this booking's messages", so STOMP's extra topic/broker machinery would be pure overhead here), registered at `/ws/chat` by `ChatWebSocketConfig`. Browsers can't attach custom headers to a WebSocket handshake, so the access token travels as a query parameter (`?bookingId=...&token=...`) instead of the usual `Authorization` header; the handler validates it itself on connect (reusing `JwtService`/`RevokedTokenRepository`, same as every REST request) and additionally confirms the caller is actually one of that specific booking's two parties (same "don't reveal what you can't touch" check `MessageService.findAccessibleBooking` already does for REST) before admitting the connection - `SecurityConfig` only needed `/ws/**` added to `permitAll`, since the handshake itself carries no token for the servlet filter chain to check. `MessageService.send()` calls `ChatWebSocketHandler.broadcast(bookingId, response)` right after persisting a message, delivering it to every session currently connected for that booking (a no-op, not an error, if nobody's connected - the REST list is still the source of truth on next open).

**Mobile**: new `ChatSocket` (`web_socket_channel`) opens one connection per booking when `ChatScreen` mounts, using the logged-in user's current access token. Deliberately kept simple for this app's scale: no reconnect-on-drop logic (a dropped connection just means live updates pause until the screen is reopened, same degraded behavior as the old poll on a failed request) and no separate message cache - each incoming WebSocket frame just invalidates the existing `chatMessagesProvider`, so the REST list stays the single source of truth instead of two copies that could drift.

Verified live against the rebuilt Docker container: opened the customer's chat screen for an ACCEPTED booking in a browser tab, then sent a message as the provider via a direct REST call (`curl`, separate session - Flutter web shares `flutter_secure_storage` across tabs on the same origin, so two logged-in tabs isn't possible for this app) - the message appeared in the open browser tab immediately, with no refresh and no poll. Sending from the customer's own screen back to the provider also verified working. 153 backend tests pass (`MessageServiceTest` updated for the new `ChatWebSocketHandler` dependency, no new test count - the handler's auth/broadcast logic is exercised live rather than unit-tested, matching this codebase's existing pattern for `SecureFileStorageService`'s I/O-heavy paths), `flutter analyze` clean, 24 Flutter tests pass.

## ❌ Not started

| Item | Notes |
|---|---|
| Deployment (hosting) | The backend is containerized and now has CI validating it on every push (see above) - what's still missing is actually choosing a host (Render/Railway/Fly.io/a VPS/etc.), a CD step that deploys on a green `main` build, and building/distributing the Flutter app for a target platform (web build, or app store submission for mobile). |
| Review reporting/moderation | The design reference's admin Overview shows a reported-review item in "Needs your action" - deliberately left out (user's own scope call, 2026-09-11): nothing in the app lets anyone report a review yet, so this needs a whole new feature (report action + DB column + admin moderation endpoint), not just an admin-screen restyle. |
| Chat read receipts | The Customer Experience Redesign's mockup (C4) shows ✓✓ read receipts - deliberately deferred (2026-09-14): needs a `read` field on messages plus UI, and chat itself was already close to the mockup's style without it. |

---

## Decision points for what's next

1. **Deployment** — the backend is containerized now, so the remaining decision is narrower: pick a host for that image + Postgres (Render/Railway/Fly.io/a VPS), set up CI/CD, and decide the Flutter app's distribution target (hosted web build vs. app store submission). Worth scoping explicitly before starting — see `NEXT_SESSION.md` for the open questions.
