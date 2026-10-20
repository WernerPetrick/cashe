/// Build-time configuration passed with `--dart-define`.
abstract final class Env {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static bool get isDev => flavor == 'dev';
}
