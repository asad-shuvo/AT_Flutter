# Contracts Household Feature Reference

## Purpose

This document captures the full NativeScript behavior of the `Household` feature used under `My Contracts` so the Flutter migration can implement the same behavior intentionally.

Primary source app:

- NativeScript repo: `D:\Mobile Repo\old\l3-angular-sln-mobileat`
- Flutter repo: `D:\Mobile Repo\old\AT_Flutter`

Current Flutter status:

- The Flutter contracts page only has a visual placeholder for the household bar.
- The current Flutter implementation uses hard-coded member names and does not load backend household/business data.
- See `lib/features/contracts/presentation/contracts_page.dart`.

## High-Level Feature Summary

In NativeScript, the household feature on the contracts screen is a shared selection/filter system that:

- loads household members and business members for the logged-in customer,
- shows those members above the contracts tabs,
- lets the user filter contracts by one or more selected `PersonId` values,
- stores the selected `PersonId` set in shared state,
- triggers contract sync and reload when the selected people change,
- supports both `Household` mode and `Business` mode.

This is not just a small chip row. It is a cross-module filtering mechanism that drives which contracts are fetched from the backend.

## Main Screen Placement

On the NativeScript contracts page, the household filter sits between:

- the page header/top bar, and
- the contracts top navigation tabs.

Source:

- `src/app/app-customer-contracts/components/customer-contracts-default/customer-contracts-default.component.html`

Relevant behavior:

- `ns-household-member-filter` is always mounted on the contracts page.

## Backend and Data Sources

### Household and Business Fetch

The feature loads household and business data from:

- `SelectNetworkQuery/GetMyHouseholdAndBusiness`

Source:

- `src/app/sn-config/utils/sn-business.service.ts`

Payload:

- `CustomerId`
- `MessageCorrelationId`

Returned conceptual data:

- logged-in person metadata,
- `HouseholdMemberList`,
- `BusinessList`.

### Contract Sync Endpoints

When household selection changes, contract tabs sync using the selected `PersonIds`.

Shared contract sync:

- `ExternalDataSyncCommand/SyncCustomerKvvContract`

Investment-specific additive sync:

- `ExternalDataSyncCommand/SyncCustomerAdditiveContract`

Source:

- `src/app/sn-config/utils/sn-business.service.ts`

## Core State Model

The shared household state lives in:

- `src/app/shared/modules/household-member-filter/services/contract-household.service.ts`

Important state:

- `_selectedHouseholdData: BehaviorSubject<string[]>`
- `_businessAndMemberList`
- `_householdBusinessList`
- `_loggedInHouseholdMemberInfo`

Important contract member model:

- `IContractHouseholdMember`

Fields:

- `PersonId`
- `CustomerId`
- `DisplayName`
- `LastName`
- `ProfileImage`
- `ColorCode`
- `IsSelected`
- `ProposedUserId`
- `ManagerNr`
- `TotalContracts`

Interface source:

- `src/app/shared-data/interfaces/household-member.interface.ts`

## Shared State Outside the Feature

Some selection and mode state is also stored in `SnCommonService`.

Source:

- `src/app/sn-config/utils/sn-common.service.ts`

Used fields:

- `setHouseholdSelectedData(ids)`
- `getHouseholdSelectedData()`
- `SelectedHouseholFeature`

Meaning:

- `getHouseholdSelectedData()` stores a previously chosen person selection.
- `SelectedHouseholFeature == true` means household mode.
- `SelectedHouseholFeature == false` means business mode.

## Main Business Rules

### 1. Logged-in user is always inserted first

The logged-in user is manually added as the first household member before API household members are appended.

Behavior:

- display label becomes `me`,
- `PersonId` is set from `customerDetails.ItemId`,
- selection defaults to the logged-in user if there is no prior stored selection.

Source:

- `src/app/shared/modules/household-member-filter/components/app-contracts-household-member-filter/app-household-member-filter.component.ts`

### 2. The feature only appears when needed

The top chip bar only renders if one of these is true:

- there is more than one household member,
- there is at least one business member.

Source:

- `src/app/shared/modules/household-member-filter/components/app-contracts-household-member-filter/app-household-member-filter.component.html`

Implication:

- if the user effectively only has themself and no business members, the filter is hidden.

