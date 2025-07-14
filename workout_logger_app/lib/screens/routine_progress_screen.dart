import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:overload_pro_app/models/workout_log.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:overload_pro_app/utils/unit_pref.dart';

enum TimePeriod { week, month, year }

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
  TimePeriod selectedPeriod = TimePeriod.month;
  bool isLoading = true;
  WeightUnit _unit = WeightUnit.kg;

  @override
  void initState() {
    super.initState();
    UnitPref.get().then((u) => setState(() => _unit = u));
    fetchAllLogs();
  }

  /* ───────────────────────────────── helpers ───────────────────────────── */

  double _display(double kg) => _unit == WeightUnit.kg ? kg : kg * 2.20462;
  String _unitLbl() => _unit == WeightUnit.kg ? 'kg' : 'lbs';

  Future<void> fetchAllLogs() async {
    try {
      final exercises = await ApiService.getExercises(widget.routineId);
      if (exercises.isNotEmpty) {
        selectedExerciseName = exercises.first.name;
      }
      for (var ex in exercises) {
        final logs = await ApiService.getLogs(ex.id);
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

  List<WorkoutLog> _getFilteredLogs() {
    if (selectedExerciseName == null ||
        !exerciseLogs.containsKey(selectedExerciseName)) {
      return [];
    }

    final allLogs = exerciseLogs[selectedExerciseName]!;
    final now = DateTime.now();

    switch (selectedPeriod) {
      case TimePeriod.week:
        return allLogs
            .where(
              (log) => log.date.isAfter(now.subtract(const Duration(days: 7))),
            )
            .toList();
      case TimePeriod.month:
        return allLogs
            .where(
              (log) => log.date.isAfter(now.subtract(const Duration(days: 30))),
            )
            .toList();
      case TimePeriod.year:
        return allLogs
            .where(
              (log) =>
                  log.date.isAfter(now.subtract(const Duration(days: 365))),
            )
            .toList();
    }
  }

  String _getDateFormat() {
    switch (selectedPeriod) {
      case TimePeriod.week:
        return 'E'; // Mon, Tue, Wed
      case TimePeriod.month:
        return 'd MMM'; // 27 Jun
      case TimePeriod.year:
        return 'MMM'; // Jun, Jul
    }
  }

  Widget _buildTimePeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22FF7A).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TimePeriod.values.map((period) {
          final isSelected = selectedPeriod == period;
          final label = period.name.toUpperCase();

          return GestureDetector(
            onTap: () => setState(() => selectedPeriod = period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF22FF7A)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCard() {
    final logs = _getFilteredLogs();
    if (logs.isEmpty) return const SizedBox();

    final isWeight = showWeight[selectedExerciseName]!;

    // Apply unit conversion for weight display
    final latestValue = isWeight
        ? _display(logs.last.weight)
        : logs.last.reps.toDouble();
    final startingValue = isWeight
        ? _display(logs.first.weight)
        : logs.first.reps.toDouble();

    double percentageChange = 0;
    if (startingValue > 0) {
      percentageChange = ((latestValue - startingValue) / startingValue) * 100;
    }

    final periodText = selectedPeriod == TimePeriod.week
        ? 'Week'
        : selectedPeriod == TimePeriod.month
        ? 'Month'
        : 'Year';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C2C2E),
            const Color(0xFF2C2C2E).withOpacity(0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22FF7A).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$selectedExerciseName ${isWeight ? "Weight" : "Reps"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: percentageChange >= 0
                      ? const Color(0xFF22FF7A).withOpacity(0.2)
                      : Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: percentageChange >= 0
                        ? const Color(0xFF22FF7A)
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latestValue.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  isWeight ? _unitLbl() : "reps", // Use unit label
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last $periodText Progress',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final logs = _getFilteredLogs();
    final screenHeight = MediaQuery.of(context).size.height;
    final chartHeight = (screenHeight * 0.4).clamp(250.0, 400.0);

    if (logs.isEmpty) {
      return Container(
        height: chartHeight,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2C1D).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF22FF7A).withOpacity(0.1)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, color: Colors.white30, size: 48),
              SizedBox(height: 16),
              Text(
                "No data available for this period",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final isWeight = showWeight[selectedExerciseName]!;

    // Apply unit conversion for chart spots
    final spots = logs
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
            entry.key.toDouble(),
            isWeight
                ? _display(entry.value.weight) // Convert weight units
                : entry.value.reps.toDouble(),
          ),
        )
        .toList();

    final values = spots.map((spot) => spot.y).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    double finalMinY;
    double finalMaxY;
    double horizontalInterval;
    double leftTitleInterval;

    // Check if all data points are the same
    if (minValue == maxValue) {
      // If so, create a default visible range
      finalMinY = minValue - 5;
      finalMaxY = maxValue + 5;
      horizontalInterval = 2.5;
      leftTitleInterval = 2.5;
    } else {
      final range = maxValue - minValue;
      final padding = range * 0.1;
      finalMinY = minValue - padding;
      finalMaxY = maxValue + padding;
      horizontalInterval = range / 4;
      leftTitleInterval = range / 4;
    }

    if (horizontalInterval == 0) horizontalInterval = 1;
    if (leftTitleInterval == 0) leftTitleInterval = 1;

    int getXAxisInterval() {
      if (logs.length <= 5) return 1;
      if (logs.length <= 10) return 2;
      if (logs.length <= 20) return 3;
      return (logs.length / 6).ceil();
    }

    return Container(
      height: chartHeight,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22FF7A).withOpacity(0.1)),
      ),
      child: LineChart(
        LineChartData(
          minY: finalMinY,
          maxY: finalMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            verticalInterval: getXAxisInterval().toDouble(),
            horizontalInterval: horizontalInterval,
            getDrawingVerticalLine: (value) =>
                FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: getXAxisInterval().toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < logs.length) {
                    final log = logs[index];
                    final dateStr = DateFormat(
                      _getDateFormat(),
                    ).format(log.date);

                    // Apply unit conversion for bottom title display
                    final valueStr = isWeight
                        ? '${_display(log.weight).toStringAsFixed(1)}${_unitLbl()}'
                        : '${log.reps} reps';

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            valueStr,
                            style: const TextStyle(
                              color: Color(0xFF22FF7A),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                reservedSize: 50,
                interval: leftTitleInterval,
                getTitlesWidget: (value, meta) {
                  if (value == finalMinY) {
                    return const SizedBox();
                  }
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              barWidth: 3,
              color: const Color(0xFF22FF7A),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFF22FF7A),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF22FF7A).withOpacity(0.3),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${widget.routineName} Progress',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22FF7A)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF22FF7A).withOpacity(0.3),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF2C2C2E),
                        value: selectedExerciseName,
                        isExpanded: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
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
                          setState(() => selectedExerciseName = value);
                        },
                      ),
                    ),
                  ),

                  if (selectedExerciseName != null) ...[
                    const SizedBox(height: 24),

                    // Time Period Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_buildTimePeriodSelector()],
                    ),

                    const SizedBox(height: 24),

                    // Weight/Reps Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF22FF7A).withOpacity(0.3),
                            ),
                          ),
                          child: ToggleButtons(
                            borderRadius: BorderRadius.circular(10),
                            selectedColor: Colors.black,
                            fillColor: const Color(0xFF22FF7A),
                            color: Colors.white70,
                            borderColor: Colors.transparent,
                            selectedBorderColor: Colors.transparent,
                            constraints: const BoxConstraints(
                              minWidth: 100,
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
                            children: const [
                              Text(
                                'Weight',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Reps',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Stats Card
                    _buildStatsCard(),

                    const SizedBox(height: 24),

                    // Chart
                    _buildChart(),
                  ],
                ],
              ),
            ),
    );
  }
}
