import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/profile/captcha_bottom_sheet.dart';
import 'package:filip_at_flutter/features/profile/gdpr_consent_flow.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/profile/update_email_controller.dart';
import 'package:filip_at_flutter/features/profile/update_email_form.dart';
import 'package:filip_at_flutter/features/profile/update_password_controller.dart';
import 'package:filip_at_flutter/features/profile/update_password_form.dart';
import 'package:filip_at_flutter/features/profile/update_phone_controller.dart';
import 'package:filip_at_flutter/features/profile/update_phone_form.dart';
import 'package:filip_at_flutter/features/profile/verification_code_sheet.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/utils/logout_utils.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.dashboardRepository,
    required this.authSessionController,
    this.syncNotificationService,
    this.profileRepository,
    this.showHouseholdConsent = true,
  });

  final DashboardRepository dashboardRepository;
  final AuthSessionController authSessionController;
  final SyncNotificationService? syncNotificationService;
  final ProfileRepository? profileRepository;
  final bool showHouseholdConsent;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UpdateEmailController? _emailController;
  UpdatePhoneController? _phoneController;
  UpdatePasswordController? _passwordController;
  String? _phoneNumberOverride;

  @override
  void initState() {
    super.initState();
    final repository = widget.profileRepository;
    if (repository != null) {
      _emailController = UpdateEmailController(repository: repository);
      _phoneController = UpdatePhoneController(repository: repository);
      _passwordController = UpdatePasswordController(repository: repository);
    }
  }

  @override
  void dispose() {
    _emailController?.dispose();
    _phoneController?.dispose();
    _passwordController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(FilipIcons.back, color: Color(0xFF808080), size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.tr('tns.myAccountHeader'),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF666666),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E5E5)),
        ),
      ),
      body: FutureBuilder<UserProfile?>(
        future: widget.dashboardRepository.fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }
          final profile = snapshot.data ?? _emptyProfile;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 164,
                    child: Center(child: _ProfileAvatar(profile: profile)),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
                  _AccountInfoSection(
                    label: l10n.tr('tns.fullName'),
                    value: profile.displayName,
                  ),
                  _AccountActionSection(
                    label: l10n.tr('tns.emailAddress'),
                    value: profile.email,
                    actionLabel: l10n.tr('tns.updateEmail'),
                    onTap: () => _startEmailUpdateFlow(
                      context: context,
                      currentEmail: profile.email,
                    ),
                  ),
                  _AccountActionSection(
                    label: l10n.tr('tns.phoneNumber'),
                    value: _phoneNumberOverride ?? profile.phoneNumber,
                    actionLabel: l10n.tr('tns.updatePhone'),
                    onTap: () => _startPhoneUpdateFlow(
                      context: context,
                      currentPhone: _phoneNumberOverride ?? profile.phoneNumber,
                    ),
                  ),
                  _PasswordSection(
                    label: l10n.tr('tns.password'),
                    actionLabel: l10n.tr('tns.changePassword'),
                    onTap: () => _startPasswordUpdateFlow(context),
                  ),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBFBFB),
                      border: Border(
                        top: BorderSide(color: Color(0xFFE5E5E5)),
                        bottom: BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.tr('tns.preferences').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.2,
                        color: Color(0xFF808080),
                      ),
                    ),
                  ),
                  _PreferencesSection(
                    title: l10n.tr('tns.myConsentsAndPreferences'),
                    description: l10n.tr('tns.myConsentsAndPreferencesDescription'),
                    onTap: () => _openConsentModal(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _showPendingMessage(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryRed,
                          side: const BorderSide(color: Color(0xFFD2D2D2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          l10n.tr('tns.deleteAccount'),
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPendingMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.tr('tns.retry'))),
      );
  }

  Future<void> _openConsentModal(BuildContext context) async {
    final repository = widget.profileRepository;
    if (repository == null) {
      _showPendingMessage(context);
      return;
    }
    await GdprConsentFlow.open(
      context: context,
      repository: repository,
      showHouseholdOption: widget.showHouseholdConsent,
      syncNotificationService: widget.syncNotificationService,
    );
  }

  // ── Email flow ────────────────────────────────────────────────────────────

  Future<void> _startEmailUpdateFlow({
    required BuildContext context,
    required String currentEmail,
  }) async {
    final controller = _emailController;
    if (controller == null) {
      _showPendingMessage(context);
      return;
    }
    controller.resetFlow();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => CaptchaBottomSheet(
        controller: controller,
        onVerified: (captchaVerificationCode) {
          _openUpdateEmailSheet(
            context: context,
            currentEmail: currentEmail,
            captchaVerificationCode: captchaVerificationCode,
          );
        },
      ),
    );
  }

  Future<void> _openUpdateEmailSheet({
    required BuildContext context,
    required String currentEmail,
    required String captchaVerificationCode,
  }) async {
    final controller = _emailController;
    if (controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UpdateEmailForm(
        controller: controller,
        currentEmail: currentEmail,
        onConfirm: (newEmail) async {
          final success = await controller.startEmailFlow(
            currentEmail: currentEmail,
            newEmail: newEmail,
            captchaVerificationCode: captchaVerificationCode,
            language: Localizations.localeOf(context).languageCode == 'de'
                ? 'de-DE'
                : 'en-US',
          );
          if (!success || !mounted) {
            _showErrorCode(context, controller.flowErrorCode);
            return;
          }
          _openEmailVerificationSheet(context);
        },
      ),
    );
  }

  Future<void> _openEmailVerificationSheet(BuildContext context) async {
    final controller = _emailController;
    if (controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) => VerificationCodeSheet(
        controller: controller,
        title: context.l10n.tr('tns.changeEmailAddress'),
        icon: SelectNetworkIcons.email,
        descriptionText:
            '${context.l10n.tr('tns.verificationCodeTitleForEmail')} ${controller.newEmail}',
        onConfirm: (code) async {
          final success = await controller.confirmVerificationCode(code);
          if (!success || !mounted) {
            _showErrorCode(context, controller.flowErrorCode);
            return;
          }
          if (!mounted) return;
          Navigator.of(context).pop();
          final messenger = ScaffoldMessenger.of(context);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(context.l10n.tr('tns.consentsUpdatedSuccessfully')),
              ),
            );
          await Future<void>.delayed(const Duration(milliseconds: 1000));
          if (!mounted) return;
          await widget.authSessionController.clearRememberMeInfo();
          if (!mounted) return;
          await performLogout(
            context,
            authSessionController: widget.authSessionController,
          );
        },
        onResend: () async {
          if (!mounted) return;
          Navigator.of(context).pop();
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            builder: (_) => CaptchaBottomSheet(
              controller: controller,
              onVerified: (captchaVerificationCode) async {
                final ok = await controller.resendVerificationCode(
                  captchaVerificationCode,
                );
                if (!mounted) return;
                if (!ok) {
                  _showErrorCode(context, controller.flowErrorCode);
                  return;
                }
                _openEmailVerificationSheet(context);
              },
            ),
          );
        },
      ),
    );
  }

  // ── Phone flow ────────────────────────────────────────────────────────────

  Future<void> _startPhoneUpdateFlow({
    required BuildContext context,
    required String currentPhone,
  }) async {
    final controller = _phoneController;
    if (controller == null) {
      _showPendingMessage(context);
      return;
    }
    controller.resetFlow();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => CaptchaBottomSheet(
        controller: controller,
        onVerified: (captchaVerificationCode) {
          _openUpdatePhoneSheet(
            context: context,
            currentPhone: currentPhone,
            captchaVerificationCode: captchaVerificationCode,
          );
        },
      ),
    );
  }

  Future<void> _openUpdatePhoneSheet({
    required BuildContext context,
    required String currentPhone,
    required String captchaVerificationCode,
  }) async {
    final controller = _phoneController;
    if (controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UpdatePhoneForm(
        controller: controller,
        currentPhone: currentPhone,
        onConfirm: (newPhone) async {
          final success = await controller.startPhoneFlow(
            currentPhone: currentPhone,
            newPhone: newPhone,
            captchaVerificationCode: captchaVerificationCode,
            language: Localizations.localeOf(context).languageCode == 'de'
                ? 'de-DE'
                : 'en-US',
          );
          if (!success || !mounted) {
            _showErrorCode(context, controller.flowErrorCode);
            return;
          }
          _openPhoneVerificationSheet(context);
        },
      ),
    );
  }

  Future<void> _openPhoneVerificationSheet(BuildContext context) async {
    final controller = _phoneController;
    if (controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) => VerificationCodeSheet(
        controller: controller,
        title: context.l10n.tr('tns.changePhoneNumber'),
        icon: SelectNetworkIcons.phone,
        descriptionText:
            '${context.l10n.tr('tns.verificationCodeTitleForPhoneNumber')} ${controller.newPhone}',
        onConfirm: (code) async {
          final success = await controller.confirmVerificationCode(code);
          if (!success || !mounted) {
            _showErrorCode(context, controller.flowErrorCode);
            return;
          }
          if (!mounted) return;
          setState(() {
            _phoneNumberOverride = controller.newPhone;
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(context.l10n.tr('tns.consentsUpdatedSuccessfully')),
              ),
            );
        },
        onResend: () async {
          if (!mounted) return;
          Navigator.of(context).pop();
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            builder: (_) => CaptchaBottomSheet(
              controller: controller,
              onVerified: (captchaVerificationCode) async {
                final ok = await controller.resendPhoneCode(captchaVerificationCode);
                if (!mounted) return;
                if (!ok) {
                  _showErrorCode(context, controller.flowErrorCode);
                  return;
                }
                _openPhoneVerificationSheet(context);
              },
            ),
          );
        },
      ),
    );
  }

  // ── Password flow ─────────────────────────────────────────────────────────

  Future<void> _startPasswordUpdateFlow(BuildContext context) async {
    final controller = _passwordController;
    if (controller == null) {
      _showPendingMessage(context);
      return;
    }
    controller.reset();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => UpdatePasswordForm(
        controller: controller,
        onConfirm: (oldPassword, newPassword) async {
          final success = await controller.changePassword(
            oldPassword: oldPassword,
            newPassword: newPassword,
          );
          if (!mounted) return;
          if (!success) {
            _showPasswordError(context, controller.flowErrorCode);
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(context.l10n.tr('tns.passwordUpdateSuccess')),
              ),
            );
          await Future<void>.delayed(const Duration(milliseconds: 1000));
          if (!mounted) return;
          await widget.authSessionController.clearRememberMeInfo();
          if (!mounted) return;
          await performLogout(
            context,
            authSessionController: widget.authSessionController,
          );
        },
      ),
    );
  }

  void _showPasswordError(BuildContext context, String? code) {
    final l10n = context.l10n;
    final text = switch (code) {
      'OLD_PASSWORD_NOT_MATCHED' => l10n.tr('tns.currentPasswordNotMatched'),
      'PREVIOUS_PASSWORD' => l10n.tr('tns.currentPasswordNotMatched'),
      _ => l10n.tr('tns.passwordUpdateFailed'),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _showErrorCode(BuildContext context, String? code) {
    final l10n = context.l10n;
    final text = switch (code) {
      'USER_EXISTS_WITH_NEW_CONTACT' => l10n.tr('USER_ALREADY_EXIST_WITH_THIS_CONTACT'),
      '2FA_CODE_IS_NOT_VALID' => l10n.tr('tns.twoFacodeInvalid'),
      'CAPTCHA_NOT_MATCHED' => l10n.tr('tns.captchaNotMatchError'),
      _ => l10n.tr('tns.retry'),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.resolvedProfileImageUrl;
    if (imageUrl != null) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _ProfileAvatarFallback(profile: profile);
          },
        ),
      );
    }
    return _ProfileAvatarFallback(profile: profile);
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  const _ProfileAvatarFallback({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Color(profile.avatarColorValue),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        profile.initials.isEmpty ? '-' : profile.initials,
        style: const TextStyle(
          fontFamily: 'Calibri',
          fontSize: 35,
          fontWeight: FontWeight.w800,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
}

class _AccountInfoSection extends StatelessWidget {
  const _AccountInfoSection({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label),
          const SizedBox(height: 4),
          _SectionValue(value),
        ],
      ),
    );
  }
}

class _AccountActionSection extends StatelessWidget {
  const _AccountActionSection({
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onTap,
  });

  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 8, 20, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(label),
                const SizedBox(height: 4),
                _SectionValue(value),
              ],
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordSection extends StatelessWidget {
  const _PasswordSection({
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  final String label;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(13, 0, 20, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(label),
                const SizedBox(height: 4),
                const Text(
                  '********',
                  style: TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.fromLTRB(13, 0, 20, 0),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                SelectNetworkIcons.preferencesConsent,
                size: 24,
                color: Color(0xFF808080),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF808080),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF808080),
      ),
    );
  }
}

class _SectionValue extends StatelessWidget {
  const _SectionValue(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 16,
        fontWeight: FontWeight.w300,
        color: Color(0xFF333333),
      ),
    );
  }
}

const UserProfile _emptyProfile = UserProfile(
  displayName: '-',
  email: '-',
  phoneNumber: '-',
  avatarColorValue: 0xFF10B377,
  profileImageUrl: null,
);
