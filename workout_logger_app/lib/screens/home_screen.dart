import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overload_pro_app/screens/routine_detail_screen.dart';
import '../models/routine.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Routine> routines = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRoutines();
  }

  Future<void> loadRoutines() async {
    try {
      final data = await ApiService.getRoutines();

      setState(() {
        routines = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  void showAddRoutineDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2C2C2E),
        title: Text("New Routine", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "e.g., Pull Day",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF22FF7A)),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              try {
                final newRoutine = await ApiService.addRoutine(name);
                await FirebaseAnalytics.instance.logEvent(
                  name: 'create_routine',
                  parameters: {
                    'routine_id': newRoutine.id,
                    'routine_name': newRoutine.name,
                  },
                );
                setState(() {
                  routines.add(newRoutine);
                });
                Navigator.pop(context);
              } catch (e) {
                print('Failed to add routine: $e');
              }
            },
            child: Text("Create", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E),
        elevation: 0,
        title: Text(
          'Welcome back, Adel',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: showAddRoutineDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF22FF7A),
                      foregroundColor: Colors.black,
                    ),
                    child: Text("Create New Routine"),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Your Routines",
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: routines.length,
                      itemBuilder: (context, index) {
                        final routine = routines[index];
                        return Dismissible(
                          key: Key(routine.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF2C2C2E),
                                title: const Text(
                                  "Delete Routine",
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  "Are you sure you want to delete this routine?",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF22FF7A),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            try {
                              await ApiService.deleteRoutine(routine.id);
                              setState(() {
                                routines.removeAt(index);
                              });
                            } catch (e) {
                              print("Error deleting routine: $e");
                            }
                          },
                          child: Card(
                            color: const Color(0xFF2C2C2E),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                routine.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Created: ${routine.createdAt.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(color: Colors.white54),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white30,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RoutineDetailScreen(routine: routine),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
            // case 2:
            //   Navigator.pushReplacementNamed(context, '/settings');
            //   break;
            // case 3:
            //   // Navigator.pushReplacementNamed(context, '/profile');
            //   break;
          }
        },
      ),
    );
  }
}
