import 'package:flutter/material.dart';
import 'package:workout_logger_app/screens/progress_chart_screen.dart';
import 'package:workout_logger_app/screens/routine_progress_screen.dart';
import 'screens/home_screen.dart';

void main() {
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
