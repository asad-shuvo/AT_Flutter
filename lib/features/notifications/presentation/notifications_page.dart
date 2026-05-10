import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/chat/presentation/chat_page.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/contracts_page.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/notifications/data/notification_item_model.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/real_estate_page.dart';
import 'package:filip_at_flutter/features/explorer/presentation/filip_explorer_page.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/widgets/app_bottom_nav.dart';
import 'package:filip_at_flutter/shared/widgets/app_side_drawer.dart';
import 'package:filip_at_flutter/shared/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.dashboardRepository,
    required this.contractsRepository,
    required this.notificationsRepository,
    required this.authSessionController,
    required this.appVersion,
    required this.syncNotificationService,
    required this.householdController,
  });

  final DashboardRepository dashboardRepository;
  final ContractsRepository contractsRepository;
  final NotificationsRepository notificationsRepository;
  final AuthSessionController authSessionController;
  final String appVersion;
  final SyncNotificationService syncNotificationService;
  final HouseholdMemberFilterController householdController;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const int _pageSize = 100;

  late final Future<UserProfile?> _userProfileFuture;
  late final ScrollController _scrollController;
  late Future<int> _unreadNotificationsFuture;

  final List<NotificationItem> _items = <NotificationItem>[];
  int _pageNumber = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = widget.dashboardRepository.fetchUserProfile();
    _unreadNotificationsFuture = widget.notificationsRepository
        .fetchUnreadCount();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _items.clear();
      _pageNumber = 1;
      _hasMore = true;
      _isInitialLoading = true;
      _isLoadingMore = false;
      _loadError = null;
    });
    await _loadPage(pageNumber: 1, reset: true);
  }

  Future<void> _loadMore() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _loadPage(pageNumber: _pageNumber + 1, reset: false);
  }

  Future<void> _loadPage({required int pageNumber, required bool reset}) async {
    try {
      final data = await widget.notificationsRepository.fetchNotifications(
        pageNumber: pageNumber,
        pageSize: _pageSize,
      );

      final unreadIds = data.items
          .where((item) => !item.isRead && item.id.isNotEmpty)
          .map((item) => item.id)
          .toList(growable: false);
      if (unreadIds.isNotEmpty) {
        await widget.notificationsRepository.markNotificationsAsRead(unreadIds);
      }

      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(data.items);
        } else {
          _items.addAll(data.items);
        }
        _pageNumber = pageNumber;
        _hasMore = data.hasMore;
        _isInitialLoading = false;
        _isLoadingMore = false;
        _loadError = null;
        _unreadNotificationsFuture = widget.notificationsRepository
            .fetchUnreadCount();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        _loadError = error;
      });
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 220) {
      return;
    }
    _loadMore();
  }

  Future<void> _openContracts() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContractsPage(
          contractsRepository: widget.contractsRepository,
          dashboardRepository: widget.dashboardRepository,
          notificationsRepository: widget.notificationsRepository,
          authSessionController: widget.authSessionController,
          appVersion: widget.appVersion,
          syncNotificationService: widget.syncNotificationService,
          householdController: widget.householdController,
        ),
      ),
    );
    if (!mounted) return;
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Builder(
        builder: (innerContext) => SafeArea(
          child: Column(
            children: [
              FutureBuilder<int>(
                future: _unreadNotificationsFuture,
                builder: (context, snapshot) {
                  return AppTopBar(
                    onMenuTap: () => Scaffold.of(innerContext).openDrawer(),
                    onNotificationTap: () {},
                    showBadge: (snapshot.data ?? 0) > 0,
                    notificationIconColor: AppColors.primaryRed,
                  );
                },
              ),
              _NotificationHeader(title: context.l10n.tr('tns.notification')),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: null,
        onDashboardTap: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
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
              ),
            ),
          );
        },
        onContractsTap: () => _openContracts(),
        onRealEstateTap: () => _openPage(const RealEstatePage()),
        onMessagesTap: () => _openPage(const ChatPage()),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
          ),
        ),
      );
    }

    if (_loadError != null && _items.isEmpty) {
      return _NotificationMessage(
        message: context.l10n.tr('tns.notificationLoadError'),
      );
    }

    if (_items.isEmpty) {
      return _NotificationMessage(
        message: context.l10n.tr('tns.youDontHaveNotification'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      color: AppColors.primaryRed,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 120),
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryRed,
                    ),
                  ),
                ),
              ),
            );
          }
          return _NotificationCard(item: _items[index]);
        },
      ),
    );
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      color: AppColors.primaryRed,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            fontSize: 24,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 8,
            height: 82,
            child: item.isRead
                ? const SizedBox.shrink()
                : const Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 4,
                      height: 62,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          SizedBox(
            width: 62,
            height: 82,
            child: Center(
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD8D8D8)),
                ),
                child: Center(
                  child: Icon(
                    IconData(
                      item.iconCodePoint,
                      fontFamily: 'filip_at_iconpack_29022024',
                    ),
                    size: 30,
                    color: const Color(0xFF808080),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.resolve(item.titleKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _subtitleText(context, item),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF808080),
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
            child: Text(
              _timeLabel(context, item.createdTime),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Color(0xFF808080),
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitleText(BuildContext context, NotificationItem item) {
    final l10n = context.l10n;
    final subtitle = l10n.resolve(item.subtitleKey);

    if (item.titleKey == 'SLS_INVESTMENT_NOTIFICATION_TITLE') {
      return subtitle;
    }

    final buffer = StringBuffer();
    final subtitleName = item.subtitleName?.trim();
    if (subtitleName != null && subtitleName.isNotEmpty) {
      buffer.write('"$subtitleName" ');
    }
    buffer.write(subtitle);

    if (item.subtitleDate != null) {
      buffer.write(' ${_formatDate(context, item.subtitleDate!)}');
    }
    return buffer.toString();
  }

  String _timeLabel(BuildContext context, DateTime createdAt) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(createdAt);

    if (diff.inSeconds < 60) {
      return l10n.tr('tns.justNow').toUpperCase();
    }

    if (diff.inMinutes < 60) {
      final unit = diff.inMinutes == 1 ? l10n.tr('min') : l10n.tr('mins');
      return _agoLabel(l10n, diff.inMinutes, unit).toUpperCase();
    }

    if (diff.inHours < 24) {
      final unit = diff.inHours == 1 ? l10n.tr('hour') : l10n.tr('hours');
      return _agoLabel(l10n, diff.inHours, unit).toUpperCase();
    }

    if (diff.inDays < 31) {
      final unit = diff.inDays == 1 ? l10n.tr('day') : l10n.tr('days');
      return _agoLabel(l10n, diff.inDays, unit).toUpperCase();
    }

    return _formatDate(context, createdAt).toUpperCase();
  }

  String _agoLabel(AppLocalizations l10n, int value, String unit) {
    final template = l10n.resolve('value1_value2_ago');
    return template
        .replaceAll('{{value1}}', '$value')
        .replaceAll('{{value2}}', unit);
  }

  String _formatDate(BuildContext context, DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    if (context.l10n.isGerman) {
      final month = value.month.toString().padLeft(2, '0');
      return '$day.$month.${value.year}';
    }

    const months = <String>[
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final month = months[value.month - 1];
    return '$day $month, ${value.year}';
  }
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 15,
            color: Color(0xFF656565),
          ),
        ),
      ),
    );
  }
}
