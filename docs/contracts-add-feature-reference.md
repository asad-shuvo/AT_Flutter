# Contracts Add Feature Reference

This document captures the NativeScript behavior for the `Add contract` entry and create forms so the Flutter migration can match it intentionally and move the reusable pieces into shared code.

## Entry Rule

On NativeScript contracts pages, the add button is not always available.

- It is shown only when exactly one `PersonId` is selected.
- That selected `PersonId` must be the logged-in user.
- If multiple household members are selected, the add action is hidden.
- If a non-logged-in household member is selected, the add action is hidden.
- If business mode is selected, the add action is hidden in normal contracts behavior.

NativeScript references:

- `src/app/app-customer-investment-contracts/components/customer-investment-command/customer-investment-command.component.html`
- `src/app/app-customer-insure/components/customer-insure-command/customer-insure-command.component.html`
- `src/app/app-customer-retirement/components/customer-retirement-command/customer-retirement-command.component.html`
- `src/app/app-customer-loan/components/customer-loan-command/customer-loan-command.component.html`

## Shared Add Feature Behavior

All four contract areas follow the same broad create flow:

- Add entry is available from the tab header next to the info icon.
- Tapping add opens a modal or bottom-sheet style form.
- Create forms validate required fields before submission.
- Numeric inputs use locale-aware masking and max-value validation.
- Date inputs use date pickers with cross-field limits where relevant.
- Partner selection uses a searchable or dropdown-backed partner list.
- Submission calls `ContractsCommand/CreateNewContract`.
- On success, the tab refreshes its data and logs a FILIP activity event.
- The same create pattern exists for edit and delete in the surrounding feature, even though the field set differs per contract type.

NativeScript references:

- `src/app/sn-config/utils/contract-common.service.ts`
- `src/app/app-customer-investment-contracts/components/customer-investment/customer-investment.component.ts`
- `src/app/app-customer-insure/components/customer-insure/customer-insure.component.ts`
- `src/app/app-customer-retirement/components/customer-retirement/customer-retirement.component.ts`
- `src/app/app-customer-loan/components/customer-loan/customer-loan.component.ts`

## Common Field Patterns

These patterns repeat across the add forms and are good candidates for shared Flutter widgets:

- Header title, close action, create button, and validation footer behavior.
- Dropdown field row with label, selected value, and validation message.
- Text input row with NativeScript-style label and field chrome.
- Currency and numeric masked input.
- Date picker row.
- Partner picker.
- Notes field with `10..300` character validation.
- Disabled-field handling for synced or source-locked fields.

## Insurance Add Form

Entity behavior:

- Uses `ContractEntityName: Insure`.
- Create payload is prepared by `InsureService.prepareInsureInsertData(...)`.

Fields:

- `Type` required.
- `Title` required.
- `ContractNumber`.
- `PremiumFrequency` required.
- `GrossPremium` required.
- `PartnerName` and `PartnerItemId`.
- `MaturityBenefits` shown as insurance amount.
- `StartDate`.
- `EndDate`.
- `Notes`.

Rules and quirks:

- `GrossPremium` and `MaturityBenefits` use masked numeric validation.
- `EndDate` is disabled when the form is in lifetime mode.
- Field disabling can come from backend sync restrictions.

NativeScript references:

- `src/app/app-customer-insure/components/customer-insure/customer-insure.component.html`
- `src/app/app-customer-insure/components/customer-insure/customer-insure.component.ts`

## Retirement Add Form

Entity behavior:

- Still uses `ContractEntityName: Insure` in NativeScript for retirement contracts.
- Create payload is prepared by `RetirementService.prepareRetirementInsertData(...)`.

Fields:

- `Type` required.
- `Title` required.
- `ContractNumber`.
- `PremiumFrequency` required.
- `GrossPremium` required.
- `PartnerName` and `PartnerItemId`.
- `StartDate`.
- `EndDate`.
- `DueDate`.
- `Status`.
- `Notes`.

Rules and quirks:

- `GrossPremium` has masked numeric validation and a formatted minimum check.
- Status is a dropdown, not free text.

NativeScript references:

