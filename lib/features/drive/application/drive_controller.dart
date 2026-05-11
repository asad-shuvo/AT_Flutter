import 'dart:async';

import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/drive/data/drive_models.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:flutter/foundation.dart';

class DriveController extends ChangeNotifier {
  DriveController({
    required DriveRepository repository,
    required HouseholdMemberFilterController householdController,
    required String customerUserId,
    required String customerPersonId,
  })  : _repository = repository,
        _householdController = householdController,
        _customerUserId = customerUserId,
        _customerPersonId = customerPersonId;

  final DriveRepository _repository;
  final HouseholdMemberFilterController _householdController;
  String _customerUserId;
  String _customerPersonId;

  void setSession({required String customerUserId, required String customerPersonId}) {
    _customerUserId = customerUserId;
    _customerPersonId = customerPersonId;
  }

  // ─── State ────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  List<DriveFolder> _folders = [];
  List<DriveFile> _files = [];
  int _totalCount = 0;
  int _pageNumber = 0;
  bool _hasMore = true;

  String? _currentFolderId;
  List<DriveBreadcrumb> _breadcrumbs = const [];
  DriveViewMode _viewMode = DriveViewMode.list;
  DriveSortMode _sortMode = DriveSortMode.newestFirst;

  String _searchText = '';
  bool _isSearchMode = false;

  String? _workspaceId;
  List<String> _ownerIds = [];
  bool _hasCreatePermission = true;

  // ─── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<DriveFolder> get displayFolders => _applySort(_folders);
  List<DriveFile> get displayFiles => _applySortFiles(_files);
  int get totalCount => _totalCount;
  String? get currentFolderId => _currentFolderId;
  List<DriveBreadcrumb> get breadcrumbs => _breadcrumbs;
  DriveViewMode get viewMode => _viewMode;
  DriveSortMode get sortMode => _sortMode;
  String get searchText => _searchText;
  bool get isSearchMode => _isSearchMode;
  String? get workspaceId => _workspaceId;
  bool get hasCreatePermission =>
      _hasCreatePermission && !_isDefaultFolderContext;
  bool get isAtRoot => _currentFolderId == null;
  String get customerPersonId => _customerPersonId;
  String get customerUserId => _customerUserId;

  bool get _isDefaultFolderContext =>
      DriveDefaultFolders.isDefaultFolder(_currentFolderId);

  bool canShowMoreVert(String? ownerId) {
    if (ownerId == null || ownerId.isEmpty) return true;
    return ownerId == _customerUserId;
  }

