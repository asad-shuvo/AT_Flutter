import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.authSessionController,
  });

  final AuthSessionController authSessionController;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricEnabled = false;

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
          l10n.tr('preferences.title'),
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
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _PreferenceCard(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        MaterialIconsNS.fingerprint,
                        size: 24,
                        color: Color(0xFF808080),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            l10n.tr('preferences.biometricTitle'),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.95,
                        child: SwitchTheme(
                          data: SwitchThemeData(
                            trackOutlineColor: MaterialStateProperty.all(
                              Colors.transparent,
                            ),
                            thumbColor: MaterialStateProperty.resolveWith<Color>((
                              states,
                            ) {
                              if (states.contains(MaterialState.selected)) {
                                return AppColors.primaryRed;
                              }
                              return const Color(0xFFC6C6C6);
                            }),
                            trackColor: MaterialStateProperty.resolveWith<Color>((
                              states,
                            ) {
                              if (states.contains(MaterialState.selected)) {
                                return const Color(0x33D82034);
                              }
                              return const Color(0xFFE3E3E3);
                            }),
                          ),
                          child: Switch(
                            value: _biometricEnabled,
                            onChanged: (value) {
                              setState(() {
                                _biometricEnabled = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l10n.tr('preferences.biometricDescription'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF808080),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _PreferenceCard(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FilipIcons.pin,
                        size: 24,
                        color: Color(0xFF808080),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            l10n.tr('preferences.pinTitle'),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l10n.tr('preferences.pinDescription'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF808080),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _showPendingMessage(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryRed,
                        side: const BorderSide(color: Color(0xFFCCCCCC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        l10n.tr('preferences.resetPin'),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.4,
                        ),
                      ),
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

  void _showPendingMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.tr('preferences.actionPending'))),
      );
  }

}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
