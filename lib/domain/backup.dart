import 'dart:convert';
import '../data/models/loan.dart';
import '../data/models/person.dart';
import '../data/models/repayment.dart';

class BackupData {
  final List<Person> people;
  final List<Loan> loans;
  final List<Repayment> repayments;

  const BackupData({
    required this.people,
    required this.loans,
    required this.repayments,
  });
}

class BackupService {
  static const _appId = 'udhaar_book';
  static const _version = 1;

  static String encode({
    required List<Person> people,
    required List<Loan> loans,
    required List<Repayment> repayments,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'app': _appId,
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'people': people.map((p) => p.toJson()).toList(),
      'loans': loans.map((l) => l.toJson()).toList(),
      'repayments': repayments.map((r) => r.toJson()).toList(),
    });
  }

  /// Parses and validates a backup. Throws [FormatException] with a
  /// readable message if anything is wrong. Never returns partial data.
  static BackupData decode(String text) {
    final Object? raw;
    try {
      raw = jsonDecode(text);
    } on FormatException {
      throw const FormatException('This is not valid backup text.');
    }

    if (raw is! Map<String, dynamic> || raw['app'] != _appId) {
      throw const FormatException('This is not an Udhaar Book backup.');
    }
    final version = raw['version'];
    if (version is! int || version > _version) {
      throw const FormatException(
        'This backup was made by a newer version of the app.',
      );
    }

    final List<Person> people;
    final List<Loan> loans;
    final List<Repayment> repayments;
    try {
      people = (raw['people'] as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
      loans = (raw['loans'] as List)
          .map((e) => Loan.fromJson(e as Map<String, dynamic>))
          .toList();
      repayments = (raw['repayments'] as List)
          .map((e) => Repayment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const FormatException('The backup is damaged or incomplete.');
    }

    _validate(people, loans, repayments);
    return BackupData(people: people, loans: loans, repayments: repayments);
  }

  static void _validate(
    List<Person> people,
    List<Loan> loans,
    List<Repayment> repayments,
  ) {
    final personIds = people.map((p) => p.id).toSet();
    if (personIds.length != people.length) {
      throw const FormatException('The backup has duplicate people.');
    }

    final loanIds = loans.map((l) => l.id).toSet();
    if (loanIds.length != loans.length) {
      throw const FormatException('The backup has duplicate loans.');
    }

    for (final l in loans) {
      if (!personIds.contains(l.personId)) {
        throw const FormatException('A loan points to a missing person.');
      }
      if (l.principal <= 0) {
        throw const FormatException('A loan has an invalid amount.');
      }
    }

    final paidPerLoan = <String, int>{};
    for (final r in repayments) {
      if (!loanIds.contains(r.loanId)) {
        throw const FormatException('A payment points to a missing loan.');
      }
      if (r.amount <= 0) {
        throw const FormatException('A payment has an invalid amount.');
      }
      paidPerLoan[r.loanId] = (paidPerLoan[r.loanId] ?? 0) + r.amount;
    }

    for (final l in loans) {
      if ((paidPerLoan[l.id] ?? 0) > l.principal) {
        throw const FormatException('A loan has more paid than its amount.');
      }
    }
  }
}
