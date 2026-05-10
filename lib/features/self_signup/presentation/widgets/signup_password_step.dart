import 'package:filip_at_flutter/features/self_signup/application/self_signup_controller.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_shared.dart';
import 'package:flutter/material.dart';

class SignupPasswordStep extends StatefulWidget {
  const SignupPasswordStep({super.key, required this.controller});
  final SelfSignupController controller;

  @override
  State<SignupPasswordStep> createState() => _SignupPasswordStepState();
}

class _SignupPasswordStepState extends State<SignupPasswordStep> {
  final _passwordCtrl = TextEditingController();
  final _repeatPasswordCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  bool _agreedToTerms = false;
  bool _isPasswordHidden = true;
  bool _isRepeatPasswordHidden = true;

  static final _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[-_!*@#$,.;?§%^&+=/]).{6,300}$',
  );
  bool _passwordTouched = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _repeatPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (_dateOfBirth == null) return false;
    if (!_passwordRegex.hasMatch(_passwordCtrl.text)) return false;
    if (_passwordCtrl.text != _repeatPasswordCtrl.text) return false;
    if (!_agreedToTerms) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_isFormValid) return;
    final dob = _dateOfBirth!;
    final dobUtc = DateTime.utc(dob.year, dob.month, dob.day).toIso8601String();
    await widget.controller.submitPasswordSet(
      password: _passwordCtrl.text,
      dateOfBirth: dobUtc,
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
                        'Password',
                        const Icon(Icons.lock_outline,
                            size: 22, color: Color(0xFFD91F32)),
                      ),
                      signupFieldLabel('Date of Birth *'),
                      const SizedBox(height: 6),
                      _buildDateField(),
                      const SizedBox(height: 14),
                      signupFieldLabel('Password *'),
                      const SizedBox(height: 6),
                      _passwordField(_passwordCtrl, 'Password',
                          _isPasswordHidden, () {
                        setState(
                            () => _isPasswordHidden = !_isPasswordHidden);
                      }),
                      if (_passwordTouched &&
                          !_passwordRegex.hasMatch(_passwordCtrl.text))
                        const Padding(
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
                        ),
                      const SizedBox(height: 14),
                      signupFieldLabel('Repeat Password *'),
                      const SizedBox(height: 6),
                      _passwordField(
                          _repeatPasswordCtrl, 'Repeat Password',
                          _isRepeatPasswordHidden, () {
                        setState(() => _isRepeatPasswordHidden =
                            !_isRepeatPasswordHidden);
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
                  'Please setup password below to finish the process',
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

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC9C9C9), width: 1.0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _dateOfBirth != null
                    ? '${_dateOfBirth!.month}/${_dateOfBirth!.day}/${_dateOfBirth!.year}'
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
              fontFamily: 'Calibri',
              fontSize: 14,
              color: Color(0xFF2D2D2D),
            ),
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
          TextSpan(
            text: "By clicking on 'Continue/Next' you agree to our ",
          ),
          TextSpan(
            text: 'terms of use',
            style: TextStyle(color: Color(0xFFD91F32)),
          ),
          TextSpan(
            text: ' and confirm that you have read through the information on ',
          ),
          TextSpan(
            text: 'data protection',
            style: TextStyle(color: Color(0xFFD91F32)),
          ),
          TextSpan(
            text:
                '. Please read the terms of use and information on data protection carefully.',
          ),
        ],
      ),
    );
  }
}
