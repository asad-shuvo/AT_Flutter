/// Currency formatter matching NativeScript customCurrency pipe.
/// Austrian convention: dot thousands, comma decimal, always 2dp, € prefix.
/// Examples: € 140.507,76  /  € -254,56  /  € 0,00
class CurrencyFormatter {
  const CurrencyFormatter._();

  static String formatEuro(double? value) {
    if (value == null) return '-';

    final isNeg = value < 0;
    final abs = value.abs();
    final fixed = abs.toStringAsFixed(2); // "140507.76"
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
      buf.write(intPart[i]);
    }

    final sign = isNeg ? '-' : '';
    return '€ $sign$buf,$decPart';
  }
}
