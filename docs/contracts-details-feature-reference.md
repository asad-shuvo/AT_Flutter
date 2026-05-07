# Contracts Details Feature Reference

## Purpose

This document lists the expected Contracts Details behavior from the AT NativeScript app, including key features, edge cases, and step-by-step user flows so the AT Flutter migration can match parity intentionally.

Primary source context:

- NativeScript app modules referenced by existing parity docs:
  - `docs/contracts-household-feature-reference.md`
  - `docs/contracts-add-feature-reference.md`
- Flutter implementation touchpoints:
  - `lib/features/contracts/presentation/contracts_page.dart`
  - `lib/features/contracts/presentation/widgets/contracts_add_contract_modal.dart`

## What "Contract Details" Includes

In NativeScript contracts UX, "details" is not just one static page. It includes:

- Contract card-level visible details (type, date/end date, partner, amount).
- Action sheet for a contract (`Edit`, `Delete` depending on source/ownership).
- Edit form prefilled from full contract details payload.
- Validation and conditional sections by contract type (Insurance, Retirement, Loan, Investment).
- Refresh/sync behavior after edit/delete.

## Core Features

## 1. Contract list cards expose quick details

Each card shows:

- Contract title (fallbacks to mapped type when missing).
- Contract type subtitle.
- Relevant date (for some tabs: end date or display date).
- Partner display (with safe fallback `-` when empty/unknown).
- Monetary summary amount (fallback `-` when unavailable).

## 2. More-actions menu per contract

From a contract card, a kebab menu opens a bottom sheet with:

- `Edit Contract` (always shown when user has ownership context).
- `Delete Contract` (shown only for deletable source contracts, typically `FILIP`).

## 3. Delete confirmation flow

Delete flow behavior:

- Open confirmation sheet/dialog.
- Confirm executes delete API by entity + contract item id.
- Success: refresh contracts and show success snackbar.
- Failure: show failure snackbar and keep existing UI state.

## 4. Edit flow uses full-details enrichment

Edit flow behavior:

- User taps `Edit Contract`.
- App opens the same add/edit modal in `isEdit = true` mode.
- App fetches full contract details via contract details API.
- Form is prefilled by merging visible-list data with full payload fields.
- Submit updates contract through entity-specific update logic.
- On success, list and overview reload.

## 5. Shared details/edit field framework

Across all entity types:

- Required field validation gates submit.
- Numeric fields use parsing and min/max constraints.
- Date pickers support nullable values and per-field rules.
- Partner/type/frequency use lookup dropdowns.
- Notes and text fields enforce length/format limits.

## 6. Investment has richest "Contract Details" section

Investment edit/details form includes a distinct `Contract Details` section and dynamic fields:

- Core values: book value, current value, dates, payment method.
- Type-conditional fields: ISIN, risk, shares, coupon fields, issuer, bond price/date, IBAN/BIC, premium-benefit flags, etc.
- Labels and visible fields can change with selected investment type.

## Key Corner Cases

## Household/member selection impact

- Contract data is filtered by selected `PersonId` list.
- Multi-select household is supported.
- Last selected member cannot be deselected from top chip row.
- Business and household selections are mutually exclusive in practice.
- Add/edit affordances can be hidden based on selection policy (not self, multi-select, business mode).

## Ownership/source restrictions

- More-actions visibility depends on whether contract belongs to currently selected person.
- Delete is restricted by source (for example only `FILIP` source deletable).

## Data quality and fallback handling

- Missing partner names display as `-`.
- Missing amounts display as `-`.
- Missing titles fallback to mapped contract type label.
- Date parsing can fail; null-safe display is required.
- Numeric parsing must handle string/int/double API variants.

## Network/sync resilience

- Sync failures should not blank existing data abruptly.
- Reload-after-delete/edit failures should preserve last known render where possible.
- User feedback should distinguish operation failure vs no-data state.

## Type-specific conditional logic

- Loan: interest-type dependent fields (fixed vs variable paths).
- Insurance/Retirement: premium + date + status/frequency rules.
- Investment: most conditional field matrix; visibility and labels must update when type changes.

## Step-by-Step User Flows

## Flow A: View details from contracts list

1. User opens `My Contracts`.
2. User optionally changes household/business selection.
3. User opens a contract tab (Insurance/Retirement/Loan/Investment).
4. App syncs/fetches contracts for selected `PersonId`s.
5. User sees card-level details (title, type, date, partner, amount).

## Flow B: Edit contract

1. User taps card more-actions.
2. User taps `Edit Contract`.
3. App opens edit modal and fetches lookup data + full contract details.
4. App pre-fills form values (including hidden fields that exist only in full payload).
5. User edits and submits.
6. App updates backend and reloads list/overview.
7. App returns updated contract state in UI.

## Flow C: Delete contract

1. User taps card more-actions.
2. User taps `Delete Contract` (if allowed).
3. User confirms delete in confirmation UI.
4. App calls delete API.
5. On success, app reloads and shows success message.
6. On failure, app shows error message and keeps prior data visible.

## Flow D: Selection-driven details context

1. User changes selected household/business members.
2. App updates selected `PersonId` state.
3. App re-syncs contracts by selected people.
4. Contract details/cards, edit visibility, and add/delete affordances update accordingly.

## Parity Checklist (NativeScript -> Flutter)

- Card details fields and fallback rendering match NativeScript behavior.
- More-actions sheet has correct action visibility rules.
- Delete confirmation and error/success handling match.
- Edit modal uses full-details enrichment before render.
- Conditional field logic per entity is implemented (especially Investment).
- Selection rules (household/business, cannot deselect all, own-selection constraints) are enforced consistently.
- Reload/sync resilience avoids destructive empty states on transient failures.
