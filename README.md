# soom-mobile

SOOM — Qatar Arabic-English classifieds marketplace. Flutter (Android + iOS), the primary product.

- Architecture, rules and scope: see `CLAUDE.md` (read this first).
- Build plan and design tokens: `../soom-docs/SOOM_Build_Plan_v1/`.
- State management: flutter_bloc (Cubit default). Routing: go_router. Auth/push: Firebase.
- Backend API: `soom-api` (Laravel), base path `/api/v1`.

## Structure (task M0.1 — Flutter scaffold in place)

```
lib/
├── app/       # bootstrap, router (go_router), theme, localization, di
├── core/      # api (Dio), auth, errors, storage (Hive), analytics, widgets
└── features/  # auth, home, search, listings, posting, favorites,
               # chat, notifications, profile, settings
               #   (each: data / domain / presentation / widgets)
```

Directories are scaffolded with `.gitkeep` placeholders; they fill in as later
M0.x–M6.x tasks land. `main.dart` is still the default Flutter entry point and is
replaced by the app bootstrap in a later Phase 0 task.

Curated files kept across the scaffold: `CLAUDE.md`, `.gitignore`, `VENDOR_PORTS.md`, `vendor/`.
