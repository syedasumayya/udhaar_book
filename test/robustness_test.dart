import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udhaar_book/data/models/person.dart';
import 'package:udhaar_book/data/repositories/prefs_repository.dart';

void main() {
  test('unreadable stored data is kept aside instead of crashing', () async {
    SharedPreferences.setMockInitialValues({'people_v1': 'this is not json'});
    final prefs = await SharedPreferences.getInstance();
    final repo = PrefsRepository(prefs);

    expect(await repo.getPeople(), isEmpty);
    expect(prefs.getString('people_v1_unreadable'), 'this is not json');
  });

  test('saving after a bad read does not destroy the kept copy', () async {
    SharedPreferences.setMockInitialValues({'people_v1': 'this is not json'});
    final prefs = await SharedPreferences.getInstance();
    final repo = PrefsRepository(prefs);

    await repo.savePerson(
        Person(id: 'p1', name: 'Ali', createdAt: DateTime(2026, 10, 9)));

    expect((await repo.getPeople()).single.name, 'Ali');
    expect(prefs.getString('people_v1_unreadable'), 'this is not json');
  });
}