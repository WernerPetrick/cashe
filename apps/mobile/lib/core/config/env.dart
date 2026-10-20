/// Build-time configuration passed with `--dart-define`.
abstract final class Env {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  // Appwrite Auth project. Not secret: these identify the project, not grant access.
  static const appwriteEndpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://fra.cloud.appwrite.io/v1',
  );
  static const appwriteProjectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '6ad71a680004138e628a',
  );

  static bool get isDev => flavor == 'dev';
}
