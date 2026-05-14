import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdvisorInfoCard extends StatelessWidget {
  const AdvisorInfoCard({
    super.key,
    required this.insightsFuture,
    required this.onChatTap,
  });

  final Future<DashboardInsightsData> insightsFuture;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardInsightsData>(
      future: insightsFuture,
      builder: (context, snapshot) {
        final advisorInfo = snapshot.data?.advisorInfo;
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            advisorInfo == null;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  ),
                )
              : advisorInfo != null && advisorInfo.isAvailable
              ? _LoadedAdvisorCard(
                  advisorInfo: advisorInfo,
                  onChatTap: onChatTap,
                )
              : _EmptyAdvisorCard(),
        );
      },
    );
  }
}

class _LoadedAdvisorCard extends StatelessWidget {
  const _LoadedAdvisorCard({
    required this.advisorInfo,
    required this.onChatTap,
  });

  final DashboardAdvisorInfo advisorInfo;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              _AdvisorAvatar(advisorInfo: advisorInfo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.tr('tns.myFinancialAdvisor'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF808080),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      advisorInfo.displayName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Image.asset(
                  'assets/images/login/swisslife_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _AdvisorActionIcon(
                  icon: FilipIcons.advisorMail,
                  onTap: () => _launchEmail(context),
                ),
              ),
              Expanded(
                child: _AdvisorActionIcon(
                  icon: FilipIcons.advisorPhone,
                  onTap: () => _launchPhone(context),
                ),
              ),
              Expanded(
                child: _AdvisorActionIcon(
                  icon: FilipIcons.advisorChat,
                  onTap: onChatTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final email = advisorInfo.email?.trim();
    if (email == null || email.isEmpty) {
      _showActionMessage(context, context.l10n.tr('tns.emailNotFound'));
      return;
    }

    final launched = await launchUrl(Uri(scheme: 'mailto', path: email));
    if (!launched && context.mounted) {
      _showActionMessage(context, context.l10n.tr('tns.unknownError'));
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final phone = advisorInfo.phone?.trim();
    if (phone == null || phone.isEmpty) {
      _showActionMessage(context, context.l10n.tr('tns.invalidPhone'));
      return;
    }

    final launched = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!launched && context.mounted) {
      _showActionMessage(context, context.l10n.tr('tns.unknownError'));
    }
  }

  void _showActionMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AdvisorAvatar extends StatelessWidget {
  const _AdvisorAvatar({required this.advisorInfo});

  final DashboardAdvisorInfo advisorInfo;

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage =
        advisorInfo.profileImageUrl != null &&
        advisorInfo.profileImageUrl!.startsWith('http');

    return Container(
      width: 65,
      height: 65,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: hasNetworkImage
            ? Image.network(
                advisorInfo.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _InitialAvatar(
                  backgroundColor: Color(advisorInfo.avatarColorValue),
                  initials: advisorInfo.initials,
                ),
              )
            : _InitialAvatar(
                backgroundColor: Color(advisorInfo.avatarColorValue),
                initials: advisorInfo.initials,
              ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.backgroundColor, required this.initials});

  final Color backgroundColor;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AdvisorActionIcon extends StatelessWidget {
  const _AdvisorActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Icon(icon, color: const Color(0xFF808080), size: 25),
        ),
      ),
    );
  }
}

class _EmptyAdvisorCard extends StatelessWidget {
  const _EmptyAdvisorCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD8D8D8), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    FilipIcons.personOutline,
                    color: Color(0xFFB4B4B4),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tr('tns.myFinancialAdvisor'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF808080),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.tr('tns.noAdvisorAssigned'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Image.asset(
                  'assets/images/login/swisslife_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Text(
            context.l10n.tr('tns.noAdvisorAssignedSubheader'),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB4B4B4),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
