# vendor/ — read-only eClassify reference

This folder holds the **purchased eClassify template**, used as a *reference to read
from* — never as code we ship.

**Nothing here except this README is committed.** `.gitignore` excludes `vendor/*`.
That is deliberate and must stay that way: this repository is public and the
template is licensed to us, not redistributable by us.

## What belongs here

```text
vendor/
├── README.md              ← this file (the only committed thing)
└── eclassify-v2.6.0/      ← the template, local only
```

| | |
|---|---|
| **Template** | eClassify — Flutter classifieds app |
| **Version** | `2.6.0+29` (per the template's own `pubspec.yaml`) |
| **Contents** | 305 Dart files under `lib/` — `data/{cubits,helper,model,repositories}`, `ui/screens` — plus `android/`, `ios/`, `assets/`, and desktop shells |
| **Source** | CodeCanyon / Envato purchase |
| **Licence ref** | Envato purchase code — held in `vendor/LICENSE.local.md` (gitignored) |

> The purchase code itself is **deliberately not in this file.** It is a licence
> credential tied to the owner's Envato account, and this repository is public.
> It lives in `vendor/LICENSE.local.md`, which is gitignored and never leaves the
> machine. Cite it in `VENDOR_PORTS.md` as *"Envato purchase code"* — never the value.

## Restoring it on a fresh clone

A new clone will **not** have `eclassify-v2.6.0/`. Copy it back in from the original
purchase, or from `SOOM_Project/vendor-eclassify-full/` (the complete package —
Flutter app, Laravel admin panel, Next.js web — which lives outside this repo).

Nothing in the build depends on it: the app compiles and CI passes without it. Only
the ability to read the reference is lost.

Related references elsewhere in the workspace:

- `soom-api/vendor/eclassify-v2.6.0/` — trimmed Laravel source (169 PHP files)
- `SOOM_Project/vendor-eclassify-full/` — the complete original package

## The rules

1. **Read-only.** Never edit anything under `eclassify-v2.6.0/`. Never ship it.
2. **Never bulk-copy.** To reuse something: read it, extract the specific logic,
   refactor it into SOOM's structure and conventions.
3. **Log every port** in [`../VENDOR_PORTS.md`](../VENDOR_PORTS.md) — source,
   destination, what changed, licence ref, reviewer.
4. **Strip non-MVP scope on the way in.** The template carries payments,
   subscriptions, featured ads, reviews, jobs, blogs and AdMob. None of that is in
   the SOOM MVP; it does not come across with a port.

The template is excluded from static analysis (`analysis_options.yaml` →
`exclude: vendor/**`) and sits outside `lib/`, so it is never compiled into the app.

## How to reuse it

Ask for an extract-and-refactor, not a copy. For example:

> *"Read `vendor/eclassify-v2.6.0/lib/data/cubits/custom_field/`, extract the
> custom-field schema logic, refactor it into `lib/features/posting/` following
> SOOM conventions, strip the non-MVP parts, and add a row to VENDOR_PORTS.md."*
