class WorkoutLog {
  final String id;
  final String userId;
  final String exerciseId;
  final double weight;
  final int reps;
  final String? notes;
  final DateTime date;
  final int totalSets;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.weight,
    required this.reps,
    this.notes,
    required this.date,
    required this.totalSets,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['_id'],
      userId: json['userId'],
      exerciseId: json['exerciseId'],
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'],
      notes: json['notes'],
      date: DateTime.parse(json['date']),
      totalSets: json['totalSets'],
    );
  }
}
