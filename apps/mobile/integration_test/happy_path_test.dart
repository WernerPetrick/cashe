import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/happy_path.dart';

/// The Phase 2 happy path on a device or emulator, against the in-memory API:
///   fvm flutter test integration_test -d emulator-5554
/// The same flow runs headless in test/app/happy_path_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('happy path: send a gift, claim it, unlock and pay', (
    tester,
  ) async {
    await runHappyPath(tester);
  });
}
