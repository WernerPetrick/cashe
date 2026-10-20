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
    return _exchange();
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } on AppwriteException catch (error) {
      throw Failure.fromAppwrite(error);
    }
    _jwt.invalidate();
    return _exchange();
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

  Future<AppUser> _exchange() async {
    return switch (await _api.post('/session', AppUser.fromJson)) {
      ApiSuccess(:final value) => value,
      ApiFailure(:final failure) => throw failure,
    };
  }
}
