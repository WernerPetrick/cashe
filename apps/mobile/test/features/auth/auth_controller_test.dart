import 'package:cashe/core/errors/failure.dart';
import 'package:cashe/features/auth/data/auth_repository.dart';
import 'package:cashe/features/auth/domain/app_user.dart';
import 'package:cashe/features/auth/presentation/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const parent = AppUser(id: 1, displayName: 'Pat Parent', role: UserRole.adult);

void main() {
  late MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  AuthController controller() =>
      container.read(authControllerProvider.notifier);

  test('restores an existing session', () async {
    when(() => repository.restore()).thenAnswer((_) async => parent);

    expect(await container.read(authControllerProvider.future), parent);
  });

  test('signs in and exposes the user', () async {
    when(() => repository.restore()).thenAnswer((_) async => null);
    when(() => repository.signIn(email: 'p@x.io', password: 'pw'))
        .thenAnswer((_) async => parent);
    await container.read(authControllerProvider.future);

    final failure = await controller().signIn(email: 'p@x.io', password: 'pw');

    expect(failure, isNull);
    expect(container.read(authControllerProvider).value, parent);
  });

  test('returns the failure and stays signed out', () async {
    when(() => repository.restore()).thenAnswer((_) async => null);
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const Failure(Failure.invalidCredentials));
    await container.read(authControllerProvider.future);

    final failure = await controller().signIn(email: 'p@x.io', password: 'bad');

    expect(failure, const Failure(Failure.invalidCredentials));
    expect(container.read(authControllerProvider).value, isNull);
  });

  test('signs out', () async {
    when(() => repository.restore()).thenAnswer((_) async => parent);
    when(() => repository.signOut()).thenAnswer((_) async {});
    await container.read(authControllerProvider.future);

    await controller().signOut();

    expect(container.read(authControllerProvider).value, isNull);
  });
}
