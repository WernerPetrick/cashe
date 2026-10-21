import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  _registerFontLicences();
  runApp(const ProviderScope(child: CasheApp()));
}

/// Bundled fonts are SIL Open Font License 1.1; show it on the licence page.
void _registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [
      ('Manrope', 'Manrope-OFL.txt'),
      ('JetBrains Mono', 'JetBrainsMono-OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('assets/fonts/$file'));
    }
  });
}
