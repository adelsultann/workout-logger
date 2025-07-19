import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:overload_pro_app/models/workout_log.dart';
import 'package:overload_pro_app/screens/exercise_progress_screen.dart';
import 'package:overload_pro_app/utils/unit_pref.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _notesController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<WorkoutLog> _logs = [];
  bool _isLoading = true;
  bool _isSaving = false;
  WeightUnit _unit = WeightUnit.kg;
  WorkoutLog? _lastLog;
  bool _showQuickFill = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initUnit();
    _loadLogs();
  }

  Future<void> _initUnit() async {
    final u = await UnitPref.get();
    // mounted property is part of the State class
    //it checks if the state object is still in the tree so when user leaves the screen it does not throw an error
    if (mounted) setState(() => _unit = u);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /* ----------------------------- LOAD / SAVE ----------------------------- */

  Future<void> _loadLogs() async {
    try {
      final data = await ApiService.getLogs(widget.exercise.id);
      // sort the log list by date descending(from newest to oldest)
      data.sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _logs = data;
        //if the list is not empty, set the last log
        _lastLog = data.isNotEmpty ? data.first : null;
        _showQuickFill = data.isNotEmpty;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (_) {
      _showErrorSnackBar('Failed to load workout history');
      setState(() => _isLoading = false);
    }
  }

  double _toKg(double value) =>
      _unit == WeightUnit.kg ? value : value / 2.20462;
  double _display(double kg) => _unit == WeightUnit.kg ? kg : kg * 2.20462;

  /// Fill the form with the last workout log data. If there is no last log or

  void _quickFillLastWorkout() {
    if (_lastLog != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _weightController.text = _display(_lastLog!.weight).toStringAsFixed(1);
        _repsController.text = _lastLog!.reps.toString();
        if (_lastLog!.notes != null) {
          _notesController.text = _lastLog!.notes!;
        }
      });
    }
  }

  Future<void> _submitLog() async {
    // if the form is not valid, return
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
        _lastLog = newLog;
        _isSaving = false;
        _formKey.currentState?.reset();
        _weightController.clear();
        _repsController.clear();
        _notesController.clear();
        FocusScope.of(context).unfocus();
      });
      _showSuccessSnackBar('Set logged successfully! 💪');
    } catch (_) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to save workout log');
    }
  }

  Future<void> _deleteLog(String id) async {
    try {
      await ApiService.deleteLog(id);
      setState(() {
        _logs.removeWhere((l) => l.id == id);
        _lastLog = _logs.isNotEmpty ? _logs.first : null;
      });
      _showSuccessSnackBar('Set deleted');
    } catch (_) {
      _showErrorSnackBar('Failed to delete set');
    }
  }

  /* --------------------------------  UI  --------------------------------- */

  @override
  Widget build(BuildContext context) {
    final unitLabel = _unit == WeightUnit.kg ? 'kg' : 'lbs';

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),

      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildWorkoutForm(unitLabel),
                ),
                const SizedBox(height: 32),
                _buildStatsCards(),
                const SizedBox(height: 32),
                _buildRecentLogsSection(unitLabel),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF1C1C1E),
      elevation: 0,

      //expandedHeight: 120,
      leading: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.exercise.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1C1C1E), Color(0xFF1C1C1E)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutForm(String unitLabel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF22FF7A).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: Color(0xFF22FF7A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Log New Set',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_showQuickFill)
                  TextButton.icon(
                    onPressed: _quickFillLastWorkout,
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Fill Last'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF22FF7A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedInputField(
                    controller: _weightController,
                    label: 'Weight',
                    suffix: unitLabel,
                    icon: Icons.fitness_center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEnhancedInputField(
                    controller: _repsController,
                    label: 'Reps',
                    icon: Icons.repeat,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            // note field option
            // const SizedBox(height: 16),
            // _buildEnhancedInputField(
            //   controller: _notesController,
            //   label: 'Notes (optional)',
            //   icon: Icons.note,
            //   isOptional: true,
            //   maxLines: 3,
            // ),
            const SizedBox(height: 24),
            _buildEnhancedSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    bool isOptional = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A9B8A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 16),
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
            prefixIcon: Icon(icon, color: const Color(0xFF22FF7A), size: 20),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Color(0xFF8A9B8A)),
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22FF7A), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submitLog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22FF7A),
          disabledBackgroundColor: const Color(0xFF22FF7A).withOpacity(.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Save Set',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_logs.isEmpty) return const SizedBox.shrink();

    final totalSets = widget.exercise.totalSets;
    final maxWeight = _logs.map((e) => e.weight).reduce(max);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Sets',
            totalSets.toString(),
            Icons.fitness_center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Max Weight',
            '${_display(maxWeight).toStringAsFixed(1)} ${_unit == WeightUnit.kg ? 'kg' : 'lbs'}',
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF22FF7A), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8A9B8A), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogsSection(String unitLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: Color(0xFF22FF7A), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Recent Sets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _goToProgress,
              icon: const Icon(Icons.analytics, size: 16),
              label: const Text('View Progress'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF22FF7A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLogsList(unitLabel),
      ],
    );
  }

  Widget _buildLogsList(String unitLabel) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFF22FF7A)),
        ),
      );
    }

    final displayLogs = _logs
        .take(widget.exercise.totalSets)
        .toList(); // Show more logs

    if (displayLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.fitness_center, color: Color(0xFF8A9B8A), size: 48),
            SizedBox(height: 16),
            Text(
              'No sets logged yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start by logging your first set above!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8A9B8A)),
            ),
          ],
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
          child: _buildEnhancedLogItem(log, setNumber, unitLabel, idx == 0),
        );
      },
    );
  }

  Widget _buildEnhancedLogItem(
    WorkoutLog log,
    int setNumber,
    String unitLabel,
    bool isLatest,
  ) {
    final isToday = DateTime.now().difference(log.date).inDays == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest
              ? const Color(0xFF22FF7A).withOpacity(0.3)
              : const Color(0xFF2C2C2E),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLatest
                  ? const Color(0xFF22FF7A)
                  : const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                setNumber.toString(),
                style: TextStyle(
                  color: isLatest ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_display(log.weight).toStringAsFixed(1)} $unitLabel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22FF7A).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${log.reps} reps',
                        style: const TextStyle(
                          color: Color(0xFF22FF7A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isToday
                      ? 'Today'
                      : DateFormat('MMM d, yyyy').format(log.date.toLocal()),
                  style: const TextStyle(
                    color: Color(0xFF8A9B8A),
                    fontSize: 14,
                  ),
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
          ),
          if (isLatest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22FF7A).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Latest',
                style: TextStyle(
                  color: Color(0xFF22FF7A),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _goToProgress() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExerciseProgressScreen(
        exerciseName: widget.exercise.name,
        exerciseId: widget.exercise.id,
      ),
    ),
  );

  Widget _buildDismissibleBackground() => Container(
    margin: const EdgeInsets.only(bottom: 12),
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
        Text(
          'Delete',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Future<bool?> _showDeleteConfirmationDialog() => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Set?', style: TextStyle(color: Colors.white)),
      content: const Text(
        'This action cannot be undone.',
        style: TextStyle(color: Color(0xFF8A9B8A)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF8A9B8A)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  void _showSuccessSnackBar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF22FF7A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  void _showErrorSnackBar(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
}
