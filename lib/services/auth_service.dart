import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Creates a new Firebase Auth account for an employee using an ephemeral secondary FirebaseApp instance.
  /// This prevents logging out the current admin user on the client while creating the employee's auth credentials.
  Future<UserCredential> createEmployeeAuthAccount({
    required String email,
    required String password,
  }) async {
    final String tempAppName = 'EmployeeCreation_${DateTime.now().millisecondsSinceEpoch}';
    final FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: tempAppName,
      options: Firebase.app().options,
    );

    try {
      final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final UserCredential credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } finally {
      await secondaryApp.delete();
    }
  }
}
