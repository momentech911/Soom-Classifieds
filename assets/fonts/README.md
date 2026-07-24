# assets/fonts — brand font files go here

**These files are missing.** The app currently falls back to the platform font.
It renders and behaves correctly; it just isn't in the brand face yet.

Why they're missing: the vendor template's `assets/fonts/` folder was empty when
the reference was trimmed, and Cairo has to be fetched from Google Fonts. Binary
font files can't be generated — someone has to download them.

## What to add

| Family | Language | Weights | Source |
|---|---|---|---|
| **Manrope** | English (LTR) | 400, 500, 600, 700, 800 | [Google Fonts](https://fonts.google.com/specimen/Manrope) |
| **Cairo** | Arabic (RTL) | 400, 500, 600, 700 | [Google Fonts](https://fonts.google.com/specimen/Cairo) |

Expected filenames — `pubspec.yaml` refers to these exactly:

```text
assets/fonts/
├── Manrope-Regular.ttf      (400)
├── Manrope-Medium.ttf       (500)
├── Manrope-SemiBold.ttf     (600)
├── Manrope-Bold.ttf         (700)
├── Manrope-ExtraBold.ttf    (800)
├── Cairo-Regular.ttf        (400)
├── Cairo-Medium.ttf         (500)
├── Cairo-SemiBold.ttf       (600)
└── Cairo-Bold.ttf           (700)
```

## Enabling them

1. Put the `.ttf` files here with the names above.
2. Uncomment the `fonts:` block in `pubspec.yaml`.
3. `flutter pub get`.

No Dart changes. `AppFonts.familyFor(locale)` already returns `Cairo` for Arabic
and `Manrope` otherwise, and the theme applies it — the families simply start
resolving once registered.

Both are licensed under the SIL Open Font License, so they can ship with the app.
Keep the licence files alongside them if you vendor them in.
