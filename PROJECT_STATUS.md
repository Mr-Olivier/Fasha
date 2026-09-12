# Fasha — Project Status

_Originally snapshotted 2026-09-07 by auditing the actual codebase (controllers, screens, migrations, tests) against the project's plan; updated as work lands. This file is the current source of truth for what's done and what's left — README.md describes the shipped product, not day-to-day progress._

## TL;DR

The originally planned MVP is **functionally complete and exceeded** — every planned feature works end-to-end, plus features that went beyond the original plan (chat, notifications, onboarding, Google Sign-In) got built too. What's left is **deployment**, plus one external setup step (Google Cloud OAuth credentials) before Google Sign-In actually works.

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
| Chat | per-booking message list + send (**not in original MVP scope — built anyway**) |
| User | get/update own profile, change password, upload avatar |

- 133 backend unit/service tests passing (`./mvnw test`, with Postgres running - `BackendApplicationTests.contextLoads` needs a live database, same as the app itself).
- Role-based authorization (`@PreAuthorize` + ownership checks) covers every mutating endpoint.
- Flyway owns the schema (21 migrations), `ddl-auto: validate`.

### Security hardening (2026-09-11)
- **Refresh-token rotation**: access tokens are now short-lived (15 min, was 24h - `app.jwt.expiration-ms`), paired with a long-lived (30 day) refresh token stored server-side as a SHA-256 hash (`refresh_tokens` table, `RefreshTokenService`). Each refresh is single-use and rotates to a new pair; presenting an already-used (stolen) refresh token revokes every other live session for that user (reuse detection). The Flutter app's `ApiClient` interceptor transparently refreshes on a 401 and retries the original request - no screen has to know about it.
- **Login rate-limiting / account lockout**: `LoginAttemptService` locks an email out for 15 minutes after 5 failed login attempts (in-memory; a horizontally-scaled deployment would swap this for Redis - see its doc comment).
- **Admin audit log**: `admin_audit_log` table + `AdminAuditService.record(...)`, called from every admin mutation (approve/reject, suspend/resume/delete, category create/update/delete/visibility). Viewable in the app via the Overview screen's "Activity log" tile.
- **Security response headers**: CSP (`default-src 'none'`), HSTS, `Referrer-Policy: no-referrer` added in `SecurityConfig` (X-Content-Type-Options/X-Frame-Options were already on by Spring Security's own defaults).

### Mobile (Flutter) — screens confirmed present and wired into `app_router.dart`
| Group | Screens |
|---|---|
| Auth | Splash, Onboarding (3-slide, shown once/device), Login, Register, Forgot Password, Reset Password (OTP), Verify Email — all five form screens share a common `AuthHeader` (logo + title + subtitle); Login and Register also offer "Continue with Google" |
| Customer | Home (categories grid), Provider List, Provider Detail (services + reviews inline — no separate "service detail" page, by design), Request Booking, My Bookings (card-based; booking actions/detail inline, no separate detail screen) |
| Provider | **Dedicated 4-tab bottom nav** (Jobs/Services/Reviews/Profile, see Provider Tools below). Jobs: `ProviderDashboardScreen` (stat row + inline incoming requests), Request Detail (countdown + accept/reject), Active Job (work note + photos + mark complete), "see all" Incoming Requests. Services: My Services (visibility toggle + duration), Add/Edit Service. Reviews: provider-facing reviews list. Profile: shared Profile tab, plus Business Profile (name/category/location/experience/photo) and Get Verified (KYC upload) reachable from it. Also: Completed Jobs & Earnings screen. |
| Admin | **Dedicated 5-tab bottom nav** (Overview/Providers/Customers/Categories/Profile - `AppShell` is role-aware, see below) replacing the old "everything pushed from Home" navigation. Overview: live stat row + **3 dashboard charts** (bookings trend, providers-by-category, user growth - `fl_chart`, categorical palette validated with the dataviz skill's script) + "Needs your action" pending-provider queue + Activity log link. Providers: status filter chips (All/Pending/Approved/Rejected) over every provider, each card with approve/reject (pending only) AND suspend/resume/delete for the owner account. Customers: same suspend/resume/delete account management. Categories: Add/Edit/hide-show toggle with per-category provider/booking counts. Activity log: read-only audit trail. |
| Shared | Profile (includes "Settings": appearance/theme, edit profile, change password, logout — merged, no separate Settings screen), Chat, Notifications, Write Review |

- `flutter analyze`: clean, 0 issues.
- **Role-aware bottom navigation**: `AppShell` (`core/router/app_shell.dart`) reads the logged-in user's role and shows 2 tabs (Home/Profile) for customer/provider, 5 for admin - one `StatefulShellRoute` with a fixed 5-branch set underneath either way, so switching role never means switching navigation architecture.
- Light/dark/system theming: **done** — `ThemeModeController` persists choice via SharedPreferences, toggle lives in Profile screen, both `ThemeData.light`/`.dark` fully built (Kigali Green palette, Plus Jakarta Sans). Verified live in both modes, including the new admin dashboard charts. README §15 had this unchecked — it's stale.
- Loading/error/empty states: consistently implemented via Riverpod `AsyncValue.when(...)` across every screen sampled.
- 5 Flutter test files (validators, auth form validation, provider profile validation, service form validation, a widget smoke test) - `widget_test.dart`'s smoke test has a pre-existing flaky `pumpAndSettle` timeout unrelated to this session's work (confirmed via `git stash` against a clean HEAD before starting).

- Provider search/filtering: a debounced text search box (matches business name, location, and description) plus category filter chips on `ProviderListScreen`, reachable either from a category tile on Home or a new "Search providers" bar above it. Backend combines `categoryId` and `search` with AND. Verified live against the running app and API.

### Extras beyond the original plan
- Real-time-ish chat per booking (polling-based)
- Notifications feature
- First-run onboarding carousel
- Email-based OTP verification/reset (the original plan assumed no email server at all — dev-mode token display)
- Google Sign-In (see Partially done - code complete, needs Google Cloud credentials to actually run)

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

### Seed/demo data
`V15__seed_demo_data.sql` — 7 providers (5 APPROVED across 5 categories, 1 PENDING, 1 REJECTED so the admin approval screens have real cases), 12 services, 2 customers, 1 admin (`demo.admin@fasha.rw`), and 8 bookings covering every state in the booking state machine, with 2 matching reviews. All seeded users share the password `Demo1234!` (a real BCrypt hash, not a placeholder). Verified live: login, provider search, admin pending/rejected listings, and rating aggregation all checked out against a fresh migration run plus the full backend test suite (96 tests).

---

## ⚠️ Partially done

| Item | State | Gap |
|---|---|---|
| Google Sign-In | Fully coded on both backend (`POST /api/auth/google`, `V16__add_google_auth_to_users.sql`) and mobile (`GoogleAuthService`, "Continue with Google" on Login and Register) - compiles clean, `flutter analyze` clean, all 96 backend tests pass, and the failure paths (unconfigured backend, unconfigured mobile build) were verified live to fail with a clear message instead of crashing or silently doing nothing | Needs a real Google Cloud project + OAuth Client IDs (Web + Android) created in Google Cloud Console - only you can do this (it needs your Google account). See `NEXT_SESSION.md` item 2 for the exact steps, including this machine's debug keystore SHA-1. Until then, `GOOGLE_OAUTH_CLIENT_ID` stays unset and the feature is inert everywhere but not broken. |

## ❌ Not started

| Item | Notes |
|---|---|
| Deployment | No Dockerfile for the backend, no CI/CD (`.github/` is empty), no hosting configured. `docker-compose.yml` only covers local Postgres. |
| Review reporting/moderation | The design reference's admin Overview shows a reported-review item in "Needs your action" - deliberately left out (user's own scope call, 2026-09-11): nothing in the app lets anyone report a review yet, so this needs a whole new feature (report action + DB column + admin moderation endpoint), not just an admin-screen restyle. |

---

## Decision points for what's next

1. **Deployment** — the only remaining item. Biggest unknown/time-sink (hosting choice, env config, building the Flutter app for a target platform). Worth scoping explicitly before starting — see `NEXT_SESSION.md` for the open questions.
