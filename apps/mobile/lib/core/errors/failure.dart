import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

/// An expected failure with a stable [code]. The one place that maps codes to
/// user-facing text is [message].
class Failure implements Exception {
  const Failure(this.code, [this.details = const []]);

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
      'user_already_exists' => const Failure(accountExists),
      'password_recently_used' ||
      'password_personal_data' => const Failure(weakPassword),
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
  static const accountExists = 'account_exists';
  static const weakPassword = 'weak_password';
  static const rateLimited = 'rate_limited';
  static const unknown = 'unknown';

  final String code;

  /// Field-level messages from the API (e.g. validation errors), shown as-is.
  final List<String> details;

  String get message => switch (code) {
    network => "Couldn't reach Cashe. Check your connection and try again.",
    unauthorized => 'Your session has expired. Please sign in again.',
    authUnavailable => "We couldn't check your sign-in. Try again shortly.",
    invalidCredentials => 'That email and password don’t match.',
    blocked => 'This account has been blocked.',
    accountExists =>
      'There’s already a wallet for this email. Sign in instead.',
    weakPassword =>
      'Choose a stronger password: 8+ characters, not a common one.',
    rateLimited => 'Too many attempts. Wait a moment and try again.',
    'not_found' => "We couldn't find that wallet.",
    'forbidden' => "You can't do that with this wallet.",
    'validation_failed' =>
      details.isEmpty ? 'Some details need fixing.' : details.join('\n'),
    'invalid_amount' => 'Enter an amount above zero.',
    'insufficient_funds' => "There isn't enough money in this wallet.",
    'wallet_closed' => 'This wallet is closed.',
    'wallet_locked' =>
      'This wallet is locked. Stay at the place until it unlocks.',
    'idempotency_conflict' =>
      'That request was already sent. Refresh and try again.',
    'invalid_claim' => "This gift link isn't valid any more.",
    'own_gift' => "You can't claim your own gift.",
    'not_cancellable' => 'This gift has already been claimed.',
    'invalid_location' || 'invalid_ping' => "Your location couldn't be read.",
    'invalid_query' => 'Type at least 2 letters to search.',
    'place_search_unavailable' => "Place search isn't available right now. Try again, or add the place on the map.",
    _ => 'Something went wrong. Please try again.',
  };

  @override
  bool operator ==(Object other) => other is Failure && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Failure($code)';
}
