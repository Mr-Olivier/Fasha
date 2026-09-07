# Fasha — Project Status

_Originally snapshotted 2026-09-07 by auditing the actual codebase (controllers, screens, migrations, tests) against the project's plan; updated as work lands. This file is the current source of truth for what's done and what's left — README.md describes the shipped product, not day-to-day progress._

## TL;DR

The originally planned MVP is **functionally complete and exceeded** — every planned feature works end-to-end, plus features that went beyond the original plan (chat, notifications, onboarding) got built too. What's left is almost entirely **launch logistics**: demo seed data and deployment.

---

## ✅ Completed

### Backend (Spring Boot) — all endpoints verified present in controllers
| Feature | Endpoints |
|---|---|
| Auth | register, login, logout, forgot-password, reset-password, verify-email, resend-verification (OTP-based, emailed via Brevo) |
| Categories | public list (seeded with real categories via `V5__seed_categories.sql`) |
| Provider profiles | public browse (by category and/or free-text search across name/location/description), public detail, get/update own profile |
| Services | provider CRUD on own listings |
| Bookings | create, list, detail, accept/reject/start/complete/cancel — full state machine enforced in `BookingService` |
| Reviews | create (customer, only on completed bookings), list by provider |
| Admin | category CRUD, provider approval list + approve/reject |
| Notifications | list, unread count, mark read / mark all read |
| Chat | per-booking message list + send (**not in original MVP scope — built anyway**) |
| User | get/update own profile, change password, upload avatar |

- 95 backend unit/service tests passing (`./mvnw test`; the 1 failing test, `BackendApplicationTests.contextLoads`, only fails because Postgres isn't running locally — not a code issue).
- Role-based authorization (`@PreAuthorize` + ownership checks) covers every mutating endpoint.
- Flyway owns the schema (14 migrations), `ddl-auto: validate`.

### Mobile (Flutter) — screens confirmed present and wired into `app_router.dart`
| Group | Screens |
|---|---|
| Auth | Splash, Onboarding (3-slide, shown once/device), Login, Register, Forgot Password, Reset Password (OTP), Verify Email |
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

---

## ⚠️ Partially done

| Item | State | Gap |
|---|---|---|
| Seed/demo data | Categories are seeded (`V5__seed_categories.sql`) | No seeded providers, services, bookings, users, or reviews — a fresh DB looks sparse for a demo |

## ❌ Not started

| Item | Notes |
|---|---|
| Deployment | No Dockerfile for the backend, no CI/CD (`.github/` is empty), no hosting configured. `docker-compose.yml` only covers local Postgres. |

---

## Decision points for what's next

1. **Seed data** — highest remaining leverage for demo value. A single Flyway migration or a `CommandLineRunner` dev-profile seeder with realistic providers/services/bookings/reviews.
2. **Deployment** — biggest unknown/time-sink (hosting choice, env config, building the Flutter app for a target platform). Worth scoping explicitly before starting.

No blockers exist to doing these in any order — they're independent of each other.
