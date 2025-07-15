import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/settingScreen.dart';
import 'screens/progress_screen.dart';

Future<User> ensureUserSignedIn(FirebaseAnalytics analytics) async {
  final prefs = await SharedPreferences.getInstance();

  // Already signed in?
  if (FirebaseAuth.instance.currentUser != null) {
    final u = FirebaseAuth.instance.currentUser!;
    // Tie analytics user to this UID
    await analytics.setUserId(id: u.uid);
    return u;
  }

  // First launch → anonymous
  final cred = await FirebaseAuth.instance.signInAnonymously();
  final u = cred.user!;
  await prefs.setString('firstSignIn', DateTime.now().toIso8601String());
  await prefs.setInt('workoutCount', 0);

  // Tag analytics with this new UID
  await analytics.setUserId(id: u.uid);
  debugPrint("✅ Anon sign-in: ${u.uid}");
  return u;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create one global Analytics instance
  final analytics = FirebaseAnalytics.instance;

  // Ensure user signed in & analytics knows the UID
  await ensureUserSignedIn(analytics);

  runApp(WorkoutLoggerApp(analytics: analytics));
}

class WorkoutLoggerApp extends StatelessWidget {
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  WorkoutLoggerApp({super.key, required this.analytics})
    : observer = FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Overload Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      navigatorObservers: [observer], // ← auto-track screen views
      initialRoute: '/home',
      routes: {
        '/home': (_) => const HomeScreen(),
        '/settings': (_) => const SettingScreen(),
        '/signup': (_) => const AuthScreen(),
        //'/progress': (_) => const ProgressScreen(),
      },
    );
  }
}
