class Routine {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['_id'],
      userId: json['userId'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
