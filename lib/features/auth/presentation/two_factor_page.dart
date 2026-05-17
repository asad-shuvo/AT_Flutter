import 'package:filip_at_flutter/app/localization/app_language_scope.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/data/auth_exception.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:flutter/material.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/services.dart';

class TwoFactorPage extends StatefulWidget {
  const TwoFactorPage({
    super.key,
    required this.twoFactorToken,
    required this.pseudoNumber,
    required this.username,
    required this.password,
    required this.rememberMe,
    required this.authSessionController,
  });

  final String twoFactorToken;
  final String pseudoNumber;
  final String username;
  final String password;
  final bool rememberMe;
  final AuthSessionController authSessionController;

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  bool _codeNotEmpty = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    final hasValue = _codeController.text.trim().isNotEmpty;
    if (hasValue != _codeNotEmpty) {
      setState(() => _codeNotEmpty = hasValue);
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.authSessionController.verify2faCode(
        code: code,
        token: widget.twoFactorToken,
      );

      if (widget.rememberMe && widget.username.isNotEmpty) {
        await widget.authSessionController.saveRememberMeInfo(
          email: widget.username,
          password: widget.password,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.loginIntermediary,
        (_) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.tr('tns.retry'))),
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageController = AppLanguageScope.of(context);
    final l10n = context.l10n;
    final isGermanSelected = l10n.isGerman;
    final canSubmit = _codeNotEmpty && !_isSubmitting;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            SizedBox(
                              height: 276,
                              width: double.infinity,
                              child: Image.asset(
                                'assets/images/login/login_image.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                            Positioned(
                              bottom: -30,
                              child: _buildFloatingLogoCard(),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 52, 12, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  l10n.tr('tns.welcomeToFinancialLifePlanner'),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontFamily: 'Calibri',
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 26,
                                    height: 1.28,
                                    color: const Color(0xFF5A5551),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                widget.pseudoNumber.isNotEmpty
                                    ? '${l10n.tr('tns.aMessageHasBeenSent')} ${widget.pseudoNumber}.'
                                    : l10n.tr('tns.aMessageHasBeenSent'),
                                style: const TextStyle(
                                  fontFamily: 'Calibri',
                                  fontSize: 15,
                                  color: Color(0xFF2F2F2F),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textInputAction: TextInputAction.done,
                                onSubmitted: canSubmit ? (_) => _verify() : null,
                                style: const TextStyle(
                                  fontFamily: 'Calibri',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF2F2F2F),
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.tr('tns.verificationCode'),
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Calibri',
                                    fontSize: 16,
                                    color: Color(0xFF9D9D9D),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  enabledBorder: _inputBorder(),
                                  focusedBorder: _inputBorder(
                                    color: const Color(0xFFD91F32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: canSubmit ? _verify : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD91F32),
                        disabledBackgroundColor:
                            const Color(0xFFD91F32).withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
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
                              l10n.tr('tns.verify'),
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              l10n.tr('tns.dontHaveAnAccount'),
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 12,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context)
                                  .pushNamed(AppRouter.selfSignup),
                              child: Text(
                                l10n.tr('tns.createNow'),
                                style: const TextStyle(
                                  fontFamily: 'Calibri',
                                  fontSize: 12,
                                  color: Color(0xFFD91F32),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            MaterialIconsNS.language,
                            size: 15,
                            color: Color(0xFF8B8B8B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            languageController.languageCode.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 12,
                              color: Color(0xFF7D7D7D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              languageController.setLanguageCode(
                                isGermanSelected ? 'en' : 'de',
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 34,
                              height: 20,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isGermanSelected
                                    ? const Color(0xFFF2B7BE)
                                    : const Color(0xFFD2D2D2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Align(
                                alignment: isGermanSelected
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x22000000),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder({Color color = const Color(0xFFC9C9C9)}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
      borderSide: BorderSide(color: color, width: 1.15),
    );
  }

  Widget _buildFloatingLogoCard() {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F1F1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/login/filip_icon.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

