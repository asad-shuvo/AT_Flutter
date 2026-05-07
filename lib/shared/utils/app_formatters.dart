import 'package:filip_at_flutter/app/localization/app_localizations.dart';

/// Returns '-' for null, empty string, or zero — mirrors NativeScript's checkEmpty pipe.
String checkEmpty(dynamic value) {
  if (value == null || value == '' || value == 0) return '-';
  return value.toString();
}

/// Currency formatting matching NativeScript's customCurrency pipe.
///
/// Austrian convention: dot thousands separator, comma decimal, always 2dp.
///   default  → "€ 1.234,56"
///   showName → "1.234,56 Euro"
class AppCurrencyFormatter {
  const AppCurrencyFormatter._();

  static String format(num? value, {bool showName = false}) {
    if (value == null) return '-';
    final formatted = _formatNumber(value);
    if (showName) return '$formatted Euro';
    return '€ $formatted';
  }

  /// Formats a number with dot-thousands and comma-decimal, fixed 2dp.
  static String formatNumber(num? value) {
    if (value == null) return '-';
    return _formatNumber(value);
  }

  static String _formatNumber(num value) {
    final isNeg = value < 0;
    final abs = value.abs();
    final fixed = abs.toStringAsFixed(2); // e.g. "1234.56"
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // Insert dot thousands separator every 3 digits from the right
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
      buf.write(intPart[i]);
    }

    return '${isNeg ? '-' : ''}$buf,$decPart';
  }
}

/// Date formatting matching NativeScript's localizedDate pipe patterns.
///
/// Pass [l10n] for localized month names and "o'clock" text.
/// Without [l10n], English month names are used as fallback.
///
/// Supported patterns:
///   'DD.MM.YYYY'    → 25.12.2024
///   '00.00.00'      → 25.12.24
///   'DD.MM.YYYY.c'  → 25. Dezember 2024   (localized month)
///   '00.00.00.c'    → 25. Dezember 2024   (same as above)
///   'dd MM, yyyy'   → 25 Dez, 2024        (short localized month)
///   'm.d.yyyy'      → 12.25.2024          (month.day.year)
///   'HH:mm'         → 14:30
///   'HH:mm:ss'      → 14:30:00
///   'HH:mm.c'       → 14:30 Uhr
///   'HH:mm:ss.c'    → 14:30:00 Uhr
class AppDateFormatter {
  const AppDateFormatter._();

  static String format(
    dynamic value,
    String pattern, {
    AppLocalizations? l10n,
  }) {
    if (value == null) return '';
    final date = _toDateTime(value);
    if (date == null) return '';

    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = date.year.toString().substring(2);
    final yyyy = date.year.toString();

    switch (pattern) {
      case 'DD.MM.YYYY':
        return '$dd.$mm.$yyyy';

      case '00.00.00':
        return '$dd.$mm.$yy';

      case 'DD.MM.YYYY.c':
      case '00.00.00.c':
        final monthLong = _monthName(date.month, l10n);
        return '$dd. $monthLong $yyyy';

      case 'dd MM, yyyy':
        final monthShort = _monthName(date.month, l10n).substring(0, 3);
        return '$dd $monthShort, $yyyy';

      case 'm.d.yyyy':
        return '${date.month}.${date.day}.$yyyy';

      case 'HH:mm':
        return _hhmm(date);

      case 'HH:mm:ss':
        return _hhmmss(date);

      case 'HH:mm.c':
        return '${_hhmm(date)} ${_oclock(l10n)}';

      case 'HH:mm:ss.c':
        return '${_hhmmss(date)} ${_oclock(l10n)}';

      default:
        return '$dd.$mm.$yyyy';
    }
  }

  /// Strips timezone offset (UTC → local wall-clock), matching NativeScript's utcDate pipe.
  static DateTime? utcToLocal(String? value) {
    if (value == null || value.isEmpty) return null;
    final d = DateTime.tryParse(value);
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day, d.hour, d.minute, d.second);
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _hhmmss(DateTime d) =>
      '${_hhmm(d)}:${d.second.toString().padLeft(2, '0')}';

  static String _oclock(AppLocalizations? l10n) =>
      l10n?.tr('common.oclock') ?? "o'clock";

  static String _monthName(int month, AppLocalizations? l10n) {
    if (l10n != null) return l10n.tr('common.month.$month');
    const names = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }
}
