import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Shows the delete account confirmation sheet.
/// Returns true if deletion was triggered (caller should not act further — sheet
/// handles logout internally).
Future<bool?> showAccountDeleteBottomSheet(
  BuildContext context, {
  required ProfileRepository repository,
  required AuthSessionController authSessionController,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AccountDeleteBottomSheet(
      repository: repository,
      authSessionController: authSessionController,
    ),
  );
}

class AccountDeleteBottomSheet extends StatefulWidget {
  const AccountDeleteBottomSheet({
    super.key,
    required this.repository,
    required this.authSessionController,
  });

  final ProfileRepository repository;
  final AuthSessionController authSessionController;

  @override
  State<AccountDeleteBottomSheet> createState() =>
      _AccountDeleteBottomSheetState();
}

class _AccountDeleteBottomSheetState extends State<AccountDeleteBottomSheet> {
  bool _isDeleting = false;

  Future<void> _onDeleteConfirmed() async {
    setState(() => _isDeleting = true);

    // Step 1 — fire and forget (NS: no response check)
    await widget.repository.dropRequest();

    // Step 2+3 — main deletion with optional challenge
    final ok = await widget.repository.deletePersonRelatedData();

    if (!mounted) return;

    if (ok) {
      // NS: show snackbar, wait 1 second, then logout
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.tr('ACCOUNT_DELETE_SUCCESSFULL_MESSAGE')),
            duration: const Duration(seconds: 5),
          ),
        );

      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      // Clear session + navigate to login
      await widget.authSessionController.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.login,
        (_) => false,
      );
    } else {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.tr('SOMETHING_WENT_WRONG'))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning icon — matches NS screenshot
          const Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: AppColors.primaryRed,
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            l10n.tr('tns.deleteAccountModalTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            l10n.tr('tns.deleteAccountModalSubtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          // Buttons row
          Row(
            children: [
              // CANCEL
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed:
                        _isDeleting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(color: AppColors.primaryRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      l10n.tr('tns.cancel').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // DELETE
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isDeleting ? null : _onDeleteConfirmed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.tr('tns.requestDelete').toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
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
