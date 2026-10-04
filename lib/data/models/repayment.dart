class Repayment {
  final String id;
  final String loanId;
  final int amount; // paisa
  final DateTime date;
  final String note;

  const Repayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'loanId': loanId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory Repayment.fromJson(Map<String, dynamic> j) => Repayment(
    id: j['id'] as String,
    loanId: j['loanId'] as String,
    amount: j['amount'] as int,
    date: DateTime.parse(j['date'] as String),
    note: (j['note'] as String?) ?? '',
  );
}
