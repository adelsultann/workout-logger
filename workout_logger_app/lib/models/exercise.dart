class Exercise {
  final String id;
  final String routineId;
  final String name;
  final int totalSets;

  Exercise({
    required this.id,
    required this.routineId,
    required this.name,
    required this.totalSets,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['_id'],
      routineId: json['routineId'],
      name: json['name'],
      totalSets: (json['totalSets'] ?? 0) as int,
    );
  }
}
