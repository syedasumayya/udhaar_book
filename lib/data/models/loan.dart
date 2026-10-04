/// lent     = you gave money, they owe you.
/// borrowed = you took money, you owe them.
enum LoanDirection { lent, borrowed }

class Loan {
  final String id;
  final String personId;
  final LoanDirection direction;
  final int principal; // paisa
  final DateTime date;
  final DateTime? dueDate;
  final String note;
  final DateTime createdAt;

  const Loan({
    required this.id,
    required this.personId,
    required this.direction,
    required this.principal,
    required this.date,
    this.dueDate,
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'personId': personId,
    'direction': direction.name,
    'principal': principal,
    'date': date.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
    id: j['id'] as String,
    personId: j['personId'] as String,
    direction: LoanDirection.values.byName(j['direction'] as String),
    principal: j['principal'] as int,
    date: DateTime.parse(j['date'] as String),
    dueDate: j['dueDate'] == null
        ? null
        : DateTime.parse(j['dueDate'] as String),
    note: (j['note'] as String?) ?? '',
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
