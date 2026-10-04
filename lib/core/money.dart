/// All amounts in the app are integers in the smallest unit (paisa).
class Money {
  static String format(int minor, {String symbol = 'Rs '}) {
    final negative = minor < 0;
    final abs = minor.abs();
    final whole = abs ~/ 100;
    final frac = abs % 100;

    final digits = whole.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    final fracPart = frac == 0 ? '' : '.${frac.toString().padLeft(2, '0')}';
    return '${negative ? '-' : ''}$symbol$buf$fracPart';
  }

  /// Turns what the user typed ("1,500.50") into paisa. Returns null if invalid.
  static int? parse(String input) {
    final cleaned = input.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }
}
