import '../models/loan.dart';
import '../models/person.dart';
import '../models/repayment.dart';

abstract class AppRepository {
  Future<List<Person>> getPeople();
  Future<void> savePerson(Person person); // add or update
  Future<void> deletePerson(String id); // also deletes their loans

  Future<List<Loan>> getLoans();
  Future<void> saveLoan(Loan loan); // add or update
  Future<void> deleteLoan(String id); // also deletes its repayments

  Future<List<Repayment>> getRepayments();
  Future<void> saveRepayment(Repayment repayment);
  Future<void> deleteRepayment(String id);

  /// Replaces all stored data in one go (used by restore and delete-all).
  Future<void> replaceAll({
    required List<Person> people,
    required List<Loan> loans,
    required List<Repayment> repayments,
  });
}
