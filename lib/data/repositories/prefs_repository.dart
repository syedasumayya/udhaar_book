import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loan.dart';
import '../models/person.dart';
import '../models/repayment.dart';
import 'app_repository.dart';

class PrefsRepository implements AppRepository {
  PrefsRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _peopleKey = 'people_v1';
  static const _loansKey = 'loans_v1';
  static const _repaymentsKey = 'repayments_v1';

  List<T> _read<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _write(String key, List<Map<String, dynamic>> items) async {
    await _prefs.setString(key, jsonEncode(items));
  }

  // ---- People ----
  @override
  Future<List<Person>> getPeople() async => _read(_peopleKey, Person.fromJson);

  @override
  Future<void> savePerson(Person person) async {
    final all = await getPeople();
    final i = all.indexWhere((p) => p.id == person.id);
    i == -1 ? all.add(person) : all[i] = person;
    await _write(_peopleKey, all.map((p) => p.toJson()).toList());
  }

  @override
  Future<void> deletePerson(String id) async {
    final loans = await getLoans();
    for (final l in loans.where((l) => l.personId == id)) {
      await deleteLoan(l.id);
    }
    final all = await getPeople();
    all.removeWhere((p) => p.id == id);
    await _write(_peopleKey, all.map((p) => p.toJson()).toList());
  }

  // ---- Loans ----
  @override
  Future<List<Loan>> getLoans() async => _read(_loansKey, Loan.fromJson);

  @override
  Future<void> saveLoan(Loan loan) async {
    final all = await getLoans();
    final i = all.indexWhere((l) => l.id == loan.id);
    i == -1 ? all.add(loan) : all[i] = loan;
    await _write(_loansKey, all.map((l) => l.toJson()).toList());
  }

  @override
  Future<void> deleteLoan(String id) async {
    final reps = await getRepayments();
    reps.removeWhere((r) => r.loanId == id);
    await _write(_repaymentsKey, reps.map((r) => r.toJson()).toList());

    final all = await getLoans();
    all.removeWhere((l) => l.id == id);
    await _write(_loansKey, all.map((l) => l.toJson()).toList());
  }

  // ---- Repayments ----
  @override
  Future<List<Repayment>> getRepayments() async =>
      _read(_repaymentsKey, Repayment.fromJson);

  @override
  Future<void> saveRepayment(Repayment repayment) async {
    final all = await getRepayments();
    final i = all.indexWhere((r) => r.id == repayment.id);
    i == -1 ? all.add(repayment) : all[i] = repayment;
    await _write(_repaymentsKey, all.map((r) => r.toJson()).toList());
  }

  @override
  Future<void> deleteRepayment(String id) async {
    final all = await getRepayments();
    all.removeWhere((r) => r.id == id);
    await _write(_repaymentsKey, all.map((r) => r.toJson()).toList());
  }

  // ---- Bulk ----
  @override
  Future<void> replaceAll({
    required List<Person> people,
    required List<Loan> loans,
    required List<Repayment> repayments,
  }) async {
    await _write(_peopleKey, people.map((p) => p.toJson()).toList());
    await _write(_loansKey, loans.map((l) => l.toJson()).toList());
    await _write(_repaymentsKey, repayments.map((r) => r.toJson()).toList());
  }
}
