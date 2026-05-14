import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/chat/presentation/chat_page.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/contracts_page.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/drive/application/drive_controller.dart';
import 'package:filip_at_flutter/features/drive/presentation/drive_capture_preview_page.dart';
import 'package:filip_at_flutter/features/drive/data/drive_models.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:filip_at_flutter/features/explorer/presentation/filip_explorer_page.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/notifications/presentation/notifications_page.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/survey/data/survey_address_repository.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/real_estate_page.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/widgets/app_bottom_nav.dart';
import 'package:filip_at_flutter/shared/widgets/app_side_drawer.dart';
import 'package:filip_at_flutter/shared/widgets/app_top_bar.dart';
import 'package:filip_at_flutter/shared/widgets/contracts_household_member_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class DrivePage extends StatefulWidget {
  const DrivePage({
    super.key,
    required this.driveRepository,
    required this.householdController,
    required this.userSessionCache,
    required this.dashboardRepository,
    required this.contractsRepository,
    required this.notificationsRepository,
    required this.authSessionController,
    required this.appVersion,
    required this.syncNotificationService,
    this.profileRepository,
    this.surveyAddressRepository,
  });

  final DriveRepository driveRepository;
  final HouseholdMemberFilterController householdController;
  final UserSessionCache userSessionCache;
  final DashboardRepository dashboardRepository;
  final ContractsRepository contractsRepository;
  final NotificationsRepository notificationsRepository;
  final AuthSessionController authSessionController;
  final String appVersion;
  final SyncNotificationService syncNotificationService;
  final ProfileRepository? profileRepository;
  final SurveyAddressRepository? surveyAddressRepository;

  @override
  State<DrivePage> createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> {
  static const double _contentBottomClearance = 120;
  late final DriveController _controller;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late final Future<UserProfile?> _userProfileFuture;
  late Future<int> _unreadNotificationsFuture;

  @override
  void initState() {
    super.initState();
    _controller = DriveController(
      repository: widget.driveRepository,
      householdController: widget.householdController,
      customerUserId: '',
      customerPersonId: '',
    );
    widget.householdController.addListener(_onHouseholdChanged);
    _resolveSessionAndInit();
    _userProfileFuture = widget.dashboardRepository.fetchUserProfile();
    _unreadNotificationsFuture = widget.notificationsRepository.fetchUnreadCount();
  }

  Future<void> _resolveSessionAndInit() async {
    final session = await widget.userSessionCache.resolve();
    if (!mounted) return;
    _controller.setSession(
      customerUserId: session?.userId ?? '',
      customerPersonId: session?.personId ?? '',
    );
    await _controller.init();
  }

  void _onHouseholdChanged() => _controller.applyHouseholdFilter();

  @override
  void dispose() {
    widget.householdController.removeListener(_onHouseholdChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _controller.onSearchChanged(text);
    });
  }

  void _clearSearchBeforeFolderChange() {
    _searchDebounce?.cancel();
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    _controller.clearSearch();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsPage(
          dashboardRepository: widget.dashboardRepository,
          contractsRepository: widget.contractsRepository,
          notificationsRepository: widget.notificationsRepository,
          authSessionController: widget.authSessionController,
          appVersion: widget.appVersion,
          syncNotificationService: widget.syncNotificationService,
          householdController: widget.householdController,
          driveRepository: widget.driveRepository,
          userSessionCache: widget.userSessionCache,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _unreadNotificationsFuture = widget.notificationsRepository.fetchUnreadCount();
    });
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      drawer: AppSideDrawer(
        userProfileFuture: _userProfileFuture,
        dashboardRepository: widget.dashboardRepository,
        contractsRepository: widget.contractsRepository,
        notificationsRepository: widget.notificationsRepository,
        authSessionController: widget.authSessionController,
        appVersion: widget.appVersion,
        syncNotificationService: widget.syncNotificationService,
        householdController: widget.householdController,
        driveRepository: widget.driveRepository,
        userSessionCache: widget.userSessionCache,
        profileRepository: widget.profileRepository,
        surveyAddressRepository: widget.surveyAddressRepository,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (innerContext) => FutureBuilder<int>(
                future: _unreadNotificationsFuture,
                builder: (context, snapshot) => AppTopBar(
                  onMenuTap: () => Scaffold.of(innerContext).openDrawer(),
                  onNotificationTap: _openNotifications,
                  showBadge: (snapshot.data ?? 0) > 0,
                ),
              ),
            ),
            // Red header
            Container(
              width: double.infinity,
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFD82034), Color(0xFFA11C36)],
                ),
              ),
              child: Text(
                l10n.tr('tns.MyDRIVE'),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  fontSize: 24,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
            // Household filter bar
            ListenableBuilder(
              listenable: widget.householdController,
              builder: (context, _) {
                if (!widget.householdController.shouldShowFilter) {
                  return const SizedBox.shrink();
                }
                return ContractsHouseholdMemberFilterBar(
                  controller: widget.householdController,
                  onMemberTap: (personId) {
                    widget.householdController
                        .toggleVisibleMemberSelection(personId);
                    _controller.applyHouseholdFilter();
                  },
                  onArrowTap: () => _showHouseholdFilterSheet(context),
                );
              },
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _SearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onFilterTap: () => _showSortFilterSheet(context),
                hint: l10n.tr('tns.SEARCH_FOR_A_DOCUMENT_NAME'),
              ),
            ),
            // Content
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return _buildBody(context, l10n);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: null,
        onDashboardTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
        onHomeTap: () {
          final navigator = Navigator.of(context);
          navigator.popUntil((route) => route.isFirst);
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => FilipExplorerPage(
                dashboardRepository: widget.dashboardRepository,
                contractsRepository: widget.contractsRepository,
                notificationsRepository: widget.notificationsRepository,
                authSessionController: widget.authSessionController,
                appVersion: widget.appVersion,
                syncNotificationService: widget.syncNotificationService,
                householdController: widget.householdController,
                driveRepository: widget.driveRepository,
                userSessionCache: widget.userSessionCache,
                profileRepository: widget.profileRepository,
              ),
            ),
          );
        },
        onContractsTap: () => _openPage(
          ContractsPage(
            contractsRepository: widget.contractsRepository,
            dashboardRepository: widget.dashboardRepository,
            notificationsRepository: widget.notificationsRepository,
            authSessionController: widget.authSessionController,
            appVersion: widget.appVersion,
            syncNotificationService: widget.syncNotificationService,
            householdController: widget.householdController,
            driveRepository: widget.driveRepository,
            userSessionCache: widget.userSessionCache,
            profileRepository: widget.profileRepository,
          ),
        ),
        onRealEstateTap: () => _openPage(const RealEstatePage()),
        onMessagesTap: () => _openPage(const ChatPage()),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    final folders = _controller.displayFolders;
    final files = _controller.displayFiles;
    final totalCount = _controller.totalCount;
    final isGrid = _controller.viewMode == DriveViewMode.grid;

    return Column(
      children: [
        // Breadcrumbs (when inside a folder)
        if (_controller.breadcrumbs.length > 1)
          _BreadcrumbBar(
            breadcrumbs: _controller.breadcrumbs,
            onTap: (itemId) {
              _clearSearchBeforeFolderChange();
              _controller.navigateBreadcrumb(itemId);
            },
          ),
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.tr('tns.ALL_DOCUMENT')} ($totalCount)',
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textBody,
                  ),
                ),
              ),
              // Grid/list toggle
              _ViewToggleButton(
                isGrid: isGrid,
                onTap: _controller.toggleViewMode,
              ),
              const SizedBox(width: 6),
              // Add button
              if (_controller.hasCreatePermission)
                _AddButton(
                  onTap: () => _showAddSheet(context),
                ),
            ],
          ),
        ),
        // Items list
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification &&
                  n.metrics.extentAfter < 200 &&
                  !_controller.isLoadingMore) {
                _controller.loadMore();
              }
              return false;
            },
            child: isGrid
                ? _buildGridView(context, l10n, folders, files)
                : _buildListView(context, l10n, folders, files),
          ),
        ),
        if (_controller.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(
              color: AppColors.primaryRed,
              strokeWidth: 2,
            ),
          ),
      ],
    );
  }

  Widget _buildListView(
    BuildContext context,
    AppLocalizations l10n,
    List<DriveFolder> folders,
    List<DriveFile> files,
  ) {
    final items = <Widget>[];
    for (final folder in folders) {
      items.add(_FolderListTile(
        folder: folder,
        showMoreVert: _controller.canShowMoreVert(folder.ownerId),
        onTap: () {
          _clearSearchBeforeFolderChange();
          _controller.openFolder(folder.itemId, folder.name);
        },
        onMoreVert: folder.isDefault
            ? null
            : () => _showFolderMoreVert(context, folder),
        l10n: l10n,
      ));
    }
    for (final file in files) {
      items.add(_FileListTile(
        file: file,
        showMoreVert: _controller.canShowMoreVert(file.ownerId),
        onMoreVert: () => _showFileMoreVert(context, file),
        l10n: l10n,
      ));
    }

    if (items.isEmpty) {
      return _EmptyState(l10n: l10n);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, _contentBottomClearance),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => items[i],
    );
  }

  Widget _buildGridView(
    BuildContext context,
    AppLocalizations l10n,
    List<DriveFolder> folders,
    List<DriveFile> files,
  ) {
    final allItems = <Widget>[
      for (final folder in folders)
        _FolderGridCard(
          folder: folder,
          showMoreVert: _controller.canShowMoreVert(folder.ownerId),
          onTap: () {
            _clearSearchBeforeFolderChange();
            _controller.openFolder(folder.itemId, folder.name);
          },
          onMoreVert: folder.isDefault
              ? null
              : () => _showFolderMoreVert(context, folder),
          l10n: l10n,
        ),
      for (final file in files)
        _FileGridCard(
          file: file,
          showMoreVert: _controller.canShowMoreVert(file.ownerId),
          onMoreVert: () => _showFileMoreVert(context, file),
          l10n: l10n,
        ),
    ];

    if (allItems.isEmpty) return _EmptyState(l10n: l10n);

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, _contentBottomClearance),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: allItems.length,
      itemBuilder: (_, i) => allItems[i],
    );
  }

  // â”€â”€â”€ Bottom Sheets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _showHouseholdFilterSheet(BuildContext context) async {
    final result = await showContractsHouseholdFilterSheet(
      context,
      initialMode: widget.householdController.mode,
      initialHouseholdMembers: widget.householdController.copyHouseholdMembers(),
      initialBusinessMembers: widget.householdController.copyBusinessMembers(),
    );
    if (result != null && context.mounted) {
      widget.householdController.applySelection(
        mode: result.mode,
        householdMembers: result.householdMembers,
        businessMembers: result.businessMembers,
      );
      _controller.applyHouseholdFilter();
    }
  }

  Future<void> _showSortFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<DriveSortMode>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SortFilterSheet(current: _controller.sortMode),
    );
    if (selected != null) _controller.setSortMode(selected);
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _AddOptionsSheet(
        l10n: l10n,
        onCapturePhoto: () {
          Navigator.pop(sheetCtx);
          _captureAndUploadPhoto(context);
        },
        onUploadFile: () {
          Navigator.pop(sheetCtx);
          _showUploadSheet(context);
        },
        onCreateFolder: () {
          Navigator.pop(sheetCtx);
          _showCreateFolderSheet(context);
        },
      ),
    );
  }

  Future<void> _showUploadSheet(BuildContext context) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _UploadFileSheet(
        l10n: l10n,
        onConfirm: (bytes, fileName, contentType) async {
          Navigator.pop(sheetCtx);
          final ok = await _controller.uploadFile(
            fileName: fileName,
            bytes: bytes,
            contentType: contentType,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok
                    ? l10n.tr('tns.UPLOAD_SUCCESS')
                    : l10n.tr('tns.UPLOAD_FAILED')),
                backgroundColor:
                    ok ? Colors.green.shade700 : AppColors.primaryRed,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _showCreateFolderSheet(BuildContext context) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _CreateFolderSheet(
        l10n: l10n,
        onConfirm: (name) async {
          Navigator.pop(sheetCtx);
          final ok = await _controller.createFolder(name);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok
                    ? l10n.tr('tns.FOLDER_CREATED')
                    : l10n.tr('tns.FOLDER_CREATE_FAILED')),
                backgroundColor:
                    ok ? Colors.green.shade700 : AppColors.primaryRed,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _captureAndUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 90,
    );
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (!context.mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DriveCapturePreviewPage(
          imageBytes: bytes,
          controller: _controller,
        ),
      ),
    );
  }

  Future<void> _showFolderMoreVert(
      BuildContext context, DriveFolder folder) async {
    final l10n = context.l10n;
    final inArchive = DriveDefaultFolders.isArchivedContext(
        _controller.breadcrumbs.isNotEmpty
            ? _controller.breadcrumbs.first.itemId
            : null);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _FolderMoreVertSheet(
        folder: folder,
        l10n: l10n,
        isInArchiveContext: inArchive,
        onRename: () {
          Navigator.pop(sheetCtx);
          _showRenameSheet(
            context,
            initialName: folder.name,
            onConfirm: (newName) => _controller.renameFolder(folder, newName),
          );
        },
        onFavorite: () {
          Navigator.pop(sheetCtx);
          _controller.toggleFolderFavorite(folder);
        },
        onArchive: () {
          Navigator.pop(sheetCtx);
          _controller.archiveFolder(folder);
        },
        onRestore: () {
          Navigator.pop(sheetCtx);
          _controller.restoreFolder(folder);
        },
      ),
    );
  }

  Future<void> _showFileMoreVert(BuildContext context, DriveFile file) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _FileMoreVertSheet(
        file: file,
        l10n: l10n,
        isInArchiveContext: DriveDefaultFolders.isArchivedContext(
            _controller.currentFolderId),
        onRename: () {
          Navigator.pop(sheetCtx);
          _showRenameSheet(
            context,
            initialName: file.name.contains('.')
                ? file.name.substring(0, file.name.lastIndexOf('.'))
                : file.name,
            onConfirm: (newName) => _controller.renameFile(file, newName),
          );
        },
        onFavorite: () {
          Navigator.pop(sheetCtx);
          _controller.toggleFileFavorite(file);
        },
        onArchive: () {
          Navigator.pop(sheetCtx);
          _controller.archiveFile(file);
        },
        onRestore: () {
          Navigator.pop(sheetCtx);
          _controller.restoreFile(file);
        },
        onDownload: () {
          Navigator.pop(sheetCtx);
          _downloadFile(context, file);
        },
        onDelete: file.canPermanentDelete
            ? () async {
                Navigator.pop(sheetCtx);
                final confirmed = await _showDeleteConfirmSheet(context);
                if (confirmed != true) return;
                await _controller.permanentDeleteFile(file);
              }
            : null,
        onDetail: () {
          Navigator.pop(sheetCtx);
          _showFileDetailSheet(context, file);
        },
      ),
    );
  }

  Future<void> _showRenameSheet(
    BuildContext context, {
    required String initialName,
    required Future<bool> Function(String) onConfirm,
  }) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _RenameSheet(
        l10n: l10n,
        initialName: initialName,
        onConfirm: (name) async {
          Navigator.pop(sheetCtx);
          await onConfirm(name);
        },
      ),
    );
  }

  Future<void> _showFileDetailSheet(BuildContext context, DriveFile file) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FileDetailSheet(file: file, l10n: l10n),
    );
  }

  Future<void> _downloadFile(BuildContext context, DriveFile file) async {
    final rawUrl = file.url?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('tns.DOWNLOAD_FAILED'))),
      );
      return;
    }

    final normalized = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('tns.DOWNLOAD_FAILED'))),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('tns.DOWNLOAD_FAILED'))),
      );
    }
  }

  Future<bool?> _showDeleteConfirmSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DeleteConfirmSheet(l10n: context.l10n),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Search Bar
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    required this.hint,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: AppColors.primaryRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                color: AppColors.textBody,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.filter_alt_outlined,
                  color: AppColors.primaryRed, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Breadcrumb Bar
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.breadcrumbs, required this.onTap});

  final List<DriveBreadcrumb> breadcrumbs;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: breadcrumbs.length,
        separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
        ),
        itemBuilder: (_, i) {
          final crumb = breadcrumbs[i];
          final isLast = i == breadcrumbs.length - 1;
          return GestureDetector(
            onTap: isLast ? null : () => onTap(crumb.itemId),
            child: Center(
              child: Text(
                l10n.tr(crumb.name),
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 13,
                  color: isLast ? AppColors.primaryRed : AppColors.textMuted,
                  fontWeight:
                      isLast ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// View toggle button
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({required this.isGrid, required this.onTap});

  final bool isGrid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primaryRed),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          isGrid ? Icons.table_rows_rounded : Icons.grid_view_rounded,
          color: AppColors.primaryRed,
          size: 20,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primaryRed),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.add, color: AppColors.primaryRed, size: 20),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Folder list tile
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FolderListTile extends StatelessWidget {
  const _FolderListTile({
    required this.folder,
    required this.onTap,
    required this.showMoreVert,
    required this.l10n,
    this.onMoreVert,
  });

  final DriveFolder folder;
  final VoidCallback onTap;
  final bool showMoreVert;
  final AppLocalizations l10n;
  final VoidCallback? onMoreVert;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFCECEE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                _driveFolderIcon,
                color: AppColors.primaryRed,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n.tr(folder.name),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (folder.isFavorite)
              const Icon(_driveStarIcon, color: Color(0xFFF5A623), size: 22),
            if (showMoreVert && onMoreVert != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onMoreVert,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_vert, color: AppColors.textMuted, size: 24),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// File list tile
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FileListTile extends StatelessWidget {
  const _FileListTile({
    required this.file,
    required this.showMoreVert,
    required this.l10n,
    this.onMoreVert,
  });

  final DriveFile file;
  final bool showMoreVert;
  final AppLocalizations l10n;
  final VoidCallback? onMoreVert;

  @override
  Widget build(BuildContext context) {
    final sizeParts = <String>[file.fileType];
    if (file.fileSizeLabel.isNotEmpty) sizeParts.add(file.fileSizeLabel);
    final shortDate = _formatListDate(file.createDate);
    if (shortDate.isNotEmpty) sizeParts.add(shortDate);
    final subtitle = sizeParts.join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              _driveFileIcon,
              color: Color(0xFF888888),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                if (file.ownerName != null && file.ownerName!.isNotEmpty)
                  _OwnerAvatar(name: file.ownerName!),
              ],
            ),
          ),
          if (file.isFavorite)
            const Icon(_driveStarIcon, color: Color(0xFFF5A623), size: 22),
          if (showMoreVert && onMoreVert != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onMoreVert,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child:
                    Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Folder grid card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FolderGridCard extends StatelessWidget {
  const _FolderGridCard({
    required this.folder,
    required this.onTap,
    required this.showMoreVert,
    required this.l10n,
    this.onMoreVert,
  });

  final DriveFolder folder;
  final VoidCallback onTap;
  final bool showMoreVert;
  final AppLocalizations l10n;
  final VoidCallback? onMoreVert;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (folder.isFavorite)
              const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 8, right: 8),
                  child: Icon(_driveStarIcon, color: Color(0xFFF5A623), size: 22),
                ),
              )
            else
              const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCECEE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(_driveFolderIcon,
                      color: AppColors.primaryRed, size: 24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tr(folder.name),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showMoreVert && onMoreVert != null)
                    GestureDetector(
                      onTap: onMoreVert,
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.more_vert,
                            color: AppColors.textMuted, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// File grid card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FileGridCard extends StatelessWidget {
  const _FileGridCard({
    required this.file,
    required this.showMoreVert,
    required this.l10n,
    this.onMoreVert,
  });

  final DriveFile file;
  final bool showMoreVert;
  final AppLocalizations l10n;
  final VoidCallback? onMoreVert;

  @override
  Widget build(BuildContext context) {
    final sizeParts = <String>[file.fileType];
    if (file.fileSizeLabel.isNotEmpty) sizeParts.add(file.fileSizeLabel);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (file.isFavorite)
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8, right: 8),
                child: Icon(_driveStarIcon, color: Color(0xFFF5A623), size: 22),
              ),
            )
          else
            const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Icon(_driveFileIcon,
                    color: Color(0xFF888888), size: 24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 8, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showMoreVert && onMoreVert != null)
                  GestureDetector(
                    onTap: onMoreVert,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.more_vert,
                          color: AppColors.textMuted, size: 18),
                    ),
                  ),
              ],
            ),
          ),
          if (sizeParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
              child: Text(
                sizeParts.join(' • '),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (file.ownerName != null && file.ownerName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
              child: _OwnerAvatar(name: file.ownerName!),
            ),
        ],
      ),
    );
  }
}

