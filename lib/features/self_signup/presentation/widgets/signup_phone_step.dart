import 'dart:convert';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/self_signup/application/self_signup_controller.dart';
import 'package:filip_at_flutter/features/self_signup/data/country_data.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

CountryInfo _defaultCountry() =>
    kAllCountries.firstWhere((c) => c.iso2 == 'AT');

class SignupPhoneStep extends StatefulWidget {
  const SignupPhoneStep({super.key, required this.controller});
  final SelfSignupController controller;

  @override
  State<SignupPhoneStep> createState() => _SignupPhoneStepState();
}

class _SignupPhoneStepState extends State<SignupPhoneStep> {
  final _phoneController = TextEditingController();
  final _captchaController = TextEditingController();
  late CountryInfo _selectedCountry = _defaultCountry();
  bool _isValid = false;

  Uint8List? _captchaBytes;
  String _captchaBase64Cached = '';

  Uint8List? _getCaptchaBytes() {
    final b64 = widget.controller.captchaImageBase64;
    if (b64 != _captchaBase64Cached) {
      _captchaBase64Cached = b64;
      _captchaBytes = b64.isNotEmpty ? base64Decode(b64) : null;
    }
    return _captchaBytes;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _checkValid() {
    final phone = _phoneController.text.trim();
    final captcha = _captchaController.text.trim();
    final ok = phone.length >= 6 && captcha.isNotEmpty;
    if (ok != _isValid) setState(() => _isValid = ok);
  }

  Future<void> _submit() async {
    if (!_isValid) return;
    final ok = await widget.controller.submitCaptchaAndProceed(
      _captchaController.text.trim(),
    );
    if (!ok || !mounted) return;
    final fullPhone =
        '${_selectedCountry.dialCode}${_phoneController.text.trim()}';
    widget.controller.session.userCountryCode = _selectedCountry.dialCode;
    await widget.controller.sendPhoneCode(fullPhone);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Center(child: _buildIllustration()),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    l10n.tr('tns.yourPhoneNumber'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontStyle: FontStyle.italic,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    l10n.tr('tns.yourEmailAddressSuccessfullyVerified'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      color: Color(0xFF7A7A7A),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                signupFieldLabel('${l10n.tr('tns.mobileNumber')} *'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCountryPicker(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => _checkValid(),
                        style: signupInputStyle,
                        decoration: signupInputDecoration(
                          l10n.tr('tns.phoneNumber'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (c.isCaptchaLoading)
                  const SizedBox(
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD91F32),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else
                  _buildCaptchaImage(c),
                const SizedBox(height: 10),
                signupFieldLabel('${l10n.tr('tns.captcha')} *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _captchaController,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _checkValid(),
                  onFieldSubmitted: (_) => _submit(),
                  style: signupInputStyle,
                  decoration: signupInputDecoration(l10n.tr('tns.captcha')),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        signupBottomButton(
          label: '${l10n.tr('tns.continue').toUpperCase()} >',
          isEnabled: _isValid && !c.isLoading,
          isLoading: c.isLoading,
          onTap: _submit,
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return Image.network(
      'https://az-cdn.selise.biz/selisecdn/cdn/slnetwork/assets/mobile_app_images/onboarding_phone.png',
      width: 130,
      height: 130,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) =>
          const Icon(Icons.phone_android, size: 80, color: Color(0xFFD91F32)),
    );
  }

  Widget _buildCountryPicker() {
    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC9C9C9), width: 1.0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FlagEmoji(emoji: _selectedCountry.flagEmoji),
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
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CountryPickerSheet(
        selected: _selectedCountry,
        onSelect: (country) {
          setState(() => _selectedCountry = country);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildCaptchaImage(SelfSignupController c) {
    final bytes = _getCaptchaBytes();
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              border: Border.all(color: const Color(0xFFD0D0D0), width: 0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: bytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      bytes,
                      gaplessPlayback: true,
                      fit: BoxFit.contain,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: c.loadCaptcha,
          icon: const Icon(Icons.refresh, color: Color(0xFF555555), size: 24),
        ),
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected, required this.onSelect});

  final CountryInfo selected;
  final ValueChanged<CountryInfo> onSelect;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
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
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
                        _FlagEmoji(emoji: country.flagEmoji),
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

class _FlagEmoji extends StatelessWidget {
  const _FlagEmoji({required this.emoji});
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: const TextStyle(fontSize: 20));
  }
}