### 3. Household and business are two modes

The feature operates in one of two modes:

- `Household`
- `Business`

Rules:

- household mode shows household members,
- business mode shows business members,
- top chip row content changes based on the active mode,
- the bottom sheet is used to switch modes.

### 4. Contract filtering is based on selected `PersonId` values

All contracts tabs listen to the selected household state and then:

- copy the selected `PersonId` list into a local `selectedPersonIds`,
- trigger sync,
- reload the list/overview data using those `PersonIds`.

This applies to:

- insurance,
- retirement,
- loan,
- investment.

### 5. Multi-select is allowed

Household selection is multi-select.

Behavior:

- multiple household members can be selected,
- selected members are combined into the `PersonIds` payload,
- contract queries are executed for all selected people.

Important nuance:

- the top chip row allows toggling multiple selected members,
- the bottom sheet also supports multiple selection for household mode.

### 6. Last selected member cannot be deselected from the top chip row

If the user tries to deselect the only currently selected member from the top chip row:

- the deselection is blocked,
- snackbar key `CANNOT_DESELECT_ALL_MEMBER` is shown.

Source:

- `isSingleSelectedMember(...)`
- `showWarningSnackBar()`

Note:

- this guard is explicit in the top chip row flow.

### 7. Business and household selections are mutually exclusive in practice

When interacting with selection logic:

- business selection clears household selection in relevant paths,
- selecting a business member can clear household selections,
- household-focused bulk selection clears business selection.

This means the app behaves as if the user is filtering by either:

- a set of household people,
- or a set of business people,

but not both simultaneously as a normal intended contract-filtering state.

### 8. Duplicate business members are removed

Business members are filtered so the business list excludes:

- anyone already present in household members,
- the logged-in user.

Source:

- `findNonMatchingBusinessMember(...)` in `contract-household.service.ts`

Implication:

- the same person should not appear twice across household/business display in normal contracts mode.

## UI Behavior

## Top Chip Row

Source:

- `app-household-member-filter.component.html`

Behavior:

- horizontally scrollable chip list,
- each chip shows avatar plus translated uppercase last name,
- selected chip style uses red border and pink-tinted background,
- unselected chip style uses gray border and gray background,
- right side has a dropdown arrow to open the bottom sheet.

Avatar behavior:

- uses profile image when available,
- otherwise uses colored circle with initial.

Logged-in user naming:

- top row shows translated last name `tns.me` for the first manually inserted member.

## Bottom Sheet

Source:

- `household-business-bottomsheet.component.ts`
- `household-business-bottomsheet.component.html`

Behavior:

- opens from dropdown arrow,
- contains tabs for `Household` and `Business`,
- shows counts beside each tab,
- shows a member list for the active mode,
- shows a footer CTA button,
- footer button text is `Show contracts` on contracts pages.

Household-only controls:

- `Multiple selection` label,
- `Select all` checkbox/tap action.

Business-only contracts behavior:

- bottom sheet shows a business-specific message in routes where only business is relevant,
- not part of the standard contracts page behavior,
- relevant mostly to chat reuse of this shared component.

## Contract Tab Integration

Each tab subscribes to the selected household subject and uses the selected `PersonIds`.

### Insurance

Source:

- `src/app/app-customer-insure/components/customer-insure/customer-insure.component.ts`
- `src/app/app-customer-insure/services/insure-list.service.ts`

Behavior:

- listens to selected household ids,
- calls `syncContractsData`,
- loads contract overview with selected `PersonIds`,
- loads list with selected `PersonIds`.

### Retirement

Source:

- `src/app/app-customer-retirement/components/customer-retirement/customer-retirement.component.ts`
- `src/app/app-customer-retirement/services/retirement-list.service.ts`

Behavior:

- same pattern as insurance,
- uses selected `PersonIds` for overview and contract list.

### Loan

Source:

- `src/app/app-customer-loan/components/customer-loan/customer-loan.component.ts`
- `src/app/app-customer-loan/services/loan-list.service.ts`

Behavior:

- same pattern as insurance,
- uses selected `PersonIds` for overview and contract list.

### Investment

Source:

- `src/app/app-customer-investment-contracts/components/customer-investment/customer-investment.component.ts`
- `src/app/app-customer-investment-contracts/services/investment-list.service.ts`

