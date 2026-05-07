# Contracts Details Pages - Full Feature Reference

**Source of truth**: NativeScript AT mobile app  
**Goal**: Document the complete contracts-details behavior across all four contract detail surfaces so the Flutter app can match parity intentionally.

---

## Scope

This document covers the contracts details experience for all contract types handled in the NativeScript app:

- Insurance details
- Retirement details
- Loan details
- Investment details

In the NativeScript app, "details" is not a single static page. It includes:

- contract card-level summary details,
- per-contract action sheet behavior,
- type-specific detail/edit forms,
- validation and conditional field sections,
- delete/edit refresh behavior,
- household/business selection-driven filtering.

---

## Shared Contracts-Details Behavior

### What users can do

- View contract summary cards.
- Open a contract action menu.
- Edit allowed contracts.
- Delete allowed contracts.
- Review type-specific details.
- Refresh and re-sync after changes.
- Work within household or business filtered context.

### Shared page patterns

- The contracts page shows multiple contract tabs by type.
- Each tab is filtered by the selected `PersonId` set.
- Contract data is loaded based on selected people and current mode.
- An action sheet or more-actions menu exposes edit/delete.
- Edit opens the add/edit form in edit mode with prefilled values.
- Delete is confirmed before the backend call.
- Success updates the visible list; failure preserves existing UI state.

### Shared list-card content

Each contract card commonly shows:

- title, with mapped type fallback when missing,
- contract type subtitle,
- partner display with `-` fallback,
- relevant date or end date,
- summary amount with `-` fallback,
- more-actions entry when the user has permission.

---

## Global Business Rules

### Ownership and source rules

- Editability depends on ownership context and source restrictions.
- Delete is typically more restrictive than view access.
- Add/edit affordances can be hidden when the selected people are not the logged-in user or when multiple selection is active.
- Household and business modes are treated as separate selection contexts.

### Selection-driven behavior

- Contracts are filtered by selected `PersonId` values.
- Multiple household members can be selected.
- Business selection is handled separately from household selection.
- The contracts data refreshes when selected people change.
- The app should avoid destructive blank states while syncing.

### Data fallback rules

- Missing names, titles, dates, or amounts are rendered as `-`.
- Numeric values may arrive as string, integer, or floating point values.
- Date parsing must be null-safe.
- Enum lookups must fall back to a safe default if the API value is unknown.

---

## Shared Detail Page Actions

### Edit

- User taps `Edit Contract` from the card action menu.
- App opens the shared add/edit modal in edit mode.
- The modal is prefilled using full contract details.
- Validation runs before submission.
- Submit updates the contract through entity-specific logic.
- On success, the list and related views refresh.

### Delete

- User taps `Delete Contract` from the card action menu.
- App shows confirmation UI.
- Confirm executes the delete call using entity and item identifiers.
- On success, the contract list refreshes and a success message is shown.
- On failure, the prior state remains visible and the user sees an error.

### Notes and text fields

- Notes and long text fields use length validation.
- Typical notes range is 10 to 300 characters.
- Non-owner users can usually view notes but not edit them.

---

## Contract Type Details

### 1. Insurance Details

Insurance details focus on coverage and premium data.

Common fields:

- type,
- title,
- contract number,
- premium frequency,
- gross premium,
- partner name / partner item id,
- maturity benefits,
- start date,
- end date,
- notes.

Behavior notes:

- `GrossPremium` and `MaturityBenefits` use numeric masking and validation.
- `EndDate` can be disabled in lifetime mode.
- Source-locked or sync-locked fields may be disabled in the UI.
- Missing partner or amount values use placeholder rendering.

Key edge cases:

- lifetime policy should suppress or disable end date editing,
- invalid or empty premium values must not submit,
- title may fall back to a mapped type label.

### 2. Retirement Details

Retirement details are similar to insurance but include retirement-specific status and due-date behavior.

Common fields:

- type,
- title,
- contract number,
- premium frequency,
- gross premium,
- partner name / partner item id,
- start date,
- end date,
- due date,
- status,
- notes.

Behavior notes:

- `GrossPremium` uses masked numeric validation and minimum checks.
- `Status` is a dropdown, not free text.
- Due date and end date rules may depend on contract state.
- The retirement flow uses the same shared edit-shell behavior as insurance.

Key edge cases:

- missing due date should not break the page,
- status must map to a valid backend enum,
- text/date formatting must stay null-safe.

### 3. Loan Details

Loan details expose repayment and interest structure.

Common fields:

