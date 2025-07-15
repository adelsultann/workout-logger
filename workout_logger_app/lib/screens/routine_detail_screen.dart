// DESIGN NOTE: Removed unused packages & fixed naming inconsistencies.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overload_pro_app/screens/log_workout_screen.dart';
import 'package:overload_pro_app/screens/routine_progress_screen.dart';
import 'package:overload_pro_app/services/firebasUpgrade.dart';
import 'package:overload_pro_app/utils/usage_counter.dart';

import '../models/exercise.dart';
import '../models/routine.dart';
import '../services/api_service.dart';

class RoutineDetailScreen extends StatefulWidget {
  final Routine routine;
  const RoutineDetailScreen({super.key, required this.routine});
  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  List<Exercise> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  /* -------------------- Load all the exercise----------- */
  Future<void> _loadExercises() async {
    try {
      final data = await ApiService.getExercises(widget.routine.id);
      if (mounted) {
        setState(() {
          exercises = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  /* --------------- UPGRADE DIALOG ----------------------- */
  void _maybeShowSignupDialog(BuildContext ctx) async {
    final firstLaunchCount = await UsageCounter.getExerciseCount();
    if (firstLaunchCount < 1)
      return; // adjust this as needed for selecting the proper time

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogContext) {
        final emailCtrl = TextEditingController();
        final passCtrl = TextEditingController();
        final formKey = GlobalKey<FormState>();

        return AlertDialog(
          backgroundColor: const Color(0xFF1A2C1D), // Darker, modern background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Save Your Progress',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtitle explaining the benefit of signing up
              const Text(
                "Create a free account so you don't lose your workout history. 📈",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8A9B8A), fontSize: 15),
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    // Improved Email TextField
                    TextFormField(
                      controller: emailCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Color(0xFF8A9B8A)),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF8A9B8A),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Improved Password TextField
                    TextFormField(
                      controller: passCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Color(0xFF8A9B8A)),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF8A9B8A),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 24,
            top: 10,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            // Using a wider column for better button layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primary action button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22FF7A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;

                    try {
                      await upgradeAnonymousAccount(
                        email: emailCtrl.text.trim(),
                        password: passCtrl.text.trim(),
                      );

                      // Stop prompting after successful signup
                      await UsageCounter.resetExerciseCount();

                      if (dialogContext.mounted) Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Account created successfully! 🎉'),
                          backgroundColor: Color(0xFF22FF7A),
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(e.message ?? 'An error occurred.'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Signup failed: $e')),
                      );
                    }
                  },
                  child: const Text(
                    'Create Free Account',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Secondary "Later" button
                TextButton(
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(color: Color(0xFF8A9B8A)),
                  ),
                  onPressed: () async {
                    // Reset counter so it doesn't prompt again immediately
                    await UsageCounter.resetExerciseCount();
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /* ------ ADD EXERCISE DIALOG --------------------------- */
  void _showAddExerciseDialog() {
    final nameCtrl = TextEditingController();
    final setCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>(); // Key for validation

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add New Exercise',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtitle for better context
              const Text(
                'Enter the details for your new exercise.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8A9B8A), fontSize: 15),
              ),
              const SizedBox(height: 24),
              // Improved Exercise Name TextFormField
              TextFormField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  labelStyle: const TextStyle(color: Color(0xFF8A9B8A)),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 66, 66, 72),
                  prefixIcon: const Icon(
                    Icons.fitness_center_outlined,
                    color: Color(0xFF8A9B8A),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an exercise name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Improved Total Sets TextFormField
              TextFormField(
                controller: setCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                // Restrict input to numbers only
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Total Sets',
                  labelStyle: const TextStyle(color: Color(0xFF8A9B8A)),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 66, 66, 72),
                  prefixIcon: const Icon(
                    Icons.format_list_numbered,
                    color: Color(0xFF8A9B8A),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the number of sets';
                  }
                  final setCount = int.tryParse(value);
                  if (setCount == null || setCount <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22FF7A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  // Validate the form before proceeding
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  final name = nameCtrl.text.trim();
                  final setCount = int.parse(setCtrl.text.trim());

                  // Close dialog first for a smoother UX
                  Navigator.pop(dialogContext);

                  try {
                    final newExercise = await ApiService.addExercise(
                      widget.routine.id,
                      name,
                      setCount,
                    );
                    setState(() => exercises.add(newExercise));

                    // Check if the signup dialog should be shown
                    final count = await UsageCounter.incrementExerciseCount();
                    if (mounted && count >= 1) {
                      _maybeShowSignupDialog(context);
                    }
                  } catch (e) {
                    debugPrint('Failed to add exercise: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to add exercise.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Add Exercise',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              // Secondary "Cancel" button
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF8A9B8A)),
                ),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* --------------------------- NAVIGATION --------------------------- */
  void _goToProgress() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RoutineProgressScreen(
        routineId: widget.routine.id,
        routineName: widget.routine.name,
      ),
    ),
  );
  void _goToLog(Exercise ex) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => LogWorkoutScreen(exercise: ex)),
  );

  /* --------------------------- UI --------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.routine.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddExerciseDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF22FF7A),
        onPressed: _goToProgress,
        child: const Icon(Icons.bar_chart, color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exercises.isEmpty
          ? const Center(
              child: Text(
                'No exercises yet',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length,
              itemBuilder: (_, i) => _ExerciseCard(
                exercise: exercises[i],
                onTap: () => _goToLog(exercises[i]),
                onDismissed: () async {
                  await ApiService.deleteExercise(exercises[i].id);
                  if (mounted) setState(() => exercises.removeAt(i));
                },
              ),
            ),
    );
  }
}

/* --------------------------- EXERCISE CARD WIDGET --------------------------- */
class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(exercise.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async => await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          title: const Text('Delete?', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white54),

              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Color(0xFF22FF7A),
              ),
              child: const Text('Delete'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: Card(
        color: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: onTap,
          title: Text(
            exercise.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Total Sets: ${exercise.totalSets}',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Icon(
            CupertinoIcons.chevron_forward,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
