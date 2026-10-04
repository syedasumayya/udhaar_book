import '../data/models/loan.dart';
import '../data/models/repayment.dart';

class Totals {
  final int owedToMe; // people owe you
  final int iOwe; // you owe people
  const Totals({required this.owedToMe, required this.iOwe});

  /// Positive = overall you are owed money.
  int get net => owedToMe - iOwe;
}

class Balance {
  static int paid(Loan loan, Iterable<Repayment> repayments) => repayments
      .where((r) => r.loanId == loan.id)
      .fold(0, (sum, r) => sum + r.amount);

  static int remaining(Loan loan, Iterable<Repayment> repayments) {
    final left = loan.principal - paid(loan, repayments);
    return left < 0 ? 0 : left;
  }

  static bool isOverdue(
    Loan loan,
    Iterable<Repayment> repayments, {
    DateTime? now,
  }) {
    if (loan.dueDate == null) return false;
    if (remaining(loan, repayments) == 0) return false;
    return loan.dueDate!.isBefore(now ?? DateTime.now());
  }

  static Totals totals(Iterable<Loan> loans, Iterable<Repayment> repayments) {
    var owedToMe = 0;
    var iOwe = 0;
    for (final loan in loans) {
      final left = remaining(loan, repayments);
      if (loan.direction == LoanDirection.lent) {
        owedToMe += left;
      } else {
        iOwe += left;
      }
    }
    return Totals(owedToMe: owedToMe, iOwe: iOwe);
  }
}
