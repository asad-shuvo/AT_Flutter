# Self-Signup / Create Account — Business Spec

> Source of truth: `l3-angular-sln-mobileat/src/app/app-self-signup/`
> Reference files: `app-self-signup.component.ts`, `app-self-signup.service.ts`, `signup-endpoints-payload.interface.ts`

---

## 1. Two User Paths

### Path A — New Customer (email NOT in system)
Email is available for self-signup (`IsEmailAvailableForSelfSignup = true`).
Full personal details required.

### Path B — Existing Portal Customer (email already in system)
Customer already exists on portal (has email/phone on record).
Only password + DOB needed to onboard them.

Both paths share the same first 4 steps (email verify → phone verify). They diverge after `GET GetSignupVerificaitonData`.

---

## 2. Step-by-Step Flow

### Step 1: Email Input
- User enters email address
- CAPTCHA challenge rendered and solved
- `POST SignupCommand/SendEmailVerificationCode`
- **Error branch:** `USER_EXIST_FOR_THIS_EMAIL` → show `EMAIL_ALREADY_TAKEN_VIEW` (redirect to login)

### Step 2: Email OTP Verification
- User enters 6-digit OTP received by email
- `POST SignupCommand/VerifyEmailVerificationCode`
- On success: stores `EmailVerificationToken` in session state
- **Resend:** After 60s countdown → show CAPTCHA → `POST SignupCommand/ResendEmailVerificationCode`
- **Error:** `EMAIL_VERIFICATION_CODE_INVALID` or `EMAIL_VALIDATE_FAILED` → snackbar "INVALID_VERIFICATION_CODE"

### Step 3: Phone Input
- User enters phone number + country code (dial code prefix)
- CAPTCHA challenge rendered and solved
- `POST SignupCommand/SendPhoneNumberVerificationCode`
- **Error branch:** Phone already registered → show `PHONE_EXIST_LOGIN_VIEW` (redirect to login)
- **Error:** `PHONE_VERIFICATION_CODE_SEND_FAILED` → snackbar "FAILED_TO_SEND_VERIFICATION_CODE"

### Step 4: Phone OTP Verification
- User enters 6-digit OTP received by SMS
- `POST SignupCommand/VerifyPhoneNumberVerificationCode`
- On success: stores `PhoneVerificationToken` in session state
- **Resend:** same 60s timer → CAPTCHA → `POST SignupCommand/ResendPhoneNumberVerificationCode`
- **Error:** `PHONE_VALIDATE_FAILED` → snackbar "INVALID_VERIFICATION_CODE"
- After success → `GET SignupQuery/GetSignupVerificaitonData` → branching decision

### Branch Decision (after phone OTP)
```
GetSignupVerificaitonData response
  ├─ IsEmailAvailableForSelfSignup = false → Path B: PASSWORD_SET view
  └─ IsEmailAvailableForSelfSignup = true  → Optional: ASSIGN_ADVISOR → Path A: SELF_SIGN_UP view
```

---

## 3. Path A — Full Signup Form (`SELF_SIGN_UP` view)

### Step 5a: Optional Advisor Assignment
- User can enter an advisor number (referral code)
- `GET SlSnQuery/GetAdvisorByAdvisorNumber?AdvisorNumber=XXX`
- Returns: DisplayName, Phone, Email, ProfileImage
- User confirms or skips — step is entirely optional

### Step 6a: Full Registration Form
Fields required:
- Salutation (dropdown)
- First Name (2–50 chars)
- Last Name (2–50 chars)
- Date of Birth (≥18 years old, after 1900-01-01)
- Sex (dropdown)
- Street (2–50 chars)
- City (2–50 chars)
- Postal Code (2–50 numeric chars)
- Country (dropdown — from AggregateService country list)
- Nationality (dropdown — from KVV dictionary)
- Post-Nominal Title (optional, 0–20 chars)
- Designation (optional, 0–30 chars)
- Password (see Password Rules)
- Confirm Password (must match)
- Terms & Data Protection checkbox (required)

