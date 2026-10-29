import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() => ref.watch(authRepositoryProvider).restore();

  /// Whether [email] has an account, or null if that can't be checked now.
  Future<bool?> accountExists(String email) =>
      ref.read(authRepositoryProvider).accountExists(email);

  /// Returns the failure to show, or null on success.
  Future<Failure?> signIn({required String email, required String password}) =>
      _attempt(
        () => ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password),
      );

  /// Creates an account and signs in. Returns the failure to show, or null.
  Future<Failure?> signUp({
    required String name,
    required String email,
    required String password,
  }) => _attempt(
    () => ref
        .read(authRepositoryProvider)
        .signUp(name: name, email: email, password: password),
  );

  Future<Failure?> _attempt(Future<AppUser> Function() signingIn) async {
    try {
      state = AsyncData(await signingIn());
      return null;
    } on Failure catch (failure) {
      return failure;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}
