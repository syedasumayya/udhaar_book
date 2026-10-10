import '../data/models/loan.dart';

class MonthActivity {
  final DateTime month; // first day of the month
  final int lent;
  final int borrowed;

  const MonthActivity({
    required this.month,
    required this.lent,
    required this.borrowed,
  });
}

class MonthlyActivity {
  /// Totals of loans created in each of the last [months] months, oldest first.
  static List<MonthActivity> lastMonths(
    Iterable<Loan> loans, {
    int months = 6,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final starts = [
      for (var i = months - 1; i >= 0; i--) DateTime(n.year, n.month - i),
    ];
    final lent = List<int>.filled(months, 0);
    final borrowed = List<int>.filled(months, 0);

    for (final l in loans) {
      final idx = starts.indexWhere(
        (s) => s.year == l.date.year && s.month == l.date.month,
      );
      if (idx == -1) continue;
      if (l.direction == LoanDirection.lent) {
        lent[idx] += l.principal;
      } else {
        borrowed[idx] += l.principal;
      }
    }

    return [
      for (var i = 0; i < months; i++)
        MonthActivity(month: starts[i], lent: lent[i], borrowed: borrowed[i]),
    ];
  }
}