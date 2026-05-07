# Investment Contracts Details Page - Complete Feature & Business Logic Reference

**Source**: NativeScript AT Mobile App  
**For**: Flutter AT Mobile App Implementation  
**Page**: Investment Contract Details View (detailed page after tapping a contract)

---

## Table of Contents

1. [Overview](#overview)
2. [Business Logic](#business-logic)
3. [Features & User Capabilities](#features--user-capabilities)
4. [Corner Cases & Edge Cases](#corner-cases--edge-cases)
5. [API Calls](#api-calls)
6. [UI Structure](#ui-structure)
7. [Navigation](#navigation)
8. [Data Structure](#data-structure)
9. [Investment Type Field Visibility Matrix](#investment-type-field-visibility-matrix)
10. [Special Behaviors & Interactions](#special-behaviors--interactions)
11. [Error Messages & Feedback](#error-messages--feedback)
12. [Loading States](#loading-states)

---

## Overview

The **Investment Contracts Details Page** is the full detail view shown when a user taps on an investment contract from the contracts list. This is a **read-focused page with limited edit capability**.

**Key Characteristics**:
- Displays all relevant investment contract data
- Shows dynamic fields based on the specific investment type (6 types)
- Supports notes management (add/edit for owner, read-only for others)
- Allows document uploads and viewing
- Provides edit capability (modal-based, for owner + FILIP/KVV source only)
- Smart back navigation based on entry route
- Shows activity/update history

**Not on this page**:
- Deleting contracts (available from list's more-actions menu)
- Creating new contracts (separate add flow)
- Bulk operations (handled at list level)

---

## Business Logic

### 1.1 Load & Display Contract Details

**When page opens**:
1. Extract contract ID from route parameter
2. Extract logged-in user's PersonId
3. Call API to fetch full contract details
4. Fetch partner logo/branding in parallel
5. Populate all fields based on investment type visibility rules
6. Display last update timestamp

**Data enrichment**:
- If partner logo fails to load, show letter badge with first letter of partner name
- If amounts are missing, display "-" placeholder
- If contract title is empty, use mapped investment type label (e.g., "Fixed Deposit")

### 1.2 Determine Editability

**Editability rules**:
```
User can edit IF:
  - User is contract owner (PersonId matches logged-in user) AND
  - Contract source is "FILIP" or "KVV" (system-managed, not external)

Otherwise:
  - Hide edit button
  - Show notes as read-only (if any)
  - Disable all form inputs
```

**Child data flag**:
- Set `isChildData = true` if viewing parent's contract (PersonId ≠ logged-in user)
- When `isChildData = true`, everything is view-only

### 1.3 Edit Contract (Modal Flow)

**When edit button is clicked**:
1. Open edit modal with form
2. Pre-fill all fields with current contract values
3. Show form validation errors in real-time
4. On submit:
   - Validate all required fields
   - Compare new values with old values
   - Only create activity log if data actually changed
   - Show success/error toast
   - Refresh display on success

**Change tracking**:
- Build a changeLogs array with only fields that changed
- If changeLogs is empty (no actual changes), show "No changes made" toast and close modal
- Only call createFilipUpdateLog if changeLogs.length > 0

### 1.4 Notes Management

**View notes**:
- Display existing notes in read-only accordion section
- Show last edit timestamp
- Show character count (e.g., "245/300")

**Edit notes** (owner only):
- Click pencil icon to enter edit mode
- TextArea becomes editable inline
- Show character counter
- Validate:
  - Min: 10 characters
  - Max: 300 characters
- Save → Submit API, refresh display
- Cancel → Discard changes

**Non-owner viewing**:
- Can see notes if they exist
- Cannot edit or add notes
- Notes section shows as read-only

### 1.5 Document Management

**Upload documents**:
- Click "Upload Document" or upload button
- Select file from device
- Show upload progress
- On success, list new document in documents section
- On failure, show error message

**View documents**:
- Display list of attached documents with file names
- Tap to download/open
- Delete button available for owner only

### 1.6 Smart Back Navigation

**Before opening details page**:
- App stores the previous route (where user came from)
- Options: `/notification`, `/customer-dashboard`, `/customercontracts/investment`, or other

**When user taps back button**:
- Navigate to stored previous route
- If no previous route stored, default to `/customercontracts/investment`

---

## Features & User Capabilities

| Feature | Available To | Description |
|---------|--------------|-------------|
| **View contract overview** | All users | Accordion with partner logo, title, last update timestamp |
| **Expand/collapse overview** | All users | Toggle to show/hide contract details grid |
| **View 30+ contract fields** | All users | Dynamic grid with fields based on investment type |
| **Edit contract** | Owner + FILIP/KVV source | Pencil icon → Modal with prefilled form |
| **Add/edit notes** | Owner only | Inline edit in notes section, 10-300 char limit |
| **View notes** | All users | Read notes if they exist |
| **Upload documents** | All users | Attach files to contract |
| **View documents** | All users | See list of attached files, download/open them |
| **Delete documents** | Owner only | Remove documents from contract |
| **View activity history** | All users | See last update timestamp and who made it |
| **Smart back navigation** | All users | Intelligent routing to previous page |
| **Copy to clipboard** | All users (potential) | Copy IBAN, BIC, ISIN, account numbers (UX detail) |

---

## Corner Cases & Edge Cases

### 4.1 Data Handling

| Edge Case | Behavior | Recovery |
|-----------|----------|----------|
| Missing partner name | Display "-" | UI stays stable |
| Missing amounts (CurrentValue, BookValue) | Display "-" | UI stays stable |
| Missing contract title | Use mapped investment type (e.g., "Fixed Deposit") | Use enum mapping table |
| Empty notes | Show "No notes" placeholder + "Add note" button | User can add notes |
| Empty documents | Show "No documents" message + upload button | User can upload |
| Invalid enum value (e.g., unknown coupon type) | Default to "OTHER" or skip display | Safe fallback |
| Null/undefined boolean fields | Treat as false, display "No" | Default to "No" |
| Missing dates | Display as "-" | Show placeholder |
| Partial/slow API response | Show loading spinner for section | Retry button available |
| Network timeout on load | Show error + "Retry" button | User can retry |

### 4.2 Permission & Ownership

| Case | Behavior | UI Consequence |
|------|----------|---|
| User is not contract owner | Cannot edit | Edit button hidden |
| Contract source is external (not FILIP/KVV) | Cannot edit | Edit button hidden |
| Child viewing parent's contract (isChildData = true) | View-only mode | All editing disabled, notes read-only |
| Non-owner viewing notes | Can see if they exist | Notes section marked read-only |
| Non-owner trying to upload docs | May be allowed or blocked (clarify with team) | Button enabled/disabled accordingly |

### 4.3 Network & Loading States

| State | UI Behavior | User Action |
|-------|------------|-------------|
| Initial page load | Show loading skeleton for details section | Wait or go back |
| Fetching partner logo | Show generic badge `[I]` initially | Logo loads when ready |
| Edit form loading | Submit button disabled, show spinner | Wait for validation |
| API failure on load | Show error message + "Retry" button | Click retry to fetch again |
| Edit submission failure | Keep modal open, show error toast, preserve form | Fix and resubmit or cancel |
| Network timeout on edit | Show timeout error in modal | Retry or discard |
| Partial data load | Display available fields, skip hidden ones | Continue with available data |
| Edit succeeds but refresh fails | Show success toast, allow dismiss | Data is saved, UI may not update |

### 4.4 Form Validation (Edit Modal)

| Validation | Rules | Error Handling |
|-----------|-------|----------------|
| Required fields | Cannot be empty on submit | Show field-level "Required" error |
| Numeric fields | Must parse as valid number | Reject non-numeric input |
| Date fields | Must be valid date format | Show date picker, validate format |
| IBAN/BIC | Must match banking format (if validated) | Show specific format error |
| Notes length | 10-300 characters | Show character counter, block submit if invalid |
| Currency format | Must be valid ISO code | Validate against known currencies |
| Percentage fields (risk, rates) | 0-100% range | Validate numeric range |

### 4.5 Special Edit Cases

| Case | Handling |
|------|----------|
| Editing unchanged data | Don't create activity log; show "No changes" message |
| Only one field changed | Create activity log with single entry |
| Multiple fields changed | Create activity log with all changed fields |
| Edit modal closed by back button | Discard changes without warning (or ask for confirmation) |
| Simultaneous edit attempts | Lock UI, prevent double submission |
| Edit while offline | Show error, suggest retry when online |
| Rapid submit clicks | Disable submit button after first click until response |

### 4.6 Investment Type-Specific Cases

| Investment Type | Special Cases |
|---|---|
| **Stocks** | May have risk %, shares, current share value. Missing IBAN/BIC normal. |
| **Bonds** | Must have coupon fields. Bond price is important. No IBAN/BIC. |
| **Fixed Deposit** | No BookValue. Interest rate required. Payment frequency may apply. |
| **Savings Book** | BookValue shown. Interest rate shown. Payment frequency shown. |
| **Savings Account/Cash** | IBAN/BIC required. Interest rate shown. Payment frequency shown. |
| **Building Savings** | Payment frequency shown. Risk typically not shown. |

---

## API Calls

### 5.1 Load Contract Details

**Function**: `getData()` or similar

**Service**: `snBusinessService`

**Endpoint**: `snBusinessService.getContractList()`

**Request Payload**:
```json
{
  "PersonIds": ["logged-in-person-id"],
  "ContractEntityName": "Investment",
  "ItemIds": ["contract-id-to-view"]
}
```

**Response**: 
```json
{
  "result": [
    {
      "id": "INV-123",
      "contractNumber": "C-123456",
      "investmentType": "stocks",
      "title": "Apple Inc. Stocks",
      "personId": "user-123",
      "source": "FILIP",
      "currentValue": 50000.00,
      "bookValue": 45000.00,
      "currentValueDate": "2024-03-15T00:00:00Z",
      "investmentStartDate": "2020-01-01T00:00:00Z",
      "investmentEndDate": null,
      "bookValueDate": "2024-03-15T00:00:00Z",
      "paymentFrequency": null,
      "targetSumSavingsPlan": false,
      "premiumBenefit": true,
      "riskPercentage": 25,
      "numberOfShares": 100,
      "interestRate": null,
      "couponType": null,
      "couponRate": null,
      "couponPeriod": null,
      "bondPrice": null,
      "bondPriceDate": null,
      "iban": null,
      "bic": null,
      "isin": "US0378331005",
      "currency": "EUR",
      "issuer": "Apple Inc.",
      "productPartner": "Deutsche Börse",
      "currentShareValue": 450.00,
      "partnerId": "partner-123",
      "lastModifiedDate": "2024-03-15T14:30:00Z",
      "lastModifiedBy": "System",
      "notes": "This is a long-term investment...",
      "documents": [
        { "id": "doc-1", "name": "Annual Report 2024.pdf", "url": "..." },
        { "id": "doc-2", "name": "Quarterly Statement Q1.pdf", "url": "..." }
      ]
    }
  ]
}
```

**Called**: On page mount

**Error handling**: Show error message + "Retry" button

---

### 5.2 Fetch Partner Logo/Branding

**Function**: `getPartnerLogo(partnerIds)` or similar

**Endpoint**: Partner branding service

**Request**: Array of partner IDs
```json
["partner-123"]
```

**Response**:
```json
{
  "result": [
    {
      "partnerId": "partner-123",
      "logoUrl": "https://example.com/logo.png",
      "displayName": "Deutsche Börse"
    }
  ]
}
```

**Fallback**: If logoUrl is null/missing, show letter badge with first letter of partner name

**Called**: In parallel with contract details load

---

### 5.3 Update Contract Data (Edit Submit)

**Function**: `editCustomerContractsData()` or similar

**Service**: `ContractCommonService`

**Endpoint**: Contract update endpoint

**Request Payload** (complete investment object with modifications):
```json
{
  "id": "INV-123",
  "contractNumber": "C-123456",
  "investmentType": "stocks",
  "title": "Apple Inc. Stocks (Modified)",
  "currentValue": 52000.00,
  "bookValue": 45000.00,
  // ... all other fields ...
}
```

**Response**:
```json
{
  "success": true,
  "message": "Contract updated successfully",
  "updatedContract": {
    // Full contract object with updated values
  }
}
```

**Called**: When user submits edit form

**Error handling**: Show error toast, keep modal open, preserve form data

---

### 5.4 Create Activity Log Entry (Change Tracking)

**Function**: `createFilipUpdateLog()`

**Service**: Internal logging service

**Endpoint**: Activity log creation

**Request Payload**:
```json
{
  "data": { /* full contract object */ },
  "entityType": "Investment",
  "action": "Update",
  "personId": "logged-in-user-id",
  "changeLogs": [
    {
      "fieldName": "CurrentValue",
      "oldValue": "50000.00",
      "newValue": "52000.00"
    },
    {
      "fieldName": "Title",
      "oldValue": "Apple Inc. Stocks",
      "newValue": "Apple Inc. Stocks (Modified)"
    }
  ]
}
```

**Response**: Success/error

**Called**: After successful contract update, but **ONLY if changeLogs is not empty**

**Important**: Do not create activity log if no fields changed (oldValue === newValue for all fields)

---

### 5.5 Add/Update Notes

**Function**: `updateContractNotes()` or similar

**Endpoint**: Notes update endpoint

**Request Payload**:
```json
{
  "contractId": "INV-123",
  "notes": "Updated note content here..."
}
```

**Response**:
```json
{
  "success": true,
  "notes": "Updated note content here...",
  "lastModified": "2024-03-15T15:30:00Z"
}
```

**Called**: When user saves notes (after validation)

**Validation**: 10-300 characters

---

### 5.6 Upload Document

**Function**: `uploadContractDocument()` or similar

**Endpoint**: File upload endpoint

**Request**: Multipart form with file + contract ID

**Response**:
```json
{
  "success": true,
  "document": {
    "id": "doc-3",
    "name": "New Document.pdf",
    "url": "https://example.com/docs/..."
  }
}
```

**Called**: When user selects file to upload

---

### 5.7 Delete Document

**Function**: `deleteContractDocument()` or similar

**Endpoint**: Document deletion endpoint

**Request**:
```json
{
  "contractId": "INV-123",
  "documentId": "doc-1"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Document deleted"
}
```

**Called**: When user taps delete on a document (owner only)

---

## UI Structure

### 6.1 Page Header

```
┌───────────────────────────────────────┐
│ ← | Contract Title or Type Label      │
└───────────────────────────────────────┘
```

- **Left**: Back button (navigation to previous route)
- **Center**: Contract title (or mapped investment type if title missing)
- **Right**: Usually empty (edit button not in header, but in overview section)

---

### 6.2 Contract Overview Section (Expandable Accordion)

```
┌─────────────────────────────────────────────┐
│ [Logo/Badge] Contract Overview  ✎  ▼       │
│ Last updated: 15 Mar 2024, 2:30 PM         │
├─────────────────────────────────────────────┤
│ (Content shown when expanded)               │
│ Account Number:         INV-2024-001       │
│ Contract Number:        C-123456           │
│ Investment Type:        Stocks              │
│ Current Value:          €50,000.00         │
│ Source:                 FILIP              │
│ Product Partner:        Deutsche Börse     │
│ ... (more fields based on type) ...        │
└─────────────────────────────────────────────┘
```

**Components**:
- **Partner Logo** (left side, ~40px): 
  - If logoUrl available, show branded image
  - Otherwise, show letter badge with partner name first letter (e.g., `[D]`)
- **"Contract Overview"** label (center-left)
- **Edit button** (pencil icon ✎, right side):
  - **Visible** only if: user is owner AND source is FILIP/KVV
  - **Clickable** → Opens edit modal
  - **Hidden** if not editable
- **Expand/collapse icon** (▼/▶, right):
  - Rotates 180° when toggling
  - Indicates section can be expanded/collapsed
- **Last update timestamp** (below title):
  - Format: "15 Mar 2024, 2:30 PM"
  - Shows when contract was last modified

---

### 6.3 Details Grid (Expandable Content)

Shown when overview accordion is expanded. A two-column layout with:
- **Column 1**: Field label (left-aligned, ~40% width)
- **Column 2**: Field value (right-aligned, ~60% width, gray text)

**Total rows**: 20-35 rows depending on investment type

**Example rows**:
```
Account Number              INV-2024-001
Contract Number             C-123456
Investment Type             Stocks
Current Value               €50,000.00
Source                      FILIP
Product Partner             Deutsche Börse
Investment Start Date       01 Jan 2020
Investment End Date         -
Book Value                  €45,000.00
Book Value Date             15 Mar 2024
Payment Frequency           Quarterly
Target Sum Savings Plan     No
Premium Benefit             Yes
Lump Sum Investment         Yes
Risk Percentage             25%
Number of Shares            100
Interest Rate               2.5%
Coupon Type                 Fixed
Coupon Rate                 3.0%
Coupon Period               Annual
IBAN                        DE89370400440532013000
BIC                         COBADEFFXXX
ISIN                        US0378331005
Currency                    EUR
Issuer                      Apple Inc.
Current Value Date          15 Mar 2024
Bond Price                  98.5%
Bond Price Date             15 Mar 2024
Current Share Value         €450.00
```

**Styling**:
- Labels in regular text, value in muted/gray text
- Values right-aligned for better scanning
- Missing values show as "-"
- Currency amounts formatted with €/$ and thousands separator
- Boolean values displayed as "Yes" or "No"

---

### 6.4 Notes Section (Collapsible)

```
┌─────────────────────────────────────────────┐
│ 📝 My Notes                                 │
│ Last edited: 10 Mar 2024, 10:15 AM         │
│ 245/300 characters                         │
├─────────────────────────────────────────────┤
│ (Content shown when expanded)               │
│                                             │
│ "This is my investment note. It helps me   │
│  remember why I chose this contract and    │
│  what my goals are for this investment."   │
│                                             │
│ (Edit button ✎ visible to owner only)      │
└─────────────────────────────────────────────┘
```

**Features**:
- **Icon**: 📝 or note emoji
- **Title**: "My Notes" (or localized equivalent)
- **Meta info**: Last edit date/time + character count
- **Content**: Notes text (read-only or inline editable)
- **Edit button** (✎):
  - Visible only to contract owner
  - Triggers inline edit mode
- **Placeholder** (if no notes): "No notes. Click + to add notes."
- **Character counter**: Always shown "XX/300"

**Edit mode** (when user clicks edit):
- TextArea becomes editable
- Show character limit warning at 280+ characters
- Save button (checkmark ✓)
- Cancel button (X)
- Character counter updates in real-time

---

### 6.5 Documents / Resources Section

```
┌─────────────────────────────────────────────┐
│ 📎 Documents                               │
├─────────────────────────────────────────────┤
│ [+ Upload Document]                         │
│                                             │
│ Linked Documents:                           │
│ • Annual Report 2024.pdf          [↓] [×]  │
│ • Quarterly Statement Q1.pdf      [↓] [×]  │
│ • Investment Strategy.docx        [↓] [×]  │
└─────────────────────────────────────────────┘
```

**Features**:
- **Icon**: 📎 paperclip
- **Title**: "Documents"
- **Upload button**: "+ Upload Document"
  - Opens file picker
  - Shows upload progress
  - Adds new document to list on success
- **Document list**:
  - File name + icon (PDF, Word, etc.)
  - Download icon [↓] - tap to open/download
  - Delete icon [×] - visible to owner only
  - On delete: Show confirmation, then remove from list

**Empty state** (if no documents):
- "No documents uploaded"
- Only upload button shown

---

## Navigation

### 7.1 Entry Point

**Route**: `/customercontracts/investment/:id`

**How users reach this page**:
1. From contracts list → Tap on an investment contract card
2. From notifications → Tap on contract-related notification
3. From dashboard → Tap on contract link (if present)

**Route Parameters**:
- `:id` → Contract ID to load

**State to preserve**:
- Store `previousRoute` before navigating to details
- Options: `/notification`, `/customer-dashboard`, `/customercontracts/investment`, or other source

---

### 7.2 Exit Points (Back Navigation)

When user taps the back button:
1. Check stored `previousRoute`
2. Navigate to that route
3. If no `previousRoute` stored, default to `/customercontracts/investment` (list page)

**Navigation logic**:
```typescript
onBackPressed() {
  if (previousRoute) {
    navigate(previousRoute);
  } else {
    navigate('/customercontracts/investment');
  }
}
```

---

### 7.3 Other Navigation (From Details Page)

**Edit modal**:
- Opens in modal overlay (does not navigate away)
- Close modal → Return to details page

**Notes edit**:
- Inline edit (does not navigate)

**Document upload**:
- File picker (does not navigate)
- Return to details page after upload

---

## Data Structure

### 8.1 Investment Contract Entity

```typescript
interface Investment {
  // Identifiers
  id: string;
  contractNumber: string;
  accountNumber: string;
  
  // Type & classification
  investmentType: InvestmentType;  // Enum: stocks | bonds | fixed_deposit | savings_book | savings_account | building_savings
  title: string;  // May be empty, use investmentType label as fallback
  
  // Ownership & source
  personId: string;  // Contract owner's ID
  source: "FILIP" | "KVV" | "EXTERNAL";  // Determines edit capability
  
  // Values & amounts
  currentValue: number;
  bookValue: number;
  currentValueDate: Date;
  bookValueDate: Date;
  
  // Dates
  investmentStartDate: Date;
  investmentEndDate: Date | null;
  
  // Investment-specific fields (conditional visibility)
  paymentFrequency?: string;  // e.g., "Quarterly", "Monthly"
  targetSumSavingsPlan?: boolean;  // Yes/No flag
  premiumBenefit?: boolean;  // Yes/No flag
  riskPercentage?: number;  // 0-100%
  numberOfShares?: number;
  interestRate?: number;  // Percentage
  
  // Bond fields (bonds only)
  couponType?: string;  // e.g., "Fixed", "Floating"
  couponRate?: number;  // Percentage
  couponPeriod?: string;  // e.g., "Annual", "Semi-annual"
  bondPrice?: number;  // Percentage
  bondPriceDate?: Date;
  
  // Banking fields (savings account only)
  iban?: string;
  bic?: string;
  
  // Securities
  isin?: string;  // International Securities Identification Number
  
  // General info
  currency: string;  // ISO 4217 code, e.g., "EUR", "USD"
  issuer?: string;  // Company/entity that issued the security
  productPartner: string;  // Bank or financial institution
  partnerId: string;  // Used for logo lookup
  
  // Additional values
  currentShareValue?: number;  // For stocks
  lumpsumInvestment?: boolean;
  
  // Metadata
  lastModifiedDate: Date;
  lastModifiedBy: string;  // Usually "System" or user name
  
  // Associated data
  notes?: string;
  documents?: Document[];
}

enum InvestmentType {
  STOCKS = "stocks",
  BONDS = "bonds",
  FIXED_DEPOSIT = "fixed_deposit",
  SAVINGS_BOOK = "savings_book",
  SAVINGS_ACCOUNT_OR_CASH = "savings_account",
  BUILDING_SAVINGS = "building_savings"
}

interface Document {
  id: string;
  name: string;
  url: string;
  uploadedDate?: Date;
  size?: number;  // Bytes
}

interface PartnerLogo {
  partnerId: string;
  logoUrl: string;  // May be null
  displayName: string;
}
```

---

## Investment Type Field Visibility Matrix

**Legend**: ✓ = Always visible | ✗ = Never visible | - = Conditional

| Field | Stocks | Bonds | Fixed Deposit | Savings Book | Savings Account | Building Savings |
|-------|--------|-------|---------------|--------------|-----------------|------------------|
| **Core Fields** | | | | | | |
| Account/Contract Number | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Investment Type | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Current Value | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Source | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Product Partner | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Dates** | | | | | | |
| Investment Start Date | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Investment End Date | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Values & Valuations** | | | | | | |
| Book Value | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ |
| Book Value Date | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ |
| Current Value Date | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Payment & Frequency** | | | | | | |
| Payment Frequency | ✗ | ✗ | ✗ | ✓ | ✓ | ✓ |
| **Savings Flags** | | | | | | |
| Target Sum Savings Plan | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ |
| Premium Benefit | ✓ | ✗ | ✗ | ✓ | ✗ | ✗ |
| Lump Sum Investment | - | - | - | - | - | - |
| **Risk & Returns** | | | | | | |
| Risk Percentage | - | - | ✗ | ✗ | ✗ | ✗ |
| Interest Rate | ✗ | ✗ | ✓ | ✓ | ✓ | ✗ |
| **Equity Fields** | | | | | | |
| Number of Shares | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Current Share Value | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **Bond Fields** | | | | | | |
| Coupon Type | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Coupon Rate | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Coupon Period | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Bond Price | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Bond Price Date | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Banking Fields** | | | | | | |
| IBAN | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ |
| BIC | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ |
| **Securities Identifiers** | | | | | | |
| ISIN | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| **Issuer & Partners** | | | | | | |
| Issuer | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Currency | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**Key visibility rules**:
1. **BookValue**: Hidden only for FIXED_DEPOSIT
2. **PaymentFrequency**: Visible only for savings types + BUILDING_SAVINGS
3. **Risk**: Mostly hidden except partially for BONDS
4. **InterestRate**: Visible only for FIXED_DEPOSIT, SAVINGS_BOOK, SAVINGS_ACCOUNT
5. **Coupon* fields**: Visible **only for BONDS**
6. **IBAN/BIC**: Visible **only for SAVINGS_ACCOUNT_OR_CASH**
7. **ISIN**: Hidden only for savings/* + FIXED_DEPOSIT
8. **Issuer**: Visible for STOCKS, BONDS only

---

## Special Behaviors & Interactions

### 10.1 Editability Determination

```typescript
// Helper function to determine if user can edit this contract
isEditable(): boolean {
  const isOwner = contractData.personId === loggedInUser.personId;
  const isSystemManaged = contractData.source === 'FILIP' || contractData.source === 'KVV';
  return isOwner && isSystemManaged;
}

// Flag for child viewing parent's contract
isChildData(): boolean {
  return contractData.personId !== loggedInUser.personId;
}
```

**When not editable**:
- Edit button is hidden
- Notes section is read-only
- No upload document button (or disabled)
- All fields are display-only (no input elements)

---

### 10.2 Edit Modal Interaction

**Open modal**:
1. User clicks edit button (pencil icon)
2. Modal opens with form pre-filled with current values
3. Form validation runs on every change
4. Submit button disabled until form is valid AND data changed

**Data comparison**:
```typescript
const isChanged = (oldData, newData) => {
  // Deep compare all fields
  return JSON.stringify(oldData) !== JSON.stringify(newData);
}
```

**Submit**:
1. Disable submit button, show spinner
2. Validate all required fields
3. Call API to update contract
4. Compare before/after to build changeLogs
5. Call createFilipUpdateLog only if changeLogs.length > 0
6. Close modal on success
7. Refresh contract display
8. Show success toast

**Error**:
1. Show error toast
2. Keep modal open
3. Preserve form data
4. Allow user to fix and retry

---

### 10.3 Notes Inline Editing

**Read mode**:
```
┌──────────────────────────┐
│ My Notes  ✎              │
│ Last edited: 10 Mar 2024 │
│ 245/300 chars            │
├──────────────────────────┤
│ "This is my note..."     │
└──────────────────────────┘
```

**Edit mode** (after clicking ✎):
```
┌──────────────────────────────────┐
│ My Notes                          │
├──────────────────────────────────┤
│ [TextArea - editable]             │
│                                   │
│ 245/300 characters ▌              │
│                                   │
│ [Save ✓]  [Cancel ✗]             │
└──────────────────────────────────┘
```

**Validation**:
- Min: 10 characters
- Max: 300 characters
- Warn user if exceeding 300
- Save button only enabled if valid

**Cancel**:
- Discard all changes
- Return to read mode
- Show original notes

**Save**:
- Validate length
- Call API to update notes
- Show success/error toast
- Return to read mode

---

### 10.4 Partner Logo Loading & Fallback

```typescript
// If logoUrl is available, show image
if (partnerLogo?.logoUrl) {
  return <img src={partnerLogo.logoUrl} alt={partnerName} />;
}

// Otherwise, show letter badge
const firstLetter = partnerName?.charAt(0).toUpperCase() || 'P';
return <div className="badge">{firstLetter}</div>;
```

---

### 10.5 Boolean & Null Handling

```typescript
// Boolean fields: Target Sum Savings Plan, Premium Benefit
displayValue(field): string {
  if (field.value === true) return 'Yes';
  if (field.value === false) return 'No';
  return '-';
}

// Null/empty values
displayValue(field): string {
  if (!field.value || field.value === '') return '-';
  return field.value;
}

// Numbers with formatting
displayValue(amount): string {
  if (!amount) return '-';
  return `€${parseFloat(amount).toLocaleString('de-DE', { 
    minimumFractionDigits: 2, 
    maximumFractionDigits: 2 
  })}`;
}
```

---

### 10.6 Date Formatting

```typescript
// Last update timestamp
formatDate(date): string {
  // Format: "15 Mar 2024, 2:30 PM"
  return new Date(date).toLocaleDateString('en-US', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

// Contract dates (start, end, book value date)
formatDate(date): string {
  // Format: "01 Jan 2020"
  return new Date(date).toLocaleDateString('en-US', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  });
}
```

---

### 10.7 Accordion Toggle & Animations

**Overview section**:
- Click anywhere on header to toggle
- Icon rotates: ▼ → ▶ (or 0° → 180°)
- Content slides down/up with smooth animation
- Expanded state persisted per page visit (not across page reloads)

**Notes section**:
- Same toggle behavior
- Separate from overview section

**Documents section**:
- Usually always expanded (no toggle)
- Or optional toggle with same icon rotation

---

## Error Messages & Feedback

### 11.1 Toast Messages (Short-lived notifications)

| Scenario | Message | Duration | Type |
|----------|---------|----------|------|
| Edit success | "Contract updated successfully" | 2-3 sec | Success (green) |
| No changes | "No changes were made" | 2-3 sec | Info (blue) |
| Edit failed | "Failed to update contract. Please try again." | 3-4 sec | Error (red) |
| Notes saved | "Notes saved" | 2-3 sec | Success (green) |
| Notes failed | "Failed to save notes" | 3-4 sec | Error (red) |
| Upload success | "Document uploaded successfully" | 2-3 sec | Success (green) |
| Upload failed | "Failed to upload document" | 3-4 sec | Error (red) |
| Delete success | "Document deleted" | 2-3 sec | Success (green) |
| Delete failed | "Failed to delete document" | 3-4 sec | Error (red) |

---

### 11.2 Validation Error Messages (Modal/Form)

| Validation | Error Message | Placement |
|-----------|--------------|-----------|
| Required field empty | "This field is required" | Below input |
| Invalid number | "Please enter a valid number" | Below input |
| Invalid date | "Please enter a valid date" | Below input |
| IBAN format invalid | "Please enter a valid IBAN" | Below input |
| BIC format invalid | "Please enter a valid BIC" | Below input |
| Notes < 10 chars | "Minimum 10 characters required" | Below textarea |
| Notes > 300 chars | "Maximum 300 characters allowed" | Below textarea |
| Form not valid | "Please fix errors above" | On submit button |

---

### 11.3 Page-Level Errors (Banners)

| Scenario | Message | Recovery |
|----------|---------|----------|
| Load failed | "Unable to load contract details. Please check your connection." | [Retry] button |
| Network timeout | "Request timed out. Please try again." | [Retry] button |
| No contract found | "Contract not found. Please try again." | Back button |
| Permission denied | "You do not have permission to view this contract." | Back button |
| Server error (500) | "An error occurred. Please try again later." | [Retry] button |

---

## Loading States

### 12.1 Skeleton Loaders (Initial Load)

Show skeleton placeholders while fetching data:

```
┌───────────────────────────────────────┐
│ ← | [████ Title Skeleton ████]        │
├───────────────────────────────────────┤
│ [███ Overview ███]              ▼    │
│ Last updated: [████ loading ████]    │
├───────────────────────────────────────┤
│ [████ Field Name ████]  [████ Value ████] |
│ [████ Field Name ████]  [████ Value ████] |
│ [████ Field Name ████]  [████ Value ████] |
│ [████ Field Name ████]  [████ Value ████] |
│ [████ Field Name ████]  [████ Value ████] |
└───────────────────────────────────────┘
```

**Duration**: Until data arrives (max 5-10 seconds, then show error)

---

### 12.2 Partner Logo Loading

- Show generic badge `[I]` initially
- Replace with branded logo when loaded
- If logo fails, keep badge permanently

---

### 12.3 Edit Modal Submission

- Submit button shows spinner and becomes disabled
- Other form fields remain enabled (user can see what they submitted)
- On response: Remove spinner, close modal

---

### 12.4 Document Upload Progress

- Show upload progress bar (0-100%)
- Button disabled during upload
- On completion: Refresh documents list
- On error: Show error toast, button re-enabled

---

### 12.5 Empty States

| State | UI Display |
|-------|-----------|
| No notes | "No notes. Click + to add notes." button |
| No documents | "No documents uploaded. Click + to upload." |
| No contract found | Full-page error message + back button |
| No data (after successful load) | Display all "-" placeholders |

---

## Checklist for Flutter Implementation

- [ ] Create `InvestmentContractsDetailsPage` screen
- [ ] Implement `Investment` entity model with all fields
- [ ] Build dynamic details grid with conditional field visibility
- [ ] Create investment type enum (6 types)
- [ ] Implement overview accordion (expand/collapse)
- [ ] Add partner logo loading with fallback badge
- [ ] Implement notes management (view/edit/save)
- [ ] Add document upload & management
- [ ] Create edit modal with pre-population
- [ ] Implement change tracking & activity log integration
- [ ] Add validation for all form fields
- [ ] Implement smart back navigation
- [ ] Add all error handling & messaging
- [ ] Add skeleton loaders & loading states
- [ ] Test all 6 investment types with their specific fields
- [ ] Verify edit permissions (owner + FILIP/KVV source)
- [ ] Test child data view-only mode
- [ ] Format numbers, dates, and currencies correctly
- [ ] Match NativeScript UI styling & typography
- [ ] Test on multiple screen sizes
- [ ] Verify all API integration points

---

**Source**: NativeScript AT Mobile App - Investment Contracts Details Component  
**Version**: 1.0  
**Last Updated**: May 2026
