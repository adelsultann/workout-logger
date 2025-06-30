import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/routine.dart';
import '../models/exercise.dart';
import '../models/workout_log.dart';

class ApiService {
  static const baseUrl =
      'http://10.0.2.2:5000/api'; // Use 10.0.2.2 for Android emulator

  static Future<List<Routine>> getRoutines(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/routines?userId=$userId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      return data.map((json) => Routine.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load routines');
    }
  }

  static Future<Routine> addRoutine(String userId, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/routines'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'name': name}),
    );

    if (response.statusCode == 201) {
      return Routine.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create routine');
    }
  }

  static Future<void> deleteRoutine(String routineId) async {
    final res = await http.delete(Uri.parse('$baseUrl/routines/$routineId'));

    if (res.statusCode != 200) {
      throw Exception('Failed to delete routine');
    }
  }

  static Future<List<Exercise>> getExercises(String routineId) async {
    final response = await http.get(Uri.parse('$baseUrl/exercises/$routineId'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Exercise.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load exercises');
    }
  }

  static Future<Exercise> addExercise(
    String routineId,
    String name,
    int totalSets,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/exercises'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'routineId': routineId,
        'name': name,
        'totalSets': totalSets,
      }),
    );

    if (response.statusCode == 201) {
      return Exercise.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add exercise');
    }
  }

  static Future<void> deleteExercise(String exerciseId) async {
    final res = await http.delete(Uri.parse('$baseUrl/exercises/$exerciseId'));

    if (res.statusCode != 200) {
      throw Exception('Failed to delete exercise');
    }
  }

  static Future<List<WorkoutLog>> getLogs(String exerciseId) async {
    final res = await http.get(Uri.parse('$baseUrl/logs/$exerciseId'));
    if (res.statusCode == 200) {
      List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => WorkoutLog.fromJson(e)).toList().reversed.toList();
    } else {
      throw Exception('Failed to get logs');
    }
  }

  static Future<WorkoutLog> addLog({
    required String userId,
    required String exerciseId,
    required double weight,
    required int reps,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/logs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'exerciseId': exerciseId,
        'weight': weight,
        'reps': reps,
        'notes': notes,
      }),
    );

    if (res.statusCode == 201) {
      return WorkoutLog.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to add log');
    }
  }

  static Future<void> deleteLog(String logId) async {
    final res = await http.delete(Uri.parse('$baseUrl/logs/$logId'));

    if (res.statusCode != 200) {
      throw Exception('Failed to delete log');
    }
  }

  static Future<List<WorkoutLog>> getAllLogs() async {
    final res = await http.get(Uri.parse('$baseUrl/logs'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load logs');
    }

    List<dynamic> data = json.decode(res.body);
    return data.map((json) => WorkoutLog.fromJson(json)).toList();
  }
}
