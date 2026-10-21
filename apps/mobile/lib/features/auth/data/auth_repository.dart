import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/auth/appwrite_providers.dart';
import '../../../core/auth/jwt_source.dart';
import '../../../core/errors/failure.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    account: ref.watch(appwriteAccountProvider),
    api: ref.watch(apiClientProvider),
    jwt: ref.watch(jwtSourceProvider),
  );
});

/// Signs in with Appwrite, then exchanges the session for the Cashe user.
/// Throws [Failure] for expected problems.
class AuthRepository {
  AuthRepository({
    required this._account,
    required this._api,
    required this._jwt,
  });

  final Account _account;
  final ApiClient _api;
  final JwtSource _jwt;

  /// The signed-in user from an existing Appwrite session, or null if none.
  Future<AppUser?> restore() async {
    try {
      await _account.get();
    } on AppwriteException catch (error) {
      if (error.code == 401) return null;
      throw Failure.fromAppwrite(error);
    }
    return (await _api.get('/me', AppUser.fromJson)).unwrap();
  }

  /// Creates the Appwrite account, then signs in as it. [name] is what funders
  /// see ("Claimed by …").
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
    } on AppwriteException catch (error) {
      // The email is checked before this, so a bad argument is the password
      // failing Appwrite's rules (e.g. too short or too common).
      if (error.type == 'general_argument_invalid') {
        throw const Failure(Failure.weakPassword);
      }
      throw Failure.fromAppwrite(error);
    }
    return signIn(email: email, password: password);
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _createSession(email, password);
    } on AppwriteException catch (error) {
      if (error.type != _sessionAlreadyExists) {
        throw Failure.fromAppwrite(error);
      }
      // A session survived an earlier, half-finished sign-in. It may belong to
      // someone else, so end it and sign in as the person typing now.
      await signOut();
      try {
        await _createSession(email, password);
      } on AppwriteException catch (retryError) {
        throw Failure.fromAppwrite(retryError);
      }
    }
    _jwt.invalidate();
    return _exchange();
  }

  static const _sessionAlreadyExists = 'user_session_already_exists';

  Future<void> _createSession(String email, String password) {
    return _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException {
      // Already gone or offline: the local state is cleared either way.
    } finally {
      _jwt.invalidate();
    }
  }

  /// First sign-in on this device: POST /session creates the Cashe user if new.
  Future<AppUser> _exchange() async {
    return (await _api.post('/session', AppUser.fromJson)).unwrap();
  }
}
