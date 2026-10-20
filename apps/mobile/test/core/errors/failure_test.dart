import 'package:appwrite/appwrite.dart';
import 'package:cashe/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Failure map(int? code, String? type) =>
      Failure.fromAppwrite(AppwriteException('x', code, type));

  test('maps wrong credentials', () {
    expect(
      map(401, 'user_invalid_credentials'),
      const Failure(Failure.invalidCredentials),
    );
  });

  test('treats only dead sessions as expiry', () {
    expect(map(401, 'user_jwt_invalid'), const Failure(Failure.unauthorized));
    expect(
      map(401, 'general_unauthorized_scope'),
      const Failure(Failure.unauthorized),
    );
  });

  test('does not call an unrecognised 401 an expired session', () {
    expect(
      map(401, 'user_session_already_exists'),
      const Failure(Failure.unknown),
    );
    expect(
      map(401, 'user_more_factors_required'),
      const Failure(Failure.unknown),
    );
  });

  test('maps a missing response to a network failure', () {
    expect(map(null, null), const Failure(Failure.network));
  });
}
