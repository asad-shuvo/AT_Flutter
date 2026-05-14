import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class SurveyCompleteBottomSheet extends StatelessWidget {
  const SurveyCompleteBottomSheet({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB23A4D), width: 2),
            ),
            child: const Icon(Icons.check, color: Color(0xFFB23A4D), size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.tr('SURVEY_SUCCESS_TITLE'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tr('SURVEY_SUCCESS_SUBTITLE'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: Color(0xFF333333),
              height: 1.4,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD82034),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.tr('GO_TO_SURVEY').toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
