import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:overload_pro_app/screens/home_screen.dart';
import 'package:overload_pro_app/utils/usage_counter.dart';

/* ───────────────────────────────── AuthScreen ─────────────────────────────── */
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLogin = true; // toggle sign-in / sign-up
  bool _isLoading = false;

  /* ───── Helpers ───── */

  Future<void> _upgradeAnonymous(String email, String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.isAnonymous) return;

    final cred = EmailAuthProvider.credential(email: email, password: password);
    await user.linkWithCredential(cred); // keeps UID
    await UsageCounter.resetExerciseCount(); // stop upgrade prompts
  }

  Future<void> _signIn(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _signIn(email, pass);
      } else {
        await _upgradeAnonymous(email, pass); // one-time upgrade
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin ? 'Signed in 🎉' : 'Account created 🎉'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'email-already-in-use'
          ? 'Email already in use'
          : e.message ?? 'Auth error';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /* ───── UI ───── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isLogin ? 'Sign In' : 'Sign Up',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : 'Enter valid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : 'Min 6 chars',
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22FF7A),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          )
                        : Text(
                            _isLogin ? 'Sign In' : 'Create Account',
                            style: const TextStyle(color: Colors.black),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  child: Text(
                    _isLogin
                        ? 'No account? Create one'
                        : 'Already registered? Sign in',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
