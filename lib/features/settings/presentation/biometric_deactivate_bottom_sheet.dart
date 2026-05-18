import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/material.dart';

class BiometricDeactivateBottomSheet extends StatefulWidget {
  const BiometricDeactivateBottomSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BiometricDeactivateBottomSheet(),
    );
  }

  @override
  State<BiometricDeactivateBottomSheet> createState() =>
      _BiometricDeactivateBottomSheetState();
}

class _BiometricDeactivateBottomSheetState
    extends State<BiometricDeactivateBottomSheet> {
  final _passwordController = TextEditingController();
  bool _passwordHidden = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(SelectNetworkIcons.warning, size: 64, color: AppColors.primaryRed),
          const SizedBox(height: 16),
          Text(
            l10n.tr('tns.biometrincDeactivateInstruction'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              color: Color(0xFF444444),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.tr('tns.enterPasswordToConfirm'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              color: Color(0xFF444444),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: _passwordHidden,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              color: Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: l10n.tr('tns.password'),
              hintStyle: const TextStyle(
                fontFamily: 'Calibri',
                color: Color(0xFFA6A6A6),
                fontSize: 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordHidden
                      ? SelectNetworkIcons.eyeDisabled
                      : SelectNetworkIcons.eye,
                  color: const Color(0xFF808080),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _passwordHidden = !_passwordHidden),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                borderSide: const BorderSide(color: Color(0xFFC9C9C9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                borderSide: const BorderSide(color: Color(0xFFC9C9C9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                borderSide:
                    const BorderSide(color: AppColors.primaryRed, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppFormTokens.buttonRadius),
                      ),
                    ),
                    child: Text(
                      l10n.tr('tns.cancel').toUpperCase(),
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
                  height: 48,
                  child: FilledButton(
                    onPressed: _passwordController.text.isNotEmpty
                        ? () => Navigator.of(context)
                            .pop(_passwordController.text)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      disabledBackgroundColor: const Color(0xFFD3D3D3),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppFormTokens.buttonRadius),
                      ),
                    ),
                    child: Text(
                      l10n.tr('tns.confirm').toUpperCase(),
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
        ],
      ),
    );
  }
}
