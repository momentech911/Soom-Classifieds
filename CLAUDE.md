# CLAUDE.md — SOOM Mobile (soom-mobile)

> Drop this file at the **root of the `soom-mobile` repo**. Claude Code reads it automatically as project memory. Keep it short and current. (Backend repo gets its own CLAUDE.md later.)

## What SOOM is

SOOM is a **Qatar-only, Arabic-English classifieds marketplace**. Mobile (Flutter) is the primary product. Guests browse without login; login is required to post, favorite, chat, report, and manage the account. SOOM does not process buyer↔seller payments in the MVP. Every new or materially edited ad is **moderated**.

## Golden rules (do not violate)

1. **Vendor is read-only.** The eClassify template lives in `vendor/eclassify-v2.6.0/` for reference only. Never edit it, never bulk-copy it into the app, never ship it. To reuse code: read it, extract the specific logic, refactor it into SOOM's structure, and log it in `VENDOR_PORTS.md`.
2. **State management = flutter_bloc.** Cubit by default; event-driven Bloc only for the posting wizard and chat. Business logic lives in repositories/services, not widgets.
3. **Routing = go_router** with typed routes + guards. **Never** reproduce eClassify's global named-route switch.
4. **AR + EN are first-class.** Every screen must render correctly in **RTL (Arabic)** and **LTR (English)**. No hardcoded strings — use typed localization keys. Test both directions.
5. **Qatar is fixed.** No country/state selector. Phone prefix is a fixed visible `+974`; user enters 8 digits only. Location model is Qatar → municipality → area (zone optional).
6. **Feature-first structure.** Code goes under `lib/features/<feature>/{data,domain,presentation,widgets}` with shared code in `lib/core` and app wiring in `lib/app`.
7. **Small increments.** Implement one plan task at a time. Leave the app compiling, analyzed, tested, and committed. Never a broken main.
8. **MVP scope discipline.** Do NOT build: payments, subscriptions, featured listings, reviews, jobs, blogs, audio/video, AdMob, doc verification. If a template module includes them, strip them.

## Architecture

```text
lib/
├── app/       # bootstrap, go_router, theme, localization, DI (register cubits)
├── core/      # api (Dio), auth, errors, storage (Hive), analytics, shared widgets
└── features/  # auth, home, search, listings, posting, favorites, chat,
               # notifications, profile, settings  (each: data/domain/presentation/widgets)
```

## App identity (do not change)

- **Android `applicationId` / iOS bundle id: `com.soom.app`** — matches the
  apps registered in Firebase project `soom-5672c`.
- Renamed from Flutter's generated `com.soom.soom_mobile` / `com.soom.soomMobile`
  on 27 July 2026, before any release. **After first store release this can
  never change**: a different id is a different app, with no upgrade path for
  existing users.
- Firebase config lives in `android/app/google-services.json` and
  `ios/Runner/GoogleService-Info.plist`. Both are **gitignored** — this repo is
  public. There is no generated `firebase_options.dart`; the native files are
  the single source, so nothing has to be kept in sync.
- The **service account key** is backend-only, at
  `soom-api/storage/app/firebase/service-account.json` (gitignored). It must
  never appear in this repo.

## Stack

Flutter (Dart 3) · flutter_bloc · Dio · Hive + secure storage · go_router · Firebase Auth (phone OTP) · FCM · S3-compatible media · backend is Laravel `/api/v1`.

## Key product rules to encode

- 19 routes only; reusable sheets/dialogs/states are **not** routes.
- Price types are category-configurable: Fixed, Negotiable, Free, Contact for price, Starting from (Monthly/Yearly reserved for Property, which is deferred).
- Media: 1–10 images, compression + metadata removal, independent per-image retry, signed upload. Images only.
- Ad durations: general 30 days, Vehicles 45, Services 60. Posting defaults: 5 active general, 3 active Services (configurable).
- Drafts: authenticated users keep ≤10 server drafts for 60 days.
- A conversation is unique to **buyer + seller + advertisement**.
- Own-ad actions are Edit / Manage / Share — never buyer-contact actions.
- Material edit creates a **pending version** while the last approved version stays live (unless safety requires suspension).
- Contact channels: in-app Chat (default on), WhatsApp + Call require seller opt-in; at least one channel required. WhatsApp opens a prefilled localized message + ad deep link.

## Definition of Done (every task)

`flutter analyze` clean · smoke test added · AR + EN verified · `VENDOR_PORTS.md` updated if template code reused · committed with clear message · CI green.

## Reference docs (in soom-docs)

PRD v1.1 · Technical Foundation v1 · Adaptation Matrix v1 · Preliminary Audit · Qatar Location Taxonomy · Qatar Legal Compliance Suite · Build Plan + Architecture Decisions (this package).
