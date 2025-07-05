import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:overload_pro_app/models/exercise.dart';
import 'package:overload_pro_app/models/routine.dart';
import 'package:overload_pro_app/models/workout_log.dart';
import 'package:overload_pro_app/services/api_service.dart';
import 'package:overload_pro_app/widgets/bottom_nav_bar.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  /* ─────────────────────────  local state  ───────────────────────── */
  List<Routine> routines = [];
  List<Exercise> exercises = [];
  List<WorkoutLog> logs = [];

  Routine? selectedRoutine;
  Exercise? selectedExercise;

  bool showWeight = true;
  bool loadingRoutines = true;
  bool loadingExercises = false;
  bool loadingLogs = false;

  /* ─────────────────────────  lifecycle  ─────────────────────────── */
  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  /* ─────────────────────────  loaders  ───────────────────────────── */
  Future<void> _loadRoutines() async {
    setState(() => loadingRoutines = true);
    try {
      routines = await ApiService.getRoutines();
      if (routines.isNotEmpty) selectedRoutine = routines.first;
      await _loadExercises(); // chain-load
    } catch (e) {
      debugPrint('Routine load error: $e');
    }
    if (mounted) setState(() => loadingRoutines = false);
  }

  Future<void> _loadExercises() async {
    if (selectedRoutine == null) return;
    setState(() => loadingExercises = true);
    try {
      exercises = await ApiService.getExercises(selectedRoutine!.id);
      selectedExercise = exercises.isNotEmpty ? exercises.first : null;
      await _loadLogs();
    } catch (e) {
      debugPrint('Exercise load error: $e');
    }
    if (mounted) setState(() => loadingExercises = false);
  }

  Future<void> _loadLogs() async {
    if (selectedExercise == null) return;
    setState(() => loadingLogs = true);
    try {
      logs = await ApiService.getLogs(selectedExercise!.id);
      // newest last for chart
      logs.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('Logs load error: $e');
    }
    if (mounted) setState(() => loadingLogs = false);
  }

  /* ─────────────────────────  helpers  ───────────────────────────── */
  List<FlSpot> _spots() => List.generate(
    logs.length,
    (i) => FlSpot(
      i.toDouble(),
      showWeight ? logs[i].weight : logs[i].reps.toDouble(),
    ),
  );

  double get _maxY {
    if (logs.isEmpty) return 100;
    final values = logs
        .map((log) => showWeight ? log.weight : log.reps.toDouble())
        .toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    return max * 1.2; // Add 20% padding
  }

  double get _minY {
    if (logs.isEmpty) return 0;
    final values = logs
        .map((log) => showWeight ? log.weight : log.reps.toDouble())
        .toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    return (min * 0.8).clamp(
      0,
      double.infinity,
    ); // Subtract 20% but don't go below 0
  }

  String _getProgressSummary() {
    if (logs.length < 2) return 'Start tracking to see progress';

    final firstValue = showWeight
        ? logs.first.weight
        : logs.first.reps.toDouble();
    final lastValue = showWeight ? logs.last.weight : logs.last.reps.toDouble();
    final improvement = lastValue - firstValue;
    final unit = showWeight ? 'kg' : 'reps';

    if (improvement > 0) {
      return '+${improvement.toStringAsFixed(1)} $unit improvement';
    } else if (improvement < 0) {
      return '${improvement.toStringAsFixed(1)} $unit from start';
    } else {
      return 'No change from start';
    }
  }

  /* ─────────────────────────  build  ─────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Progress Tracker',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ───── Header Section ─────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2C1D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF22FF7A).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Routine',
                    style: TextStyle(
                      color: Color(0xFF22FF7A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ───── Routine dropdown ─────
                  loadingRoutines
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF22FF7A),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1E13),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF22FF7A).withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<Routine>(
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1A2C1D),
                            value: selectedRoutine,
                            iconEnabledColor: const Color(0xFF22FF7A),
                            underline: const SizedBox(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            items: routines
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(r.name),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (r) async {
                              if (r == null) return;
                              setState(() {
                                selectedRoutine = r;
                                selectedExercise = null;
                                logs = [];
                              });
                              await _loadExercises();
                            },
                          ),
                        ),

                  const SizedBox(height: 20),

                  const Text(
                    'Select Exercise',
                    style: TextStyle(
                      color: Color(0xFF22FF7A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ───── Exercise dropdown ─────
                  if (loadingExercises)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF22FF7A),
                      ),
                    )
                  else if (exercises.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'No exercises available',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF22FF7A).withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButton<Exercise>(
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A2C1D),
                        value: selectedExercise,
                        iconEnabledColor: const Color(0xFF22FF7A),
                        underline: const SizedBox(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        items: exercises
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(e.name),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (e) async {
                          if (e == null) return;
                          setState(() {
                            selectedExercise = e;
                          });
                          await _loadLogs();
                        },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ───── Metrics Toggle & Summary ─────
            if (selectedExercise != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Weight / Reps toggle
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2C1D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF22FF7A).withOpacity(0.3),
                      ),
                    ),
                    child: ToggleButtons(
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: Colors.black,
                      fillColor: const Color(0xFF22FF7A),
                      color: Colors.white70,
                      borderColor: Colors.transparent,
                      selectedBorderColor: Colors.transparent,
                      isSelected: [showWeight, !showWeight],
                      onPressed: (i) => setState(() => showWeight = i == 0),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Weight',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Reps',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress summary
                  if (logs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22FF7A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF22FF7A).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getProgressSummary(),
                        style: const TextStyle(
                          color: Color(0xFF22FF7A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),
            ],

            // ───── Chart Section ─────
            Container(
              height: 320,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2C1D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF22FF7A).withOpacity(0.3),
                ),
              ),
              child: loadingLogs
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF22FF7A),
                      ),
                    )
                  : logs.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedExercise == null
                              ? 'Select an exercise to view progress'
                              : 'No workout data available',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete some workouts to see your progress chart',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedExercise?.name} - ${showWeight ? 'Weight' : 'Reps'} Progress',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: true,
                                drawVerticalLine: false,
                                horizontalInterval: (_maxY - _minY) / 5,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withOpacity(0.1),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 &&
                                          value.toInt() < logs.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            'W${value.toInt() + 1}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 48,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Text(
                                          value.toInt().toString(),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minY: _minY,
                              maxY: _maxY,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _spots(),
                                  isCurved: true,
                                  barWidth: 3,
                                  color: const Color(0xFF22FF7A),
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 4,
                                            color: const Color(0xFF22FF7A),
                                            strokeWidth: 2,
                                            strokeColor: const Color(
                                              0xFF0F1E13,
                                            ),
                                          );
                                        },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(
                                      0xFF22FF7A,
                                    ).withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // ───── Stats Cards ─────
            if (logs.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2C1D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF22FF7A).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Best ${showWeight ? 'Weight' : 'Reps'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${logs.map((l) => showWeight ? l.weight : l.reps.toDouble()).reduce((a, b) => a > b ? a : b).toStringAsFixed(showWeight ? 1 : 0)}${showWeight ? ' kg' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF22FF7A),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2C1D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF22FF7A).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workouts',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            logs.length.toString(),
                            style: const TextStyle(
                              color: Color(0xFF22FF7A),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/progress');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
            case 3:
              // Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}
