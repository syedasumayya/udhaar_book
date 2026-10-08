import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udhaar_book/data/models/loan.dart';
import 'package:udhaar_book/data/models/person.dart';
import 'package:udhaar_book/data/models/repayment.dart';
import 'package:udhaar_book/data/repositories/prefs_repository.dart';
import 'package:udhaar_book/domain/backup.dart';
import 'package:udhaar_book/domain/csv_report.dart';
import 'package:udhaar_book/providers.dart';

final _day = DateTime(2026, 10, 4);

Person _person([String name = 'Ali']) =>
    Person(id: 'p1', name: name, createdAt: _day);

Loan _loan({
  int principal = 100000,
  String personId = 'p1',
  String note = '',
}) => Loan(
  id: 'l1',
  personId: personId,
  direction: LoanDirection.lent,
  principal: principal,
  date: DateTime(2026, 10, 1),
  note: note,
  createdAt: _day,
);

Repayment _rep(int amount) => Repayment(
  id: 'r1',
  loanId: 'l1',
  amount: amount,
  date: DateTime(2026, 10, 2),
);

void main() {
  group('backup', () {
    test('encode then decode gives the same data back', () {
      final text = BackupService.encode(
        people: [_person()],
        loans: [_loan()],
        repayments: [_rep(25000)],
      );
      final back = BackupService.decode(text);
      expect(back.people.single.name, 'Ali');
      expect(back.loans.single.principal, 100000);
      expect(back.repayments.single.amount, 25000);
    });

    test('rejects text that is not JSON', () {
      expect(() => BackupService.decode('hello'), throwsFormatException);
    });

    test('rejects JSON from another app', () {
      expect(
        () => BackupService.decode('{"app":"other","version":1}'),
        throwsFormatException,
      );
    });

    test('rejects a backup from a newer version', () {
      const text =
          '{"app":"udhaar_book","version":99,"people":[],"loans":[],"repayments":[]}';
      expect(() => BackupService.decode(text), throwsFormatException);
    });

    test('rejects a loan that points to a missing person', () {
      final text = BackupService.encode(
        people: [_person()],
        loans: [_loan(personId: 'ghost')],
        repayments: const [],
      );
      expect(() => BackupService.decode(text), throwsFormatException);
    });

    test('rejects a loan with more paid than its amount', () {
      final text = BackupService.encode(
        people: [_person()],
        loans: [_loan(principal: 10000)],
        repayments: [_rep(20000)],
      );
      expect(() => BackupService.decode(text), throwsFormatException);
    });
  });

  group('csv', () {
    test('has a header and one row per loan', () {
      final csv = CsvReport.loans(
        people: [_person()],
        loans: [_loan()],
        repayments: [_rep(25000)],
      );
      final lines = csv.split('\n');
      expect(lines.length, 2);
      expect(lines[1], startsWith('Ali,,Gave,1000,250,750,2026-10-01,,Open'));
    });

    test('quotes commas and quotes, and guards formulas', () {
      final csv = CsvReport.loans(
        people: [_person('Ali, "AJ"')],
        loans: [_loan(note: '=SUM(A1)')],
        repayments: const [],
      );
      expect(csv, contains('"Ali, ""AJ"""'));
      expect(csv, contains("'=SUM(A1)"));
    });
  });

  group('state', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(PrefsRepository(prefs)),
        ],
      );
      await container.read(appDataProvider.future);
    });

    tearDown(() => container.dispose());

    test('replaceAll swaps the data, clearAll empties it', () async {
      final notifier = container.read(appDataProvider.notifier);
      await notifier.replaceAll(
        people: [_person()],
        loans: [_loan()],
        repayments: [_rep(25000)],
      );

      var data = container.read(appDataProvider).requireValue;
      expect(data.people.length, 1);
      expect(data.totals.owedToMe, 75000);

      await notifier.clearAll();
      data = container.read(appDataProvider).requireValue;
      expect(data.people, isEmpty);
      expect(data.loans, isEmpty);
      expect(data.repayments, isEmpty);
    });
  });
}
