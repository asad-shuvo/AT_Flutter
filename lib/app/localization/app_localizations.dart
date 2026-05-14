import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._localizedValues);

  final Locale locale;
  final Map<String, Map<String, String>> _localizedValues;

  static const Locale fallbackLocale = Locale('de');
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'No AppLocalizations found in context.');
    return localizations!;
  }

  bool get isGerman => locale.languageCode == 'de';

  String tr(String key, [Map<String, String>? replacements]) {
    final localizedMap = _localizedValues[locale.languageCode];
    final fallbackMap = _localizedValues[fallbackLocale.languageCode]!;
    var value =
        _resolveValue(localizedMap, key) ??
        _resolveValue(fallbackMap, key) ??
        key;
    if (replacements != null) {
      replacements.forEach((replacementKey, replacementValue) {
        value = value.replaceAll('{{$replacementKey}}', replacementValue);
      });
    }
    return value;
  }

  String resolve(String keyOrValue) {
    if (_hasTranslationForKey(keyOrValue)) {
      return tr(keyOrValue);
    }
    return keyOrValue;
  }

  String trBestEffort(String value) {
    final raw = value.trim();
    if (raw.isEmpty) {
      return value;
    }

    final upperSnake = raw
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toUpperCase();
    final lower = raw.toLowerCase();
    final lowerSnake = upperSnake.toLowerCase();

    final candidates = <String>{
      raw,
      upperSnake,
      lower,
      lowerSnake,
      'tns.$raw',
      'tns.$lower',
      'tns.$lowerSnake',
      'FREQ_$upperSnake',
    };

    for (final key in candidates) {
      if (_hasTranslationForKey(key)) {
        return tr(key);
      }
    }

    return value;
  }

  bool _hasTranslationForKey(String key) {
    final localizedMap = _localizedValues[locale.languageCode];
    final fallbackMap = _localizedValues[fallbackLocale.languageCode]!;
    return _resolveValue(localizedMap, key) != null ||
        _resolveValue(fallbackMap, key) != null;
  }

  String? _resolveValue(
    Map<String, String>? localizedMap,
    String key,
  ) {
    if (localizedMap == null) {
      return null;
    }

    final candidates = <String>{key};

    if (key.startsWith('tns.')) {
      candidates.add(key.substring(4));
    } else {
      candidates.add('tns.$key');
    }

    final leaf = key.split('.').last;
    candidates.add(leaf);
    if (leaf.startsWith('tns.')) {
      candidates.add(leaf.substring(4));
    }

    final upperSnake = key
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toUpperCase();
    if (upperSnake.isNotEmpty) {
      candidates.add(upperSnake);
      candidates.add('tns.$upperSnake');
      final upperLeaf = leaf
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '')
          .toUpperCase();
      if (upperLeaf.isNotEmpty) {
        candidates.add(upperLeaf);
      }
    }

    final lower = key.toLowerCase();
    candidates.add(lower);
    candidates.add(leaf.toLowerCase());

    for (final candidate in candidates) {
      final value = localizedMap[candidate];
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static Future<Map<String, String>> _loadLanguageJson(
    String languageCode,
  ) async {
    final source = await rootBundle.loadString(
      'assets/i18n/$languageCode.json',
    );
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      return const <String, String>{};
    }
    return _flattenJson(decoded);
  }

  static Map<String, String> _flattenJson(Map<String, dynamic> source) {
    final result = <String, String>{};

    void visit(Map<String, dynamic> node, [String prefix = '']) {
      node.forEach((key, value) {
        final nextKey = prefix.isEmpty ? key : '$prefix.$key';
        if (value is Map<String, dynamic>) {
          visit(value, nextKey);
          return;
        }
        result[nextKey] = value?.toString() ?? '';
      });
    }

    visit(source);
    return result;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final languageCode = locale.languageCode;
    final fallbackCode = AppLocalizations.fallbackLocale.languageCode;
    final localizedValues = <String, Map<String, String>>{};

    try {
      localizedValues[fallbackCode] = await AppLocalizations._loadLanguageJson(
        fallbackCode,
      );
    } catch (_) {
      localizedValues[fallbackCode] = const <String, String>{};
    }

    if (languageCode == fallbackCode) {
      localizedValues[languageCode] = localizedValues[fallbackCode]!;
      return AppLocalizations(locale, localizedValues);
    }

    try {
      localizedValues[languageCode] = await AppLocalizations._loadLanguageJson(
        languageCode,
      );
    } catch (_) {
      localizedValues[languageCode] = const <String, String>{};
    }

    return AppLocalizations(locale, localizedValues);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

