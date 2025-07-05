import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:overload_pro_app/services/api_service.dart';
import 'package:overload_pro_app/models/routine.dart';
import 'package:overload_pro_app/models/exercise.dart';
import 'package:overload_pro_app/models/workout_log.dart';

class BackupExportWidget extends StatefulWidget {
  const BackupExportWidget({super.key});

  @override
  State<BackupExportWidget> createState() => _BackupExportWidgetState();
}

class _BackupExportWidgetState extends State<BackupExportWidget> {
  bool _isExporting = false;
  String _exportStatus = '';
  List<String> _exportedFiles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Backup & Export',
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
            // ───── Export Description ─────
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
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_download,
                        color: Color(0xFF22FF7A),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Export Your Data',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Export all your workout data including routines, exercises, and workout logs as CSV files. This backup can be used to restore your data or analyze your progress in external tools.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ───── Export Options ─────
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
                    'What will be exported:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildExportItem(
                    'Routines',
                    'All your workout routines with details',
                    Icons.format_list_bulleted,
                  ),
                  _buildExportItem(
                    'Exercises',
                    'Exercise details, sets, reps, and weights',
                    Icons.fitness_center,
                  ),
                  _buildExportItem(
                    'Workout Logs',
                    'Complete workout history and progress',
                    Icons.history,
                  ),
                  _buildExportItem(
                    'Timestamps',
                    'Creation and modification dates',
                    Icons.access_time,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ───── Export Button ─────
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22FF7A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _isExporting ? null : _exportAllData,
              child: _isExporting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Exporting...',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'Export All Data',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // ───── Export Status ─────
            if (_exportStatus.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _exportStatus.contains('Success')
                      ? const Color(0xFF22FF7A).withOpacity(0.1)
                      : _exportStatus.contains('Error')
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF1A2C1D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _exportStatus.contains('Success')
                        ? const Color(0xFF22FF7A).withOpacity(0.3)
                        : _exportStatus.contains('Error')
                        ? Colors.red.withOpacity(0.3)
                        : const Color(0xFF22FF7A).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _exportStatus.contains('Success')
                          ? Icons.check_circle
                          : _exportStatus.contains('Error')
                          ? Icons.error
                          : Icons.info,
                      color: _exportStatus.contains('Success')
                          ? const Color(0xFF22FF7A)
                          : _exportStatus.contains('Error')
                          ? Colors.red
                          : Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _exportStatus,
                        style: TextStyle(
                          color: _exportStatus.contains('Success')
                              ? const Color(0xFF22FF7A)
                              : _exportStatus.contains('Error')
                              ? Colors.red
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ───── Exported Files List ─────
            if (_exportedFiles.isNotEmpty)
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
                      'Exported Files:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(_exportedFiles.map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.file_present,
                              color: Color(0xFF22FF7A),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                file,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ───── Instructions ─────
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
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF22FF7A),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'How it works:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep(
                    '1',
                    'Click "Export All Data" to start the process',
                  ),
                  _buildInstructionStep(
                    '2',
                    'Your data will be converted to CSV format',
                  ),
                  _buildInstructionStep(
                    '3',
                    'Files will be saved and shared automatically',
                  ),
                  _buildInstructionStep(
                    '4',
                    'Choose where to save or share your backup',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF22FF7A), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF22FF7A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAllData() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Preparing export...';
      _exportedFiles.clear();
    });

    try {
      // Request permissions for mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _requestPermissions();
      }

      setState(() {
        _exportStatus = 'Fetching data...';
      });

      // Fetch all data
      final routines = await ApiService.getRoutines();
      final allExercises = <Exercise>[];
      final allLogs = <WorkoutLog>[];

      // Collect all exercises and logs
      for (final routine in routines) {
        final exercises = await ApiService.getExercises(routine.id);
        allExercises.addAll(exercises);

        for (final exercise in exercises) {
          final logs = await ApiService.getLogs(exercise.id);
          allLogs.addAll(logs);
        }
      }

      setState(() {
        _exportStatus = 'Creating CSV files...';
      });

      // Create CSV files
      final routinesCsv = _createRoutinesCsv(routines);
      final exercisesCsv = _createExercisesCsv(allExercises);
      final logsCsv = _createLogsCsv(allLogs);

      // Save files
      final files = await _saveFiles({
        'routines': routinesCsv,
        'exercises': exercisesCsv,
        'workout_logs': logsCsv,
      });

      setState(() {
        _exportStatus = 'Sharing files...';
      });

      // Share files
      await _shareFiles(files);

      setState(() {
        _exportStatus = 'Success! Files exported and shared.';
        _exportedFiles = files.map((f) => f.path.split('/').last).toList();
      });
    } catch (e) {
      setState(() {
        _exportStatus = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  String _createRoutinesCsv(List<Routine> routines) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Name,Description,Created Date,Modified Date');

    for (final routine in routines) {
      buffer.writeln(
        [
          routine.id,
          _escapeCsvField(routine.name),

          routine.createdAt?.toIso8601String() ?? '',
          routine.createdAt?.toIso8601String() ?? '',
        ].join(','),
      );
    }

    return buffer.toString();
  }

  String _createExercisesCsv(List<Exercise> exercises) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Routine ID,Name,Sets,Reps,Weight,Rest Time,Notes,Created Date',
    );

    for (final exercise in exercises) {
      buffer.writeln(
        [
          exercise.id,
          exercise.routineId,
          _escapeCsvField(exercise.name),
          exercise.totalSets,
        ].join(','),
      );
    }

    return buffer.toString();
  }

  String _createLogsCsv(List<WorkoutLog> logs) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Exercise ID,Date,Sets Completed,Reps,Weight,Duration,Notes',
    );

    for (final log in logs) {
      buffer.writeln(
        [
          log.id,
          log.exerciseId,
          log.date.toIso8601String(),

          log.reps,
          log.weight,

          _escapeCsvField(log.notes ?? ''),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  Future<List<File>> _saveFiles(Map<String, String> csvData) async {
    final files = <File>[];
    final timestamp = DateTime.now().toIso8601String().split('T')[0];

    for (final entry in csvData.entries) {
      final fileName = 'overload_pro_${entry.key}_$timestamp.csv';
      final file = await _saveFile(fileName, entry.value);
      files.add(file);
    }

    return files;
  }

  Future<File> _saveFile(String fileName, String content) async {
    final Directory directory;

    if (kIsWeb) {
      // For web, we'll use a temporary approach
      throw UnimplementedError(
        'Web export not fully implemented in this example',
      );
    } else if (Platform.isAndroid) {
      directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  Future<void> _shareFiles(List<File> files) async {
    final xFiles = files.map((f) => XFile(f.path)).toList();

    await Share.shareXFiles(
      xFiles,
      subject: 'Overload Pro - Workout Data Export',
      text:
          'Your workout data exported from Overload Pro app. Import these CSV files to restore your data.',
    );
  }
}
