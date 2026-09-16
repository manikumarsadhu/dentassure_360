import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

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

  /// Updates the password for the currently signed-in user
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user session found.');
    }
    await user.updatePassword(newPassword.trim());
  }

  /// Creates a Firebase Auth user without changing the current signed-in session.
  /// Uses the Identity Toolkit REST API so Company Admin / HR stay logged in on web.
  Future<String> createAuthUserUid({
    required String email,
    required String password,
  }) async {
    final apiKey = Firebase.app().options.apiKey;
    if (apiKey.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-api-key',
        message: 'Firebase API key is not configured.',
      );
    }

    final response = await http.post(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      ),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['error'] != null) {
      final raw = (data['error']['message'] ?? 'INTERNAL_ERROR').toString();
      throw FirebaseAuthException(
        code: _identityToolkitCode(raw),
        message: raw,
      );
    }

    final uid = data['localId'] as String?;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'internal-error',
        message: 'Firebase did not return a user id for the new employee.',
      );
    }
    return uid;
  }

  String _identityToolkitCode(String message) {
    final code = message.split(' :').first.trim().toUpperCase();
    switch (code) {
      case 'EMAIL_EXISTS':
        return 'email-already-in-use';
      case 'INVALID_EMAIL':
        return 'invalid-email';
      case 'WEAK_PASSWORD':
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
        return 'weak-password';
      case 'OPERATION_NOT_ALLOWED':
        return 'operation-not-allowed';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return 'too-many-requests';
      default:
        return code.toLowerCase().replaceAll('_', '-');
    }
  }

  /// Creates a new Firebase Auth account using an ephemeral secondary FirebaseApp instance.
  /// This prevents logging out the currently logged-in user (e.g. Platform Admin or Company Admin)
  /// while provisioning a new user's authentication credentials.
  Future<UserCredential> createSecondaryAuthAccount({
    required String email,
    required String password,
  }) async {
    final String tempAppName =
        'SecondaryAuth_${DateTime.now().microsecondsSinceEpoch}';
    final FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: tempAppName,
      options: Firebase.app().options,
    );

    try {
      final FirebaseAuth secondaryAuth =
          FirebaseAuth.instanceFor(app: secondaryApp);
      final UserCredential credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } finally {
      await secondaryApp.delete();
    }
  }

  /// Creates a new Firebase Auth account for an employee using an ephemeral secondary FirebaseApp instance.
  Future<UserCredential> createEmployeeAuthAccount({
    required String email,
    required String password,
  }) async {
    return createSecondaryAuthAccount(email: email, password: password);
  }

  /// Creates a new Firebase Auth account for a Company Admin using an ephemeral secondary FirebaseApp instance.
  Future<UserCredential> createCompanyAdminAuthAccount({
    required String email,
    required String password,
  }) async {
    return createSecondaryAuthAccount(email: email, password: password);
  }
}
