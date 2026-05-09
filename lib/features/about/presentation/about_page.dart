import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.appVersion});

  final String appVersion;

  static const String _imprintUrl =
      'https://www.swisslife-select.at/home/footer/impressum.html';
  static const String _dataPrivacyUrl =
      'https://www.swisslife-select.at/home/footer/datenschutz.html';
  static const String _legalUrl =
      'https://www.swisslife-select.at/home/footer/nutzungsbedingungen_filip.html';
  static const String _seliseUrl = 'https://selise.ch/';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final year = DateTime.now().year;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF555555)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.tr('about.title'),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8E8E8)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Logo row ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final rowWidth = constraints.maxWidth > 320
                      ? 320.0
                      : constraints.maxWidth;
                  return SizedBox(
                    width: rowWidth,
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Image.asset(
                              'assets/images/login/splash_logo.png',
                              width: 100,
                              height: 35,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Center(
                            child: Container(
                              width: 1,
                              height: 45,
                              color: const Color(0xFFCCCCCC),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              'assets/images/login/swisslife_logo.png',
                              width: 120,
                              height: 45,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 42),

              // ── Version ──
              Text(
                '${l10n.tr('about.version')} $appVersion',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF333333),
                ),
              ),

              const SizedBox(height: 32),

              // ── Copyright ──
              Text(
                '${l10n.tr('about.copyright')} $year. ${l10n.tr('about.allRightsReserved')}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF808080),
                ),
              ),

              const SizedBox(height: 2),

              // ── Technology & Design by SELISE ──
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openUrl(_seliseUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: '${l10n.tr('about.technologyDesign')} ',
                          style: const TextStyle(color: Color(0xFF808080)),
                        ),
                        TextSpan(
                          text: l10n.tr('about.selise'),
                          style: const TextStyle(color: Color(0xFFD82034)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── IMPRINT | DATA PRIVACY | LEGAL ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LinkButton(
                    label: l10n.tr('about.imprint'),
                    onTap: () => _openUrl(_imprintUrl),
                  ),
                  const _Pipe(),
                  _LinkButton(
                    label: l10n.tr('about.dataPrivacy'),
                    onTap: () => _openUrl(_dataPrivacyUrl),
                  ),
                  const _Pipe(),
                  _LinkButton(
                    label: l10n.tr('about.legal'),
                    onTap: () => _openUrl(_legalUrl),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD82034),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _Pipe extends StatelessWidget {
  const _Pipe();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '|',
        style: TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
      ),
    );
  }
}
