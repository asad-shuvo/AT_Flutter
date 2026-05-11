# Drive (AT NativeScript) - Features, Business Rules, Corner Cases

Source reviewed:
- `D:\Mobile Repo\old\l3-angular-sln-mobileat\src\app\app-document-manager\**`
- `D:\Mobile Repo\old\l3-angular-sln-mobileat\graphify-out\graph.html`

## 1) Feature Inventory

- Drive root with breadcrumb navigation.
- Default virtual folders at root:
  - Portal Files
  - Starred Documents
  - Archived Documents
  - Dossiers
- Folder traversal with route-driven deep-link (`/drive/:folderId`).
- List + grid view rendering.
- Search (server-side fulltext) for files and folders.
- Client-side sort/filter bottom sheet:
  - Name A-Z / Z-A
  - Largest/Smallest file
  - Newest/Oldest date
- File upload from picker.
- Android capture photo -> upload as drive file.
- Create folder.
- Rename file/folder.
- Favorite / unfavorite file/folder.
- Archive / restore file/folder.
- Permanent delete (restricted condition).
- Download/open file (with Android PDF preview dialog flow).
- Details bottom sheet.
- Infinite scroll pagination (`pageSize=10`).
- Owner-aware filtering (household/member context).

## 2) Data/Domain Behavior

- Core entities mapped to view models:
  - `DriveFile`
  - `DriveFolder`
- Workspace model:
  - On init, app resolves user workspace by `OwnerId + IsShared`.
  - If missing, app creates both user workspace + shared workspace.
- Query path split:
  - Standard listing: `getDriveList` payload route (`GetFolders` wrapper returns folders+files).
  - Search listing: `SearchObjectArtifact` with separate file/folder requests then merge.

## 3) Business Rules

### 3.1 Folder Scopes / Tags

- Root/default folder IDs are virtual selectors, not real parent container.
- For default folders, backend query switches behavior:
  - Portal Files -> `Tag=PortalFile`
  - Dossiers -> `Tag=DossierFile`
  - Star -> `IsFavorite=true`
  - Archive -> `IsArchived=true`
- Normal folders:
  - Folder items tagged `CreateFolder`
  - File items tagged `UploadFile`

### 3.2 Ownership and Visibility

- Data filtered by owner list.
- Primary owner default = logged-in customer user id.
- If household member(s) selected, owner IDs replaced by selected proposed-user IDs.
- Create permission disabled when selection is not exactly customer-only context.

### 3.3 Add/Create Permission Rules

- Add button hidden inside default folders:
  - Archive, Star, Portal Files, Dossiers.
- More-vert actions shown only when:
  - item has no owner OR
  - `item.OwnerId == currentCustomerUserId`.

### 3.4 Action Menu Rules

- Archived item:
  - show `Restore`
  - in archive folder + source `Filip` => show `Delete Permanently`
- Non-archived item (outside archive folder):
  - show `Rename`
  - show `Favorite/Unfavorite`
  - show `Archive`
- File/shared file only:
  - show `Download`
  - show `Details`

### 3.5 Upload Rules

- Max file count per upload action: `1`.
- Max file size: `6,000,000 bytes`.
- File metadata injected on upload:
  - `DocumentSize`
  - `ExternalDocumentCreateDate`
  - `FileType`
  - `RelatedTo=Drive`
  - `Source=Filip`
  - `SourceEntityName=Person`
  - `SourceId=currentCustomerPersonId`
- PDF upload sets `GenerateThumbnail=true`.

### 3.6 Capture Photo Rules (Android)

- Android only in add menu.
- Camera image resized (`captureImageMaxSize=1280`), uploaded as `.jpg`.
- User must provide image name (1..20 chars).
- Optional immediate favorite mark after upload.

### 3.7 Naming Rules

- Folder create:
  - min length from config = `2`
  - UI field max length `40`
  - value trimmed before create
- Rename:
  - min length `2`
  - max length `40`
  - for files, extension preserved and only basename changed

### 3.8 Sorting Rules

- Default list sort by date desc:
  - prefer `MetaData.ExternalDocumentCreateDate.Value`
  - fallback `CreateDate`
- Size sort parses textual size units (`KB`, `MB`) client-side.

## 4) API/Operation Flows

- Create folder:
  1. Resolve workspace id
  2. `CreateFolder` command
  3. Insert activity log (`drive-folder`)
- Upload file:
  1. Get pre-signed URL
  2. Upload binary to storage (platform-specific)
  3. Create drive object artifact (`uploadFile`)
  4. Insert activity log (`drive-file`)
- Favorite:
  - `AddToFavorite` command toggles state
- Archive/Restore:
  - `deleteDriveData(objectArtifactId, isArchivedFlag)`
- Permanent delete:
  - `permanentDeleteDriveData`
  - then remove matching activity log row
- Rename:
  - `renameObjectArtifact`

## 5) Corner Cases / Edge Cases

- Root/default folder handling:
  - default folder ids must map to tag/favorite/archive filters; parent id forced null.
- Breadcrumb dedupe:
  - duplicate breadcrumb IDs cleaned before back-nav.
- Deep-link into nested folder while in archive/star context:
  - breadcrumb reconstruction includes only chain meeting archive/favorite condition.
- Search behavior:
  - disabled when query empty string.
  - archive folder intentionally bypasses search branch in current logic.
- Pagination:
  - on folder change, page reset required; otherwise list appends stale page segments.
- Owner context switch:
  - household change can force root reset + disable add features.
- Thumbnail/file URL hydration:
  - URL fetched from storage metadata (`ThumbnailId` fallback `FileStorageId`).
- Android file picker content URI:
  - file copied to temp before upload.
- Temp folder cleanup:
  - picker/camera flow clears temp folder before copy.
- Permanent delete availability:
  - only archived + inside archive + `MetaData.Source.Value == 'Filip'`.
- Rename file extension safety:
  - extension retained; avoids changing actual type on rename.
- More-vert security gate:
  - non-owner documents suppress actions.
- Capture photo favorite race:
  - code waits then emits refresh event; async timing dependent.
- Workspace bootstrap race:
  - first-time users depend on successful workspace auto-create.

## 6) Known Risks / Implementation Notes (for Flutter parity)

- Static mutable state in service (`customer ids`, `breadcrumbs`, `page`, etc.) can leak across lifecycle if not reset correctly.
- Mixed API styles (`SearchObjectArtifact`, `getDriveList`, legacy SQL paths) need strict parity mapping to avoid result mismatch.
- Archive/Star default-folder logic deeply coupled to hardcoded GUID constants.
- Multiple async chains use nested subscribe/promise; failures mostly logged, not user surfaced.
- Graph file gave architectural dependency picture only; business truth came from source files above.

