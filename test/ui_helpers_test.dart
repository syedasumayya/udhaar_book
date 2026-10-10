import 'package:flutter_test/flutter_test.dart';
import 'package:udhaar_book/core/date_format.dart';
import 'package:udhaar_book/data/models/loan.dart';
import 'package:udhaar_book/domain/monthly_activity.dart';

Loan _loan(String id, LoanDirection d, int amount, DateTime date) => Loan(
      id: id,
      personId: 'p1',
      direction: d,
      principal: amount,
      date: date,
      createdAt: date,
    );

void main() {
  test('daysBetween counts calendar days', () {
    expect(
      daysBetween(DateTime(2026, 10, 9, 23, 59), DateTime(2026, 10, 10, 0, 1)),
      1,
    );
    expect(daysBetween(DateTime(2026, 10, 10), DateTime(2026, 10, 10, 18)), 0);
    expect(daysBetween(DateTime(2026, 10, 10), DateTime(2026, 10, 7)), -3);
  });

  group('monthly activity', () {
    test('returns 6 months, oldest first, across a year boundary', () {
      final m = MonthlyActivity.lastMonths([], now: DateTime(2026, 2, 10));
      expect(
        m.map((e) => '${e.month.year}-${e.month.month}').toList(),
        ['2025-9', '2025-10', '2025-11', '2025-12', '2026-1', '2026-2'],
      );
    });

    test('sums given and taken per month and ignores older loans', () {
      final loans = [
        _loan('a', LoanDirection.lent, 1000, DateTime(2026, 10, 2)),
        _loan('b', LoanDirection.lent, 500, DateTime(2026, 10, 20)),
        _loan('c', LoanDirection.borrowed, 300, DateTime(2026, 9, 5)),
        _loan('d', LoanDirection.lent, 9999, DateTime(2026, 3, 1)),
      ];
      final m = MonthlyActivity.lastMonths(loans, now: DateTime(2026, 10, 15));

      expect(m.length, 6);
      expect(m.last.lent, 1500);
      expect(m.last.borrowed, 0);
      expect(m[4].borrowed, 300);
      expect(m.fold<int>(0, (s, e) => s + e.lent), 1500);
    });
  });
}