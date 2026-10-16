import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHelper {
  static String parse(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Incorrect email or password. Please check your credentials and try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'Your account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please wait a few moments and try again.';
        case 'email-already-in-use':
        case 'email-already-exists':
          return 'This email is already registered. Please login or use a different email.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Email and password sign-in is not enabled. Please contact support.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        case 'channel-error':
          return 'Please fill in all required fields.';
        case 'expired-action-code':
          return 'The reset code or link has expired. Please request a new one.';
        case 'invalid-action-code':
          return 'The verification code you entered is invalid. Please check and try again.';
        case 'requires-recent-login':
          return 'Please log out and log in again before retrying this action.';
        default:
          final msg = error.message;
          if (msg != null &&
              msg.isNotEmpty &&
              !msg.contains('[') &&
              !msg.toLowerCase().contains('firebase')) {
            return msg;
          }
          return 'Authentication failed. Please check your details and try again.';
      }
    }

    final raw = error.toString().replaceAll('Exception:', '').trim();

    if (raw.startsWith('BANNED:')) {
      return raw;
    }

    final lower = raw.toLowerCase();
    if (lower.contains('invalid-credential') ||
        lower.contains('wrong-password') ||
        lower.contains('user-not-found') ||
        lower.contains('malformed or has expired') ||
        lower.contains('auth credential is incorrect')) {
      return 'Incorrect email or password. Please check your credentials and try again.';
    }
    if (lower.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (lower.contains('user-disabled')) {
      return 'Your account has been disabled. Please contact support.';
    }
    if (lower.contains('too-many-requests')) {
      return 'Too many failed attempts. Please wait a few moments and try again.';
    }
    if (lower.contains('email-already-in-use') ||
        lower.contains('already in use') ||
        lower.contains('already registered')) {
      return 'This email is already registered. Please login or use a different email.';
    }
    if (lower.contains('weak-password')) {
      return 'The password is too weak. Please use at least 6 characters.';
    }
    if (lower.contains('network-request-failed') ||
        lower.contains('socketexception') ||
        lower.contains('connection failed') ||
        lower.contains('network error')) {
      return 'Network connection error. Please check your internet and try again.';
    }
    if (lower.contains('channel-error')) {
      return 'Please fill in all required fields.';
    }

    // Strip [firebase_auth/...] tags if present
    String cleaned = raw.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (cleaned.isEmpty ||
        cleaned.toLowerCase().contains('firebase') ||
        cleaned.toLowerCase().contains('credential')) {
      return 'Incorrect email or password. Please check your credentials and try again.';
    }

    return cleaned;
  }
}
