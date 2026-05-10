import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/self_signup/application/self_signup_controller.dart';
import 'package:filip_at_flutter/features/self_signup/data/self_signup_repository.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_captcha_view.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_email_step.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_full_form_step.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_otp_step.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_password_step.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_phone_step.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_success_view.dart';
import 'package:flutter/material.dart';

class SelfSignupPage extends StatefulWidget {
  const SelfSignupPage({super.key, required this.repository});

  final SelfSignupRepository repository;

  @override
  State<SelfSignupPage> createState() => _SelfSignupPageState();
}

class _SelfSignupPageState extends State<SelfSignupPage> {
  late final SelfSignupController _controller;
  bool _successSheetShown = false;

  @override
  void initState() {
    super.initState();
    // Fresh token per signup attempt — prevents 401 from reusing expired token.
    widget.repository.resetSession();
    _controller = SelfSignupController(repository: widget.repository);
    _controller.addListener(_onStateChange);
    _controller.loadCaptcha();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.setLanguageCode(Localizations.localeOf(context).languageCode);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;
    if (_controller.view == SelfSignupView.success && !_successSheetShown) {
      _successSheetShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showSuccessSheet();
      });
    } else {
      setState(() {});
    }
    if (_controller.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.trBestEffort(_controller.errorMessage!),
              ),
              backgroundColor: const Color(0xFF333333),
            ),
          );
        _controller.clearError();
      });
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SignupSuccessView(
        onGoToLogin: () => Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRouter.login, (_) => false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = context.l10n;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.8),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.tr('tns.cancel').toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFFD91F32),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '${l10n.tr('tns.registrationStep').toUpperCase()} ${_controller.currentStep}/3',
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 13,
                color: Color(0xFF8B8B8B),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_controller.view) {
      case SelfSignupView.emailInput:
        return SignupEmailStep(controller: _controller);
      case SelfSignupView.emailOtp:
        return SignupOtpStep(controller: _controller, isEmail: true);
      case SelfSignupView.phoneInput:
        return SignupPhoneStep(controller: _controller);
      case SelfSignupView.phoneOtp:
        return SignupOtpStep(controller: _controller, isEmail: false);
      case SelfSignupView.captchaView:
        return SignupCaptchaView(controller: _controller);
      case SelfSignupView.fullForm:
        return SignupFullFormStep(controller: _controller);
      case SelfSignupView.passwordSet:
      case SelfSignupView.success:
        return SignupPasswordStep(controller: _controller);
    }
  }
}
