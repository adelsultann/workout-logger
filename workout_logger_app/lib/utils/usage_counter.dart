import 'package:shared_preferences/shared_preferences.dart';

class UsageCounter {
  static const _key = 'exerciseCount';

  /// +1 each time user creates an exercise
  static Future<int> incrementExerciseCount() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_key) ?? 0) + 1;
    print('this is the count now $next');
    await prefs.setInt(_key, next);
    return next;
  }

  /// Retrieve current count
  static Future<int> getExerciseCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  /// Reset to zero after user upgrades / registers
  static Future<void> resetExerciseCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key); // or prefs.setInt(_key, 0);
  }
}
