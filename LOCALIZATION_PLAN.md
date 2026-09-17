# Multi-Language Support Plan — English / Kinyarwanda / French

_Written 2026-09-17. This is a plan, not a build log — nothing described here has been implemented yet. Read this whenever you're ready to start, then work through the phases in order. See `PROJECT_STATUS.md`/`NEXT_SESSION.md` once work actually begins, the same way every other feature in this project is tracked._

## Why this matters (the value)

- **Reach**: Rwanda's population speaks Kinyarwanda first, and there's a real French-speaking community (older generations, francophone neighbours, NGOs/businesses) alongside English. An app that only speaks English quietly excludes a large share of the people it's meant to serve.
- **Trust and polish**: this is the single most visible "this is a serious, professional Rwandan product" signal you can ship — it's the first thing people compare against Irembo, MTN MoMo, and every other major Rwandan app, all of which are multilingual.
- **Zero ongoing cost for the biggest part of it** (see below) — this is a one-time development effort, not a recurring bill, as long as you follow the approach in this plan.
- **Low risk**: it doesn't touch any business logic (bookings, payments, chat) — it's purely about *which words* are shown, so it can be built and tested incrementally without breaking anything that already works.

## The approach, in one paragraph

There are two completely different kinds of "text" in this app, and they need two completely different solutions:

