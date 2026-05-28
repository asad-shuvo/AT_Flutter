import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _iconFont = 'filip_at_iconpack_29022024';

// PUA chars set via PowerShell
const _iconEmail = '';
const _iconPhone = '';
const _iconChat = '';
const _iconInfo = '';

class AdvisorInfo {
  const AdvisorInfo({
    required this.displayName,
    required this.title,
    this.profileImageUrl,
    this.colorCode = const Color(0xFF43B883),
    this.email,
    this.phone,
  });

  final String displayName;
  final String title;
  final String? profileImageUrl;
  final Color colorCode;
  final String? email;
  final String? phone;
}

Future<void> showContactAdvisorSheet({
  required BuildContext context,
  AdvisorInfo? advisor,
  VoidCallback? onChatTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => _ContactAdvisorSheet(advisor: advisor, onChatTap: onChatTap),
  );
}

class _ContactAdvisorSheet extends StatelessWidget {
  const _ContactAdvisorSheet({this.advisor, this.onChatTap});

  final AdvisorInfo? advisor;
  final VoidCallback? onChatTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHeader(
            title: l10n.tr('contactAdvisor'),
            onClose: () => Navigator.of(context).pop(),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: advisor != null
                ? _AdvisorCard(advisor: advisor!, onChatTap: onChatTap)
                : _NoAdvisorCard(l10n: l10n),
          ),
          // Thick separator bar like NS-AT `.bar`
          Container(height: 10, color: const Color(0xFFF2F2F2)),
          _BrokerInfoSection(l10n: l10n),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 22, color: Color(0xFF666666)),
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisorCard extends StatelessWidget {
  const _AdvisorCard({required this.advisor, this.onChatTap});

  final AdvisorInfo advisor;
  final VoidCallback? onChatTap;

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          // Top info row — #FAFAFA background
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                _AdvisorAvatar(advisor: advisor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          advisor.title,
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF808080),
                          ),
                        ),
                        Text(
                          advisor.displayName,
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // Logo — white bg, borderRadius 0 10 0 0
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/login/swisslife_logo.png',
                      width: 62,
                      height: 62,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom icons row
          Row(
            children: [
              _ContactButton(
                icon: _iconEmail,
                align: MainAxisAlignment.start,
                padding: const EdgeInsets.only(left: 24, top: 12, bottom: 12, right: 12),
                onTap: advisor.email != null
                    ? () => _launch('mailto:${advisor.email}')
                    : null,
              ),
              _ContactButton(
                icon: _iconPhone,
                align: MainAxisAlignment.center,
                padding: const EdgeInsets.all(12),
                onTap: advisor.phone != null
                    ? () => _launch('tel:${advisor.phone}')
                    : null,
              ),
              _ContactButton(
                icon: _iconChat,
                align: MainAxisAlignment.end,
                padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12, left: 12),
                onTap: onChatTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdvisorAvatar extends StatelessWidget {
  const _AdvisorAvatar({required this.advisor});

  final AdvisorInfo advisor;

  @override
  Widget build(BuildContext context) {
    // Outer white circle with lightgray border (65x65)
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: advisor.profileImageUrl != null
          ? ClipOval(
              child: Image.network(
                advisor.profileImageUrl!,
                width: 63,
                height: 63,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _InitialCircle(advisor: advisor),
              ),
            )
          : _InitialCircle(advisor: advisor),
    );
  }
}

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.advisor});

  final AdvisorInfo advisor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 63,
      height: 63,
      decoration: BoxDecoration(
        color: advisor.colorCode,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          advisor.displayName.isNotEmpty
              ? advisor.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.align,
    required this.padding,
    required this.onTap,
  });

  final String icon;
  final MainAxisAlignment align;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: align,
            children: [
              Text(
                icon,
                style: TextStyle(
                  fontFamily: _iconFont,
                  fontSize: 25,
                  color: onTap != null
                      ? const Color(0xFF808080)
                      : const Color(0xFFCACACA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAdvisorCard extends StatelessWidget {
  const _NoAdvisorCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                // Placeholder avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5E5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD8D8D8), width: 2),
                  ),
                  child: const Center(
                    child: Text(
                      '',
                      style: TextStyle(
                        fontFamily: _iconFont,
                        fontSize: 22,
                        color: Color(0xFFB4B4B4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tr('myFinancialAdvisor'),
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 12,
                            color: Color(0xFF808080),
                          ),
                        ),
                        Text(
                          l10n.tr('noAdvisorAssigned'),
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/login/swisslife_logo.png',
                      width: 62,
                      height: 62,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Text(
              l10n.tr('noAdvisorAssignedSubheader'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                color: Color(0xFFB4B4B4),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrokerInfoSection extends StatelessWidget {
  const _BrokerInfoSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                _iconInfo,
                style: TextStyle(
                  fontFamily: _iconFont,
                  fontSize: 28,
                  color: Color(0xFFD82034),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.tr('aboutEstateBroker'),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 18,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.tr('brokerInfoDetails'),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
