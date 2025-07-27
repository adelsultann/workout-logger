import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:overload_pro_app/models/exercise.dart';
import 'package:overload_pro_app/models/routine.dart';
import 'package:overload_pro_app/models/workout_log.dart';

// … your models …

class ApiService {
  // static const baseUrl = 'http://10.0.2.2:5000/api';

  // real device
  // static const baseUrl = 'http://192.168.2.130:5000/api';

  //live deplyment backend
  static const baseUrl = 'https://over-load-pro-backend.onrender.com/api';

  // 🔑 helper – returns headers with Authorization: Bearer <token>
  static Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser!;
    final token = await user.getIdToken(); // fresh JWT
    print('JWT: $token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /* ---------- ROUTINES ---------- */

  static Future<List<Routine>> getRoutines() async {
    final res = await http.get(
      Uri.parse('$baseUrl/routines'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) throw Exception('Failed to load routines');
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Routine.fromJson(e)).toList();
  }

  static Future<Routine> addRoutine(String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/routines'),
      headers: await _authHeaders(),
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode != 201) throw Exception('Failed to create routine');
    return Routine.fromJson(jsonDecode(res.body));
  }

  static Future<void> deleteRoutine(String routineId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/routines/$routineId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) throw Exception('Failed to delete routine');
  }

  /* ---------- EXERCISES ---------- */

  static Future<List<Exercise>> getExercises(String routineId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/exercises/$routineId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) throw Exception('Failed to load exercises');
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Exercise.fromJson(e)).toList();
  }

  static Future<Exercise> addExercise(
    String routineId,
    String name,
    int totalSets,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/exercises'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'routineId': routineId,
        'name': name,
        'totalSets': totalSets,
      }),
    );
    if (res.statusCode != 201) throw Exception('Failed to add exercise');
    return Exercise.fromJson(jsonDecode(res.body));
  }

  static Future<void> deleteExercise(String exerciseId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/exercises/$exerciseId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) throw Exception('Failed to delete exercise');
  }

  static Future<void> updateExerciseOrder(
    String routineId,
    List<Exercise> exercises,
  ) async {
    // Create a list of exercise IDs in their new order
    final exerciseOrder = exercises
        .asMap()
        .entries
        .map(
          (entry) => {
            'exerciseId': entry.value.id,
            'order': entry.key, // 0-based index as the new order
          },
        )
        .toList();

    final res = await http.put(
      Uri.parse('$baseUrl/exercises/$routineId/reorder'),
      headers: await _authHeaders(),
      body: jsonEncode({'exercises': exerciseOrder}),
    );

    if (res.statusCode != 200) {
      print(res.body);
      print(res.statusCode);

      throw Exception('Failed to update exercise orderrr');
    }
  }
  /* ---------- LOGS ---------- */

  // 🔔 NOTE: backend route is /logs/exercise/:id
  static Future<List<WorkoutLog>> getLogs(String exerciseId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/logs/$exerciseId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) throw Exception('Failed to get logs');
    final data = jsonDecode(res.body) as List;
    return data.map((e) => WorkoutLog.fromJson(e)).toList().reversed.toList();
  }

  static Future<WorkoutLog> addLog({
    required String exerciseId,
    required double weight,
    required int reps,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/logs'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'exerciseId': exerciseId,
        'weight': weight,
        'reps': reps,
        'notes': notes,
      }),
    );
    if (res.statusCode != 201) throw Exception('Failed to add log');
    return WorkoutLog.fromJson(jsonDecode(res.body));
  }

  static Future<void> deleteLog(String logId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/logs/$logId'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) throw Exception('Failed to delete log');
  }

  static Future<List<WorkoutLog>> getAllLogs() async {
    final res = await http.get(
      Uri.parse('$baseUrl/logs'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) throw Exception('Failed to load logs');
    final data = jsonDecode(res.body) as List;
    return data.map((e) => WorkoutLog.fromJson(e)).toList();
  }
}
