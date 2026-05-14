---
name: at-flutter-parity
description: Use when working in the Filip AT Flutter app that is being migrated from the AT NativeScript mobile app. Apply this skill for UI implementation, refactors, feature migration, API wiring, structure cleanup, theming, icon usage, typography, and screenshot matching so Flutter stays visually and structurally aligned with the NativeScript source app while maintaining strict security standards.
---

# AT Flutter Parity

Use this skill for any work inside `old/filip_at_flutter` that is based on the NativeScript AT mobile app in `old/l3-angular-sln-mobileat`.

## Core rule

The NativeScript AT app is the source of truth for:

- icon usage
- typography
- color palette
- spacing rhythm
- theme behavior
- API behavior
- feature grouping

Do not invent a new visual system when the NativeScript app already defines one.

## Working rules

1. Check the NativeScript AT app first before changing Flutter behavior, styling, naming, or API calls.
2. Prefer already imported Flutter assets, icon packs, fonts, and theme tokens over new ones.
3. Match screenshots as closely as possible. Default expectation is pixel-perfect or very near pixel-perfect.
4. Keep feature logic close to the feature. Do not scatter feature services and models into unrelated folders.
5. Favor NativeScript parity over “clean slate Flutter redesign” unless the user explicitly asks for redesign.
6. Preserve security at all times. Never trade security for speed.

## UI parity checklist

- Use the same icon family or imported icon pack already mapped from the NativeScript app.
- Use the same font family and font style already configured from the NativeScript app.
- Use the same red, gray, white, accent, shadow, and border language from the NativeScript app.
- Match layout spacing, radius, card height, icon size, line height, and alignment from screenshots or the old app.
- Match state behavior too: loading, disabled, empty, selected, active indicator, and pressed states.
- If a screen differs from the screenshot, refine spacing and sizing before adding new decorative ideas.

## Theme and design system checklist

- Reuse the current Flutter theme setup if it already mirrors the NativeScript app.
- Add new colors only when they already exist in the NativeScript app or are required by the user.
- Centralize reusable colors, type styles, spacing constants, and common surfaces.
- Do not mix unrelated visual styles across screens.
- If a screenshot and current Flutter screen disagree, trust the screenshot and old app over placeholder Flutter styling.

## Structure checklist

The Flutter app should move toward the same feature/module shape as the NativeScript app.

- Keep code by feature first, not by technical layer first.
- Put each feature under `lib/features/<feature_name>/`.
- Keep service/repository code in the same feature folder as the feature it supports.
- Keep feature models, controllers, repositories, pages, and widgets inside that feature unless they are truly shared.
- Create and maintain `lib/shared/` for app-wide reusable widgets, helpers, theme pieces, and common view parts.
- Create and maintain a package-style shared area only when reuse is broader than one feature.
- Prefer names that resemble the NativeScript module or feature name when practical.

## Suggested Flutter feature layout

```text
lib/
  features/
    auth/
      data/
      application/
      presentation/
    dashboard/
      data/
      application/
      presentation/
  shared/
    widgets/
    models/
    theme/
    utils/
```

If the NativeScript feature has a dedicated service, keep the equivalent Flutter repository/service inside that feature folder.

## API migration checklist

- Find the NativeScript service and component flow first.
- Copy the same endpoint purpose, payload shape, and response mapping before optimizing.
- Preserve the same auth assumptions, person/customer identifiers, and business rules.
- Avoid guessing field names when the old app already contains them.
- If the Flutter call differs from NativeScript, document why in code comments only when the difference is necessary.

## Security checklist

- Never hardcode secrets, passwords, tokens, client secrets, or private endpoints into UI code.
- Never leave temporary debug logs for tokens, passwords, OTP values, or raw sensitive responses in final code.
- Minimize logging of personally identifiable information.
- Store sensitive credentials only in the approved storage path already used by the app.
- Keep auth headers, token handling, and session cleanup explicit and conservative.
- Validate and sanitize data coming from network responses before assuming shape.
- Do not weaken TLS, bypass auth, disable validation, or add insecure fallbacks.
- If a quick fix introduces security risk, stop and choose the safer route.

## Screenshot matching workflow

1. Compare the Flutter screen with the screenshot and the NativeScript screen.
2. Fix structure first: height, width, padding, margins, stack order, and alignment.
3. Fix typography next: family, size, weight, italics, line height, and letter spacing.
4. Fix visual polish last: shadow, opacity, borders, and icon sizing.
5. Recheck with a fresh screenshot after major UI edits.

## Do not do these by default

- Do not introduce a new design language.
- Do not replace imported NativeScript icons with random Material icons if the mapped pack exists.
- Do not move feature services into a global folder just for convenience.
- Do not add broad debug logging in security-sensitive flows unless it is temporary and deliberate.
- Do not restructure large areas of the Flutter app away from NativeScript parity without user approval.

## Completion check before finishing a task

- Is the Flutter result visually aligned with the NativeScript app or provided screenshot?
- Did the change reuse the existing NativeScript-based icon, typography, color, and theme setup?
- Is the code placed in the correct feature folder?
- Is the service or repository kept with the feature it belongs to?
- Were security risks avoided?
- Were temporary sensitive debug logs removed if they are no longer needed?

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

# en/de.json now single source of truth.
# No mixed hardcoded-vs-JSON mismatch path.
