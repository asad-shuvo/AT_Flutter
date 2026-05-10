import 'package:filip_at_flutter/features/self_signup/application/self_signup_controller.dart';
import 'package:filip_at_flutter/features/self_signup/data/country_data.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_shared.dart';
import 'package:flutter/material.dart';

const List<String> kSalutations = ['Mr.', 'Mrs.'];
const List<String> kGenders = ['Male', 'Female', 'Others'];

class SignupFullFormStep extends StatefulWidget {
  const SignupFullFormStep({super.key, required this.controller});
  final SelfSignupController controller;

  @override
  State<SignupFullFormStep> createState() => _SignupFullFormStepState();
}

class _SignupFullFormStepState extends State<SignupFullFormStep> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _postNominalCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _repeatPasswordCtrl = TextEditingController();

  String? _salutation;
  String? _selectedGender;
  // Stores ISO2 country code (e.g. "AT") — matches NativeScript payload Key
  String? _selectedCountryCode;
  String? _selectedNationalityCode;
  DateTime? _dateOfBirth;
  bool _agreedToTerms = false;
  bool _isPasswordHidden = true;
  bool _isRepeatPasswordHidden = true;
  bool _passwordTouched = false;

  static final _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[-_!*@#$,.;?§%^&+=/]).{6,300}$',
  );

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _postNominalCtrl.dispose();
    _designationCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _passwordCtrl.dispose();
    _repeatPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (_salutation == null) return false;
    if (_firstNameCtrl.text.trim().length < 2) return false;
    if (_lastNameCtrl.text.trim().length < 2) return false;
    if (_dateOfBirth == null) return false;
    if (_selectedGender == null) return false;
    if (_streetCtrl.text.trim().length < 2) return false;
    if (_cityCtrl.text.trim().length < 2) return false;
    if (_postalCtrl.text.trim().length < 2) return false;
    if (_selectedCountryCode == null) return false;
    if (_selectedNationalityCode == null) return false;
    if (!_passwordRegex.hasMatch(_passwordCtrl.text)) return false;
    if (_passwordCtrl.text != _repeatPasswordCtrl.text) return false;
    if (!_agreedToTerms) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_isFormValid) return;
    final dob = _dateOfBirth!;
    final dobUtc = DateTime.utc(dob.year, dob.month, dob.day).toIso8601String();
    await widget.controller.submitFullForm(
      salutation: _salutation!,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      dateOfBirth: dobUtc,
      sex: _selectedGender!,
      street: _streetCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      postalCode: _postalCtrl.text.trim(),
      country: _selectedCountryCode!,
      nationality: _selectedNationalityCode!,
      password: _passwordCtrl.text,
      postNominalTitle: _postNominalCtrl.text.trim(),
      designation: _designationCtrl.text.trim(),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? maxDate,
      firstDate: DateTime(1900),
      lastDate: maxDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFD91F32)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  void _onSalutationChanged(String? v) {
    setState(() {
      _salutation = v;
      // Mirror NativeScript: Mr. → Male, Mrs. → Female
      if (v == 'Mr.') _selectedGender = 'Male';
      if (v == 'Mrs.') _selectedGender = 'Female';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAlmostFinishedHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      signupSectionHeader(
                        'Basic Info',
                        const Icon(Icons.person_outline,
                            size: 22, color: Color(0xFFD91F32)),
                      ),
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        'Salutation *',
                        _salutation,
                        kSalutations,
                        _onSalutationChanged,
                      ),
                      const SizedBox(height: 14),
                      signupFieldLabel('First Name *'),
                      const SizedBox(height: 6),
                      _textField(_firstNameCtrl, 'First Name'),
                      const SizedBox(height: 14),
                      signupFieldLabel('Last Name *'),
                      const SizedBox(height: 6),
                      _textField(_lastNameCtrl, 'Last Name'),
                      const SizedBox(height: 14),
                      signupFieldLabel('Date of Birth *'),
                      const SizedBox(height: 6),
                      _buildDateField(),
                      const SizedBox(height: 14),
                      signupFieldLabel('Post Nominal'),
                      const SizedBox(height: 6),
                      _textField(_postNominalCtrl, 'Post Nominal'),
                      const SizedBox(height: 14),
                      signupFieldLabel('Designation'),
                      const SizedBox(height: 6),
                      _textField(_designationCtrl, 'Designation'),
                      const SizedBox(height: 14),
                      signupFieldLabel('Select Gender *'),
                      const SizedBox(height: 8),
                      _buildGenderRow(),
                      signupSectionDivider(),
                      signupSectionHeader(
                        'Address',
                        const Icon(Icons.home_outlined,
                            size: 22, color: Color(0xFFD91F32)),
                      ),
                      signupFieldLabel('Street *'),
                      const SizedBox(height: 6),
                      _textField(_streetCtrl, 'Street'),
                      const SizedBox(height: 14),
                      signupFieldLabel('City/State *'),
                      const SizedBox(height: 6),
                      _textField(_cityCtrl, 'City/State'),
                      const SizedBox(height: 14),
                      signupFieldLabel('Postal / Zip Code *'),
                      const SizedBox(height: 6),
                      _textField(_postalCtrl, 'Postal / Zip Code',
                          inputType: TextInputType.number),
                      const SizedBox(height: 14),
                      _buildCountryDropdown(
                        'Country *',
                        _selectedCountryCode,
                        (v) => setState(() => _selectedCountryCode = v),
                      ),
                      const SizedBox(height: 14),
                      _buildCountryDropdown(
                        'Nationality *',
                        _selectedNationalityCode,
                        (v) => setState(() => _selectedNationalityCode = v),
                      ),
                      signupSectionDivider(),
                      signupSectionHeader(
                        'Password',
                        const Icon(Icons.lock_outline,
                            size: 22, color: Color(0xFFD91F32)),
                      ),
                      signupFieldLabel('Password *'),
                      const SizedBox(height: 6),
                      _passwordField(_passwordCtrl, 'Password',
                          _isPasswordHidden, () {
                        setState(() => _isPasswordHidden = !_isPasswordHidden);
                      }),
                      if (_passwordTouched &&
                          !_passwordRegex.hasMatch(_passwordCtrl.text))
                        _buildPasswordHint(),
                      const SizedBox(height: 14),
                      signupFieldLabel('Repeat Password *'),
                      const SizedBox(height: 6),
                      _passwordField(
                          _repeatPasswordCtrl,
                          'Repeat Password',
                          _isRepeatPasswordHidden, () {
                        setState(() =>
                            _isRepeatPasswordHidden = !_isRepeatPasswordHidden);
                      }),
                      if (_passwordTouched &&
                          _repeatPasswordCtrl.text.isNotEmpty &&
                          _passwordCtrl.text != _repeatPasswordCtrl.text)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Passwords do not match.',
                            style: TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 12,
                              color: Color(0xFFD91F32),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildTermsRow(),
                      const SizedBox(height: 12),
                      _buildTermsText(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        signupBottomButton(
          label: 'COMPLETE PROFILE',
          isEnabled: _isFormValid && !c.isLoading,
          isLoading: c.isLoading,
          onTap: _submit,
        ),
      ],
    );
  }

  Widget _buildPasswordHint() {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: Text(
        'Password must contain at least 6 characters. Must include one UPPERCASE letter, one lowercase letter, one special character and one digit.',
        style: TextStyle(
          fontFamily: 'Calibri',
          fontSize: 12,
          color: Color(0xFFD91F32),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildAlmostFinishedHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Almost Finished!',
                  style: TextStyle(
                    fontFamily: 'Calibri',
                    fontStyle: FontStyle.italic,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Please provide the information and setup password below. It takes less than 30 sec.',
                  style: TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 13,
                    color: Color(0xFF7A7A7A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://az-cdn.selise.biz/selisecdn/cdn/slnetwork/assets/mobile_app_images/self_signup_document.png',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
              errorBuilder: (context, error, _) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_outlined,
                    size: 32, color: Color(0xFFD91F32)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email Address',
            style: TextStyle(
                fontFamily: 'Calibri', fontSize: 12, color: Color(0xFF8B8B8B)),
          ),
          const SizedBox(height: 2),
          Text(
            widget.controller.session.userEmail,
            style: const TextStyle(
                fontFamily: 'Calibri', fontSize: 15, color: Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Phone Number',
            style: TextStyle(
                fontFamily: 'Calibri', fontSize: 12, color: Color(0xFF8B8B8B)),
          ),
          const SizedBox(height: 2),
          Text(
            widget.controller.session.userPhoneNumber,
            style: const TextStyle(
                fontFamily: 'Calibri', fontSize: 15, color: Color(0xFF2D2D2D)),
          ),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      onChanged: (_) => setState(() {}),
      style: signupInputStyle,
      decoration: signupInputDecoration(hint),
    );
  }

  Widget _passwordField(
    TextEditingController ctrl,
    String hint,
    bool hidden,
    VoidCallback toggle,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: hidden,
      onChanged: (_) => setState(() => _passwordTouched = true),
      style: signupInputStyle,
      decoration: signupInputDecoration(
        hint,
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: const Color(0xFF888888),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC9C9C9), width: 1.0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _dateOfBirth != null
                    ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                    : 'Date of Birth',
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 15,
                  color: _dateOfBirth != null
                      ? const Color(0xFF2D2D2D)
                      : const Color(0xFFAAAAAA),
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: Color(0xFF888888)),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderRow() {
    return Row(
      children: kGenders
          .map(
            (g) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = g),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedGender == g
                              ? const Color(0xFFD91F32)
                              : const Color(0xFFC0C0C0),
                          width: 1.5,
                        ),
                      ),
                      child: _selectedGender == g
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFD91F32),
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      g,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        signupFieldLabel(label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC9C9C9), width: 1.0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                'Select ${label.replaceAll(' *', '').replaceAll('*', '')}',
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 15,
                  color: Color(0xFFAAAAAA),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF555555)),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 15,
                              color: Color(0xFF2D2D2D))),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                onChanged(v);
                setState(() {});
              },
            ),
          ),
        ),
      ],
    );
  }

  // Country/Nationality picker — stores ISO2 code, displays name
  Widget _buildCountryDropdown(
    String label,
    String? selectedCode,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        signupFieldLabel(label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showCountrySheet(
            selectedCode: selectedCode,
            onSelect: onChanged,
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC9C9C9), width: 1.0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCode != null
                        ? (kAllCountries
                                .where((c) => c.iso2 == selectedCode)
                                .firstOrNull
                                ?.name ??
                            selectedCode)
                        : 'Select ${label.replaceAll(' *', '')}',
                    style: TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 15,
                      color: selectedCode != null
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFAAAAAA),
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF555555)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCountrySheet({
    required String? selectedCode,
    required ValueChanged<String?> onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CountrySelectSheet(
        selectedCode: selectedCode,
        onSelect: (code) {
          onSelect(code);
          Navigator.pop(context);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _agreedToTerms ? const Color(0xFFD91F32) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _agreedToTerms
                    ? const Color(0xFFD91F32)
                    : const Color(0xFFC0C0C0),
                width: 1.3,
              ),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          const Text(
            'I agree to continue.',
            style: TextStyle(
                fontFamily: 'Calibri', fontSize: 14, color: Color(0xFF2D2D2D)),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsText() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'Calibri',
          fontSize: 12,
          color: Color(0xFF7A7A7A),
          height: 1.5,
        ),
        children: [
          TextSpan(text: "By clicking on 'Continue/Next' you agree to our "),
          TextSpan(
              text: 'terms of use',
              style: TextStyle(color: Color(0xFFD91F32))),
          TextSpan(
              text:
                  ' and confirm that you have read through the information on '),
          TextSpan(
              text: 'data protection',
              style: TextStyle(color: Color(0xFFD91F32))),
          TextSpan(
              text:
                  '. Please read the terms of use and information on data protection carefully.'),
        ],
      ),
    );
  }
}

class _CountrySelectSheet extends StatefulWidget {
  const _CountrySelectSheet({
    required this.selectedCode,
    required this.onSelect,
  });
  final String? selectedCode;
  final ValueChanged<String> onSelect;

  @override
  State<_CountrySelectSheet> createState() => _CountrySelectSheetState();
}

class _CountrySelectSheetState extends State<_CountrySelectSheet> {
  final _searchCtrl = TextEditingController();
  List<CountryInfo> _filtered = kAllCountries;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? kAllCountries
          : kAllCountries
              .where((c) =>
                  c.name.toLowerCase().contains(lower) ||
                  c.iso2.toLowerCase().contains(lower))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
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
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: const TextStyle(fontFamily: 'Calibri', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search country...',
                hintStyle: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 14,
                    color: Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: Color(0xFFAAAAAA)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFD91F32), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (context, _) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (_, i) {
                final country = _filtered[i];
                final isSelected = country.iso2 == widget.selectedCode;
                return InkWell(
                  onTap: () => widget.onSelect(country.iso2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Text(country.flagEmoji,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
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
                          const Icon(Icons.check,
                              size: 20, color: Color(0xFFD91F32)),
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
