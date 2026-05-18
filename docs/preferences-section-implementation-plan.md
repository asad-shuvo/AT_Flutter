# Preferences Section Implementation Plan (AT NativeScript -> AT Flutter)

## Goal
Implement full NativeScript **Preferences** experience in Flutter, including:
- My Account preference section entry
- GDPR consents read/update flow
- Biometric + PIN preferences
- Account delete flow
- Error handling, loading, sync, and tests

## Current State (Flutter)
- `ProfilePage` already has Preferences section UI and opens GDPR modal.
- `ProfileRepository` already has:
  - `fetchGdprConsent()`
  - `updateGdprConsent(...)`
  - biometric/PIN APIs
  - contact update APIs
- `SettingsPage` already covers biometric/PIN controls.
- Missing parity items: stronger GDPR loading/safety UX, account delete flow, and full parity validation vs NativeScript behavior.

---

## NativeScript Reference Scope
- Main screen: `src/app/app-my-account/components/my-account/my-account.component.html/.ts`
- GDPR modal: `src/app/app-gdpr/components/sn-gdprconsent-create-update/*`

Key NativeScript behaviors to preserve:
1. Preferences header in My Account
2. Tap row -> fetch GDPR state -> open modal
3. Modal has 5 consent checkboxes (5th is household-gated)
4. Update triggers backend sync flow
5. Loading guard prevents double-open while fetching

---

## Implementation Work Breakdown

## Phase 1: GDPR Preferences Parity Hardening
- [ ] Add explicit loading/disabled state on Preferences row in Flutter profile page while GDPR data fetch is running.
- [ ] Prevent repeated taps while request in progress (NativeScript `isGDPRConsentDataLoading` parity).
- [ ] Ensure household consent visibility strictly follows household/member logic source (not hardcoded).
- [ ] Ensure consent modal update button locks during submit + sync wait.
- [ ] Add timeout and fallback UX if sync notification is not received.

**Target files**
- `lib/features/profile/presentation/profile_page.dart`
- `lib/features/profile/gdpr_consent_flow.dart`
- `lib/features/profile/gdpr_consent_bottom_sheet.dart` (if submit-lock UI is not complete yet)

---

## Phase 2: Account Delete in Preferences/My Account
- [ ] Replace placeholder delete action in `ProfilePage` with real flow.
- [ ] Add account-delete confirmation bottom sheet.
- [ ] Implement repository/API methods for:
  - delete request call (if required by backend)
  - `deleteCustomerByPnr` with challenge retry (code + correlation id) parity
- [ ] On success:
  - show success message
  - clear biometric data
  - logout user
- [ ] On failure:
  - map backend errors to translated user messages
  - keep session intact

**Target files**
- `lib/features/profile/presentation/profile_page.dart`
- `lib/features/profile/profile_repository.dart`
- `lib/features/profile/profile_models.dart` (if new payload/result models needed)
- `lib/features/auth/application/auth_session_controller.dart` (only if extra clear hooks needed)
- New UI files under `lib/features/profile/presentation/` for delete sheets/dialogs

---

## Phase 3: Preference Navigation + Ownership Consistency
- [ ] Confirm all navigation paths (drawer/dashboard/other pages) pass required dependencies:
  - `ProfileRepository`
  - `SyncNotificationService`
  - household visibility flag source
- [ ] Remove fallback states where preferences open but repository is null.
- [ ] Ensure one source of truth for who can see household consent.

**Target files (likely)**
- `lib/shared/widgets/app_side_drawer.dart`
- `lib/features/dashboard/presentation/dashboard_page.dart`
- `lib/features/*/presentation/*` where `ProfilePage` or `SettingsPage` is pushed

---

## Phase 4: UX and Copy Parity
- [ ] Validate translation keys exist for all preference states/messages:
  - consent update success/failure
  - sync waiting/failure
  - delete account success/failure
- [ ] Match icon, spacing, and card/row height with NativeScript reference.
- [ ] Verify uppercase/letter-spacing only where required by existing app design.

**Target files**
- `lib/app/localization/*` (or JSON/arb source in project)
- Profile/settings UI files

---

## Phase 5: Test Coverage
- [ ] Unit tests for `ProfileRepository`:
  - GDPR fetch parse paths
  - GDPR update success/failure
  - delete account success/challenge/failure
- [ ] Widget tests:
  - Preferences row disabled while loading
  - Modal opens with correct checkbox state
  - Household checkbox hidden/shown correctly
  - Submit lock + snackbars
- [ ] Integration smoke:
  - open profile -> open preferences -> update consent -> sync success path
  - account delete unhappy path (no logout)

**Target files**
- `test/features/profile/*`
- `test/widget_test.dart` updates if app-wide wiring changed

---

## API/Behavior Mapping Checklist
- [ ] `checkGdprExists` equivalent is robust in Flutter (`fetchGdprConsent`)
- [ ] `SyncGdprConsentStatus` payload fields parity:
  - `Pnr`, `CustomerId`,
  - `IsMarktforschung`, `IsKundenveranstaltung`, `IsPost`, `IsNewsletter`, `IsHousehold`,
  - `IsElectronicDelivery`, `LastUpdateDate`
- [ ] Notification-based confirmation behavior aligned with backend contracts
- [ ] Error mapping parity for user-facing messages

---

## Proposed Delivery Order
1. GDPR loading/submit hardening (lowest risk, high value)
2. Account delete backend + UI flow (highest impact)
3. Dependency/navigation cleanup
4. Translation/UI parity polish
5. Tests + regression pass

---

## Definition of Done
- Preferences in Flutter matches NativeScript behavior for open/update flows.
- No placeholder actions remain in My Account preference area.
- Account delete works end-to-end with challenge retry path.
- No null-dependency preference entry points.
- Tests pass for core preference scenarios.