1. **Text you and I wrote** (button labels, screen titles, error messages, nav items) — translated **once, by hand, ahead of time**, into three files (one per language). Switching language just picks a different file. This is instant, free, works offline, and is exactly how Irembo's language switch works (see the earlier conversation — no live translation happening when you tap "FR"). **This plan covers this part in full (Phases 1–3).**
2. **Text a user wrote** (a provider's service description, a review) — would need a live translation API (Google Cloud Translation) to auto-translate, which costs money past a free tier and needs careful caching to stay cheap at scale. **This plan deliberately defers this part** (Phase 4, marked optional/later) — build it only once there's revenue to justify it, per the earlier cost discussion.

## Phase 1 — Framework setup (~30–45 min, do this first)

Nothing user-visible yet — this just wires up the machinery everything else plugs into.

1. Add packages to `mobile/pubspec.yaml`: `flutter_localizations` (SDK package, no version needed) and `intl` (version must match whatever `flutter_localizations` pulls in — `flutter pub get` will tell you if it's wrong).
2. Create `mobile/lib/l10n/` with three files: `app_en.arb`, `app_fr.arb`, `app_rw.arb`. Each is a JSON-ish file of `"key": "translated text"` pairs. `app_en.arb` is the "template" — every key must exist there first.
3. Add an `l10n.yaml` at the mobile project root telling Flutter's build tool where the ARB files live and what Dart class to generate (`AppLocalizations`).
4. Wire `MaterialApp` (in `app.dart` or wherever it's currently configured) with:
   - `localizationsDelegates: AppLocalizations.localizationsDelegates`
   - `supportedLocales: AppLocalizations.supportedLocales`
5. Build a small `LanguageController` (Riverpod, matching this app's existing pattern) that:
   - Holds the current `Locale`.
   - Persists the choice (`shared_preferences`, or a `flutter_secure_storage` key next to where the auth token lives — check what's already used for other simple app-level preferences before adding a new dependency).
   - Defaults to the device's system language if it's one of the three, otherwise English.
6. Add a language switcher to the Settings/Profile screen — likely 3 radio options or a dropdown ("English / Kinyarwanda / Français").

**Definition of done for Phase 1**: the app builds, a single test string (e.g. the splash screen's tagline) is pulled from `AppLocalizations` instead of hardcoded, and switching the language in Settings changes that one string live. This proves the pipeline end-to-end before touching the other ~48 screens.

## Phase 2 — Migrate every screen (the bulk of the work)

Every hardcoded `Text('...')` (and any string passed to a `SnackBar`, `AppToast`, `AlertDialog`, form validator message, etc.) needs to become a call like `AppLocalizations.of(context)!.bookNowButton` instead, with the key added to all three `.arb` files.

Current scope (counted directly from the codebase, so this is real, not a guess):

| Feature area | Files with hardcoded text | Suggested order |
|---|---|---|
| `auth` (login, register, OTP) | 5 | 1st — first thing every user sees |
| `home` | 1 | 2nd — highest-traffic screen |
| `onboarding` | 1 | 2nd |
| `bookings` | 12 | 3rd — biggest single chunk, do in its own session |
| `providers` | 7 | 4th |
| `admin` | 7 | 5th — lower priority, admins are comfortable with English already |
| `profile` | 3 | 4th |
| `services` | 3 | 4th |
| `reviews` | 3 | 5th |
| `chat` | 3 | 5th |
| `notifications` | 1 | 5th |

Work one feature folder at a time, in one sitting each, so each step is independently testable and committable (matches this project's usual file-by-file commit habit) — don't try to do all 49 files in one pass.

**Translation quality note**: English and French can be produced with high confidence in one pass. **Kinyarwanda needs a native-speaker review pass before shipping** — a first draft can be produced, but Rwandan users will notice unnatural phrasing immediately in their own language, and getting this wrong undermines the exact trust/polish goal this whole feature is for. Budget time for that review as its own step, not an afterthought.

**Things to double check while migrating (easy to miss):**
- Pluralization ("1 booking" vs "2 bookings") — ARB supports ICU plural syntax; don't just string-concatenate a count.
- Currency and dates — RWF amounts and date formats should use `intl`'s `NumberFormat`/`DateFormat` with the current locale, not hardcoded formatting, so e.g. dates naturally read differently in French vs English.
- Any text baked into an *image* (none currently known in this app, but check `assets/` before assuming).

## Phase 3 — Category names (small, do after Phase 2)

Category names (Plumbing, Electrical, etc.) are admin-created data, not developer-written code, so they don't live in `.arb` files. Two options — pick one, don't build both:

- **Option A (recommended, no API cost)**: add `name_fr`/`name_rw` columns next to the existing category name, and require the admin to fill in all three when creating/editing a category (there are only a handful of categories total, so this is a few minutes of admin work, once).
- **Option B**: auto-translate via API once, at creation time only, and cache the result forever in those same columns. Only worth it if you'd rather not ask the admin to type three languages.

Either way: **never** call a translation API live, every time a category is displayed — there's no reason to pay per-view for content this small and this static.

## Phase 4 — Dynamic content auto-translation (optional, later, costs money — do not build yet)

Deferred on purpose per the earlier cost discussion in this project's history. Revisit only once there's real usage/revenue. When you do:

- Scope: provider service descriptions, and optionally reviews.
- Mechanism: Google Cloud Translation API, called from the **backend only** (never from the Flutter app — an API key inside a mobile app can be extracted from the APK).
- Get the key: `console.cloud.google.com` → enable "Cloud Translation API" → Credentials → API key, **restricted to that one API**.
- Follow this project's existing pattern for optional integrations (see `AvatarStorageService`/`PushNotificationService`/`BrevoEmailService`): a `GOOGLE_TRANSLATE_API_KEY` env var that, when unset, just shows content in its original language untouched — nothing breaks without it.
- **Caching is mandatory, not optional**: translate a given piece of content once, the first time it's viewed in a different language, then store the translated text (e.g. `description_fr`/`description_rw` columns) so every later view is free. Translating on every single page load is the one mistake that actually gets expensive at scale — see the cost math already discussed for this project.
- Set a Google Cloud budget alert (and ideally a hard quota cap) before turning this on, so it can never produce a surprise bill regardless of traffic.

## Backend text (a gap worth knowing about, not yet scoped in detail)

The Spring Boot backend currently has zero internationalization — `GlobalExceptionHandler`, validation messages, and notification/email text are all hardcoded English (see `GlobalExceptionHandler.java`, `BookingPhotoService`, etc.). This mostly doesn't matter for Phase 1–3 above, since the *mobile app* controls almost everything the user sees. It only starts to matter if:
- A backend-generated error message is shown to the user verbatim (worth auditing during Phase 2 — some `ApiException` messages likely are).
- Push notification / OTP email text should also switch language (Spring's `MessageSource` + `.properties` files per locale is the direct equivalent of Flutter's `.arb` approach, keyed off the user's saved language preference).

Not scoped further here — flag it as a follow-up decision once Phase 2 reveals how much of it actually reaches the user directly.

## Cost summary (recap, so it's here for reference)

| Phase | Cost | Recurring? |
|---|---|---|
| 1–3 (static UI + category names, Option A) | $0 | No — one-time dev effort only |
| 3 (category names, Option B) | A few cents, one-time per category | No, if cached |
| 4 (dynamic content) | ~$20 per million characters translated, **only for new/uncached content** | Only for genuinely new content; near-$0 once caching is warm |

## Suggested overall order

1. Phase 1 (framework) — one session.
2. Phase 2, one feature folder per session, in the order listed above.
3. Kinyarwanda review pass — its own dedicated step, not squeezed into Phase 2.
4. Phase 3 (categories).
5. Phase 4 — only revisit when there's a real reason to (revenue, or enough providers that manual multi-language descriptions become impractical).

When you're ready to start, just say so and name the phase (e.g. "let's do Phase 1" or "let's do bookings from Phase 2") — each one is small enough to tackle in a single sitting.
