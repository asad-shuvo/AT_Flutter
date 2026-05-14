import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/survey/presentation/widgets/survey_common_widgets.dart';
import 'package:filip_at_flutter/features/survey/presentation/widgets/survey_styles.dart';
import 'package:flutter/material.dart';

class SurveyPreviousAnswerPage extends StatelessWidget {
  const SurveyPreviousAnswerPage({
    super.key,
    required this.dashboardRepository,
  });

  final DashboardRepository dashboardRepository;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: SurveyStyles.pageBackground,
      appBar: SurveyTopBar(title: l10n.tr('PREVIOUS_ANSWER')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: Text(
                ' 25.04.2026',
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF808080),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SurveyQuestionCard(
              serial: l10n.tr('QUES_ONE'),
              question: l10n.tr('QUES_ONE_TITLE'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.tr('NAME')}: ${'Asaduzzaman Shuvo'}', style: SurveyStyles.questionText),
                  const SizedBox(height: 4),
                  Text('${l10n.tr('EMAIL')}: ${'asaduzzaman.shuvo@selise.ch'}', style: SurveyStyles.questionText),
                  const SizedBox(height: 4),
                  Text('${l10n.tr('PHONE_NUMBER')}: ${'+8801867512994'}', style: SurveyStyles.questionText),
                  const SizedBox(height: 4),
                  Text('${l10n.tr('ADDRESS')}: ${'Bakultala, 3622, Fohra, Bangladesh'}', style: SurveyStyles.questionText),
                  const SizedBox(height: 10),
                  Text(
                    l10n.tr('Q1NO'),
                    style: SurveyStyles.bodyBold,
                  ),
                ],
              ),
            ),
            SurveyQuestionCard(
              serial: l10n.tr('QUES_TWO'),
              question: l10n.tr('QUES_TWO_TITLE'),
              child: Text(l10n.tr('NO'), style: SurveyStyles.bodyBold),
            ),
            SurveyQuestionCard(
              serial: l10n.tr('QUES_THREE'),
              question: l10n.tr('QUES_THREE_TITLE'),
              child: Text(l10n.tr('NO'), style: SurveyStyles.bodyBold),
            ),
            SurveyQuestionCard(
              serial: l10n.tr('QUES_FOUR'),
              question: l10n.tr('QUES_FOUR_TITLE'),
              child: Text(l10n.tr('NO'), style: SurveyStyles.bodyBold),
            ),
          ],
        ),
      ),
    );
  }
}


