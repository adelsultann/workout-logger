import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:workout_logger_app/models/workout_log.dart';
import 'package:intl/intl.dart'; // NEW: Add this package for date formatting
import '../services/api_service.dart';

class RoutineProgressScreen extends StatefulWidget {
  final String routineId;
  final String routineName;

  const RoutineProgressScreen({
    super.key,
    required this.routineId,
    required this.routineName,
  });

  @override
  State<RoutineProgressScreen> createState() => _RoutineProgressScreenState();
}

class _RoutineProgressScreenState extends State<RoutineProgressScreen> {
  String? selectedExerciseName;
  Map<String, List<WorkoutLog>> exerciseLogs = {};
  Map<String, bool> showWeight = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllLogs();
  }

  Future<void> fetchAllLogs() async {
    try {
      final exercises = await ApiService.getExercises(widget.routineId);
      if (exercises.isNotEmpty) {
        selectedExerciseName = exercises.first.name;
      }
      for (var ex in exercises) {
        final logs = await ApiService.getLogs(ex.id);
        // Sort logs by date to ensure correct chronological order for the chart
        logs.sort((a, b) => a.date.compareTo(b.date));
        exerciseLogs[ex.name] = logs;
        showWeight[ex.name] = true;
      }

      setState(() => isLoading = false);
    } catch (e) {
      print("Error fetching logs: $e");
      setState(() => isLoading = false);
    }
  }

  // NEW: Widget to build the stylish chart card
  Widget _buildChartCard() {
    if (selectedExerciseName == null ||
        !exerciseLogs.containsKey(selectedExerciseName) ||
        exerciseLogs[selectedExerciseName]!.isEmpty) {
      return const Center(
        child: Text(
          "No data available for this exercise.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    final logs = exerciseLogs[selectedExerciseName]!;
    final isWeight = showWeight[selectedExerciseName]!;

    // --- NEW: Calculate stats ---
    final last30DaysLogs = logs
        .where(
          (log) => log.date.isAfter(
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        )
        .toList();

    double latestValue = isWeight
        ? logs.last.weight
        : logs.last.reps.toDouble();
    double startingValue = (last30DaysLogs.isNotEmpty)
        ? (isWeight
              ? last30DaysLogs.first.weight
              : last30DaysLogs.first.reps.toDouble())
        : 0;

    double percentageChange = 0;
    if (startingValue > 0) {
      percentageChange = ((latestValue - startingValue) / startingValue) * 100;
    }

    final spots = logs
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
            entry.key.toDouble(),
            isWeight ? entry.value.weight : entry.value.reps.toDouble(),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- NEW: Header Section like the reference image ---
        Text(
          '$selectedExerciseName ${isWeight ? "Weight" : "Reps"}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${latestValue.toStringAsFixed(1)} ${isWeight ? "Kg" : "reps"}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Last 30 Days ',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            children: [
              TextSpan(
                text:
                    '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: percentageChange >= 0
                      ? const Color(0xFF22FF7A)
                      : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // --- UPDATED: Chart Section ---
        SizedBox(
          height: 300, // Make the chart bigger
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: (logs.length / 5)
                        .ceilToDouble(), // Adjust interval to avoid clutter
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < logs.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 10,
                          child: Text(
                            DateFormat(
                              'd MMM',
                            ).format(logs[index].date), // e.g., "27 Jun"
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3,
                  color: const Color(0xFF22FF7A),
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF22FF7A).withOpacity(0.4),
                        const Color(0xFF0F1E13).withOpacity(0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make it blend with the body
        elevation: 0,
        title: Text(
          '${widget.routineName} Progress',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22FF7A)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- UPDATED: Dropdown styling ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2C1D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF1A2C1D),
                        value: selectedExerciseName,
                        isExpanded: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        hint: const Text(
                          "Select Exercise",
                          style: TextStyle(color: Colors.white54),
                        ),
                        items: exerciseLogs.keys.map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedExerciseName = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (selectedExerciseName != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ToggleButtons(
                          borderRadius: BorderRadius.circular(10),
                          selectedColor: Colors.black,
                          fillColor: const Color(0xFF22FF7A),
                          color: Colors.white,
                          borderColor: const Color(0xFF22FF7A),
                          selectedBorderColor: const Color(0xFF22FF7A),
                          constraints: const BoxConstraints(
                            minWidth: 120,
                            minHeight: 40,
                          ),
                          isSelected: [
                            showWeight[selectedExerciseName] ?? true,
                            !(showWeight[selectedExerciseName] ?? true),
                          ],
                          onPressed: (index) {
                            setState(() {
                              showWeight[selectedExerciseName!] = index == 0;
                            });
                          },
                          children: const [Text('Weight'), Text('Reps')],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // --- UPDATED: Use the new chart card widget ---
                    _buildChartCard(),
                  ],
                ],
              ),
            ),
    );
  }
}
