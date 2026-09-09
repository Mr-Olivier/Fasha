# Fasha — Project Status

_Originally snapshotted 2026-09-07 by auditing the actual codebase (controllers, screens, migrations, tests) against the project's plan; updated as work lands. This file is the current source of truth for what's done and what's left — README.md describes the shipped product, not day-to-day progress._

## TL;DR

The originally planned MVP is **functionally complete and exceeded** — every planned feature works end-to-end, plus features that went beyond the original plan (chat, notifications, onboarding, Google Sign-In) got built too. What's left is **deployment**, plus one external setup step (Google Cloud OAuth credentials) before Google Sign-In actually works.

---

## ✅ Completed

### Backend (Spring Boot) — all endpoints verified present in controllers
| Feature | Endpoints |
|---|---|
| Auth | register, login, google (Google Sign-In - see Partially done), logout, forgot-password, reset-password, verify-email, resend-verification (OTP-based, emailed via Brevo) |
| Categories | public list (seeded with real categories via `V5__seed_categories.sql`) |
| Provider profiles | public browse (by category and/or free-text search across name/location/description), public detail, get/update own profile |
| Services | provider CRUD on own listings |
| Bookings | create, list, detail, accept/reject/start/complete/cancel — full state machine enforced in `BookingService` |
| Reviews | create (customer, only on completed bookings), list by provider |
| Admin | category CRUD, provider approval list + approve/reject |
| Notifications | list, unread count, mark read / mark all read |
| Chat | per-booking message list + send (**not in original MVP scope — built anyway**) |
| User | get/update own profile, change password, upload avatar |

- 96 backend unit/service tests passing (`./mvnw test`, with Postgres running - `BackendApplicationTests.contextLoads` needs a live database, same as the app itself).
- Role-based authorization (`@PreAuthorize` + ownership checks) covers every mutating endpoint.
- Flyway owns the schema (16 migrations), `ddl-auto: validate`.

### Mobile (Flutter) — screens confirmed present and wired into `app_router.dart`
| Group | Screens |
|---|---|
| Auth | Splash, Onboarding (3-slide, shown once/device), Login, Register, Forgot Password, Reset Password (OTP), Verify Email — all five form screens share a common `AuthHeader` (logo + title + subtitle); Login and Register also offer "Continue with Google" |
| Customer | Home (categories grid), Provider List, Provider Detail (services + reviews inline — no separate "service detail" page, by design), Request Booking, My Bookings (card-based; booking actions/detail inline, no separate detail screen) |
| Provider | Dashboard (role-adaptive `HomeScreen`), Profile Management, My Services, Add/Edit Service, Incoming Requests |
| Admin | Dashboard (role-adaptive `HomeScreen`), Providers + Approval, Categories + Add/Edit |
| Shared | Profile (includes "Settings": appearance/theme, edit profile, change password, logout — merged, no separate Settings screen), Chat, Notifications, Write Review |

- `flutter analyze`: clean, 0 issues.
- Light/dark/system theming: **done** — `ThemeModeController` persists choice via SharedPreferences, toggle lives in Profile screen, both `ThemeData.light`/`.dark` fully built (Kigali Green palette, Plus Jakarta Sans). README §15 had this unchecked — it's stale.
- Loading/error/empty states: consistently implemented via Riverpod `AsyncValue.when(...)` across every screen sampled.
- 5 Flutter test files (validators, auth form validation, provider profile validation, service form validation, a widget smoke test).

- Provider search/filtering: a debounced text search box (matches business name, location, and description) plus category filter chips on `ProviderListScreen`, reachable either from a category tile on Home or a new "Search providers" bar above it. Backend combines `categoryId` and `search` with AND. Verified live against the running app and API.

### Extras beyond the original plan
- Real-time-ish chat per booking (polling-based)
- Notifications feature
- First-run onboarding carousel
- Email-based OTP verification/reset (the original plan assumed no email server at all — dev-mode token display)
- Google Sign-In (see Partially done - code complete, needs Google Cloud credentials to actually run)

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

---

## Decision points for what's next

1. **Deployment** — the only remaining item. Biggest unknown/time-sink (hosting choice, env config, building the Flutter app for a target platform). Worth scoping explicitly before starting — see `NEXT_SESSION.md` for the open questions.