### Submission: `POST SignupCommand/SelfSignup`
Payload (`ISelfSignupPayload`):
```typescript
{
  Password: string,
  CaptchaVerificationCode: string,
  TwoFactorEnabled: true,           // always true
  MessageCorrelationId: string,     // GUID
  Person: {
    ItemId: string,                 // ProposedUserId from session
    Salutation: string,
    FirstName: string,
    LastName: string,
    Sex: string,
    DateOfBirth: string,            // UTC ISO: new Date(UTC(y,m,d,0,0,0)).toISOString()
    Street: string,
    City: string,
    PostalCode: string,
    Country: string,
    Nationality: string,
    PostNominalTitle?: string,
    Designation?: string,
    EmailVerificationToken: string,
    PhoneVerificationToken: string,
    Contacts: [
      { Phone, PhoneType, key (country alpha-2), label, dialcode },
      { Email, EmailType, Label }
    ]
  }
}
```

---

## 4. Path B — Existing Customer Onboarding (`PASSWORD_SET` view)

### Step 5b: Short Form
Fields required:
- Date of Birth (required)
- Password (see Password Rules)
- Confirm Password (must match)
- Terms & Data Protection checkbox (required)

### Submission: `POST SignupCommand/Onboard`
Payload (`IUserOnBoardPayload`):
```typescript
{
  Password: string,
  CaptchaVerificationCode: string,
  MessageCorrelationId: string,     // GUID
  Person: {
    DateOfBirth: string,            // UTC ISO string
    TwoFactorEnabled: true
  }
}
```

---

## 5. API Endpoints

| Endpoint | Method | Service | Purpose |
|----------|--------|---------|---------|
| `SignupCommand/SendEmailVerificationCode` | POST | SignUpService | Send OTP to email (CAPTCHA-gated) |
| `SignupCommand/ResendEmailVerificationCode` | POST | SignUpService | Resend email OTP after new CAPTCHA |
| `SignupCommand/VerifyEmailVerificationCode` | POST | SignUpService | Validate email OTP |
| `SignupCommand/SendPhoneNumberVerificationCode` | POST | SignUpService | Send OTP to phone (CAPTCHA-gated) |
| `SignupCommand/ResendPhoneNumberVerificationCode` | POST | SignUpService | Resend phone OTP after new CAPTCHA |
| `SignupCommand/VerifyPhoneNumberVerificationCode` | POST | SignUpService | Validate phone OTP |
| `SignupQuery/GetSignupVerificaitonData` | GET | SignUpService | Determine new vs existing user |
| `SignupCommand/SelfSignup` | POST | SignUpService | Create new user (full form) |
| `SignupCommand/Onboard` | POST | SignUpService | Onboard existing user (short form) |
| `SlSnQuery/GetAdvisorByAdvisorNumber` | GET | SLSNBusiness | Lookup advisor by number |

Base URLs (via environment):
- dev: `http://msblocks.seliselocal.com/api/SignupService/` and `.../SelectNetworkBusinessService/`
- stg: `https://msblocks.selisestage.com/api/...`
- uat: `https://msblocks.seliseuat.com/api/...`
- prod: `https://www.filip.at/api/...`

---

## 6. Payload Details

### `ISendEmailVerificationCodePayload`
```typescript
{ Email: string, Language: string, CaptchaVerificationCode?: string }
```

### `IResendEmailVerificationCodePayload`
```typescript
{ Language: string, CaptchaVerificationCode?: string }
```

### `IVerifyEmailVerificationCodePayload`
```typescript
{ VerificationCode: string }
```

### `ISendPhoneNumberVerificationCodePayload`
```typescript
{ PhoneNumber: string, Language: string, CaptchaVerificationCode?: string }
```

### `IResendPhoneNumberVerificationCodePayload`
```typescript
{ Language: string, CaptchaVerificationCode?: string }
```

