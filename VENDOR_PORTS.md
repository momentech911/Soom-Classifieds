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

_No ports yet — the register is empty as of 25 July 2026 (M0.2)._

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
