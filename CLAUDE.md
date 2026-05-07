# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Filip AT Flutter — a Flutter rewrite of the Filip AT customer mobile app (wealth/asset management platform by SELISE). The NativeScript app at `old/l3-angular-sln-mobileat` is the source of truth for UI, icons, typography, colors, spacing, API behavior, and feature grouping. Do not invent a new visual system when the NativeScript app already defines one.

## Commands

```bash
# Run the app (pick a flavor)
flutter run --target lib/main_dev.dart
flutter run --target lib/main_stg.dart
flutter run --target lib/main_uat.dart
flutter run --target lib/main.dart          # production

# Tests
flutter test                                # all tests
flutter test test/widget_test.dart          # single test file

# Lint
flutter analyze

# Build
flutter build apk --target lib/main.dart
flutter build ios --target lib/main.dart
```

## Architecture

### Layer layout

```
lib/
  app/          # App bootstrap, router, theme, environment config, service container
  core/         # HTTP client, secure storage, constants — no feature logic
  features/     # One folder per feature (see below)
  shared/       # App-wide widgets, theme tokens, icons, utils
```

### Feature module shape

Each feature lives under `lib/features/<feature_name>/` and follows:

```
features/<name>/
  application/   # Controllers and state (StatefulWidget or plain Dart)
  data/          # Repository, models, exceptions
  presentation/  # Pages and feature-specific widgets
```

Only `auth` and `dashboard` have all three layers today; other features are presentation-only stubs being migrated. Keep services/repositories inside the owning feature folder — do not move them to `core/` or a global services folder just for convenience.

### Key files

| File | Purpose |
|---|---|
| `app/bootstrap.dart` | Manual DI — wires SecureStorageService → ApiClient → repositories → controllers, then runs the app |
| `app/router/app_router.dart` | Named routes: `/` splash → `/onboarding` → `/login` → `/login/forgot-password` → `/dashboard` |
| `app/environment/app_environment.dart` | Per-flavor API base URLs and identity/token endpoint versions |
| `core/network/api_client.dart` | Raw `dart:io` HttpClient — no `dio`/`http` package |
| `core/storage/secure_storage_service.dart` | Encrypted credential storage (backed by `shared_preferences`) |
| `shared/icons/app_icon_packs.dart` | Icon constants for the custom `filip_at_iconpack_29022024` font and `MaterialIconsNS` |
| `shared/theme/app_colors.dart` | Full color palette — use these, do not add new colors unless they exist in the NativeScript app |

### Build flavors

| Flavor | Entry point | API base |
|---|---|---|
| dev | `main_dev.dart` | `http://msblocks.seliselocal.com/api` |
| stg | `main_stg.dart` | `https://msblocks.selisestage.com/api` |
| uat | `main_uat.dart` | `https://msblocks.seliseuat.com/api` |
| prod | `main.dart` | `https://www.filip.at/api` |

### Fonts and icons

- **Calibri** — body and UI text (regular + italic)
- **filip_at_iconpack_29022024** — primary icon font mapped from the NativeScript app; prefer this over Material icons
- **MaterialIconsNS** — secondary icon font (`assets/fonts/material-icons.ttf`), not the standard package
- **SelectNetwork** — supplemental icon/symbol font

Always use already-imported icon packs and font families. Do not substitute random Material icons if the mapped pack covers the symbol.

## NativeScript parity rules

1. Check the NativeScript AT app first before changing Flutter behavior, styling, naming, or API calls.
2. Match screenshots as closely as possible — default expectation is pixel-perfect or very near pixel-perfect.
3. Copy the same endpoint purpose, payload shape, and response mapping before optimizing. Preserve the same auth assumptions, person/customer identifiers, and business rules.
4. Favor NativeScript parity over clean-slate Flutter redesign unless the user explicitly asks for redesign.
5. If a Flutter screen and a screenshot disagree, fix structure first (height, width, padding, margins, stack order), then typography, then visual polish.
6. Do not introduce a new design language, move feature services into a global folder for convenience, or restructure large areas of the app away from NativeScript parity without user approval.

## Security rules

- Never hardcode secrets, tokens, passwords, or private endpoints in UI code.
- Remove temporary debug logs for tokens, OTP values, or sensitive responses before finishing a task.
- Store credentials only through `SecureStorageService`.
- Keep auth headers, token handling, and session cleanup explicit and conservative.
- Validate and sanitize network response data before assuming shape.
- Do not weaken TLS, bypass auth, disable validation, or add insecure fallbacks. If a quick fix introduces security risk, stop and choose the safer route.

## Completion checklist

Before marking a task done:
- Is the Flutter result visually aligned with the NativeScript app or the provided screenshot?
- Did the change reuse the existing icon pack, typography, color palette, and theme setup?
- Is the code placed in the correct `lib/features/<name>/` subfolder?
- Is the repository/service kept with the feature it belongs to?
- Were temporary sensitive debug logs removed?

# Reuse Code
Reuse similar code as much as possible, and only create new code when necessary. This includes:
- Reusing existing widgets and components from the `shared` folder.
- Reusing existing services and repositories if they fit the new feature's needs.
- Reusing existing theme tokens and styles for consistency.
- Reusing existing API call patterns and error handling approaches.

# Avoid unnecessary refactors
Do not refactor code just for the sake of refactoring. Only refactor when it is necessary to implement the new feature or to fix a bug. Unnecessary refactors can introduce new bugs and can make it harder to maintain the codebase. Focus on implementing the new feature or fixing the bug first, and then refactor if needed after the new code is working correctly.

# Always look at the AT NativeScript app for reference of API calls, UI design, and feature behavior. The NativeScript app is the source of truth for how the Flutter app should look and behave. Always check the NativeScript app before making decisions about UI implementation, API wiring, or feature logic in the Flutter app.

# Follow font family and font size and font style
alwys follow this font style from at nativescript mobile app

# Follow Icon of At Nativescript app

# Follow uilm of nativecsript app
