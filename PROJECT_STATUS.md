# KaziLink Rwanda — Project Status

_Snapshot taken 2026-09-07 by auditing the actual codebase (controllers, screens, migrations, tests) against `README.md`'s plan. `README.md` section 15/18 checklists were stale — this file replaces them as the current source of truth. Update this file, not the README checklists, as work continues._

## TL;DR

The MVP defined in README §12 is **functionally complete and exceeded** — every planned feature works end-to-end, plus three features that were explicitly out of scope (chat, notifications, onboarding) got built anyway. What's left is almost entirely **polish and launch logistics**, not new features: search/filtering, demo seed data, and deployment.

---

## ✅ Completed

### Backend (Spring Boot) — all endpoints verified present in controllers
| Feature | Endpoints |
|---|---|
| Auth | register, login, logout, forgot-password, reset-password, verify-email, resend-verification (OTP-based, emailed via Brevo) |
| Categories | public list (seeded with real categories via `V5__seed_categories.sql`) |
| Provider profiles | public browse (by category), public detail, get/update own profile |
| Services | provider CRUD on own listings |
| Bookings | create, list, detail, accept/reject/start/complete/cancel — full state machine enforced in `BookingService` |
| Reviews | create (customer, only on completed bookings), list by provider |
| Admin | category CRUD, provider approval list + approve/reject |
| Notifications | list, unread count, mark read / mark all read |
| Chat | per-booking message list + send (**not in original MVP scope — built anyway**) |
| User | get/update own profile, change password, upload avatar |

- 90 backend unit/service tests passing (`./mvnw test`; the 1 failing test, `BackendApplicationTests.contextLoads`, only fails because Postgres isn't running locally — not a code issue).
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

### Extras beyond the original MVP scope (README §12 explicitly deferred these)
- Real-time-ish chat per booking (polling-based)
- Notifications feature
- First-run onboarding carousel
- Email-based OTP verification/reset (README's original plan assumed no email server at all — dev-mode token display)

---

## ⚠️ Partially done

| Item | State | Gap |
|---|---|---|
| Customer discovery | Category-based browse works (`GET /api/providers?categoryId=`) | No text search, no location filter, no "Search/Filters" UI — customers can only browse by tapping a category tile |
| Seed/demo data | Categories are seeded (`V5__seed_categories.sql`) | No seeded providers, services, bookings, users, or reviews — a fresh DB looks empty for a demo |

## ❌ Not started

| Item | Notes |
|---|---|
| Deployment | No Dockerfile for the backend, no CI/CD (`.github/` is empty), no hosting configured. `docker-compose.yml` only covers local Postgres. |
| README finalization | README §10/§11/§15/§18 all predate chat, notifications, onboarding, theming completion, and OTP-based auth — needs a rewrite to match reality before it's interview-ready |

---

## Decision points for what's next

1. **Search/filters** — smallest scope, closes the last real MVP gap (README §12 item 4). Backend already supports `categoryId`; would need a text/location param added to `browseProviders` plus a search bar in `ProviderListScreen`.
2. **Seed data** — highest leverage for demo/portfolio value per README §14 ("Seed data realism... hurts portfolio value if skipped"). A single Flyway migration or a `CommandLineRunner` dev-profile seeder with realistic providers/services/bookings/reviews.
3. **Deployment** — biggest unknown/time-sink (hosting choice, env config, building the Flutter app for a target platform). Worth scoping explicitly before starting.
4. **README rewrite** — no code risk, but needed eventually so the project is explainable in an interview (README §16/§18 goal). Cheapest to do last, once the above settle.

No blockers exist to doing these in any order — they're independent of each other.