const String _driveIconFamily = 'filip_at_iconpack_29022024';
const IconData _driveFolderIcon = IconData(0xE9C9, fontFamily: _driveIconFamily);
const IconData _driveFileIcon = IconData(0xE9DF, fontFamily: _driveIconFamily);
const IconData _driveStarIcon = IconData(0xE973, fontFamily: _driveIconFamily);
const IconData _driveUploadIcon = IconData(0xE913, fontFamily: _driveIconFamily);
const IconData _driveCameraIcon = IconData(0xEA1C, fontFamily: _driveIconFamily);
const IconData _driveAttachIcon = IconData(0xEA31, fontFamily: _driveIconFamily);
const IconData _driveDeleteIcon = IconData(0xE9F9, fontFamily: _driveIconFamily);
const IconData _driveRestoreIcon = IconData(0xE94C, fontFamily: _driveIconFamily);
const IconData _driveDownloadIcon = IconData(0xE9DD, fontFamily: _driveIconFamily);
const IconData _driveInfoIcon = IconData(0xE903, fontFamily: _driveIconFamily);
const IconData _driveArchiveIcon = IconData(0xEA29, fontFamily: _driveIconFamily);
const IconData _driveRenameIcon = IconData(0xE969, fontFamily: _driveIconFamily);

String _formatListDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final dt = DateTime.parse(raw).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  } catch (_) {
    return '';
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Owner avatar chip
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OwnerAvatar extends StatelessWidget {
  const _OwnerAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF3BAF8E),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Empty state
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        l10n.tr('tns.noDataFound'),
        style: const TextStyle(
          fontFamily: 'Calibri',
          fontSize: 15,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Sort / Filter sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SortFilterSheet extends StatelessWidget {
  const _SortFilterSheet({required this.current});

  final DriveSortMode current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      (DriveSortMode.nameZA, l10n.tr('tns.NameZA')),
      (DriveSortMode.nameAZ, l10n.tr('tns.NameAZ')),
      (DriveSortMode.largestFirst, l10n.tr('tns.LargestFileFirst')),
      (DriveSortMode.smallestFirst, l10n.tr('tns.SmallestFileFirst')),
      (DriveSortMode.newestFirst, l10n.tr('tns.NewestDateFirst')),
      (DriveSortMode.oldestFirst, l10n.tr('tns.OldestDateFirst')),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  color: AppColors.primaryRed, size: 22),
              const SizedBox(width: 10),
              Text(
                l10n.tr('tns.SearchFilter'),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final opt in options)
          InkWell(
            onTap: () => Navigator.pop(context, opt.$1),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      opt.$2,
                      style: TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 15,
                        color: opt.$1 == current
                            ? AppColors.primaryRed
                            : AppColors.textBody,
                        fontWeight: opt.$1 == current
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Add options sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AddOptionsSheet extends StatelessWidget {
  const _AddOptionsSheet({
    required this.l10n,
    required this.onCapturePhoto,
    required this.onUploadFile,
    required this.onCreateFolder,
  });

  final AppLocalizations l10n;
  final VoidCallback onCapturePhoto;
  final VoidCallback onUploadFile;
  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        _SheetItem(
          icon: _driveCameraIcon,
          label: l10n.tr('tns.capturePhoto'),
          onTap: onCapturePhoto,
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        _SheetItem(
          icon: _driveUploadIcon,
          label: l10n.tr('tns.UploadFile'),
          onTap: onUploadFile,
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        _SheetItem(
          icon: _driveFolderIcon,
          label: l10n.tr('tns.CreateNewFolder'),
          onTap: onCreateFolder,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Upload file sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _UploadFileSheet extends StatefulWidget {
  const _UploadFileSheet({required this.l10n, required this.onConfirm});

  final AppLocalizations l10n;
  final Future<void> Function(List<int> bytes, String fileName, String contentType)
      onConfirm;

  @override
  State<_UploadFileSheet> createState() => _UploadFileSheetState();
}

class _UploadFileSheetState extends State<_UploadFileSheet> {
  String? _fileName;
  List<int>? _bytes;
  bool _uploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _fileName = file.name;
      _bytes = file.bytes!.toList();
    });
  }

  void _clearSelectedFile() {
    setState(() {
      _fileName = null;
      _bytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  _driveUploadIcon,
                  color: AppColors.primaryRed,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.tr('tns.UploadFile'),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (_fileName != null) ...[
                  Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD9D9D9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        l10n.tr('tns.maximumFileUploaded'),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                GestureDetector(
                  onTap: _uploading ? null : (_fileName == null ? _pickFile : null),
                  child: Container(
                    width: double.infinity,
                    height: _fileName == null ? 100 : 76,
                    padding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: _fileName == null ? 0 : 0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCCCCCC)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _fileName == null
                        ? Center(
                            child: Text(
                              l10n.tr('tns.clickHereToSelectFile'),
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Row(
                            children: [
                              const Icon(
                                _driveAttachIcon,
                                color: AppColors.textMuted,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _fileName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Calibri',
                                    fontSize: 14,
                                    color: AppColors.textBody,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _uploading ? null : _clearSelectedFile,
                                icon: const Icon(
                                  _driveDeleteIcon,
                                  color: AppColors.textMuted,
                                  size: 28,
                                ),
                                splashRadius: 20,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bytes != null
                      ? AppColors.primaryRed
                      : AppColors.primaryRed.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                onPressed: _bytes == null || _uploading
                    ? null
                    : () async {
                        setState(() => _uploading = true);
                        await widget.onConfirm(
                          _bytes!,
                          _fileName!,
                          'application/octet-stream',
                        );
                      },
                child: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        l10n.tr('tns.confirm').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Create folder sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CreateFolderSheet extends StatefulWidget {
  const _CreateFolderSheet({required this.l10n, required this.onConfirm});

  final AppLocalizations l10n;
  final Future<void> Function(String name) onConfirm;

  @override
  State<_CreateFolderSheet> createState() => _CreateFolderSheetState();
}

class _CreateFolderSheetState extends State<_CreateFolderSheet> {
  final _nameCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  _driveFolderIcon,
                  color: AppColors.primaryRed,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.tr('tns.CreateNewFolder'),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.tr('tns.FolderName'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nameCtrl,
              maxLength: 40,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 15,
                color: AppColors.textBody,
              ),
              decoration: InputDecoration(
                hintText: l10n.tr('tns.EnterFolderName'),
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryRed),
                ),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _nameCtrl.text.trim().length >= 2
                      ? AppColors.primaryRed
                      : AppColors.primaryRed.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                onPressed: _nameCtrl.text.trim().length < 2 || _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await widget.onConfirm(_nameCtrl.text.trim());
                      },
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        l10n.tr('tns.create').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Rename sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({
    required this.l10n,
    required this.initialName,
    required this.onConfirm,
  });

  final AppLocalizations l10n;
  final String initialName;
  final Future<void> Function(String) onConfirm;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final TextEditingController _ctrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.tr('tns.Rename'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textBody,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              maxLength: 40,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontFamily: 'Calibri', fontSize: 15),
              decoration: InputDecoration(
                counterText: '',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryRed),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ctrl.text.trim().length >= 2
                      ? AppColors.primaryRed
                      : AppColors.primaryRed.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                onPressed: _ctrl.text.trim().length < 2 || _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await widget.onConfirm(_ctrl.text.trim());
                      },
                child: Text(
                  l10n.tr('tns.save').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Folder more-vert sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FolderMoreVertSheet extends StatelessWidget {
  const _FolderMoreVertSheet({
    required this.folder,
    required this.l10n,
    required this.isInArchiveContext,
    required this.onRename,
    required this.onFavorite,
    required this.onArchive,
    required this.onRestore,
  });

  final DriveFolder folder;
  final AppLocalizations l10n;
  final bool isInArchiveContext;
  final VoidCallback onRename;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        if (folder.isArchived) ...[
          _SheetItem(
              icon: Icons.restore,
              label: l10n.tr('tns.Restore'),
              onTap: onRestore),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ] else ...[
          _SheetItem(
              icon: Icons.edit_outlined,
              label: l10n.tr('tns.Rename'),
              onTap: onRename),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _SheetItem(
            icon: folder.isFavorite ? Icons.star : Icons.star_outline,
            label: folder.isFavorite
                ? l10n.tr('tns.UnFavorite')
                : l10n.tr('tns.Favorite'),
            onTap: onFavorite,
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _SheetItem(
              icon: Icons.archive_outlined,
              label: l10n.tr('tns.Archive'),
              onTap: onArchive),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// File more-vert sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FileMoreVertSheet extends StatelessWidget {
  const _FileMoreVertSheet({
    required this.file,
    required this.l10n,
    required this.isInArchiveContext,
    required this.onRename,
    required this.onFavorite,
    required this.onArchive,
    required this.onRestore,
    required this.onDownload,
    required this.onDetail,
    this.onDelete,
  });

  final DriveFile file;
  final AppLocalizations l10n;
  final bool isInArchiveContext;
  final VoidCallback onRename;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onDownload;
  final VoidCallback onDetail;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        if (file.isArchived) ...[
          _SheetItem(
              icon: _driveRestoreIcon,
              label: l10n.tr('tns.Restore'),
              onTap: onRestore),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _SheetItem(
              icon: _driveDownloadIcon,
              label: l10n.tr('tns.Download'),
              onTap: onDownload),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _SheetItem(
              icon: _driveInfoIcon,
              label: l10n.tr('tns.DetailsInfo'),
              onTap: onDetail),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          if (onDelete != null) ...[
            _SheetItem(
                icon: _driveDeleteIcon,
                label: l10n.tr('tns.DeletePermanently'),
                onTap: onDelete!,
                isDestructive: true),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ],
        ] else ...[
          _SheetItem(
              icon: _driveRenameIcon,
              label: l10n.tr('tns.Rename'),
              onTap: onRename),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _SheetItem(
            icon: file.isFavorite ? Icons.star : Icons.star_outline,
            label: file.isFavorite
                ? l10n.tr('tns.UnFavorite')
                : l10n.tr('tns.Favorite'),
            onTap: onFavorite,
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _SheetItem(
              icon: _driveDownloadIcon,
              label: l10n.tr('tns.Download'),
              onTap: onDownload),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _SheetItem(
              icon: _driveInfoIcon,
              label: l10n.tr('tns.DetailsInfo'),
              onTap: onDetail),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _SheetItem(
              icon: _driveArchiveIcon,
              label: l10n.tr('tns.Archive'),
              onTap: onArchive),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// File detail sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FileDetailSheet extends StatelessWidget {
  const _FileDetailSheet({required this.file, required this.l10n});

  final DriveFile file;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final createdDate = _formatDate(
      (file.metaData?['ExternalDocumentCreateDate']?['Value'] as String?) ??
          file.createDate,
    );
    final rows = [
      ('Name', file.name),
      ('Size', file.fileSizeLabel.isNotEmpty ? file.fileSizeLabel : '-'),
      ('Type', file.fileType.isNotEmpty ? file.fileType : '-'),
      ('Created By', file.ownerName ?? '-'),
      ('Date Created (UTC)', createdDate),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.primaryRed, size: 22),
              const SizedBox(width: 10),
              Text(
                l10n.tr('tns.DetailsInfo'),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final row in rows) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.$1,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      color: AppColors.textBody,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class _DeleteConfirmSheet extends StatelessWidget {
  const _DeleteConfirmSheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            _driveDeleteIcon,
            color: AppColors.primaryRed,
            size: 84,
          ),
          const SizedBox(height: 40),
          Text(
            l10n.tr('tns.deleteFileHeader'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 18,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.tr('tns.cancel').toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryRed,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    minimumSize: const Size.fromHeight(56),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.tr('tns.confirm').toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Shared sheet item row
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SheetItem extends StatelessWidget {
  const _SheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppColors.primaryRed : AppColors.primaryRed;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                color:
                    isDestructive ? AppColors.primaryRed : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


