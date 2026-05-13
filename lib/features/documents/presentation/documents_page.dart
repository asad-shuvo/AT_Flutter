import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/drive/presentation/drive_page.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:flutter/material.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({
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

  @override
  Widget build(BuildContext context) {
    return DrivePage(
      driveRepository: driveRepository,
      householdController: householdController,
      userSessionCache: userSessionCache,
      dashboardRepository: dashboardRepository,
      contractsRepository: contractsRepository,
      notificationsRepository: notificationsRepository,
      authSessionController: authSessionController,
      appVersion: appVersion,
      syncNotificationService: syncNotificationService,
      profileRepository: profileRepository,
    );
  }
}
