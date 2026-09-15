import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return error.message ??
          'Request timed out. Please check your network connection or Firebase Console settings.';
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email address is already registered. Please log in instead.';
        case 'invalid-email':
          return 'The email address is not valid. Please enter a valid email.';
        case 'operation-not-allowed':
          return 'Email/Password sign-in is not enabled in Firebase Console. Please enable Email/Password provider under Firebase Authentication -> Sign-in method.';
        case 'weak-password':
          return 'The password is too weak. Please choose a stronger password (at least 6 characters).';
        case 'user-disabled':
          return 'This account has been disabled. Please contact your company administrator.';
        case 'user-not-found':
          return 'No account found with this email. Please check your email or register.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password. Please try again.';
        case 'too-many-requests':
          return 'Too many unsuccessful attempts. Please try again in a few minutes.';
        case 'network-request-failed':
          return 'Network connection error. Please check your internet connection and try again.';
        case 'requires-recent-login':
          return 'Please log out and log back in to perform this operation.';
        case 'app-not-authorized':
        case 'key-expired':
          return 'Firebase app is not authorized or API key is invalid for this domain.';
        default:
          return error.message ?? 'An authentication error occurred. (${error.code})';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Database permission denied. Please verify your Firestore Security Rules in Firebase Console.';
        case 'unavailable':
          return 'Firestore database service is currently unreachable. Please check internet connection.';
        case 'deadline-exceeded':
          return 'Database operation timed out. Please try again.';
        case 'not-found':
          return 'The requested database record was not found.';
        default:
          return error.message ?? 'A database error occurred. (${error.code})';
      }
    }

    if (error is String) {
      return error;
    }

    return error?.toString() ?? 'An unexpected error occurred. Please try again.';
  }
}
