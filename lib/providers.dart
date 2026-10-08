import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'data/models/loan.dart';
import 'data/models/person.dart';
import 'data/models/repayment.dart';
import 'data/repositories/app_repository.dart';
import 'domain/balance.dart';

/// Overridden in main.dart with the real storage.
final repositoryProvider = Provider<AppRepository>(
  (ref) => throw UnimplementedError('repositoryProvider must be overridden'),
);

class AppData {
  final List<Person> people;
  final List<Loan> loans;
  final List<Repayment> repayments;

  const AppData({
    required this.people,
    required this.loans,
    required this.repayments,
  });

  Totals get totals => Balance.totals(loans, repayments);

  List<Loan> loansFor(String personId) =>
      loans.where((l) => l.personId == personId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  Totals totalsFor(String personId) =>
      Balance.totals(loansFor(personId), repayments);

  Person? personById(String id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  Loan? loanById(String id) {
    for (final l in loans) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<Repayment> repaymentsFor(String loanId) =>
      repayments.where((r) => r.loanId == loanId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Unpaid loans past their due date, oldest due date first.
  List<Loan> overdueLoans({DateTime? now}) =>
      loans.where((l) => Balance.isOverdue(l, repayments, now: now)).toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  /// Unpaid loans due from today up to [days] days ahead, soonest first.
  List<Loan> upcomingLoans({int days = 7, DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final end = today.add(Duration(days: days));
    return loans.where((l) {
      final due = l.dueDate;
      if (due == null) return false;
      if (Balance.remaining(l, repayments) == 0) return false;
      return !due.isBefore(today) && !due.isAfter(end);
    }).toList()..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }
}

class AppDataNotifier extends AsyncNotifier<AppData> {
  static const _uuid = Uuid();

  AppRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<AppData> build() => _load();

  Future<AppData> _load() async => AppData(
    people: await _repo.getPeople(),
    loans: await _repo.getLoans(),
    repayments: await _repo.getRepayments(),
  );

  Future<void> _refresh() async {
    state = AsyncData(await _load());
  }

  // ---- People ----
  Future<Person> addPerson({required String name, String? phone}) async {
    final person = Person(
      id: _uuid.v4(),
      name: name.trim(),
      phone: phone,
      createdAt: DateTime.now(),
    );
    await _repo.savePerson(person);
    await _refresh();
    return person;
  }

  Future<void> updatePerson(Person updated) async {
    await _repo.savePerson(updated);
    await _refresh();
  }

  Future<void> deletePerson(String id) async {
    await _repo.deletePerson(id);
    await _refresh();
  }

  // ---- Loans ----
  Future<void> addLoan({
    required String personId,
    required LoanDirection direction,
    required int principal,
    required DateTime date,
    DateTime? dueDate,
    String note = '',
  }) async {
    final loan = Loan(
      id: _uuid.v4(),
      personId: personId,
      direction: direction,
      principal: principal,
      date: date,
      dueDate: dueDate,
      note: note.trim(),
      createdAt: DateTime.now(),
    );
    await _repo.saveLoan(loan);
    await _refresh();
  }

  Future<void> updateLoan(Loan updated) async {
    final data = state.requireValue;
    final paid = Balance.paid(updated, data.repayments);
    if (updated.principal < paid) {
      throw ArgumentError('Amount cannot be less than what is already paid');
    }
    final hasEarlierPayment = data
        .repaymentsFor(updated.id)
        .any((r) => r.date.isBefore(updated.date));
    if (hasEarlierPayment) {
      throw ArgumentError('Loan date cannot be after an existing payment');
    }
    await _repo.saveLoan(updated);
    await _refresh();
  }

  Future<void> deleteLoan(String id) async {
    await _repo.deleteLoan(id);
    await _refresh();
  }

  // ---- Repayments ----
  Future<void> addRepayment({
    required String loanId,
    required int amount,
    required DateTime date,
    String note = '',
  }) async {
    final data = state.requireValue;
    final loan = data.loanById(loanId);
    if (loan == null) throw ArgumentError('Loan not found');
    if (amount <= 0 || amount > Balance.remaining(loan, data.repayments)) {
      throw ArgumentError('Invalid repayment amount');
    }

    final repayment = Repayment(
      id: _uuid.v4(),
      loanId: loanId,
      amount: amount,
      date: date,
      note: note.trim(),
    );
    await _repo.saveRepayment(repayment);
    await _refresh();
  }

  Future<void> deleteRepayment(String id) async {
    await _repo.deleteRepayment(id);
    await _refresh();
  }

  // ---- Bulk (restore / delete all) ----
  Future<void> replaceAll({
    required List<Person> people,
    required List<Loan> loans,
    required List<Repayment> repayments,
  }) async {
    await _repo.replaceAll(
      people: people,
      loans: loans,
      repayments: repayments,
    );
    await _refresh();
  }

  Future<void> clearAll() =>
      replaceAll(people: const [], loans: const [], repayments: const []);
}

final appDataProvider = AsyncNotifierProvider<AppDataNotifier, AppData>(
  AppDataNotifier.new,
);
