import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Make sure you have this package
import 'package:overload_pro_app/models/workout_log.dart';
import '../models/exercise.dart';
import '../services/api_service.dart';

class LogWorkoutScreen extends StatefulWidget {
  final Exercise exercise;

  const LogWorkoutScreen({super.key, required this.exercise});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _notesController = TextEditingController();

  List<WorkoutLog> _logs = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Data Handling ---

  Future<void> _loadLogs() async {
    try {
      final data = await ApiService.getLogs(widget.exercise.id);
      data.sort((a, b) => b.date.compareTo(a.date)); // Sort newest to oldest
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load workout history');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      final newLog = await ApiService.addLog(
        exerciseId: widget.exercise.id,
        weight: double.parse(_weightController.text.trim()),
        reps: int.parse(_repsController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      setState(() {
        _logs.insert(0, newLog);
        _isSaving = false;
        _formKey.currentState?.reset();
        _weightController.clear();
        _repsController.clear();
        _notesController.clear();
        FocusScope.of(context).unfocus();
      });

      _showSuccessSnackBar('Workout logged successfully!');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to save workout log');
    }
  }

  // --- NEW: Handle Log Deletion ---
  Future<void> _deleteLog(String logId) async {
    try {
      await ApiService.deleteLog(logId);
      setState(() {
        _logs.removeWhere((log) => log.id == logId);
      });
      HapticFeedback.mediumImpact();
      _showSuccessSnackBar('Log deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete log');
    }
  }

  // --- UI Widgets ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        title: Text(
          widget.exercise.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildInputField(
                controller: _weightController,
                label: 'Weight (kg)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _repsController,
                label: 'Reps',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _notesController,
                label: 'Notes (optional)',
                isOptional: true,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 48),
              const Text(
                'Recent Logs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildLogsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool isOptional = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        if (keyboardType != null &&
            value != null &&
            value.isNotEmpty &&
            double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8A9B8A)),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF22FF7A), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submitLog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22FF7A),
          disabledBackgroundColor: const Color(0xFF22FF7A).withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Text(
                'Save Log',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Builds the list of recent workout logs.
  Widget _buildLogsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22FF7A)),
      );
    }

    // --- MODIFIED: Limit the list based on totalSets ---
    final displayLogs = _logs.take(widget.exercise.totalSets).toList();

    if (displayLogs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            'No logs yet. Save your first set!',
            style: TextStyle(color: Color(0xFF8A9B8A), fontSize: 16),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: displayLogs.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final log = displayLogs[index];
        final setNumber = displayLogs.length - index;

        // --- MODIFIED: Wrapped log item in a Dismissible for deletion ---
        return Dismissible(
          key: Key(log.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteLog(log.id),
          confirmDismiss: (_) => _showDeleteConfirmationDialog(),
          background: _buildDismissibleBackground(),
          child: _buildLogItem(log, setNumber),
        );
      },
    );
  }

  /// Builds a single log item card.
  Widget _buildLogItem(WorkoutLog log, int setNumber) {
    return Container(
      // Added a background color to prevent UI issues during dismissal
      color: const Color(0xFF1C1C1E),
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM d, yyyy').format(log.date.toLocal()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${log.weight} kg ⋅ ${log.reps} reps',
                style: const TextStyle(color: Color(0xFF8A9B8A), fontSize: 14),
              ),
            ],
          ),
          Text(
            'Set $setNumber',
            style: const TextStyle(
              color: Color(0xFF8A9B8A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Helper widgets for deletion ---

  /// Builds the red background that appears when swiping to delete.
  Widget _buildDismissibleBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 8),
          Text('Delete', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before deleting a log.
  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Log?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Color(0xFF8A9B8A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  // --- Snackbars for feedback ---

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF22FF7A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
