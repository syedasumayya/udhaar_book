import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udhaar_book/app.dart';
import 'package:udhaar_book/data/repositories/prefs_repository.dart';
import 'package:udhaar_book/providers.dart';
import 'package:udhaar_book/settings_provider.dart';

Future<void> openApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        repositoryProvider.overrideWithValue(PrefsRepository(prefs)),
      ],
      child: const UdhaarBookApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on the dashboard with a welcome card', (tester) async {
    await openApp(tester);
    expect(find.textContaining('Welcome to Udhaar Book'), findsOneWidget);
    expect(find.text('People owe you'), findsOneWidget);
  });

  testWidgets('can add a person from the People tab', (tester) async {
    await openApp(tester);

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No one here yet'), findsOneWidget);

    await tester.tap(find.text('Add person'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Ali');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Ali'), findsOneWidget);
  });

  testWidgets('settings shows security and backup sections', (tester) async {
    await openApp(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Set PIN lock'), findsOneWidget);
    expect(find.text('Copy backup'), findsOneWidget);
  });
}