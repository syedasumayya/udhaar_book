import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udhaar_book/data/models/loan.dart';
import 'package:udhaar_book/data/repositories/prefs_repository.dart';
import 'package:udhaar_book/providers.dart';

void main() {
  test('adding a person and a loan updates totals', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(PrefsRepository(prefs))],
    );
    addTearDown(container.dispose);

    await container.read(appDataProvider.future);
    final notifier = container.read(appDataProvider.notifier);

    final ali = await notifier.addPerson(name: 'Ali');
    await notifier.addLoan(
      personId: ali.id,
      direction: LoanDirection.lent,
      principal: 50000,
      date: DateTime(2026, 10, 4),
    );

    final data = container.read(appDataProvider).requireValue;
    expect(data.people.length, 1);
    expect(data.totals.owedToMe, 50000);
    expect(data.totalsFor(ali.id).net, 50000);
  });
}
