import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udhaar_book/data/models/loan.dart';
import 'package:udhaar_book/data/repositories/prefs_repository.dart';
import 'package:udhaar_book/domain/pin_hasher.dart';
import 'package:udhaar_book/lock_provider.dart';
import 'package:udhaar_book/providers.dart';
import 'package:udhaar_book/settings_provider.dart';

void main() {
  group('PinHasher', () {
    test('right PIN verifies, wrong PIN does not', () {
      final salt = PinHasher.newSalt();
      final hash = PinHasher.hash('1234', salt);
      expect(PinHasher.verify('1234', salt, hash), true);
      expect(PinHasher.verify('1235', salt, hash), false);
    });

    test('different salts give different hashes for the same PIN', () {
      final a = PinHasher.hash('1234', PinHasher.newSalt());
      final b = PinHasher.hash('1234', PinHasher.newSalt());
      expect(a, isNot(b));
    });
  });

  group('lock', () {
    late SharedPreferences prefs;
    late DateTime now;

    ProviderContainer makeContainer() {
      final c = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      now = DateTime(2026, 10, 9, 12);
    });

    test('set PIN, lock, then unlock with the right PIN only', () async {
      final c = makeContainer();
      final n = c.read(lockProvider.notifier);
      expect(c.read(lockProvider).hasPin, false);

      await n.setPin('1234');
      expect(c.read(lockProvider).hasPin, true);
      expect(c.read(lockProvider).locked, false);

      n.lock();
      expect(c.read(lockProvider).locked, true);
      expect(await n.unlock('0000'), false);
      expect(c.read(lockProvider).locked, true);
      expect(await n.unlock('1234'), true);
      expect(c.read(lockProvider).locked, false);
    });

    test('the app starts locked when a PIN already exists', () async {
      await makeContainer().read(lockProvider.notifier).setPin('123456');
      final fresh = makeContainer();
      expect(fresh.read(lockProvider).locked, true);
      expect(fresh.read(lockProvider).pinLength, 6);
    });

    test('the PIN is not stored in plain text', () async {
      await makeContainer().read(lockProvider.notifier).setPin('482913');
      final stored = prefs.getKeys().map((k) => '$k=${prefs.get(k)}').join(' ');
      expect(stored.contains('482913'), false);
    });

    test('5 wrong PINs force a wait, even for the right PIN', () async {
      final c = makeContainer();
      final n = c.read(lockProvider.notifier);
      await n.setPin('1234');
      n.lock();

      for (var i = 0; i < 5; i++) {
        expect(await n.unlock('0000'), false);
      }
      expect(n.waitLeft, greaterThan(Duration.zero));
      expect(await n.unlock('1234'), false);

      now = now.add(const Duration(seconds: 31));
      expect(n.waitLeft, Duration.zero);
      expect(await n.unlock('1234'), true);
      expect(c.read(lockProvider).failures, 0);
    });

    test('the wait survives an app restart', () async {
      final c = makeContainer();
      final n = c.read(lockProvider.notifier);
      await n.setPin('1234');
      n.lock();
      for (var i = 0; i < 5; i++) {
        await n.unlock('0000');
      }

      final restarted = makeContainer();
      expect(
        restarted.read(lockProvider.notifier).waitLeft,
        greaterThan(Duration.zero),
      );
    });

    test('changing or removing the PIN needs the current PIN', () async {
      final c = makeContainer();
      final n = c.read(lockProvider.notifier);
      await n.setPin('1234');

      expect(await n.removePin('9999'), false);
      expect(c.read(lockProvider).hasPin, true);

      expect(await n.changePin('1234', '5678'), true);
      n.lock();
      expect(await n.unlock('1234'), false);
      expect(await n.unlock('5678'), true);

      expect(await n.removePin('5678'), true);
      expect(c.read(lockProvider).hasPin, false);
      expect(c.read(lockProvider).locked, false);
    });

    test('rejects PINs that are too short, too long or not digits', () async {
      final n = makeContainer().read(lockProvider.notifier);
      await expectLater(n.setPin('123'), throwsArgumentError);
      await expectLater(n.setPin('1234567'), throwsArgumentError);
      await expectLater(n.setPin('12a4'), throwsArgumentError);
    });
  });

  test('settle all pays off every open loan with one person', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(PrefsRepository(prefs))],
    );
    addTearDown(c.dispose);

    await c.read(appDataProvider.future);
    final n = c.read(appDataProvider.notifier);
    final ali = await n.addPerson(name: 'Ali');
    await n.addLoan(
      personId: ali.id,
      direction: LoanDirection.lent,
      principal: 100000,
      date: DateTime(2026, 10, 1),
    );
    await n.addLoan(
      personId: ali.id,
      direction: LoanDirection.borrowed,
      principal: 40000,
      date: DateTime(2026, 10, 2),
    );
    final first = c.read(appDataProvider).requireValue.loans.first;
    await n.addRepayment(
      loanId: first.id,
      amount: 10000,
      date: DateTime(2026, 10, 3),
    );

    expect(await n.settleAll(ali.id), 2);
    final data = c.read(appDataProvider).requireValue;
    expect(data.totals.owedToMe, 0);
    expect(data.totals.iOwe, 0);

    expect(await n.settleAll(ali.id), 0);
  });
}