### `IVerifyPhoneNumberVerificationCodePayload`
```typescript
{ VerificationCode: string }
```

### `IUserOnBoardPayload` (Path B)
```typescript
{ Password: string, CaptchaVerificationCode: string, Person?: { DateOfBirth?: date, TwoFactorEnabled?: boolean } }
```

### `ISelfSignupPayload` (Path A)
```typescript
{
  Password: string,
  CaptchaVerificationCode: string,
  TwoFactorEnabled?: boolean,
  Person?: {
    Salutation?, FirstName?, LastName?, Sex?,
    Street?, City?, PostalCode?, Country?, Nationality?,
    PostNominalTitle?, Designation?,
    DateOfBirth?, TwoFactorEnabled?
  }
}
```

---

## 7. Session State Object (`selfSignUpData`)

Persists across all steps within the signup flow:

```typescript
{
  UserEmail: string,
  UserPhoneNumber: string,
  UserCountryCode: string,          // e.g. "+43"
  EmailVerificationToken: string,   // from VerifyEmail response
  PhoneVerificationToken: string,   // from VerifyPhone response
  ConsentId: string,
  VerificationToken: string,
  ProposedUserId: string,           // pre-assigned user ID from backend
  CaptchaVerificationCode: string,
  CaptchaCodeType: ContactType,     // 0=Email, 1=PhoneNumber
  AdvisorNumber: string,
  SuccessPageMessage: string
}
```

---

## 8. View States Enum

| View | Description |
|------|-------------|
| `EMAIL_INPUT` | Step 1: Enter email |
| `EMAIL_VERIFICATION_CODE_SEND` | Step 2: Enter email OTP |
| `PHONE_INPUT` | Step 3: Enter phone + country code |
| `PHONE_VERIFICATION_CODE_SEND` | Step 4: Enter phone OTP |
| `ASSIGN_ADVISOR` | Optional: Advisor lookup |
| `SELF_SIGN_UP` | Path A: Full signup form |
| `PASSWORD_SET` | Path B: Password + DOB only |
| `CAPTCHA_VARIFICATION_VIEW` | CAPTCHA modal (resend flow) |
| `RESEND_CAPTCHA_VERIFICATION` | CAPTCHA for resend |
| `EMAIL_ALREADY_TAKEN_VIEW` | Error: email taken → redirect to login |
| `PHONE_EXIST_LOGIN_VIEW` | Error: phone exists → redirect to login |
| `EMAIL_EXIST_LOGIN_VIEW` | Error: email exists → redirect to login |
| `BEING_PATIENT_VIEW` | Loading/processing state |
| `ACCOUNT_CREATE_SUCCESSFULL` | Final: success bottom sheet |
| `ACCOUNT_CREATE_FAILED` | Final: failure bottom sheet |

---

## 9. Validation Rules

| Field | Rule |
|-------|------|
| Email | Async `ValidateEmail()` — format + availability |
| Phone | 9–13 digits, numeric only |
| Password | `/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[-_!*@#$,.;?§%^&+=/]).{6,300}$/` |
| Confirm Password | Must match Password |
| First/Last Name | 2–50 chars, not whitespace-only |
| City / Street | 2–50 chars, not whitespace-only |
| Postal Code | 2–50 chars, integer digits only |
| Date of Birth | Required; ≥18 years; after 1900-01-01 |
| Post-nominal Title | Optional; 0–20 chars |
| Designation | Optional; 0–30 chars |
| Terms Checkbox | Required (must be checked) |

---

## 10. Error Codes & Handling

