// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../models/workout_log.dart';
// import '../models/exercise.dart';
// import '../services/api_service.dart';

// class ProgressChartScreen extends StatefulWidget {
//   final Exercise exercise;

//   const ProgressChartScreen({super.key, required this.exercise});

//   @override
//   State<ProgressChartScreen> createState() => _ProgressChartScreenState();
// }

// class _ProgressChartScreenState extends State<ProgressChartScreen> {
//   List<WorkoutLog> logs = [];
//   bool isLoading = true;
//   String selectedMetric = 'Weight';

//   @override
//   void initState() {
//     super.initState();
//     fetchLogs();
//   }

//   Future<void> fetchLogs() async {
//     try {
//       final data = await ApiService.getLogs(widget.exercise.id);
//       data.sort((a, b) => a.date.compareTo(b.date)); // ensure order
//       setState(() {
//         logs = data;
//         isLoading = false;
//       });
//     } catch (e) {
//       print('Failed to load logs: $e');
//     }
//   }

//   List<FlSpot> getSpots(String metric) {
//     return List.generate(logs.length, (i) {
//       double y = (metric == 'Weight')
//           ? logs[i].weight
//           : logs[i].reps.toDouble();
//       return FlSpot(i.toDouble(), y);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final weightSpots = getSpots('Weight');
//     final repsSpots = getSpots('Reps');

//     return Scaffold(
//       backgroundColor: const Color(0xFF0F1E13),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF0F1E13),
//         elevation: 0,
//         title: Text(
//           '${widget.exercise.name} Progress',
//           style: const TextStyle(color: Colors.white),
//         ),
//       ),
//       body: isLoading
//           ? const Center(
//               child: CircularProgressIndicator(color: Colors.greenAccent),
//             )
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   DropdownButton<String>(
//                     value: selectedMetric,
//                     dropdownColor: const Color(0xFF1A2C1D),
//                     style: const TextStyle(color: Colors.white),
//                     items: ['Weight', 'Reps', 'Both']
//                         .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                         .toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         setState(() => selectedMetric = value);
//                       }
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                   Expanded(
//                     child: LineChart(
//                       LineChartData(
//                         backgroundColor: const Color(0xFF1A2C1D),
//                         borderData: FlBorderData(show: false),
//                         titlesData: FlTitlesData(
//                           leftTitles: AxisTitles(
//                             sideTitles: SideTitles(showTitles: true),
//                           ),
//                           bottomTitles: AxisTitles(
//                             sideTitles: SideTitles(
//                               showTitles: true,
//                               interval: 1,
//                               getTitlesWidget: (value, meta) {
//                                 if (value.toInt() < logs.length) {
//                                   final date = logs[value.toInt()].date;
//                                   return Text(
//                                     "${date.month}/${date.day}",
//                                     style: const TextStyle(
//                                       color: Colors.white38,
//                                       fontSize: 10,
//                                     ),
//                                   );
//                                 }
//                                 return const Text('');
//                               },
//                             ),
//                           ),
//                           topTitles: AxisTitles(
//                             sideTitles: SideTitles(showTitles: false),
//                           ),
//                           rightTitles: AxisTitles(
//                             sideTitles: SideTitles(showTitles: false),
//                           ),
//                         ),
//                         gridData: FlGridData(show: false),
//                         lineBarsData: [
//                           if (selectedMetric == 'Weight' ||
//                               selectedMetric == 'Both')
//                             LineChartBarData(
//                               spots: weightSpots,
//                               isCurved: true,
//                               color: Colors.greenAccent,
//                               dotData: FlDotData(show: true),
//                               barWidth: 3,
//                             ),
//                           if (selectedMetric == 'Reps' ||
//                               selectedMetric == 'Both')
//                             LineChartBarData(
//                               spots: repsSpots,
//                               isCurved: true,
//                               color: Colors.tealAccent,
//                               dotData: FlDotData(show: true),
//                               barWidth: 3,
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