- `src/app/app-customer-retirement/components/customer-retirement/customer-retirement.component.html`
- `src/app/app-customer-retirement/components/customer-retirement/customer-retirement.component.ts`

## Loan Add Form

Entity behavior:

- Uses `ContractEntityName: Loan`.
- Create payload is prepared by `LoanService.prepareLoanInsertData(...)`.

Fields:

- `Type` required.
- `Title` used as purpose of use.
- `ContractNumber`.
- `PartnerName` and `PartnerItemId` used as banking institute.
- `Amount`.
- `StartOfRepayment`.
- `TypeOfInterest`.
- `FixedInterestRate`.
- `FixedInterestRateDuration`.
- `ReferenceInterestRate`.
- `BankSurcharge`.
- `ValueOfTradeIn` required.
- `RemainingAmount`.
- `DateOfReaminingDept`.
- `StartDate` shown as loan conclusion date.
- `EndDate`.
- `Notes`.

Rules and quirks:

- `FixedInterestRate` and `FixedInterestRateDuration` appear only when `TypeOfInterest == 'Fixed'`.
- `RemainingAmount` and `DateOfReaminingDept` have dynamic validation based on loan type and remaining-debt state.
- Numeric max and min limits are stricter here than the simpler insurance forms.

NativeScript references:

- `src/app/app-customer-loan/components/customer-loan/customer-loan.component.html`
- `src/app/app-customer-loan/components/customer-loan/customer-loan.component.ts`

## Investment Add Form

Entity behavior:

- Uses `ContractEntityName: Investment`.
- Create payload is submitted through the shared investment modal flow.
- NativeScript implements this as a reusable shared component already.

Shared component reference:

- `src/app/Customer-contracts-shared-folder/investment/investment-shared/componenets/investment-add-edit-moadal/investment-add-edit-moadal.component.ts`
- `src/app/Customer-contracts-shared-folder/investment/investment-shared/componenets/investment-add-edit-moadal/investment-add-edit-moadal.component.html`

Core fields:

- `InvestmentType`.
- `Title` required and shown as product description.
- `PartnerName` and `PartnerItemId`.
- `AccountNumber`.
- `InvestmentStartDate`.
- `InvestmentEndDate`.
- `InvestmentBookValue`.
- `BookValueDate`.
- `InvestmentCurrentValue`.
- `CurrentValueDate`.
- `PaymentFrequency`.
- `Notes`.

Type-specific optional groups:

- `IsTargetSumSavingsPlan`.
- `IsPremiumBenefit`.
- `LumpSumInvestment`.
- `Risk`.
- `CurrentShareValue`.
- `InterestRate`.
- `CouponType`.
- `CouponRate`.
- `CouponPeriod`.
- `IBAN`.
- `BIC`.
- `ISIN`.
- `Currency`.
- `Issuer`.
- `NumberofShares`.
- `BondPrice`.
- `BondPriceDate`.

Rules and quirks:

- Investment is the most dynamic add form by far.
- Labels change by investment type, for example book value vs investment amount, purchase date vs start date, maturity date vs end date.
- Field visibility and resets depend on the selected `InvestmentType`.
- NativeScript already keeps this form in a shared investment component instead of inside one tab page.

## Flutter Reuse Recommendation

For Flutter parity, the reusable contract add feature should eventually be split into shared parts instead of four separate page-local implementations:

- `ContractsAddAccessPolicy`: decides whether add is allowed for the current selected people.
- `ContractsAddFormSheet`: shared sheet shell with title, close, create button, and validation framing.
- `ContractsPartnerField`: shared partner selector.
- `ContractsCurrencyField` and `ContractsDateField`: shared input widgets.
- Per-entity form configs or controllers for Insurance, Retirement, Loan, and Investment.
- A dedicated shared investment form module because investment already behaves like a shared sub-feature in NativeScript.

## Current Flutter Gap

The current Flutter contracts screen already has placeholder add sheets, but they are not yet parity-complete with NativeScript.

Main gaps:

- NativeScript-style add visibility rule based on logged-in-user selection.
- Real per-entity field sets and validation.
- Real create submission to `CreateNewContract`.
- Shared reusable form modules for use beyond a single contracts page file.
