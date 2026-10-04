class Person {
  final String id;
  final String name;
  final String? phone;
  final DateTime createdAt;

  const Person({
    required this.id,
    required this.name,
    this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Person.fromJson(Map<String, dynamic> j) => Person(
    id: j['id'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