  // ─── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _breadcrumbs = [
      const DriveBreadcrumb(name: 'tns.DMS_MY_DOCUMENTS', itemId: 'root'),
    ];
    _currentFolderId = null;
    _pageNumber = 0;
    _folders = [];
    _files = [];
    _hasMore = true;
    _ownerIds = [_customerUserId];
    _hasCreatePermission = true;

    // Resolve workspace in background — does not block list load
    unawaited(_repository.resolveWorkspaceId(_customerUserId).then((id) {
      _workspaceId = id;
    }).catchError((_) {}));

    await _loadItems(reset: true);
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  Future<void> openFolder(String folderId, String folderName) async {
    final resolved = _displayName(folderName);
    _breadcrumbs = [
      ..._breadcrumbs,
      DriveBreadcrumb(name: resolved, itemId: folderId),
    ];
    _currentFolderId = folderId;
    _pageNumber = 0;
    _folders = [];
    _files = [];
    _hasMore = true;
    _searchText = '';
    _isSearchMode = false;
    await _loadItems(reset: true);
  }

  Future<void> navigateBreadcrumb(String itemId) async {
    if (itemId == 'root' || itemId.isEmpty) {
      await navigateToRoot();
      return;
    }
    final idx = _breadcrumbs.indexWhere((b) => b.itemId == itemId);
    if (idx < 0) return;
    _breadcrumbs = _breadcrumbs.sublist(0, idx + 1);
    _currentFolderId = itemId;
    _pageNumber = 0;
    _folders = [];
    _files = [];
    _hasMore = true;
    _searchText = '';
    _isSearchMode = false;
    await _loadItems(reset: true);
  }

  Future<void> navigateToRoot() async {
    _breadcrumbs = [
      const DriveBreadcrumb(name: 'tns.DMS_MY_DOCUMENTS', itemId: 'root'),
    ];
    _currentFolderId = null;
    _pageNumber = 0;
    _folders = [];
    _files = [];
    _hasMore = true;
    _searchText = '';
    _isSearchMode = false;
    await _loadItems(reset: true);
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    _pageNumber = 0;
    _folders = [];
    _files = [];
    _hasMore = true;
    await _loadItems(reset: true);
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isSearchMode) return;
    _pageNumber++;
    _isLoadingMore = true;
    notifyListeners();
    await _loadItems(reset: false);
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _loadItems({required bool reset}) async {
    if (reset) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      if (_isSearchMode && _searchText.isNotEmpty) {
        await _doSearch();
      } else {
        await _doFetch();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _doFetch() async {
    final result = await _repository.getDriveList(
      customerPersonId: _customerPersonId,
      ownerIds: _ownerIds.isNotEmpty ? _ownerIds : [_customerUserId],
      parentId: _realParentId(_currentFolderId),
      isArchived: DriveDefaultFolders.isArchivedContext(_currentFolderId),
      tag: _tagForFolder(_currentFolderId),
      isFavorite: DriveDefaultFolders.isStarredContext(_currentFolderId)
          ? true
          : null,
      pageNumber: _pageNumber,
      pageSize: 10,
    );

    if (result == null) {
      _hasMore = false;
      return;
    }

    final newFolders = result.folders;
    final newFiles = result.files;

    if (_pageNumber == 0) {
      _folders = isAtRoot
          ? [...DriveDefaultFolders.buildDefaultList(), ...newFolders]
          : newFolders;
      _files = newFiles;
    } else {
      _folders = [..._folders, ...newFolders];
      _files = [..._files, ...newFiles];
    }

    _totalCount = result.totalCount;
    _hasMore = (newFolders.length + newFiles.length) >= 10;
  }

  Future<void> _doSearch() async {
    final result = await _repository.searchDocuments(
      ownerUserId: _customerUserId,
      ownerIds: _ownerIds.isNotEmpty ? _ownerIds : [_customerUserId],
      searchText: _searchText,
      folderId: _currentFolderId,
    );

    if (result == null) return;
    _folders = isAtRoot
        ? [...DriveDefaultFolders.buildDefaultList(), ...result.folders]
        : result.folders;
    _files = result.files;
    _totalCount = result.totalCount;
    _hasMore = false;
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  Future<void> onSearchChanged(String text) async {
    _searchText = text;
    _isSearchMode = text.isNotEmpty;
    _pageNumber = 0;
    await _loadItems(reset: true);
  }

  void clearSearch() {
    _searchText = '';
    _isSearchMode = false;
    _pageNumber = 0;
    refresh();
  }

  // ─── View / Sort ──────────────────────────────────────────────────────────

  void toggleViewMode() {
    _viewMode =
        _viewMode == DriveViewMode.list ? DriveViewMode.grid : DriveViewMode.list;
    notifyListeners();
  }

  void setSortMode(DriveSortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  // ─── Household ────────────────────────────────────────────────────────────

  void applyHouseholdFilter() {
    final allMembers = [
      ..._householdController.householdMembers,
      ..._householdController.businessMembers,
    ];
    final selectedPersonIds = _householdController.selectedPersonIds;

    final proposedUserIds = <String>[];
    for (final pid in selectedPersonIds) {
      final member = allMembers.firstWhere(
        (m) => m.personId == pid,
        orElse: () => allMembers.first,
      );
      if (member.proposedUserId != null && member.proposedUserId!.isNotEmpty) {
        proposedUserIds.add(member.proposedUserId!);
      }
    }

    _ownerIds = proposedUserIds.isNotEmpty ? proposedUserIds : [_customerUserId];

    // Create permission: only when selection is exactly the current customer
    final isOnlyMe = selectedPersonIds.length == 1 &&
        allMembers.any((m) =>
            m.personId == selectedPersonIds.first && m.isCurrentUser);
    _hasCreatePermission = isOnlyMe;

    refresh();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<bool> createFolder(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Always fetch workspace fresh — matches NativeScript GetWorkSpaceId call per CreateFolder
      final workspaceId = await _repository.resolveWorkspaceId(_customerUserId);
      if (workspaceId == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _workspaceId = workspaceId;
      final ok = await _repository.createFolder(
        name: name,
        workspaceId: workspaceId,
        parentId: _realParentId(_currentFolderId),
      );
      if (ok) {
        await refresh();
      } else {
        _isLoading = false;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameFolder(DriveFolder folder, String newName) async {
    final ok = await _repository.renameObject(
      objectArtifactId: folder.itemId,
      newName: newName,
    );
    if (ok) {
      _folders = _folders.map((f) {
        if (f.itemId == folder.itemId) return f.copyWith(name: newName);
        return f;
      }).toList();
      notifyListeners();
    }
    return ok;
  }

  Future<bool> renameFile(DriveFile file, String newName) async {
    final ext = file.name.contains('.')
        ? '.${file.name.split('.').last}'
        : '';
    final baseName = newName.contains('.') ? newName : '$newName$ext';
    final ok = await _repository.renameObject(
      objectArtifactId: file.itemId,
      newName: baseName,
      sourceFileId: file.fileStorageId,
    );
    if (ok) {
      _files = _files.map((f) {
        if (f.itemId == file.itemId) return f.copyWith(name: baseName);
        return f;
      }).toList();
      notifyListeners();
    }
    return ok;
  }

  Future<bool> toggleFolderFavorite(DriveFolder folder) async {
    final ok = await _repository.toggleFavorite(
      objectArtifactId: folder.itemId,
      currentIsFavorite: folder.isFavorite,
      ownerUserId: _customerUserId,
    );
    if (ok) {
      if (DriveDefaultFolders.isStarredContext(_currentFolderId)) {
        await refresh();
        return true;
      }
      _folders = _folders.map((f) {
        if (f.itemId == folder.itemId) {
          return f.copyWith(isFavorite: !folder.isFavorite);
        }
        return f;
      }).toList();
      notifyListeners();
    }
    return ok;
  }

  Future<bool> toggleFileFavorite(DriveFile file) async {
    final ok = await _repository.toggleFavorite(
      objectArtifactId: file.itemId,
      currentIsFavorite: file.isFavorite,
      ownerUserId: _customerUserId,
    );
    if (ok) {
      if (DriveDefaultFolders.isStarredContext(_currentFolderId)) {
        await refresh();
        return true;
      }
      _files = _files.map((f) {
        if (f.itemId == file.itemId) return f.copyWith(isFavorite: !file.isFavorite);
        return f;
      }).toList();
      notifyListeners();
    }
    return ok;
  }

  Future<bool> archiveFolder(DriveFolder folder) async {
    final ok = await _repository.archiveItem(
      objectArtifactId: folder.itemId,
      isArchived: true,
    );
    if (ok) {
      _folders = _folders.where((f) => f.itemId != folder.itemId).toList();
      _totalCount = (_totalCount - 1).clamp(0, 999999);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> restoreFolder(DriveFolder folder) async {
    final ok = await _repository.archiveItem(
      objectArtifactId: folder.itemId,
      isArchived: false,
    );
    if (ok) {
      _folders = _folders.where((f) => f.itemId != folder.itemId).toList();
      _totalCount = (_totalCount - 1).clamp(0, 999999);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> archiveFile(DriveFile file) async {
    final ok = await _repository.archiveItem(
      objectArtifactId: file.itemId,
      isArchived: true,
    );
    if (ok) {
      _files = _files.where((f) => f.itemId != file.itemId).toList();
      _totalCount = (_totalCount - 1).clamp(0, 999999);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> restoreFile(DriveFile file) async {
    final ok = await _repository.archiveItem(
      objectArtifactId: file.itemId,
      isArchived: false,
    );
    if (ok) {
      _files = _files.where((f) => f.itemId != file.itemId).toList();
      _totalCount = (_totalCount - 1).clamp(0, 999999);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> permanentDeleteFile(DriveFile file) async {
    final ok = await _repository.permanentDeleteItem(file.itemId);
    if (ok) {
      _files = _files.where((f) => f.itemId != file.itemId).toList();
      _totalCount = (_totalCount - 1).clamp(0, 999999);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> uploadFile({
    required String fileName,
    required List<int> bytes,
    required String contentType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Always fetch workspace fresh — matches NativeScript GetWorkSpaceId call per upload
      final workspaceId = await _repository.resolveWorkspaceId(_customerUserId);
      if (workspaceId == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _workspaceId = workspaceId;

      final fileId = newGuid();
      final artifactId = newGuid();

      final uploadUrl = await _repository.getPresignedUploadUrl(
        fileId: fileId,
        fileName: fileName,
      );
      if (uploadUrl == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final uploaded = await _repository.putFileBytes(
        uploadUrl: uploadUrl,
        bytes: Uint8List.fromList(bytes),
        contentType: contentType,
      );
      if (!uploaded) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final ext = fileName.contains('.') ? fileName.split('.').last : '';
      final ok = await _repository.createFileArtifact(
        objectArtifactId: artifactId,
        fileStorageId: fileId,
        fileName: fileName,
        workspaceId: workspaceId,
        customerPersonId: _customerPersonId,
        parentId: _realParentId(_currentFolderId),
        generateThumbnail: ext.toLowerCase() == 'pdf',
        fileSizeBytes: bytes.length,
      );
      if (ok) {
        await refresh();
      } else {
        _isLoading = false;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> captureAndUploadPhoto({
    required String title,
    required List<int> bytes,
    required bool markAsFavorite,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final workspaceId = await _repository.resolveWorkspaceId(_customerUserId);
      if (workspaceId == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _workspaceId = workspaceId;

      final fileName = '$title.jpg';
      final fileId = newGuid();
      final artifactId = newGuid();

      final uploadUrl = await _repository.getPresignedUploadUrl(
        fileId: fileId,
        fileName: fileName,
      );
      if (uploadUrl == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final uploaded = await _repository.putFileBytes(
        uploadUrl: uploadUrl,
        bytes: Uint8List.fromList(bytes),
        contentType: 'image/jpeg',
      );
      if (!uploaded) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final ok = await _repository.createFileArtifact(
        objectArtifactId: artifactId,
        fileStorageId: fileId,
        fileName: fileName,
        workspaceId: workspaceId,
        customerPersonId: _customerPersonId,
        parentId: _realParentId(_currentFolderId),
        generateThumbnail: false,
        fileSizeBytes: bytes.length,
        logActivity: false,
      );
      if (ok && markAsFavorite) {
        await _repository.toggleFavorite(
          objectArtifactId: artifactId,
          currentIsFavorite: false,
          ownerUserId: _customerUserId,
        );
      }
      if (ok) {
        await refresh();
      } else {
        _isLoading = false;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  String? _realParentId(String? folderId) {
    if (folderId == null || folderId == 'root') return null;
    if (DriveDefaultFolders.isDefaultFolder(folderId)) return null;
    return folderId;
  }

  String? _tagForFolder(String? folderId) {
    switch (folderId) {
      case DriveDefaultFolders.portalFilesId:
        return 'portal-file';
      case DriveDefaultFolders.dossiersId:
        return 'dossier-file';
      case DriveDefaultFolders.myContractsId:
        return 'my-contract-file';
      case null:
        return 'upload-file';
      default:
        return null;
    }
  }

  String _displayName(String name) => name;

  List<DriveFolder> _applySort(List<DriveFolder> folders) {
    // Default folders always stay at top unsorted
    final defaults = folders.where((f) => f.isDefault).toList();
    final userFolders = folders.where((f) => !f.isDefault).toList();
    final sorted = List<DriveFolder>.from(userFolders);

    switch (_sortMode) {
      case DriveSortMode.nameAZ:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case DriveSortMode.nameZA:
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case DriveSortMode.newestFirst:
        sorted.sort((a, b) => b.sortDate.compareTo(a.sortDate));
      case DriveSortMode.oldestFirst:
        sorted.sort((a, b) => a.sortDate.compareTo(b.sortDate));
      case DriveSortMode.largestFirst:
      case DriveSortMode.smallestFirst:
        break; // folders have no size — leave as-is
    }

    return [...defaults, ...sorted];
  }

  List<DriveFile> _applySortFiles(List<DriveFile> files) {
    final sorted = List<DriveFile>.from(files);
    switch (_sortMode) {
      case DriveSortMode.nameAZ:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case DriveSortMode.nameZA:
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case DriveSortMode.newestFirst:
        sorted.sort((a, b) => b.sortDate.compareTo(a.sortDate));
      case DriveSortMode.oldestFirst:
        sorted.sort((a, b) => a.sortDate.compareTo(b.sortDate));
      case DriveSortMode.largestFirst:
        sorted.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
      case DriveSortMode.smallestFirst:
        sorted.sort((a, b) => a.fileSizeBytes.compareTo(b.fileSizeBytes));
    }
    return sorted;
  }
}