- type,
- title or purpose of use,
- contract number,
- partner name / partner item id,
- amount,
- start of repayment,
- type of interest,
- fixed interest rate,
- fixed interest rate duration,
- reference interest rate,
- bank surcharge,
- value of trade-in,
- remaining amount,
- date of remaining debt,
- start date,
- end date,
- notes.

Behavior notes:

- `FixedInterestRate` and `FixedInterestRateDuration` are only shown when the interest type is fixed.
- `RemainingAmount` and `DateOfReaminingDept` use dynamic validation.
- Loan uses stricter numeric limits than simpler forms.
- Labels can shift to reflect loan purpose terminology.

Key edge cases:

- fixed-interest-specific fields must hide cleanly when the interest type changes,
- remaining-debt fields must not be editable when the loan state does not support them,
- numeric and date parsing must handle inconsistent API values.

### 4. Investment Details

Investment details are the richest and most dynamic contracts-details surface.

Common fields:

- investment type,
- title,
- partner name / partner item id,
- account number,
- start date,
- end date,
- book value,
- book value date,
- current value,
- current value date,
- payment frequency,
- notes.

Type-specific optional fields:

- target sum savings plan,
- premium benefit,
- lump sum investment,
- risk,
- current share value,
- interest rate,
- coupon type,
- coupon rate,
- coupon period,
- IBAN,
- BIC,
- ISIN,
- currency,
- issuer,
- number of shares,
- bond price,
- bond price date.

Behavior notes:

- labels and visible fields change based on selected investment type,
- the edit form uses a shared investment component in NativeScript,
- field visibility is heavily conditional,
- the details screen may show over 30 rows depending on type.

Key edge cases:

- a bad enum value must not break the page,
- hidden fields must reset cleanly when the investment type changes,
- values like booleans and percentages must format consistently,
- missing partner logo should fall back to a letter badge.

---

## Field Visibility Summary

The exact field matrix differs per contract type, but the common pattern is:

- **Insurance**: premium and maturity-benefit centric.
- **Retirement**: insurance-like plus status and due date.
- **Loan**: repayment and interest centric.
- **Investment**: the most conditional and type-sensitive layout.

Across all types:

- core identifiers are always shown,
- amounts must be formatted safely,
- dates must be formatted safely,
- optional fields must collapse rather than render broken UI,
- unknown values should degrade to placeholders.

---

## Corner Cases & Failure Modes

### Missing or partial data

- Missing partner name displays as `-`.
- Missing amount displays as `-`.
- Missing title falls back to contract type label.
- Missing dates display as `-`.
- Null booleans display as `No` or `-` depending on the field.

### Permission and ownership

- Non-owner users should not see edit affordances.
- Source-restricted contracts should not be editable.
- Child-view context should stay view-only.
- Delete should remain hidden when the current context does not allow it.

### Network and sync resilience

- Load failure should not blank the whole view if data already exists.
- Edit failure should preserve the modal state and form values.
- Delete failure should preserve the current list.
- Sync failures should show error feedback without losing context.

### Validation

- Required fields must block submit.
- Numeric fields must reject invalid input.
- Date fields must reject invalid input.
- Notes must respect the character range.
- Unknown backend values should never crash the form.

---

## API Groups

The NativeScript contracts-details flow typically relies on these call groups:

- load contract list / full contract details,
- fetch partner logo or brand information,
- update contract data,
- create activity log entries,
- update notes,
- upload or remove documents,
- refresh contract data after mutation.

Implementation should preserve the same intent even if the Flutter service layer differs.

---

## Navigation Model

### Entry points

- from contracts list card,
- from notifications,
- from dashboard deep-linking,
- from related contract navigation.

### Exit points

- back button returns to the route the user came from,
- edit modal closes back to the same details page,
- delete returns to the refreshed list state,
- notes and document flows stay within the page.

---

## Flutter Implementation Guidance

- Build one shared contracts-details reference model for all types.
- Keep contract-type differences in a field config layer.
- Keep ownership and source checks centralized.
- Reuse shared formatting helpers for money, dates, booleans, and placeholders.
- Keep edit/delete flows consistent across all contract types.
- Preserve selection-driven filtering behavior from the household/business feature.

---

## Related References

- [Contracts Details Feature Reference](contracts-details-feature-reference.md)
- [Contracts Add Feature Reference](contracts-add-feature-reference.md)
- [Contracts Household Feature Reference](contracts-household-feature-reference.md)
- [Investment Contracts Details Page](investment-contracts-details-page.md)
