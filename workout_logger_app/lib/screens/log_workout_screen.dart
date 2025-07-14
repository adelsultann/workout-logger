import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:overload_pro_app/models/workout_log.dart';
import 'package:overload_pro_app/utils/unit_pref.dart';
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
  WeightUnit _unit = WeightUnit.kg; // default

  @override
  void initState() {
    super.initState();
    _initUnit();
    _loadLogs();
  }

  Future<void> _initUnit() async {
    final u = await UnitPref.get();
    if (mounted) setState(() => _unit = u);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /* ----------------------------- LOAD / SAVE ----------------------------- */

  Future<void> _loadLogs() async {
    try {
      final data = await ApiService.getLogs(widget.exercise.id);
      data.sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    } catch (_) {
      _showErrorSnackBar('Failed to load workout history');
      setState(() => _isLoading = false);
    }
  }

  double _toKg(double value) =>
      _unit == WeightUnit.kg ? value : value / 2.20462;
  double _display(double kg) => _unit == WeightUnit.kg ? kg : kg * 2.20462;

  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      final newLog = await ApiService.addLog(
        exerciseId: widget.exercise.id,
        weight: _toKg(double.parse(_weightController.text.trim())),
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
    } catch (_) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to save workout log');
    }
  }

  Future<void> _deleteLog(String id) async {
    try {
      await ApiService.deleteLog(id);
      setState(() => _logs.removeWhere((l) => l.id == id));
      _showSuccessSnackBar('Log deleted');
    } catch (_) {
      _showErrorSnackBar('Failed to delete log');
    }
  }

  /* --------------------------------  UI  --------------------------------- */

  @override
  Widget build(BuildContext context) {
    final unitLabel = _unit == WeightUnit.kg ? 'kg' : 'lbs';

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.exercise.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildInputField(
                controller: _weightController,
                label: 'Weight ($unitLabel)',
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
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Logs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLogsList(unitLabel),
            ],
          ),
        ),
      ),
    );
  }

  /* ------------------------  Re-usable Widgets  ------------------------- */

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool isOptional = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (v) {
        if (!isOptional && (v == null || v.isEmpty)) return 'Required';
        if (keyboardType != null &&
            v!.isNotEmpty &&
            double.tryParse(v) == null) {
          return 'Invalid number';
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
          disabledBackgroundColor: const Color(0xFF22FF7A).withOpacity(.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.black),
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

  Widget _buildLogsList(String unitLabel) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22FF7A)),
      );
    }

    final displayLogs = _logs.take(widget.exercise.totalSets).toList();

    if (displayLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'No logs yet. Save your first set!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8A9B8A)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayLogs.length,
      itemBuilder: (context, idx) {
        final log = displayLogs[idx];
        final setNumber = displayLogs.length - idx;
        return Dismissible(
          key: Key(log.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _showDeleteConfirmationDialog(),
          onDismissed: (_) => _deleteLog(log.id),
          background: _buildDismissibleBackground(),
          child: _buildLogItem(log, setNumber, unitLabel),
        );
      },
    );
  }

  Widget _buildLogItem(WorkoutLog log, int setNumber, String unitLabel) {
    return Container(
      color: const Color(0xFF1C1C1E),
      padding: const EdgeInsets.only(bottom: 16, top: 8),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_display(log.weight).toStringAsFixed(1)} $unitLabel · ${log.reps} reps',
                style: const TextStyle(color: Color(0xFF8A9B8A)),
              ),
            ],
          ),
          Text(
            'Set $setNumber',
            style: const TextStyle(color: Color(0xFF8A9B8A)),
          ),
        ],
      ),
    );
  }

  /* -------------------------  Delete helpers  -------------------------- */

  Widget _buildDismissibleBackground() => Container(
    margin: const EdgeInsets.only(bottom: 16, top: 8),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.red.shade400,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.centerRight,
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.delete, color: Colors.white),
        SizedBox(width: 8),
        Text('Delete', style: TextStyle(color: Colors.white)),
      ],
    ),
  );

  Future<bool?> _showDeleteConfirmationDialog() => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete log?', style: TextStyle(color: Colors.white)),
      content: const Text(
        'This action cannot be undone.',
        style: TextStyle(color: Color(0xFF8A9B8A)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  /* --------------------------  Snackbars  ----------------------------- */

  void _showSuccessSnackBar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFF22FF7A)),
      );
  void _showErrorSnackBar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
}
