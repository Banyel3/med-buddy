import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// One short, human line for any backend/runtime error. Never leak
/// `AuthApiException(...)` / `PostgrestException(...)` / stack traces into UI.
String friendlyError(Object e) {
  if (e is AuthException) {
    switch (e.code) {
      case 'email_address_invalid':
        return "That email address doesn't look right.";
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Wait a minute and try again.';
      case 'invalid_credentials':
        return "Email or password didn't match. Try again.";
      case 'email_not_confirmed':
        return 'Check your inbox and confirm your email first.';
      case 'user_already_exists':
      case 'email_exists':
        return 'You already have an account. Sign in instead.';
      case 'weak_password':
        return 'Pick a stronger password (at least 6 characters).';
      case 'signup_disabled':
        return 'Sign-ups are closed right now.';
    }
    final msg = e.message.trim().toLowerCase();
    if (msg.contains('jwt') ||
        msg.contains('expired') ||
        msg.contains('refresh')) {
      return 'Your session expired. Please sign in again.';
    }
    if (msg.contains('socket') ||
        msg.contains('host lookup') ||
        msg.contains('connection')) {
      return "Can't reach the server. Check your internet and try again.";
    }
    return e.message.isEmpty ? 'Sign-in failed. Try again.' : e.message;
  }
  if (e is PostgrestException) {
    switch (e.code) {
      case '42501':
        return "You don't have permission to do that.";
      case 'PGRST116':
        return "We couldn't find that. It may have been removed.";
      case '23505':
        return 'That already exists.';
      case '23502':
        return 'Some required fields are missing.';
      case '23514':
        return 'Some values are invalid.';
    }
    final msg = e.message.trim();
    return msg.isEmpty ? 'The server rejected the change.' : msg;
  }
  if (e is StorageException) {
    return "Couldn't upload the photo. Check your connection and retry.";
  }
  if (e is StateError) return e.message;
  if (e is SocketException || e is HttpException) {
    return "Can't reach the server. Check your internet and try again.";
  }
  if (e is TimeoutException) return 'The request timed out. Please try again.';
  if (e is FormatException) return 'Received an unexpected response.';
  return 'Something went wrong. Please try again.';
}
