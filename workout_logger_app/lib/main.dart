import 'package:flutter/material.dart';
import 'package:overload_pro_app/screens/auth_screen.dart';
import 'package:overload_pro_app/screens/progress_screen.dart';
import 'package:overload_pro_app/screens/settingScreen.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<User> ensureUserSignedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  final map = Map.fromIterable(keys, value: (key) => prefs.get(key));
  print(" Shared preferences: $map");
  // Has the user already signed in before?
  if (FirebaseAuth.instance.currentUser != null) {
    return FirebaseAuth.instance.currentUser!;
  }

  // First launch - do anonymous sign-in
  final userCred = await FirebaseAuth.instance.signInAnonymously();
  await prefs.setString(
    'firstSignIn',
    DateTime.now().toIso8601String(),
  ); // track timestamp
  await prefs.setInt('workoutCount', 0); // track usage
  print("✅ User signed in: ${userCred.user!.uid}");
  return userCred.user!;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("🔥 Starting Firebase init...");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("✅ Firebase init done!");

  await ensureUserSignedIn();
  runApp(const WorkoutLoggerApp());
}

class WorkoutLoggerApp extends StatelessWidget {
  const WorkoutLoggerApp({super.key});

  get yourDefaultExercise => null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/home',
      routes: {
        '/home': (_) => const HomeScreen(),
        '/settings': (_) => const SettingScreen(),
        '/signup': (_) => const AuthScreen(), // new
        // '/progress': (_) => const ProgressScreen(),
        // '/progress': (_) => ProgressChartScreen(),
        // '/calendar': (_) => CalendarScreen(),
        // '/profile': (_) => ProfileScreen(),
      },
    );
  }
}
