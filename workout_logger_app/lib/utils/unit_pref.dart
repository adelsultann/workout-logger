import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { kg, lbs }

class UnitPref {
  static const _key = 'weightUnit';

  static Future<void> set(WeightUnit u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, u.name);
  }

  static Future<WeightUnit> get() async {
    // Default to kilograms
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key) ?? WeightUnit.kg.name;
    return WeightUnit.values.firstWhere((e) => e.name == v);
  }
}