Behavior:

- listens to selected household ids,
- forces `SelectedHouseholFeature` back to household mode if needed,
- clears stored selection in `SnCommonService` in one path,
- runs both:
- `syncContractsData`
- `syncCustomerAdditiveContract`
- loads investment overview and list using selected `PersonIds`.

Important note:

- investment has more sync complexity than the other tabs.

## Navigation-Driven Entry Cases

The app also has standalone household and business pages outside contracts.

Navigation entries are added only if household/business data exists.

Source:

- `src/root/components/root-default/root-default.component.ts`
- `src/root/navigation.ts`

Behavior:

- if backend returns household members, show `HOUSEHOLD` in navigation,
- if backend returns business members, show `BUSINESS` in navigation.

When the user taps `show contracts` from these feature pages:

- household member page sets selected ids to that exact person and sets household mode,
- business page sets selected ids to that exact person and sets business mode,
- both redirect to `/customercontracts/investment`.

Sources:

- `src/app/app-customer-household/household-member/components/household-member/household-member.component.ts`
- `src/app/app-customer-household/household-business/components/household-business/household-business.component.ts`

## Business Cases

These are the main user/business scenarios supported by the NativeScript feature.

### Case 1. Logged-in user views only their own contracts

Expected behavior:

- on first load, if no prior household selection exists, the logged-in user is selected,
- contracts load for only that `PersonId`.

### Case 2. User selects multiple household members

Expected behavior:

- several household members can be selected,
- contracts are synced and fetched for all selected `PersonIds`,
- overview totals reflect the combined selected people.

### Case 3. User switches from household mode to business mode

Expected behavior:

- business member list is shown,
- selected filtering shifts to business people,
- contract results refresh using business `PersonIds`.

### Case 4. User opens contracts from a household member page

Expected behavior:

- only that specific person is preselected,
- mode is household,
- contracts open directly to investment route first,
- selection drives downstream contract data.

### Case 5. User opens contracts from a business member page

Expected behavior:

- only that specific business person is preselected,
- mode is business,
- contracts open directly to investment route first.

### Case 6. User has no extra household members and no business members

Expected behavior:

- household filter is hidden,
- contracts page behaves without the selector UI.

### Case 7. User has business members that overlap with household members

Expected behavior:

- duplicates are removed from business list in contracts mode,
- user should not see repeated entries for the same person.

## Corner Cases and Important Nuances

### Corner Case 1. Last selected member cannot be cleared from top row

Observed behavior:

- top-row deselection of the final selected member is blocked.

Risk for Flutter:

- if Flutter allows zero selected members, contract queries may no longer match NativeScript behavior.

### Corner Case 2. Bottom sheet does not visibly enforce the same last-member guard

Observed behavior:

- bottom sheet enables confirm only when at least one member is selected,
- this protects the final submit state,
- but the explicit top-row snackbar rule is different from the bottom-sheet UX.

Migration note:

- decide whether to preserve exact UX or unify behavior deliberately.

### Corner Case 3. Business-only route behavior exists in shared component

Observed behavior:

- shared component checks route and can enter `isShowBusinessOnly` mode for chat,
- in that state the UX changes and footer text becomes `Show message`.

Migration note:

- contracts-specific Flutter implementation does not need this immediately,
- but a reusable household module should keep the route-specific capability in mind.

### Corner Case 4. Previous selection restoration affects initial load

Observed behavior:

- if `SnCommonService` already holds selected ids, those are restored,
- otherwise the logged-in user is auto-selected.

Migration note:

- this is important for deep-link or navigation-based entry into contracts.

### Corner Case 5. Mode persistence exists across navigation

Observed behavior:

- `SelectedHouseholFeature` determines whether contracts initially show household or business chips.

Migration note:

- if Flutter omits mode persistence, returning from household/business entry points will not behave the same.

### Corner Case 6. Investment flow mutates shared selection helpers differently

Observed behavior:

- investment clears `SnCommonService` stored household selection in one path,
- then forces `SelectedHouseholFeature` back to household mode.

Migration note:

- this is a behavioral difference from other contract tabs and should be verified before porting blindly.

### Corner Case 7. Bottom sheet initial mode is reset

