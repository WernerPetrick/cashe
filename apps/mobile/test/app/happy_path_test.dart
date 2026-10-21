import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/happy_path.dart';

/// The same flow runs on a device from integration_test/happy_path_test.dart.
void main() {
  testWidgets('happy path: send a gift, claim it, unlock and pay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await runHappyPath(tester);
  });
}
