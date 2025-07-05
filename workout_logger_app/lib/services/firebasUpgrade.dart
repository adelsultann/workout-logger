import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> upgradeAnonymousAccount({
  required String email,
  required String password,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  // Already upgraded? skip
  if (user == null || !user.isAnonymous) return;

  final cred = EmailAuthProvider.credential(email: email, password: password);
  await user.linkWithCredential(cred); // 🔗 keeps same UID
  markUserRegistered();
}

Future<void> markUserRegistered() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('exerciseCount'); // reset or remove
}
