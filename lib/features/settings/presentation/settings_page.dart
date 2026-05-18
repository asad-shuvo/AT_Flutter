import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/settings/application/biometric_service.dart';
import 'package:filip_at_flutter/features/settings/presentation/biometric_confirm_bottom_sheet.dart';
import 'package:filip_at_flutter/features/settings/presentation/biometric_deactivate_bottom_sheet.dart';
import 'package:filip_at_flutter/features/settings/presentation/recovery_pin_page.dart';
import 'package:filip_at_flutter/features/settings/presentation/reset_pin_bottom_sheet.dart';
import 'package:filip_at_flutter/features/settings/presentation/set_pin_page.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/utils/logout_utils.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.authSessionController,
    this.profileRepository,
  });

  final AuthSessionController authSessionController;
  final ProfileRepository? profileRepository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricEnabled = false;
  bool _pinStatus = false;
  bool _loadingState = true;
  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final repo = widget.profileRepository;
    if (repo == null) {
      if (mounted) setState(() => _loadingState = false);
      return;
    }
    try {
      final results = await Future.wait([
        repo.getBiometricEnabled(),
        repo.getPinStatus(),
      ]);
      if (mounted) {
        setState(() {
          _biometricEnabled = results[0];
          _pinStatus = results[1];
          _loadingState = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingState = false);
    }
  }

  Future<void> _onBiometricChanged(bool value) async {
    final repo = widget.profileRepository;
    if (repo == null) return;

    if (value && !_biometricEnabled) {
      await _enableBiometric(repo);
    } else if (!value && _biometricEnabled) {
      await _disableBiometric(repo);
    }
  }

  Future<void> _enableBiometric(ProfileRepository repo) async {
    final l10n = context.l10n;

    final confirmed = await BiometricConfirmBottomSheet.show(
      context,
      icon: SelectNetworkIcons.warning,
      message: l10n.tr('tns.invokeForFingerprint'),
    );
    if (!mounted) return;

    if (!confirmed) {
      setState(() => _biometricEnabled = false);
      return;
    }

    try {
      final hasPinAlready = await repo.getPinStatus();
      if (!mounted) return;

      bool activated = false;

      if (hasPinAlready) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => RecoveryPinPage(
              repository: repo,
              biometricService: _biometricService,
            ),
          ),
        );
        activated = result == true;
      } else {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => SetPinPage(
              repository: repo,
              biometricService: _biometricService,
            ),
          ),
        );
        activated = result == true;
      }

      if (!mounted) return;

      if (activated) {
        await repo.setBiometricEnabled(enabled: true);
        if (!mounted) return;
        setState(() {
          _biometricEnabled = true;
          _pinStatus = true;
        });
        _showSnack(l10n.tr('tns.biometricCredentialSavedSuccessfully'));
      } else {
        setState(() => _biometricEnabled = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
      _showSnack(l10n.tr('SOMETHING_WENT_WRONG'));
    }
  }

  Future<void> _disableBiometric(ProfileRepository repo) async {
    final l10n = context.l10n;
    final password = await BiometricDeactivateBottomSheet.show(context);
    if (!mounted) return;

    if (password == null) {
      setState(() => _biometricEnabled = true);
      return;
    }

    try {
      final result = await repo.deletePin(password: password);
      if (!mounted) return;

      if (result.isSuccess) {
        await repo.setBiometricEnabled(enabled: false);
        await repo.clearPinCredential();
        if (!mounted) return;
        setState(() {
          _biometricEnabled = false;
          _pinStatus = false;
        });
        _showSnack(l10n.tr('tns.biometricDisabledSuccessfully'));
        await performLogout(
          context,
          authSessionController: widget.authSessionController,
        );
      } else {
        setState(() => _biometricEnabled = true);
        _showSnack(l10n.tr('WRONG_PASSWORD'));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _biometricEnabled = true);
      _showSnack(l10n.tr('SOMETHING_WENT_WRONG'));
    }
  }

  void _onResetPin() {
    final repo = widget.profileRepository;
    if (repo == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResetPinBottomSheet(repository: repo),
    ).then((_) => _loadState());
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final resetPinEnabled = _biometricEnabled || _pinStatus;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(FilipIcons.back, color: Color(0xFF808080), size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.tr('tns.biometricPreferences'),
          style: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF666666),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E5E5)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _PreferenceCard(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        MaterialIconsNS.fingerprint,
                        size: 24,
                        color: Color(0xFF808080),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            l10n.tr('tns.fingerprintAuthentication'),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                      _loadingState
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primaryRed,
                              ),
                            )
                          : Transform.scale(
                              scale: 0.95,
                              child: SwitchTheme(
                                data: SwitchThemeData(
                                  trackOutlineColor: WidgetStateProperty.all(
                                    Colors.transparent,
                                  ),
                                  thumbColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return AppColors.primaryRed;
                                      }
                                      return const Color(0xFFC6C6C6);
                                    },
                                  ),
                                  trackColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (states) {
                                      if (states
                                          .contains(WidgetState.selected)) {
                                        return const Color(0x33D82034);
                                      }
                                      return const Color(0xFFE3E3E3);
                                    },
                                  ),
                                ),
                                child: Switch(
                                  value: _biometricEnabled,
                                  onChanged: widget.profileRepository != null
                                      ? _onBiometricChanged
                                      : null,
                                ),
                              ),
                            ),
                    ],
                  ),
                  Text(
                    l10n.tr('tns.allowFingerprint'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF808080),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _PreferenceCard(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FilipIcons.pin,
                        size: 24,
                        color: Color(0xFF808080),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            l10n.tr('tns.pin'),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l10n.tr('tns.setRecoveryPin'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF808080),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: resetPinEnabled ? _onResetPin : null,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: resetPinEnabled
                            ? AppColors.primaryRed
                            : const Color(0xFFCACBCB),
                        disabledForegroundColor: const Color(0xFFCACBCB),
                        side: BorderSide(
                          color: resetPinEnabled
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFFE0E0E0),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        l10n.tr('tns.resetPin').toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.4,
                          color: resetPinEnabled
                              ? AppColors.primaryRed
                              : const Color(0xFFCACBCB),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
