import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/utils/logout_utils.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.dashboardRepository,
    required this.authSessionController,
  });

  final DashboardRepository dashboardRepository;
  final AuthSessionController authSessionController;

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
          l10n.tr('account.title'),
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
        future: dashboardRepository.fetchUserProfile(),
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
                    label: l10n.tr('account.fullName'),
                    value: profile.displayName,
                  ),
                  _AccountActionSection(
                    label: l10n.tr('account.emailAddress'),
                    value: profile.email,
                    actionLabel: l10n.tr('account.updateEmail'),
                    onTap: () => _showPendingMessage(context),
                  ),
                  _AccountActionSection(
                    label: l10n.tr('account.phoneNumber'),
                    value: profile.phoneNumber,
                    actionLabel: l10n.tr('account.updatePhone'),
                    onTap: () => _showPendingMessage(context),
                  ),
                  _PasswordSection(
                    label: l10n.tr('account.password'),
                    actionLabel: l10n.tr('account.changePassword'),
                    onTap: () => _showPendingMessage(context),
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
                      l10n.tr('account.preferences').toUpperCase(),
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
                    title: l10n.tr('account.consentsTitle'),
                    description: l10n.tr('account.consentsDescription'),
                    onTap: () => _showPendingMessage(context),
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
                          l10n.tr('account.deleteAccount'),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          l10n.tr('dashboard.drawerLogout'),
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 360),
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
        SnackBar(content: Text(context.l10n.tr('account.actionPending'))),
      );
  }

  Future<void> _handleLogout(BuildContext context) {
    return performLogout(
      context,
      authSessionController: authSessionController,
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

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
);
