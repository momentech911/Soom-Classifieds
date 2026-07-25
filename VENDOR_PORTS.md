# VENDOR_PORTS — eClassify → SOOM port register

Every reuse of eClassify code or logic gets a row here. This is the audit trail for
a **licensed third-party template** in a public repository: if a piece of SOOM
traces back to the template, this file says so, and says what we changed.

**The rule:** never bulk-copy. Read the source, extract the specific logic, refactor
it into SOOM's structure and conventions, strip non-MVP scope, then log it below.
See [`vendor/README.md`](vendor/README.md) for the reference itself.

## Ports

| # | Date | Source (vendor path) | Destination (soom path) | What was reused | Changes made | Licence ref | Reviewer |
|---|------|----------------------|-------------------------|-----------------|--------------|-------------|----------|
| 1 | 2026-07-25 | `soom-api/vendor/.../app/Http/Middleware/ApiLocalizationMiddleware.php` | `lib/core/api/interceptors.dart` | The locale header name — backend reads `Content-Language`, not `Accept-Language` | Client now sends both; pinned by a test | Envato purchase code | Moe Eldawo |
| 2 | 2026-07-25 | `vendor/.../lib/utils/api.dart` | `lib/core/api/api_error_mapper.dart` | 503 = planned maintenance, not a server crash | Own `ApiErrorKind.maintenance`; gate shows a retryable maintenance screen | Envato purchase code | Moe Eldawo |
| 3 | 2026-07-25 | `vendor/.../lib/data/model/system_settings_model.dart` | `lib/app/bootstrap/system_settings.dart` | Startup settings contract: `maintenance_mode`, `force_update`, per-platform `android_version`/`ios_version`, store links | Typed model, only the six startup keys, tolerates Laravel string booleans | Envato purchase code | Moe Eldawo |
| 4 | 2026-07-25 | `soom-api/vendor/.../routes/api.php` | `soom-docs/eClassify_API_Contract.md` | The 68-endpoint inventory — the real API surface | Documented, classified MVP vs drop; no code | Envato purchase code | Moe Eldawo |

## Evaluated and deliberately not ported

Recording rejections matters as much as ports: it stops the same source being
re-evaluated every phase, and it makes "we built this ourselves" a decision
rather than an oversight.

| Source | Why not |
|---|---|
| `lib/app/routes.dart` (315 lines, 55 `case`s) | This is the global named-route switch golden rule #3 forbids. SOOM uses typed `go_router`. |
| `lib/utils/api.dart` (415 lines) | Imports six cubits into the network layer, `dynamic` error type, same 401/503 block repeated three times, bundles Google Places + Twilio. Contract taken (rows 1, 2), code not. |
| `lib/app/app_theme.dart`, `lib/ui/theme/` | Wrong brand. SOOM's palette comes from `05_Design_Tokens.md`. |
| Localization (`assets/languages/`, `fetch_language_cubit`) | Server-driven runtime JSON; SOOM requires typed compile-time keys. The vendor folder is empty anyway. |
| `lib/ui/screens/splash_screen.dart` | Maintenance-mode *behaviour* was taken (row 2); the screen itself is tied to the template's navigation and settings singletons. |

Copy this template for each new row:

```text
| 1 | 2026-07-25 | vendor/eclassify-v2.6.0/lib/data/cubits/custom_field/fetch_custom_fields_cubit.dart | lib/features/posting/data/custom_field_repository.dart | custom-field schema parsing | typed models, Dio client, dropped payment fields | Envato purchase code | Moe Eldawo |
```

## What counts as a port

Log it if template code or logic **shaped** what we wrote:

- Copied then refactored — always.
- Reimplemented from reading the template's approach (an algorithm, a schema
  format, a state machine, an API contract).
- A data model or JSON shape taken from the template's API responses.

Not a port: coincidental similarity from both using the same framework idiom
(`BlocBuilder`, a standard Dio interceptor, a Material widget layout).

If unsure, log it. An extra row costs nothing; a missing one breaks the trail.

## Per-port checklist

- [ ] Refactored into SOOM structure — not dropped in as-is
- [ ] Non-MVP scope stripped (payments, subscriptions, featured, reviews, jobs, blogs, AdMob)
- [ ] Qatar rules honoured (no country/state selector, fixed `+974`)
- [ ] AR + EN both render correctly (RTL + LTR)
- [ ] Strings localised — no hardcoded copy
- [ ] `flutter analyze` clean, smoke test added
- [ ] Row added above, with a real licence ref and reviewer
