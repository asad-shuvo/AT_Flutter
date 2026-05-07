# Notification parity (NativeScript -> Flutter)

## Scope implemented

- Top bell badge now follows business data (unread notification count), not a static dot.
- Notifications page now uses real API data, with NativeScript response-key filtering and read-status flow.
- Notifications page includes:
  - top bar (`AppTopBar`)
  - red action/header bar (NativeScript-style outlined notification header)
  - notification list body
  - bottom navigation (`AppBottomNav`)
- Notification top bell icon is red on the notification screen.
- Notification bottom nav does not force Message tab active (matches NativeScript behavior where message icon is visible with badge but not selected state).

## API parity

- **List endpoint**: `POST {NotificationService}/api/Notifier/GetOfflineNotificationsByQuery`
- **Mark-read endpoint**: `POST {NotificationService}/api/Notifier/UpdateNotificationStatusToRead`
- **Response keys (same as NativeScript)**:
  - `contractadded`
  - `newsignaturedocumentuploaded`
  - `SchedulingNotification`
  - `Mobile_App_Push_Notification`

Notification service base is now flavor-aware in Flutter:

- dev/stg/uat: `/notification/v3`
- prod: `/notification/v100`

## Badge business rule

- Badge is shown when unread count > 0.
- Unread count is fetched with `OnlyUnread: true` using the same response-key filter set.
- Badge refreshes after returning from Notifications page.

## List behavior

- Notifications are loaded from offline query payload with:
  - `OrderByCreatedDate: 1`
  - `ReturnCount: true`
  - `ResponseKeyFilterOperator: "In"`
  - `PageNumber: 1`
  - `PageSize: 100`
- NativeScript business for data volume is preserved:
  - initial load requests 100 notifications
  - when fetched page size equals 100, further pages are requested (infinite scroll)
  - each next page increments `PageNumber` and appends data
- Unread items are marked read in batch after each loaded page.
- Card UI mirrors NativeScript behavior:
  - unread left red line indicator (4px, vertically inset like NativeScript card)
  - category icon with circular gray border
  - title/subtitle language uses NativeScript keys from i18n (EN/DE parity):
    - `CONTRACT_ADDED`
    - `CONTRACT_UPDATE`
    - `NEW_SIGNATURE_DOCUMENT_UPLOADED`
    - `SLS_INVESTMENT_NOTIFICATION_TITLE`
    - `SLS_INVESTMENT_NOTIFICATION_SUB_TITLE`
    - `tns.contractsAddedNotificationSubtitle`
    - `tns.contractsUpdateNotificationSubtitle`
    - `tns.esignNotificationSubtitle`
  - relative time for recent items, date fallback otherwise

## Response-key mapping used in Flutter

- `contractadded` -> title key **CONTRACT_ADDED**, icon `0xE9BE`
- `newsignaturedocumentuploaded` -> title key **NEW_SIGNATURE_DOCUMENT_UPLOADED**, icon `0xE9D3`
- `SchedulingNotification` -> title key **CONTRACT_UPDATE** (only `EXPIRINGCONTRACT_CUSTOMER`), icon `0xE9BE`
- `Mobile_App_Push_Notification` -> title key **SLS_INVESTMENT_NOTIFICATION_TITLE**, subtitle key **SLS_INVESTMENT_NOTIFICATION_SUB_TITLE**, icon `0xEA16`
