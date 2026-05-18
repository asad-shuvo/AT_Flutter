import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/material.dart';

class PostLoginBiometricSheet extends StatefulWidget {
  const PostLoginBiometricSheet({super.key, required this.repository});

  final ProfileRepository repository;

  static Future<bool> show(
    BuildContext context, {
    required ProfileRepository repository,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PostLoginBiometricSheet(repository: repository),
      ),
    );
    return result == true;
  }

  @override
  State<PostLoginBiometricSheet> createState() =>
      _PostLoginBiometricSheetState();
}

class _PostLoginBiometricSheetState extends State<PostLoginBiometricSheet> {
  bool _dontAskAgain = false;

  Future<void> _onSkip() async {
    if (_dontAskAgain) {
      await widget.repository.setDontAskBiometricPrompt(value: true);
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Icon(
                    MaterialIconsNS.fingerprint,
                    size: 20,
                    color: const Color(0xFF9A9A9A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.tr('tns.fingerprint'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      color: Color(0xFF5A5551),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        SelectNetworkIcons.fingerprint,
                        size: 80,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.tr('tns.enableFingerprintQuestion'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 16,
                          color: Color(0xFF444444),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: GestureDetector(
                onTap: () => setState(() => _dontAskAgain = !_dontAskAgain),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _dontAskAgain,
                        onChanged: (v) =>
                            setState(() => _dontAskAgain = v ?? false),
                        activeColor: AppColors.primaryRed,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.tr('tns.dontAskAgain'),
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        color: Color(0xFF5A5551),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _onSkip,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5A5551),
                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppFormTokens.buttonRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          l10n.tr('tns.skipNow').toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppFormTokens.buttonRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          l10n.tr('tns.enable').toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
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
}
