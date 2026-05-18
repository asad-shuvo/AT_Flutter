import 'dart:io';

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BiometricNotEnrolledDialog extends StatelessWidget {
  const BiometricNotEnrolledDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const BiometricNotEnrolledDialog(),
    );
  }

  Future<void> _openSettings() async {
    final uri = Platform.isIOS
        ? Uri.parse('App-Prefs:root=TOUCHID_PASSCODE')
        : Uri.parse('android.settings.BIOMETRIC_ENROLL');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppFormTokens.buttonRadius),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            MaterialIconsNS.fingerprint,
            size: 56,
            color: AppColors.primaryRed,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tr('tns.biometricNotEnrolled'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 15,
              color: Color(0xFF444444),
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.tr('tns.cancel').toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontWeight: FontWeight.w700,
              color: Color(0xFF808080),
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _openSettings();
          },
          child: Text(
            l10n.tr('tns.openSettings').toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontWeight: FontWeight.w700,
              color: AppColors.primaryRed,
            ),
          ),
        ),
      ],
    );
  }
}
