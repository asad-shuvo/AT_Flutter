import 'dart:convert';

import 'package:filip_at_flutter/app/config/app_config.dart';
import 'package:filip_at_flutter/app/localization/app_language_scope.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/data/auth_exception.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.config,
    required this.authSessionController,
  });

  final AppConfig config;
  final AuthSessionController authSessionController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _isPasswordHidden = true;
  bool _isSubmitting = false;
  bool _isLoadingRememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadRememberMeInfo();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMeInfo() async {
    final rememberMeInfo = await widget.authSessionController
        .getRememberMeInfo();

    if (!mounted) {
      return;
    }

    _usernameController.text = rememberMeInfo.email;
    _passwordController.text = rememberMeInfo.password;

    setState(() {
      _rememberMe = rememberMeInfo.isEnabled;
      _isLoadingRememberMe = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    if (!mounted) {
      return;
    }

    try {
      await widget.authSessionController.signIn(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (_rememberMe) {
        await widget.authSessionController.saveRememberMeInfo(
          email: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await widget.authSessionController.clearRememberMeInfo();
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(AppRouter.loginIntermediary);
    } on AuthException catch (error) {
      if (error.code == 'two_factor_code_require') {
        try {
          final parsed = jsonDecode(error.description ?? '{}') as Map<String, dynamic>;
          final twoFactorToken = parsed['TwoFactorToken'] as String? ?? '';
          final pseudoNumber = parsed['PsudoNumber'] as String? ?? '';
          if (mounted) {
            Navigator.of(context).pushNamed(
              AppRouter.twoFactor,
              arguments: <String, String>{
                'twoFactorToken': twoFactorToken,
                'pseudoNumber': pseudoNumber,
                'username': _usernameController.text.trim(),
                'password': _passwordController.text,
                'rememberMe': _rememberMe.toString(),
              },
            );
          }
          return;
        } catch (_) {
          // fall through to generic snackbar
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.tr('login.genericError'))));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageController = AppLanguageScope.of(context);
    final l10n = context.l10n;
    final isGermanSelected = l10n.isGerman;
    final theme = Theme.of(context);

    if (_isLoadingRememberMe) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD91F32)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
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
                      Positioned(bottom: -30, child: _buildFloatingLogoCard()),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 52, 12, 22),
                    child: Column(
                      children: [
                        Text(
                          l10n.tr('login.welcome'),
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
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(l10n.tr('login.email')),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _usernameController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  fontFamily: 'Calibri',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF2F2F2F),
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.tr('login.emailHint'),
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
                                  errorBorder: _inputBorder(
                                    color: const Color(0xFFD91F32),
                                  ),
                                  focusedErrorBorder: _inputBorder(
                                    color: const Color(0xFFD91F32),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.tr('login.emailRequired');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildFieldLabel(l10n.tr('login.password')),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _isPasswordHidden,
                                style: const TextStyle(
                                  fontFamily: 'Calibri',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF2F2F2F),
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.tr('login.passwordHint'),
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
                                  errorBorder: _inputBorder(
                                    color: const Color(0xFFD91F32),
                                  ),
                                  focusedErrorBorder: _inputBorder(
                                    color: const Color(0xFFD91F32),
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordHidden = !_isPasswordHidden;
                                      });
                                    },
                                    icon: Icon(
                                      _isPasswordHidden
                                          ? SelectNetworkIcons.eye
                                          : SelectNetworkIcons.eyeDisabled,
                                      size: 22,
                                      color: const Color(0xFF5E5E5E),
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.tr('login.passwordRequired');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final nextValue = !_rememberMe;
                                        if (!nextValue) {
                                          await widget.authSessionController
                                              .clearRememberMeInfo();
                                        }
                                        if (!mounted) {
                                          return;
                                        }
                                        setState(() {
                                          _rememberMe = nextValue;
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 120,
                                            ),
                                            height: 18,
                                            width: 18,
                                            decoration: BoxDecoration(
                                              color: _rememberMe
                                                  ? const Color(0xFFD91F32)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                color: _rememberMe
                                                    ? const Color(0xFFD91F32)
                                                    : const Color(0xFFC7C7C7),
                                                width: 1.3,
                                              ),
                                            ),
                                            child: _rememberMe
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            l10n.tr('login.rememberMe'),
                                            style: const TextStyle(
                                              fontFamily: 'Calibri',
                                              fontSize: 13,
                                              color: Color(0xFF6B6B6B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRouter.forgotPassword);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: const Color(0xFF6B6B6B),
                                    ),
                                    child: Text(
                                      l10n.tr('login.forgotPassword'),
                                      style: const TextStyle(
                                        fontFamily: 'Calibri',
                                        fontSize: 13,
                                        color: Color(0xFF6B6B6B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: SizedBox(
                                      height: 50,
                                      child: FilledButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : _submit,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFD91F32,
                                          ),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Text(
                                                l10n.tr('login.logIn'),
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
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 50,
                                      child: OutlinedButton(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFD91F32,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFD91F32),
                                            width: 1.2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Icon(
                                          SelectNetworkIcons.fingerprint,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 38),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    l10n.tr('login.noAccount'),
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
                                      l10n.tr('login.createNow'),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder({Color color = const Color(0xFFC9C9C9)}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
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

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 12,
        color: Color(0xFF888888),
      ),
    );
  }
}
