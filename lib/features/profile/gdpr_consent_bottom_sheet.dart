import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/profile/profile_models.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class GdprConsentBottomSheet extends StatefulWidget {
  const GdprConsentBottomSheet({
    super.key,
    required this.initial,
    required this.onConfirm,
    this.showHouseholdOption = true,
    this.isSubmitting = false,
  });

  final GdprConsentState initial;
  final Future<void> Function(GdprConsentState) onConfirm;
  final bool showHouseholdOption;
  final bool isSubmitting;

  @override
  State<GdprConsentBottomSheet> createState() => _GdprConsentBottomSheetState();
}

class _GdprConsentBottomSheetState extends State<GdprConsentBottomSheet> {
  late GdprConsentState _state = widget.initial;
  late bool _isSubmitting = widget.isSubmitting;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm(_state);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _toggle(int index) {
    setState(() {
      _state = switch (index) {
        0 => _state.copyWith(isMarktforschung: !_state.isMarktforschung),
        1 => _state.copyWith(
            isKundenveranstaltung: !_state.isKundenveranstaltung,
          ),
        2 => _state.copyWith(isPost: !_state.isPost),
        3 => _state.copyWith(isNewsletter: !_state.isNewsletter),
        4 => _state.copyWith(isHousehold: !_state.isHousehold),
        _ => _state,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = <({bool checked, String title, String subtitle})>[
      (
        checked: _state.isMarktforschung,
        title: l10n.tr('account.gdprOption1Title'),
        subtitle: l10n.tr('account.gdprOption1Subtitle'),
      ),
      (
        checked: _state.isKundenveranstaltung,
        title: l10n.tr('account.gdprOption2Title'),
        subtitle: l10n.tr('account.gdprOption2Subtitle'),
      ),
      (
        checked: _state.isPost,
        title: l10n.tr('account.gdprOption3Title'),
        subtitle: l10n.tr('account.gdprOption3Subtitle'),
      ),
      (
        checked: _state.isNewsletter,
        title: l10n.tr('account.gdprOption4Title'),
        subtitle: l10n.tr('account.gdprOption4Subtitle'),
      ),
    ];
    if (widget.showHouseholdOption) {
      options.add(
        (
          checked: _state.isHousehold,
          title: l10n.tr('account.gdprOption5Title'),
          subtitle: l10n.tr('account.gdprOption5Subtitle'),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFF6F6F6),
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  SelectNetworkIcons.preferencesConsent,
                  color: Color(0xFF808080),
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.tr('account.gdprTitle'),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 22 / 1.2,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tr('account.gdprDescription'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 21 / 1.2,
                color: Color(0xFF555555),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.tr('account.gdprPreferenceTitle'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 22 / 1.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.tr('account.gdprPreferenceSubtitle'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18 / 1.2,
                color: Color(0xFF808080),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: InkWell(
                      onTap: _isSubmitting ? null : () => _toggle(index),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: option.checked,
                            onChanged: _isSubmitting
                                ? null
                                : (_) => _toggle(index),
                            activeColor: AppColors.primaryRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            side: const BorderSide(
                              color: Color(0xFFCFCFCF),
                              width: 1.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.title,
                                  style: const TextStyle(
                                    fontFamily: 'Calibri',
                                    fontSize: 19 / 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D2D2D),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  option.subtitle,
                                  style: const TextStyle(
                                    fontFamily: 'Calibri',
                                    fontSize: 18 / 1.2,
                                    color: Color(0xFF808080),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC9C9C9)),
                        backgroundColor: const Color(0xFFF6F6F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        l10n.tr('tns.cancel').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primaryRed,
                        disabledBackgroundColor: const Color(0xFFE39CA6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.tr('tns.update').toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.2,
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
      ),
    );
  }
}
