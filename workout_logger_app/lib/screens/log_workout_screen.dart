import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workout_logger_app/models/workout_log.dart';
import '../models/exercise.dart';

import '../services/api_service.dart';

class LogWorkoutScreen extends StatefulWidget {
  final Exercise exercise;

  const LogWorkoutScreen({super.key, required this.exercise});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen>
    with TickerProviderStateMixin {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<WorkoutLog> logs = [];
  bool isLoading = true;
  bool isSaving = false;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    loadLogs();
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> loadLogs() async {
    try {
      final data = await ApiService.getLogs(widget.exercise.id);
      setState(() {
        logs = data;
        print('this is thelog for the sets <>list       $logs');
        print('this is logs length: ${logs.length}');
        print('ththis is the firstst: ${logs.first}');
        print('this is logs first weight: ${logs.first.weight}');
        print('this is logs first reps: ${logs.first.reps}');
        print('this is logs first notes: ${logs.first.notes}');
        print('this is the total sets: ${logs.first.totalSets}');
        isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load workout history');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> submitLog() async {
    if (!_formKey.currentState!.validate()) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      isSaving = true;
    });

    final weight = double.parse(_weightController.text.trim());
    final reps = int.parse(_repsController.text.trim());
    final notes = _notesController.text.trim();

    try {
      final newLog = await ApiService.addLog(
        userId: 'user123',
        exerciseId: widget.exercise.id,
        weight: weight,
        reps: reps,
        notes: notes.isEmpty ? null : notes,
      );

      setState(() {
        logs.insert(0, newLog); // Add to top for chronological order
        _weightController.clear();
        _repsController.clear();
        _notesController.clear();
        isSaving = false;
      });

      _showSuccessSnackBar('Workout logged successfully!');
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      _showErrorSnackBar('Failed to save workout log');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF22FF7A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C1D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3D2E), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8A9B8A)),
          prefixIcon: Icon(icon, color: const Color(0xFF22FF7A), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (logs.isEmpty) return const SizedBox.shrink();

    final lastLog = logs.first;
    final totalSets = widget.exercise.totalSets;
    final maxWeight = logs
        .map((log) => log.weight)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2C1D), Color(0xFF0F1E13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22FF7A).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: const Color(0xFF22FF7A), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Your Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Last Weight',
                  '${lastLog.weight} kg',
                  Icons.fitness_center,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Sets',
                  '$totalSets',
                  Icons.format_list_numbered,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Max Weight',
                  '${maxWeight} kg',
                  Icons.emoji_events,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8A9B8A), size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8A9B8A), fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Log your workout',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        toolbarHeight: 80,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats Card
              _buildStatsCard(),

              // Form Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2C1D).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A3D2E)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Set',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _weightController,
                              label: 'Weight (kg)',
                              icon: Icons.fitness_center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputField(
                              controller: _repsController,
                              label: 'Reps',
                              icon: Icons.repeat,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _notesController,
                        label: 'Notes (optional)',
                        icon: Icons.note_alt_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      ScaleTransition(
                        scale: _buttonScaleAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () {
                                    _buttonAnimationController.forward().then((
                                      _,
                                    ) {
                                      _buttonAnimationController.reverse();
                                    });
                                    submitLog();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22FF7A),
                              disabledBackgroundColor: const Color(
                                0xFF22FF7A,
                              ).withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.black,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Log Set',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // History Section
              Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF22FF7A), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Workout History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (logs.isNotEmpty)
                    Text(
                      '${logs.length} sets',
                      style: const TextStyle(
                        color: Color(0xFF8A9B8A),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // History List
              SizedBox(
                height: 300,
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF22FF7A),
                        ),
                      )
                    : logs.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2C1D).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2A3D2E)),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center_outlined,
                                color: Color(0xFF8A9B8A),
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No workout history yet',
                                style: TextStyle(
                                  color: Color(0xFF8A9B8A),
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Log your first set to get started!',
                                style: TextStyle(
                                  color: Color(0xFF8A9B8A),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final isLatest = index == 0;

                          return Dismissible(
                            key: Key(log.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red[600],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: const Color(0xFF1A2C1D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    'Delete Workout Log',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'This action cannot be undone. Are you sure you want to delete this workout log?',
                                    style: TextStyle(color: Color(0xFF8A9B8A)),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Color(0xFF8A9B8A),
                                        ),
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              try {
                                await ApiService.deleteLog(log.id);
                                setState(() {
                                  logs.removeAt(index);
                                });
                                HapticFeedback.mediumImpact();
                                _showSuccessSnackBar('Workout log deleted');
                              } catch (e) {
                                _showErrorSnackBar(
                                  'Failed to delete workout log',
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isLatest
                                    ? const Color(0xFF22FF7A).withOpacity(0.1)
                                    : const Color(0xFF1A2C1D),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isLatest
                                      ? const Color(0xFF22FF7A).withOpacity(0.3)
                                      : const Color(0xFF2A3D2E),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isLatest
                                        ? const Color(
                                            0xFF22FF7A,
                                          ).withOpacity(0.2)
                                        : const Color(0xFF2A3D2E),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: isLatest
                                        ? const Color(0xFF22FF7A)
                                        : const Color(0xFF8A9B8A),
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      '${log.weight} kg × ${log.reps} reps',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (isLatest) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22FF7A),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Latest',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      log.date.toLocal().toString().split(
                                        ' ',
                                      )[0],
                                      style: const TextStyle(
                                        color: Color(0xFF8A9B8A),
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (log.notes != null &&
                                        log.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        log.notes!,
                                        style: const TextStyle(
                                          color: Color(0xFF8A9B8A),
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.drag_handle,
                                  color: Color(0xFF8A9B8A),
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
