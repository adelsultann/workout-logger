import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("🔥 Starting Firebase init...");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("✅ Firebase init done!");
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

        // '/progress': (_) => ProgressChartScreen(),
        // '/calendar': (_) => CalendarScreen(),
        // '/profile': (_) => ProfileScreen(),
      },
    );
  }
}
