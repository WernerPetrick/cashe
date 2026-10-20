import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

/// An expected failure with a stable [code]. The one place that maps codes to
/// user-facing text is [message].
class Failure implements Exception {
  const Failure(this.code);

  /// Maps an Appwrite SDK error to a [Failure].
  factory Failure.fromAppwrite(AppwriteException error) {
    if (kDebugMode) {
      debugPrint(
        'Appwrite error: ${error.code} ${error.type} ${error.message}',
      );
    }
    return switch (error.type) {
      'user_invalid_credentials' => const Failure(invalidCredentials),
      'user_blocked' => const Failure(blocked),
      'general_rate_limit_exceeded' => const Failure(rateLimited),
      // Only a missing or dead session means "sign in again"; other 401s
      // (e.g. user_session_already_exists) are not expiry.
      'user_jwt_invalid' ||
      'user_unauthorized' ||
      'general_unauthorized_scope' => const Failure(unauthorized),
      _ when error.code == null || error.code == 0 => const Failure(network),
      _ => const Failure(unknown),
    };
  }

  static const network = 'network';
  static const unauthorized = 'unauthorized';
  static const authUnavailable = 'auth_unavailable';
  static const invalidCredentials = 'invalid_credentials';
  static const blocked = 'blocked';
  static const rateLimited = 'rate_limited';
  static const unknown = 'unknown';

  final String code;

  String get message => switch (code) {
    network => "Couldn't reach Cashe. Check your connection and try again.",
    unauthorized => 'Your session has expired. Please sign in again.',
    authUnavailable => "We couldn't check your sign-in. Try again shortly.",
    invalidCredentials => 'That email and password don’t match.',
    blocked => 'This account has been blocked.',
    rateLimited => 'Too many attempts. Wait a moment and try again.',
    _ => 'Something went wrong. Please try again.',
  };

  @override
  bool operator ==(Object other) => other is Failure && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Failure($code)';
}
