import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udhaar_book/data/models/loan.dart';
import 'package:udhaar_book/data/models/person.dart';
import 'package:udhaar_book/data/repositories/prefs_repository.dart';
import 'package:udhaar_book/domain/balance.dart';
import 'package:udhaar_book/providers.dart';

void main() {
  Loan makeLoan({DateTime? due}) => Loan(
    id: 'l1',
    personId: 'p1',
    direction: LoanDirection.lent,
    principal: 10000,
    date: DateTime(2026, 10, 1),
    dueDate: due,
    createdAt: DateTime(2026, 10, 1),
  );

  test('loan due today is not overdue, due yesterday is', () {
    final now = DateTime(2026, 10, 4, 15, 30);
    expect(
      Balance.isOverdue(makeLoan(due: DateTime(2026, 10, 4)), [], now: now),
      false,
    );
    expect(
      Balance.isOverdue(makeLoan(due: DateTime(2026, 10, 3)), [], now: now),
      true,
    );
  });

  group('state', () {
    late ProviderContainer container;
    late AppDataNotifier notifier;
    late Person ali;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(PrefsRepository(prefs)),
        ],
      );
      await container.read(appDataProvider.future);
      notifier = container.read(appDataProvider.notifier);
      ali = await notifier.addPerson(name: 'Ali');
      await notifier.addLoan(
        personId: ali.id,
        direction: LoanDirection.lent,
        principal: 100000,
        date: DateTime(2026, 10, 1),
        dueDate: DateTime(2026, 10, 6),
      );
    });

    tearDown(() => container.dispose());

    test('editing a person keeps their loans', () async {
      await notifier.updatePerson(
        Person(
          id: ali.id,
          name: 'Ali Khan',
          phone: '0300',
          createdAt: ali.createdAt,
        ),
      );
      final data = container.read(appDataProvider).requireValue;
      expect(data.personById(ali.id)!.name, 'Ali Khan');
      expect(data.loansFor(ali.id).length, 1);
    });

    test('cannot lower a loan below what is already paid', () async {
      var data = container.read(appDataProvider).requireValue;
      final loan = data.loans.first;
      await notifier.addRepayment(
        loanId: loan.id,
        amount: 60000,
        date: DateTime(2026, 10, 2),
      );

      await expectLater(
        notifier.updateLoan(
          Loan(
            id: loan.id,
            personId: loan.personId,
            direction: loan.direction,
            principal: 50000,
            date: loan.date,
            dueDate: loan.dueDate,
            createdAt: loan.createdAt,
          ),
        ),
        throwsArgumentError,
      );

      await notifier.updateLoan(
        Loan(
          id: loan.id,
          personId: loan.personId,
          direction: loan.direction,
          principal: 80000,
          date: loan.date,
          dueDate: loan.dueDate,
          createdAt: loan.createdAt,
        ),
      );
      data = container.read(appDataProvider).requireValue;
      expect(data.totals.owedToMe, 20000);
    });

    test('cannot move loan date after an existing payment', () async {
      var data = container.read(appDataProvider).requireValue;
      final loan = data.loans.first;
      await notifier.addRepayment(
        loanId: loan.id,
        amount: 10000,
        date: DateTime(2026, 10, 2),
      );

      await expectLater(
        notifier.updateLoan(
          Loan(
            id: loan.id,
            personId: loan.personId,
            direction: loan.direction,
            principal: loan.principal,
            date: DateTime(2026, 10, 3),
            createdAt: loan.createdAt,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('upcoming lists loans due within 7 days, overdue does not', () {
      final data = container.read(appDataProvider).requireValue;
      final now = DateTime(2026, 10, 4);
      expect(data.upcomingLoans(now: now).length, 1);
      expect(data.overdueLoans(now: now), isEmpty);

      final later = DateTime(2026, 10, 10);
      expect(data.upcomingLoans(now: later), isEmpty);
      expect(data.overdueLoans(now: later).length, 1);
    });
  });
}
