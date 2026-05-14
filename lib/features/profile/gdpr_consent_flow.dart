import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/profile/gdpr_consent_bottom_sheet.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:flutter/material.dart';

class GdprConsentFlow {
  static Future<void> open({
    required BuildContext context,
    required ProfileRepository repository,
    required bool showHouseholdOption,
    SyncNotificationService? syncNotificationService,
  }) async {
    final initial = await repository.fetchGdprConsent();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => GdprConsentBottomSheet(
        initial: initial,
        showHouseholdOption: showHouseholdOption,
        onConfirm: (next) async {
          final result = await repository.updateGdprConsent(next);
          if (!context.mounted) return;
          if (!result.isSuccess) {
            _showSnack(context, context.l10n.tr('tns.consentCouldNotUpdated'));
            return;
          }

          _showSnack(context, context.l10n.tr('tns.gdprSyncSubtitle'));
          final payload = await _waitForGdprSyncNotification(syncNotificationService);
          if (!context.mounted) return;

          final isSuccess = payload != null && _isGdprSyncSuccess(payload);
          if (isSuccess) {
            Navigator.of(context).pop();
            _showSnack(context, context.l10n.tr('tns.consentsUpdatedSuccessfully'));
            return;
          }
          _showSnack(context, context.l10n.tr('tns.gdprFailedSubTitle'));
        },
      ),
    );
  }

  static Future<Map<String, dynamic>?> _waitForGdprSyncNotification(
    SyncNotificationService? syncService,
  ) async {
    if (syncService == null) return null;
    try {
      return await syncService.gdprConsentSync.stream.first;
    } catch (_) {
      return null;
    }
  }

  static bool _isGdprSyncSuccess(Map<String, dynamic> payload) {
    final value = payload['value']?.toString() ?? payload['responseValue']?.toString();
    if (value == '200') return true;

    final message = payload['message'];
    if (message is Map) {
      final text = message['Text']?.toString().toLowerCase() ?? '';
      if (text.contains('successfully sync')) return true;
    }
    return false;
  }

  static void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

