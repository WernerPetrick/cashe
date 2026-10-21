import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/claims/presentation/claim_links.dart';
import 'router.dart';
import 'theme.dart';

class CasheApp extends ConsumerWidget {
  const CasheApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // A claim link opens the claim screen; signed-out users sign in first.
    ref.listen(claimTokensProvider, (_, token) {
      if (token.value case final value?) router.go('/claim/$value');
    });
    return MaterialApp.router(
      title: 'Cashe',
      theme: buildTheme(),
      routerConfig: router,
    );
  }
}
