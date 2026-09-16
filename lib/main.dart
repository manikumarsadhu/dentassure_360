import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/employee_dashboard.dart';
import 'screens/dashboard/platform_admin_dashboard.dart';
import 'screens/dashboard/role_portal.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const Dentassure360App());
}

class Dentassure360App extends StatelessWidget {
  const Dentassure360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dentassure 360',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066CC),
          brightness: Brightness.light,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// The AuthGate listens to Firebase Auth changes in real time and routes the user
/// to the appropriate dashboard or login screen based on their role and account status.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        // Auth state is initializing
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(message: 'Initializing Dentassure 360...');
        }

        final user = authSnapshot.data;

        // User is not signed in -> Directly show Login Screen
        if (user == null) {
          return const LoginScreen();
        }

        // User is authenticated -> Stream their Firestore UserProfile in real-time
        return StreamBuilder<UserProfile?>(
          stream: firestoreService.streamUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(message: 'Loading your profile...');
            }

            // Error loading user profile
            if (profileSnapshot.hasError) {
              return _ErrorScreen(
                title: 'Unable to load profile',
                message:
                    'An error occurred while fetching your account details: ${profileSnapshot.error}',
                onSignOut: () => authService.logout(),
              );
            }

            final profile = profileSnapshot.data;

            // Profile document missing in Firestore
            if (profile == null) {
              return _ErrorScreen(
                title: 'Account profile not found',
                message:
                    'No profile was found for ${user.email}. If you just registered, please wait a moment or sign out.',
                onSignOut: () => authService.logout(),
              );
            }

            // Account status check
            if (!profile.isActive) {
              return _ErrorScreen(
                title: 'Account Inactive',
                message:
                    'Your account is currently marked as ${profile.status}. Please contact your company administrator.',
                onSignOut: () => authService.logout(),
              );
            }

            // Route based on role
            if (profile.isPlatformAdmin) {
              return PlatformAdminDashboard(userProfile: profile);
            } else if (profile.isCompanyAdmin ||
                profile.isHR ||
                profile.isManager ||
                profile.isTeamLead) {
              return RolePortal(userProfile: profile);
            } else {
              return EmployeeDashboard(userProfile: profile);
            }
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onSignOut;

  const _ErrorScreen({
    required this.title,
    required this.message,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
