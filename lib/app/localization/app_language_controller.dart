import 'dart:ui';

import 'package:filip_at_flutter/core/storage/app_storage_keys.dart';
import 'package:filip_at_flutter/core/storage/secure_storage_service.dart';
import 'package:flutter/foundation.dart';

class AppLanguageController extends ChangeNotifier {
  AppLanguageController({required SecureStorageService secureStorageService})
    : _secureStorageService = secureStorageService;

  static const List<String> supportedLanguageCodes = <String>['en', 'de'];
  static const String defaultLanguageCode = 'de';

  final SecureStorageService _secureStorageService;

  Locale _locale = const Locale(defaultLanguageCode);

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  bool get isGerman => languageCode == 'de';

  Future<void> restoreLocale() async {
    final storedCode = await _secureStorageService.read(
      AppStorageKeys.languageCode,
    );
    _locale = Locale(_normalizeLanguageCode(storedCode));
  }

  Future<void> setLanguageCode(String languageCode) async {
    final normalizedCode = _normalizeLanguageCode(languageCode);
    if (normalizedCode == _locale.languageCode) {
      return;
    }

    _locale = Locale(normalizedCode);
    await _secureStorageService.write(
      key: AppStorageKeys.languageCode,
      value: normalizedCode,
    );
    notifyListeners();
  }

  String _normalizeLanguageCode(String? languageCode) {
    final normalizedCode = languageCode?.toLowerCase();
    if (normalizedCode != null &&
        supportedLanguageCodes.contains(normalizedCode)) {
      return normalizedCode;
    }
    return defaultLanguageCode;
  }
}
