import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/profile/presentation/profile_page.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/survey/data/survey_address_repository.dart';
import 'package:filip_at_flutter/features/survey/presentation/survey_previous_answer_page.dart';
import 'package:filip_at_flutter/features/survey/presentation/survey_service_check_page.dart';
import 'package:filip_at_flutter/features/survey/presentation/widgets/survey_common_widgets.dart';
import 'package:filip_at_flutter/features/survey/presentation/widgets/survey_styles.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:flutter/material.dart';

class SurveyPage extends StatelessWidget {
  const SurveyPage({
    super.key,
    required this.dashboardRepository,
    required this.authSessionController,
    required this.syncNotificationService,
    this.profileRepository,
    this.surveyAddressRepository,
  });

  final DashboardRepository dashboardRepository;
  final AuthSessionController authSessionController;
  final SyncNotificationService syncNotificationService;
  final ProfileRepository? profileRepository;
  final SurveyAddressRepository? surveyAddressRepository;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = profileRepository;

    return Scaffold(
      backgroundColor: SurveyStyles.pageBackground,
      appBar: SurveyTopBar(title: l10n.tr('SURVEY')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: SurveyStyles.sectionBackground,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/dashboard/survey_form.png',
                    width: 118,
                    height: 118,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.tr('SURVEY'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 28,
                      fontStyle: FontStyle.italic,
                      color: SurveyStyles.titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 300,
                    child: Text(
                      l10n.tr('SURVEY_PAGE_TITLE'),
                      textAlign: TextAlign.center,
                      style: SurveyStyles.body,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SurveyActionButton(
                    label: l10n.tr('TAKE_SERVICE_CHECK').toUpperCase(),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SurveyServiceCheckPage(
                            dashboardRepository: dashboardRepository,
                            profileRepository: profileRepository,
                            surveyAddressRepository: surveyAddressRepository,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SurveyActionButton(
                    label: l10n.tr('VIEW_PREVIOUS_ANSWER').toUpperCase(),
                    outlined: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SurveyPreviousAnswerPage(
                            dashboardRepository: dashboardRepository,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              color: SurveyStyles.sectionBackground,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: 300,
                    child: Text(
                      l10n.tr('SURVEY_INFO_UPDATE_MESSAGE'),
                      textAlign: TextAlign.center,
                      style: SurveyStyles.body,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SurveyActionButton(
                    label: l10n.tr('UPDATE_MY_PERSONAL_DETAILS').toUpperCase(),
                    outlined: true,
                    leading: const Icon(
                      FilipIcons.children,
                      color: Color(0xFFB3364B),
                      size: 20,
                    ),
                    onTap: repo == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProfilePage(
                                  dashboardRepository: dashboardRepository,
                                  authSessionController: authSessionController,
                                  syncNotificationService:
                                      syncNotificationService,
                                  profileRepository: repo,
                                ),
                              ),
                            );
                          },
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

