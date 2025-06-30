// class Log {
//   final String id;
//   final String exerciseId;
//   final int reps;
//   final double weight;
//   final DateTime date;

//   Log({
//     required this.id,
//     required this.exerciseId,
//     required this.reps,
//     required this.weight,
//     required this.date,
//   });

//   factory Log.fromJson(Map<String, dynamic> json) {
//     return Log(
//       id: json['_id'],
//       exerciseId: json['exerciseId'],
//       reps: json['reps'],
//       weight: (json['weight'] as num).toDouble(),
//       date: DateTime.parse(json['date']),
//     );
//   }
// }