| Error Code | Trigger | UI Response |
|-----------|---------|-------------|
| `USER_EXIST_FOR_THIS_EMAIL` | SendEmail response | Show `EMAIL_ALREADY_TAKEN_VIEW` |
| `EMAIL_VERIFICATION_CODE_INVALID` | VerifyEmail response | Snackbar: "INVALID_VERIFICATION_CODE" |
| `EMAIL_VALIDATE_FAILED` | VerifyEmail response | Snackbar: "INVALID_VERIFICATION_CODE" |
| `EMAIL_VERIFICATION_CODE_SEND_FAILED` | SendEmail response | Snackbar: "FAILED_TO_SEND_VERIFICATION_CODE" |
| `PHONE_VERIFICATION_CODE_SEND_FAILED` | SendPhone response | Snackbar: "FAILED_TO_SEND_VERIFICATION_CODE" |
| `PHONE_VALIDATE_FAILED` | VerifyPhone response | Snackbar: "INVALID_VERIFICATION_CODE" |
| Account creation fail | SelfSignup/Onboard | Show `ACCOUNT_CREATE_FAILED` bottom sheet |

---

## 11. OTP / CAPTCHA Mechanics

- **OTP timer:** 60-second countdown from send/resend. Format: `M:SS SEC`. Resend disabled until 0.
- **Resend flow:** 
  1. Timer expires → "Resend" button enabled
  2. Tap resend → `CAPTCHA_VARIFICATION_VIEW` shown
  3. Solve CAPTCHA → submit → new OTP sent
- **CAPTCHA:** Required on initial send AND every resend. Not required on OTP entry step.
- **Every API call** includes `MessageCorrelationId: getNewGuid()` (GUID).

---

## 12. Firebase Notification Integration

- On signup initiation: subscribe to Firebase topic with `MessageCorrelationId`
- Backend fires `USER_CREATION_SUCCEEDED` or `USER_CREATION_FAILED` via FCM
- App shows corresponding bottom sheet on notification receipt
- On completion (success or fail): unsubscribe from topic

---

## 13. Corner Cases

| Case | Behavior |
|------|----------|
| Email already taken | `EMAIL_ALREADY_TAKEN_VIEW` → button to go to login |
| Phone already registered | `PHONE_EXIST_LOGIN_VIEW` → button to go to login |
| OTP incorrect | Inline error, allow retry, counter not shown |
| OTP expired (60s) | Resend flow via new CAPTCHA |
| User exists in portal (same email) | Skip full form → Path B (password + DOB only) |
| Advisor number not found | Show error inline, allow skip |
| Advisor step skipped | Payload sent without AdvisorNumber |
| DOB < 18 years | Validation error on form |
| DOB before 1900 | Validation error on form |
| Password weak | Inline regex error, list missing requirements |
| Terms not checked | Submit button disabled or inline error |
| Network failure at any step | Show error snackbar, stay on current step |
| Firebase event arrives before UI | Queue event, show after bottom sheet ready |
| Session data missing (deep link?) | Redirect to beginning of signup flow |
| Phone country code not selected | Default or require selection before send |

---

## 14. Flutter Implementation Plan (High-Level)

### Files to create
```
lib/features/self_signup/
  application/
    self_signup_controller.dart       # state machine, step management
    self_signup_state.dart            # view enum + session data model
  data/
    self_signup_repository.dart       # all API calls
    models/
      signup_payload.dart
      onboard_payload.dart
      verification_payload.dart
      advisor.dart
      signup_verification_data.dart
  presentation/
    pages/
      self_signup_page.dart           # shell, view switcher
    widgets/
      email_input_step.dart
      email_otp_step.dart
      phone_input_step.dart
      phone_otp_step.dart
      advisor_step.dart
      full_signup_form_step.dart
      set_password_step.dart
      captcha_view.dart
      otp_timer_widget.dart
    bottom_sheets/
      account_success_bottom_sheet.dart
      account_failed_bottom_sheet.dart
      email_taken_bottom_sheet.dart
      phone_exists_bottom_sheet.dart
```

### Services to reuse
- `ApiClient` from `core/network/api_client.dart`
- `SecureStorageService` for any credential storage
- App environment URLs from `app/environment/app_environment.dart`

### No new colors or fonts — use `app_colors.dart` + existing icon packs.
