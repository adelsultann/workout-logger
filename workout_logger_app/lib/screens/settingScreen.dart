import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overload_pro_app/services/api_service.dart';
import 'package:overload_pro_app/widgets/backUpData.dart';
import 'package:overload_pro_app/widgets/bottom_nav_bar.dart';
import 'package:overload_pro_app/utils/unit_pref.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  int routineCount = 0;
  int exerciseCount = 0;
  int totalSets = 0;
  bool isLoading = true;
  WeightUnit _unit = WeightUnit.kg;

  @override
  void initState() {
    super.initState();
    _loadStats();
    UnitPref.get().then((u) => setState(() => _unit = u));
  }

  void _changeUnitDialog() async {
    final chosen = await showDialog<WeightUnit>(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: const Color(0xFF1A2C1D),
        title: const Text('Select unit', style: TextStyle(color: Colors.white)),
        children: WeightUnit.values.map((u) {
          return RadioListTile<WeightUnit>(
            value: u,
            groupValue: _unit,
            activeColor: const Color(0xFF22FF7A),
            title: Text(
              u == WeightUnit.kg ? 'Kilograms (kg)' : 'Pounds (lbs)',
              style: const TextStyle(color: Colors.white),
            ),
            onChanged: (v) => Navigator.pop(context, v),
          );
        }).toList(),
      ),
    );

    if (chosen != null && chosen != _unit) {
      await UnitPref.set(chosen);
      if (mounted) setState(() => _unit = chosen);
    }
  }

  Future<void> _loadStats() async {
    setState(() => isLoading = true);
    try {
      final routines = await ApiService.getRoutines();
      routineCount = routines.length;

      // gather all exercises for each routine
      exerciseCount = 0;
      totalSets = 0;
      for (final r in routines) {
        final ex = await ApiService.getExercises(r.id);
        exerciseCount += ex.length;
        totalSets += ex.fold(0, (sum, e) => sum + e.totalSets);
      }
    } catch (e) {
      debugPrint('Stats error: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  /* ---------------- AUTH ---------------- */

  Future<void> _handleAuthAction() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      // Navigate to sign-up / sign-in page
      Navigator.pushNamed(context, '/signup'); // create this route
    } else {
      // Show confirmation dialog before logging out
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Log Out',
                style: TextStyle(color: Color(0xFF22FF7A)),
              ),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        await FirebaseAuth.instance.signOut();
        if (mounted) setState(() {}); // refresh UI
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2C1D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'About Overload Pro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Color(0xFF22FF7A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your ultimate workout tracking companion. Track your progress, create custom routines, and achieve your fitness goals.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () async {
                const url = 'https://www.overloadpro.app/privacy';
                await Clipboard.setData(const ClipboardData(text: url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy Policy URL copied to clipboard!'),
                      backgroundColor: Color(0xFF22FF7A),
                    ),
                  );
                }
              },
              child: const Text(
                'Privacy Policy\nhttps://www.overloadpro.app/privacy',
                style: TextStyle(
                  color: Color(0xFF22FF7A),
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF22FF7A)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: const Color(0xFF22FF7A),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF22FF7A)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ───── Profile Section ─────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF22FF7A).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          // App Logo - Replace with your actual logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22FF7A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF22FF7A).withOpacity(0.3),
                              ),
                            ),
                            child: const Image(
                              image: AssetImage('assets/logoProOverLoad.png'),
                            ),
                            // To use your logo, replace the above with:
                            // child: Image.asset('assets/images/your_logo.png'),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Overload Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isGuest ? 'Guest User' : (user?.email ?? 'User'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isGuest
                                  ? Colors.orange.withOpacity(0.1)
                                  : const Color(0xFF22FF7A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isGuest
                                    ? Colors.orange.withOpacity(0.3)
                                    : const Color(0xFF22FF7A).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              isGuest ? 'Guest Account' : 'Premium User',
                              style: TextStyle(
                                color: isGuest
                                    ? Colors.orange
                                    : const Color(0xFF22FF7A),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ───── Workout Stats ─────
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
                            'Workout Statistics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Routines',
                                  routineCount.toString(),
                                  Icons.format_list_bulleted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Exercises',
                                  exerciseCount.toString(),
                                  Icons.fitness_center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            'Total Sets Completed',
                            totalSets.toString(),
                            Icons.check_circle,
                            fullWidth: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ───── Settings Options ─────
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF22FF7A).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDivider(),
                          _buildSettingsOption(
                            'Backup & Sync',
                            'Backup your workout data',
                            Icons.cloud_sync_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BackupExportWidget(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          // _buildDivider(),
                          // _buildSettingsOption(
                          //   'Help & Support',
                          //   'Get help and contact support',
                          //   Icons.help_outline,
                          //   onTap: () {
                          //     // Navigate to help
                          //   },
                          // ),
                          _buildSettingsOption(
                            'Weight Unit',
                            _unit == WeightUnit.kg
                                ? 'Currently kg'
                                : 'Currently lbs',
                            Icons.scale,
                            onTap: _changeUnitDialog,
                          ),

                          _buildDivider(),
                          _buildSettingsOption(
                            'About',
                            'App version and information',
                            Icons.info_outline,
                            onTap: _showAboutDialog,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ───── Auth Action Button ─────
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isGuest
                            ? const Color(0xFF22FF7A)
                            : Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _handleAuthAction,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isGuest ? Icons.login : Icons.logout,
                            color: isGuest ? Colors.black : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isGuest ? 'Sign In / Sign Up' : 'Log Out',
                            style: TextStyle(
                              color: isGuest ? Colors.black : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ───── Footer ─────
                    Text(
                      'Made with 💪 for fitness enthusiasts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/settings');
          }
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22FF7A).withOpacity(0.3)),
      ),
      child: fullWidth
          ? Row(
              children: [
                Icon(icon, color: const Color(0xFF22FF7A), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF22FF7A),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Icon(icon, color: const Color(0xFF22FF7A), size: 24),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF22FF7A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsOption(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF22FF7A)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.white.withOpacity(0.4),
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      height: 1,
      indent: 56,
      endIndent: 16,
    );
  }
}
