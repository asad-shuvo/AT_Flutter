import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/data/forgot_password_repository.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ResetPasswordVerificationPage extends StatefulWidget {
  const ResetPasswordVerificationPage({
    super.key,
    required this.activationCode,
    required this.repository,
  });

  final String activationCode;
  final ForgotPasswordRepository repository;

  @override
  State<ResetPasswordVerificationPage> createState() =>
      _ResetPasswordVerificationPageState();
}

enum _Stage { validating, invalid, setPassword, submitting, success, error }

class _ResetPasswordVerificationPageState
    extends State<ResetPasswordVerificationPage> {
  _Stage _stage = _Stage.validating;
  String? _recoverAccountCode;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordHidden = true;
  bool _confirmHidden = true;

  @override
  void initState() {
    super.initState();
    _validateCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    final code = await widget.repository.checkActivationCode(
      widget.activationCode,
    );
    if (!mounted) return;
    if (code != null) {
      _recoverAccountCode = code;
      setState(() => _stage = _Stage.setPassword);
    } else {
      setState(() => _stage = _Stage.invalid);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _stage = _Stage.submitting);

    final ok = await widget.repository.resetPasswordWithCode(
      newPassword: _passwordController.text.trim(),
      recoverAccountCode: _recoverAccountCode!,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _stage = _Stage.success);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } else {
      setState(() {
        _stage = _Stage.setPassword;
        _errorMessage = context.l10n.tr('SOMETHING_WENT_WRONG');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: Text(
          l10n.tr('tns.forgotPassword'),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_stage) {
      case _Stage.validating:
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
          ),
        );

      case _Stage.invalid:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.primaryRed),
              const SizedBox(height: 16),
              Text(
                l10n.tr('RequestExpiredErrorMessage'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    color: AppColors.textBody),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed),
                child: Text(l10n.tr('tns.backToLogin'),
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

      case _Stage.success:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 56, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                l10n.tr('tns.passwordResetSuccess'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    color: AppColors.textBody),
              ),
            ],
          ),
        );

      case _Stage.setPassword:
      case _Stage.submitting:
      case _Stage.error:
        return _buildForm(l10n);
    }
  }

  Widget _buildForm(AppLocalizations l10n) {
    final submitting = _stage == _Stage.submitting;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tr('tns.setNewPassword'),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            obscureText: _passwordHidden,
            enabled: !submitting,
            decoration: InputDecoration(
              labelText: l10n.tr('tns.newPassword'),
              suffixIcon: IconButton(
                icon: Icon(
                    _passwordHidden ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _passwordHidden = !_passwordHidden),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.tr('tns.required');
              if (v.trim().length < 6) {
                return l10n.tr('tns.newPasswordErrMessage');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: _confirmHidden,
            enabled: !submitting,
            decoration: InputDecoration(
              labelText: l10n.tr('tns.confirmPassword'),
              suffixIcon: IconButton(
                icon: Icon(
                    _confirmHidden ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _confirmHidden = !_confirmHidden),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (v) {
              if (v != _passwordController.text) {
                return l10n.tr('tns.confirmPasswordErrMessage');
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                  color: AppColors.primaryRed, fontFamily: 'Calibri'),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.tr('tns.submit'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Calibri',
                          fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
