import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udhaar_book/data/models/loan.dart';
import 'package:udhaar_book/data/repositories/prefs_repository.dart';
import 'package:udhaar_book/providers.dart';

Future<ProviderContainer> makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [repositoryProvider.overrideWithValue(PrefsRepository(prefs))],
  );
  await container.read(appDataProvider.future);
  return container;
}

void main() {
  late ProviderContainer container;
  late String loanId;
  late String personId;

  setUp(() async {
    container = await makeContainer();
    final notifier = container.read(appDataProvider.notifier);
    final ali = await notifier.addPerson(name: 'Ali');
    personId = ali.id;
    await notifier.addLoan(
      personId: ali.id,
      direction: LoanDirection.lent,
      principal: 100000,
      date: DateTime(2026, 10, 1),
    );
    loanId = container.read(appDataProvider).requireValue.loans.first.id;
  });

  tearDown(() => container.dispose());

  test('payment reduces total, deleting it restores it', () async {
    final notifier = container.read(appDataProvider.notifier);
    await notifier.addRepayment(
      loanId: loanId,
      amount: 40000,
      date: DateTime(2026, 10, 2),
    );

    var data = container.read(appDataProvider).requireValue;
    expect(data.totals.owedToMe, 60000);

    await notifier.deleteRepayment(data.repayments.first.id);
    data = container.read(appDataProvider).requireValue;
    expect(data.totals.owedToMe, 100000);
  });

  test('cannot repay more than what is left', () async {
    final notifier = container.read(appDataProvider.notifier);
    await expectLater(
      notifier.addRepayment(
        loanId: loanId,
        amount: 100001,
        date: DateTime(2026, 10, 2),
      ),
      throwsArgumentError,
    );
  });

  test('full payment settles the person', () async {
    final notifier = container.read(appDataProvider.notifier);
    await notifier.addRepayment(
      loanId: loanId,
      amount: 100000,
      date: DateTime(2026, 10, 2),
    );
    final data = container.read(appDataProvider).requireValue;
    expect(data.totalsFor(personId).net, 0);
  });

  test('deleting a loan removes its payments', () async {
    final notifier = container.read(appDataProvider.notifier);
    await notifier.addRepayment(
      loanId: loanId,
      amount: 10000,
      date: DateTime(2026, 10, 2),
    );
    await notifier.deleteLoan(loanId);
    final data = container.read(appDataProvider).requireValue;
    expect(data.loans, isEmpty);
    expect(data.repayments, isEmpty);
  });
}
