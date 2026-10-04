import 'package:flutter_test/flutter_test.dart';
import 'package:udhaar_book/core/money.dart';
import 'package:udhaar_book/data/models/loan.dart';
import 'package:udhaar_book/data/models/repayment.dart';
import 'package:udhaar_book/domain/balance.dart';

void main() {
  final now = DateTime(2026, 10, 4);

  Loan loan(String id, LoanDirection d, int principal, {DateTime? due}) => Loan(
    id: id,
    personId: 'p1',
    direction: d,
    principal: principal,
    date: now,
    dueDate: due,
    createdAt: now,
  );

  Repayment rep(String loanId, int amount) => Repayment(
    id: '$loanId-$amount',
    loanId: loanId,
    amount: amount,
    date: now,
  );

  test('remaining = principal - repayments', () {
    final l = loan('a', LoanDirection.lent, 100000);
    expect(Balance.remaining(l, [rep('a', 30000), rep('a', 20000)]), 50000);
  });

  test('overpayment never goes negative', () {
    final l = loan('a', LoanDirection.lent, 10000);
    expect(Balance.remaining(l, [rep('a', 25000)]), 0);
  });

  test('totals split lent and borrowed', () {
    final loans = [
      loan('a', LoanDirection.lent, 100000),
      loan('b', LoanDirection.borrowed, 40000),
    ];
    final t = Balance.totals(loans, [rep('a', 25000)]);
    expect(t.owedToMe, 75000);
    expect(t.iOwe, 40000);
    expect(t.net, 35000);
  });

  test('overdue only when unpaid and past due date', () {
    final l = loan('a', LoanDirection.lent, 10000, due: DateTime(2026, 9, 1));
    expect(Balance.isOverdue(l, [], now: now), true);
    expect(Balance.isOverdue(l, [rep('a', 10000)], now: now), false);
  });

  test('money format and parse', () {
    expect(Money.format(150000), 'Rs 1,500');
    expect(Money.format(150050), 'Rs 1,500.50');
    expect(Money.parse('1,500.50'), 150050);
    expect(Money.parse('abc'), null);
  });
}
