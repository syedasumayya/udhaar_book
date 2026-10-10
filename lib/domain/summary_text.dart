import '../core/date_format.dart';
import '../core/money.dart';
import '../data/models/loan.dart';
import '../data/models/person.dart';
import '../data/models/repayment.dart';
import 'balance.dart';

class SummaryText {
  /// Added to local numbers that start with a single 0 (92 = Pakistan).
  static const defaultCountryCode = '92';

  static String forPerson({
    required Person person,
    required List<Loan> loans,
    required List<Repayment> repayments,
  }) {
    final open = loans
        .where((l) => Balance.remaining(l, repayments) > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final buf = StringBuffer()
      ..writeln('Hi ${person.name}, here is our account summary:');

    if (open.isEmpty) {
      buf.writeln('Everything is settled. Thank you!');
      return buf.toString().trim();
    }

    buf.writeln();
    for (final l in open) {
      final lent = l.direction == LoanDirection.lent;
      final paid = Balance.paid(l, repayments);
      final left = Balance.remaining(l, repayments);

      final line = StringBuffer(
        '• ${formatDate(l.date)}: ${lent ? 'I gave' : 'I took'} '
        '${Money.format(l.principal)}',
      );
      if (paid > 0) line.write(', paid ${Money.format(paid)}');
      line.write(', ${Money.format(left)} left');
      if (l.dueDate != null) line.write(' (due ${formatDate(l.dueDate!)})');
      buf.writeln(line);
    }

    final net = Balance.totals(loans, repayments).net;
    buf.writeln();
    if (net > 0) {
      buf.writeln('Total you owe me: ${Money.format(net)}');
    } else if (net < 0) {
      buf.writeln('Total I owe you: ${Money.format(-net)}');
    } else {
      buf.writeln('We are even overall.');
    }
    return buf.toString().trim();
  }

  /// Digits only, with country code, or null if it does not look like a number.
  static String? whatsappNumber(String? phone) {
    if (phone == null) return null;
    final trimmed = phone.trim();
    var digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');

    if (trimmed.startsWith('+')) {
      // already international
    } else if (digits.startsWith('00')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = '$defaultCountryCode${digits.substring(1)}';
    }
    return digits.length >= 8 && digits.length <= 15 ? digits : null;
  }

  /// Opens a chat with the person, or the chat picker if no valid number.
  static Uri whatsappUri(String? phone, String text) {
    final number = whatsappNumber(phone) ?? '';
    return Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(text)}');
  }
}