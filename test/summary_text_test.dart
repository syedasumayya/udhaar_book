import 'package:flutter_test/flutter_test.dart';
import 'package:udhaar_book/data/models/loan.dart';
import 'package:udhaar_book/data/models/person.dart';
import 'package:udhaar_book/data/models/repayment.dart';
import 'package:udhaar_book/domain/summary_text.dart';

final _ali = Person(id: 'p1', name: 'Ali', createdAt: DateTime(2026, 10, 1));

Loan _loan(String id, LoanDirection d, int principal, {DateTime? due}) => Loan(
      id: id,
      personId: 'p1',
      direction: d,
      principal: principal,
      date: DateTime(2026, 10, 1),
      dueDate: due,
      createdAt: DateTime(2026, 10, 1),
    );

Repayment _rep(String loanId, int amount) => Repayment(
      id: '$loanId-$amount',
      loanId: loanId,
      amount: amount,
      date: DateTime(2026, 10, 2),
    );

void main() {
  group('summary text', () {
    test('lists an open loan with payments and the total', () {
      final text = SummaryText.forPerson(
        person: _ali,
        loans: [
          _loan('l1', LoanDirection.lent, 100000, due: DateTime(2026, 10, 15)),
        ],
        repayments: [_rep('l1', 25000)],
      );

      expect(
        text,
        'Hi Ali, here is our account summary:\n'
        '\n'
        '• 1 Oct 2026: I gave Rs 1,000, paid Rs 250, Rs 750 left '
        '(due 15 Oct 2026)\n'
        '\n'
        'Total you owe me: Rs 750',
      );
    });

    test('says everything is settled when nothing is open', () {
      final text = SummaryText.forPerson(
        person: _ali,
        loans: [_loan('l1', LoanDirection.lent, 100000)],
        repayments: [_rep('l1', 100000)],
      );
      expect(
        text,
        'Hi Ali, here is our account summary:\n'
        'Everything is settled. Thank you!',
      );
    });

    test('shows what you owe them when you took money', () {
      final text = SummaryText.forPerson(
        person: _ali,
        loans: [_loan('l1', LoanDirection.borrowed, 40000)],
        repayments: const [],
      );
      expect(text, contains('I took Rs 400'));
      expect(text, contains('Total I owe you: Rs 400'));
    });

    test('mixed loans net out', () {
      final text = SummaryText.forPerson(
        person: _ali,
        loans: [
          _loan('l1', LoanDirection.lent, 100000),
          _loan('l2', LoanDirection.borrowed, 40000),
        ],
        repayments: const [],
      );
      expect(text, contains('I gave Rs 1,000'));
      expect(text, contains('I took Rs 400'));
      expect(text, contains('Total you owe me: Rs 600'));
    });
  });

  group('whatsapp', () {
    test('normalises phone numbers', () {
      expect(SummaryText.whatsappNumber('+92 300 1234567'), '923001234567');
      expect(SummaryText.whatsappNumber('0300-1234567'), '923001234567');
      expect(SummaryText.whatsappNumber('0092 300 1234567'), '923001234567');
    });

    test('rejects missing or nonsense numbers', () {
      expect(SummaryText.whatsappNumber(null), isNull);
      expect(SummaryText.whatsappNumber('abc'), isNull);
      expect(SummaryText.whatsappNumber('12'), isNull);
    });

    test('builds a link with the message encoded', () {
      expect(
        SummaryText.whatsappUri('0300 1234567', 'Hi there').toString(),
        'https://wa.me/923001234567?text=Hi%20there',
      );
      expect(
        SummaryText.whatsappUri(null, 'Hi there').toString(),
        'https://wa.me/?text=Hi%20there',
      );
    });
  });
}