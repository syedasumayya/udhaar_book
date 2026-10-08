import '../data/models/loan.dart';
import '../data/models/person.dart';
import '../data/models/repayment.dart';
import 'balance.dart';

class CsvReport {
  static String loans({
    required List<Person> people,
    required List<Loan> loans,
    required List<Repayment> repayments,
  }) {
    final byId = {for (final p in people) p.id: p};
    final rows = <String>[
      'Person,Phone,Type,Amount,Paid,Remaining,Loan date,Due date,Status,Note',
    ];

    final sorted = [...loans]..sort((a, b) => b.date.compareTo(a.date));
    for (final l in sorted) {
      final person = byId[l.personId];
      final paid = Balance.paid(l, repayments);
      final left = Balance.remaining(l, repayments);
      final status = left == 0
          ? 'Paid'
          : Balance.isOverdue(l, repayments)
          ? 'Overdue'
          : 'Open';

      rows.add(
        [
          _cell(person?.name ?? 'Unknown', guard: true),
          _cell(person?.phone ?? ''),
          l.direction == LoanDirection.lent ? 'Gave' : 'Took',
          _plain(l.principal),
          _plain(paid),
          _plain(left),
          _date(l.date),
          l.dueDate == null ? '' : _date(l.dueDate!),
          status,
          _cell(l.note, guard: true),
        ].join(','),
      );
    }
    return rows.join('\n');
  }

  static String _plain(int minor) {
    final whole = minor ~/ 100;
    final frac = minor % 100;
    return frac == 0 ? '$whole' : '$whole.${frac.toString().padLeft(2, '0')}';
  }

  static String _date(DateTime d) => d.toIso8601String().substring(0, 10);

  /// Quotes a value if needed. With [guard], text that starts with a formula
  /// character gets a leading apostrophe so Excel will not run it.
  static String _cell(String value, {bool guard = false}) {
    var s = value;
    if (guard && s.isNotEmpty && '=+-@'.contains(s[0])) s = "'$s";
    if (s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r')) {
      s = '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