Observed current behavior:

- on init, the bottom sheet sets `isHouseholdSelected = !isShowBusinessOnly`,
- it does not receive the previously active household/business mode from the parent.

Interpretation:

- opening the bottom sheet from contracts appears to default to household tab unless the route is business-only.

Migration note:

- this may be an intentional simplification or a NativeScript quirk.
- Flutter should decide whether to preserve this exact behavior or improve it.

### Corner Case 8. Duplicate filtering excludes logged-in user from business

Observed behavior:

- even if backend includes the logged-in user in `BusinessList`, the contracts feature filters that out.

Migration note:

- this should be preserved to avoid confusing duplicate chips.

## Current NativeScript Implementation Quirks

These should be treated carefully during migration.

### Quirk 1. The shared component is reused beyond contracts

The component is used by:

- contracts,
- document manager,
- chat.

So some logic inside the shared component is broader than contracts-only needs.

### Quirk 2. Investment route is the default contracts redirection target

Both household and business standalone pages redirect to:

- `/customercontracts/investment`

This is current app behavior, not necessarily a universal business requirement.

### Quirk 3. Some behavior is likely historical rather than ideal

Examples:

- bottom sheet not restoring current household/business tab,
- investment forcing household mode,
- separate selection persistence split between two services.

These should be verified before porting as-is.

## Migration Requirements for Flutter

To match NativeScript contracts behavior, Flutter will need:

- a repository call for `GetMyHouseholdAndBusiness`,
- a household/business member model equivalent to `IContractHouseholdMember`,
- shared state for selected `PersonId` values,
- shared state for current mode: household or business,
- top contracts household bar UI,
- bottom sheet UI for household/business switching,
- multi-select household logic,
- business member filtering to remove duplicates,
- auto-selection of logged-in user on first load,
- prevention of invalid empty-selection submission,
- tab integration so all contracts APIs use selected `PersonIds`,
- special handling for investment sync if parity is required.

## Recommended Flutter Decomposition

Suggested pieces:

- `contracts_household_repository.dart`
- `contracts_household_member.dart`
- `contracts_household_controller.dart` or equivalent state holder
- `contracts_household_bar.dart`
- `contracts_household_bottom_sheet.dart`

The contracts tabs should consume selected `PersonIds` from shared feature state instead of each tab inventing its own member logic.

## Source Reference List

Core contracts placement:

- `src/app/app-customer-contracts/components/customer-contracts-default/customer-contracts-default.component.html`

Household filter component:

- `src/app/shared/modules/household-member-filter/components/app-contracts-household-member-filter/app-household-member-filter.component.ts`
- `src/app/shared/modules/household-member-filter/components/app-contracts-household-member-filter/app-household-member-filter.component.html`

Bottom sheet:

- `src/app/shared/modules/household-member-filter/components/household-business-bottomsheet/household-business-bottomsheet.component.ts`
- `src/app/shared/modules/household-member-filter/components/household-business-bottomsheet/household-business-bottomsheet.component.html`

Shared service and model:

- `src/app/shared/modules/household-member-filter/services/contract-household.service.ts`
- `src/app/shared-data/interfaces/household-member.interface.ts`

Shared app state:

- `src/app/sn-config/utils/sn-common.service.ts`

Backend methods:

- `src/app/sn-config/utils/sn-business.service.ts`

Contracts integrations:

- `src/app/app-customer-insure/components/customer-insure/customer-insure.component.ts`
- `src/app/app-customer-retirement/components/customer-retirement/customer-retirement.component.ts`
- `src/app/app-customer-loan/components/customer-loan/customer-loan.component.ts`
- `src/app/app-customer-investment-contracts/components/customer-investment/customer-investment.component.ts`

Standalone household/business entry:

- `src/root/components/root-default/root-default.component.ts`
- `src/root/navigation.ts`
- `src/app/app-customer-household/household-member/components/household-member/household-member.component.ts`
- `src/app/app-customer-household/household-business/components/household-business/household-business.component.ts`

## Short Conclusion

For contracts, `Household` is a backend-driven people filter with state, mode switching, multi-select, sync triggers, and cross-tab contract query impact.

If Flutter only copies the current chip-row visuals, it will miss the main business behavior.
