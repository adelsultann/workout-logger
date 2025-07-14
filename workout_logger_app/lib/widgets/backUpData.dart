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
  String _selectedFormat = 'organized'; // 'organized' or 'separate'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
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
                color: const Color(0xFF2C2C2E),
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
                    'Export your workout data in an organized format. Each routine will be clearly structured with its exercises and workout logs for easy reading and analysis.',
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

            // ───── Export Format Selection ─────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF22FF7A).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Format:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFormatOption(
                    'organized',
                    'Organized Format',
                    'All routines in one file, clearly separated and structured',
                    Icons.view_stream,
                  ),
                  const SizedBox(height: 12),
                  _buildFormatOption(
                    'separate',
                    'Separate Files',
                    'Each routine in its own file for individual analysis',
                    Icons.folder_open,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ───── Export Options ─────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
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
                    'Routine Structure',
                    'Each routine with its name and description',
                    Icons.format_list_bulleted,
                  ),
                  _buildExportItem(
                    'Exercise Details',
                    'Exercise names, sets, and specifications',
                    Icons.fitness_center,
                  ),
                  _buildExportItem(
                    'Workout Logs',
                    'Reps, weights, and dates for each exercise',
                    Icons.history,
                  ),
                  _buildExportItem(
                    'Organized Layout',
                    'Easy-to-read format with clear sections',
                    Icons.dashboard,
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
                          'Export Workout Data',
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
                  color: const Color(0xFF2C2C2E),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFormat = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedFormat == value
              ? const Color(0xFF22FF7A).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedFormat == value
                ? const Color(0xFF22FF7A)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _selectedFormat == value
                  ? const Color(0xFF22FF7A)
                  : Colors.white.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _selectedFormat == value
                          ? const Color(0xFF22FF7A)
                          : Colors.white,
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
            if (_selectedFormat == value)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF22FF7A),
                size: 20,
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
        _exportStatus = 'Fetching routines and exercises...';
      });

      // Fetch all data
      final routines = await ApiService.getRoutines();
      final List<RoutineWithData> routinesWithData = [];

      for (final routine in routines) {
        final exercises = await ApiService.getExercises(routine.id);
        final List<ExerciseWithLogs> exercisesWithLogs = [];

        for (final exercise in exercises) {
          final logs = await ApiService.getLogs(exercise.id);
          exercisesWithLogs.add(ExerciseWithLogs(exercise, logs));
        }

        routinesWithData.add(RoutineWithData(routine, exercisesWithLogs));
      }

      setState(() {
        _exportStatus = 'Creating organized files...';
      });

      // Create files based on selected format
      final files = await _createExportFiles(routinesWithData);

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

  Future<List<File>> _createExportFiles(
    List<RoutineWithData> routinesWithData,
  ) async {
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    final files = <File>[];

    if (_selectedFormat == 'organized') {
      // Create one organized file with all routines
      final content = _createOrganizedContent(routinesWithData);
      final file = await _saveFile(
        'overload_pro_workout_data_$timestamp.txt',
        content,
      );
      files.add(file);
    } else {
      // Create separate files for each routine
      for (final routineData in routinesWithData) {
        final content = _createSingleRoutineContent(routineData);
        final safeName = _sanitizeFileName(routineData.routine.name);
        final file = await _saveFile(
          'overload_pro_${safeName}_$timestamp.txt',
          content,
        );
        files.add(file);
      }
    }

    return files;
  }

  String _createOrganizedContent(List<RoutineWithData> routinesWithData) {
    final buffer = StringBuffer();
    buffer.writeln('OVERLOAD PRO - WORKOUT DATA EXPORT');
    buffer.writeln('Generated: ${DateTime.now().toString()}');
    buffer.writeln('${'=' * 50}');
    buffer.writeln('');

    for (int i = 0; i < routinesWithData.length; i++) {
      final routineData = routinesWithData[i];
      buffer.write(_createSingleRoutineContent(routineData));

      if (i < routinesWithData.length - 1) {
        buffer.writeln('');
        buffer.writeln('${'=' * 50}');
        buffer.writeln('');
      }
    }

    return buffer.toString();
  }

  String _createSingleRoutineContent(RoutineWithData routineData) {
    final buffer = StringBuffer();
    final routine = routineData.routine;

    buffer.writeln('=== ${routine.name.toUpperCase()} ===');
    buffer.writeln(
      'Created: ${routine.createdAt?.toString().split(' ')[0] ?? 'Unknown'}',
    );
    buffer.writeln('');

    if (routineData.exercises.isEmpty) {
      buffer.writeln('No exercises found for this routine.');
      buffer.writeln('');
      return buffer.toString();
    }

    for (final exerciseData in routineData.exercises) {
      final exercise = exerciseData.exercise;
      buffer.writeln('>> ${exercise.name} (${exercise.totalSets} sets)');

      if (exerciseData.logs.isEmpty) {
        buffer.writeln('   No workout logs recorded');
      } else {
        // Sort logs by date (newest first)
        final sortedLogs = exerciseData.logs.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        for (final log in sortedLogs) {
          buffer.write('   Date: ${log.date.toString().split(' ')[0]}');
          buffer.write(' | Reps: ${log.reps}');
          buffer.write(' | Weight: ${log.weight}kg');

          if (log.notes != null && log.notes!.isNotEmpty) {
            buffer.write(' | Notes: ${log.notes}');
          }
          buffer.writeln('');
        }
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  Future<File> _saveFile(String fileName, String content) async {
    final Directory directory;

    if (kIsWeb) {
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
          'Your workout data exported from Overload Pro app in organized format.',
    );
  }
}

// Helper classes for organizing data
class RoutineWithData {
  final Routine routine;
  final List<ExerciseWithLogs> exercises;

  RoutineWithData(this.routine, this.exercises);
}

class ExerciseWithLogs {
  final Exercise exercise;
  final List<WorkoutLog> logs;

  ExerciseWithLogs(this.exercise, this.logs);
}
