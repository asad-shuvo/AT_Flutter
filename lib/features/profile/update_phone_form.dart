import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/profile/update_phone_controller.dart';
import 'package:filip_at_flutter/features/self_signup/data/country_data.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_shared.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/services.dart';

CountryInfo _defaultPhoneCountry() =>
    kAllCountries.firstWhere((c) => c.iso2 == 'AT');

class UpdatePhoneForm extends StatefulWidget {
  const UpdatePhoneForm({
    super.key,
    required this.controller,
    required this.currentPhone,
    required this.onConfirm,
  });

  final UpdatePhoneController controller;
  final String currentPhone;
  final ValueChanged<String> onConfirm;

  @override
  State<UpdatePhoneForm> createState() => _UpdatePhoneFormState();
}

class _UpdatePhoneFormState extends State<UpdatePhoneForm> {
  final TextEditingController _digitsController = TextEditingController();
  late CountryInfo _selectedCountry = _defaultPhoneCountry();
  String? _localError;

  @override
  void dispose() {
    _digitsController.dispose();
    super.dispose();
  }

  String _normalizePhoneDigits(String rawDigits) {
    final trimmed = rawDigits.trim();
    if (trimmed.isEmpty) return '';
    final numeric = int.tryParse(trimmed);
    if (numeric != null) return numeric.toString();
    return trimmed.replaceFirst(RegExp(r'^0+'), '');
  }

  String get _fullPhone =>
      '${_selectedCountry.dialCode}${_normalizePhoneDigits(_digitsController.text)}';

  void _onConfirmTap() {
    final l10n = context.l10n;
    final digits = _digitsController.text.trim();
    if (digits.length < 9 || digits.length > 14) {
      setState(() => _localError = l10n.tr('tns.phoneInvalid'));
      return;
    }
    final full = _fullPhone;
    if (full == widget.currentPhone) {
      setState(() => _localError = l10n.tr('tns.phoneUnchanged'));
      return;
    }
    setState(() => _localError = null);
    Navigator.of(context).pop();
    widget.onConfirm(full);
  }

  void _showCountryPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PhoneCountryPickerSheet(
        selected: _selectedCountry,
        onSelect: (country) {
          setState(() => _selectedCountry = country);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digitLen = _digitsController.text.trim().length;
    final hasDigits = digitLen >= 9 && digitLen <= 14;
    final isEnabled = hasDigits && !widget.controller.submitting;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              SelectNetworkIcons.phone,
                              color: Color(0xFF808080),
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.tr('tns.changePhoneNumber'),
                              style: TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.tr('tns.updatePhoneSubHeader'),
                          style: TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF808080),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        signupFieldLabel(l10n.tr('tns.mobileNumber')),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _showCountryPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFC9C9C9),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _PhoneFlagEmoji(
                                      emoji: _selectedCountry.flagEmoji,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${_selectedCountry.dialCode})',
                                      style: const TextStyle(
                                        fontFamily: 'Calibri',
                                        fontSize: 15,
                                        color: Color(0xFF2D2D2D),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      size: 18,
                                      color: Color(0xFF555555),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _digitsController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) =>
                                    setState(() => _localError = null),
                                onSubmitted: (_) => _onConfirmTap(),
                                style: signupInputStyle,
                                decoration: signupInputDecoration(
                                  '${l10n.tr('tns.phoneNumber')}*',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_localError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _localError!,
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 14,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isEnabled ? _onConfirmTap : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primaryRed,
                        disabledBackgroundColor: const Color(0xFFE39CA6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius)),
                      ),
                      child: const Text(
                        'UPDATE',
                        style: TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhoneFlagEmoji extends StatelessWidget {
  const _PhoneFlagEmoji({required this.emoji});
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: const TextStyle(fontSize: 20));
  }
}

class _PhoneCountryPickerSheet extends StatefulWidget {
  const _PhoneCountryPickerSheet({
    required this.selected,
    required this.onSelect,
  });

  final CountryInfo selected;
  final ValueChanged<CountryInfo> onSelect;

  @override
  State<_PhoneCountryPickerSheet> createState() =>
      _PhoneCountryPickerSheetState();
}

class _PhoneCountryPickerSheetState extends State<_PhoneCountryPickerSheet> {
  final _searchController = TextEditingController();
  List<CountryInfo> _filtered = kAllCountries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? kAllCountries
          : kAllCountries
                .where(
                  (c) =>
                      c.name.toLowerCase().contains(q) ||
                      c.dialCode.contains(q),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = context.l10n;
    return SizedBox(
      height: screenHeight * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              autofocus: false,
              style: const TextStyle(fontFamily: 'Calibri', fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.tr('tns.search'),
                hintStyle: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 14,
                  color: Color(0xFFAAAAAA),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFFAAAAAA),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                  borderSide: const BorderSide(
                    color: Color(0xFFD91F32),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                final country = _filtered[index];
                final isSelected = country.iso2 == widget.selected.iso2;
                return InkWell(
                  onTap: () => widget.onSelect(country),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        _PhoneFlagEmoji(emoji: country.flagEmoji),
                        const SizedBox(width: 10),
                        Text(
                          '(${country.dialCode})',
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 14,
                            color: Color(0xFF555555),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            country.name,
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 15,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            size: 20,
                            color: Color(0xFFD91F32),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

