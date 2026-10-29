import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/cashe_widgets.dart';
import '../../auth/presentation/auth_controller.dart';

class MeTab extends ConsumerWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final name = user?.displayName ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      children: [
        const MonoLabel('Me'),
        const SizedBox(height: 18),
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: CasheColors.track,
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                  color: CasheColors.amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(name, style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () => context.push('/claim'),
          child: const Text('Claim a gift link'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () =>
              showLicensePage(context: context, applicationName: 'Cashe'),
          child: const Text('Licences'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          child: const Text('Sign out'),
        ),
        const SizedBox(height: 18),
        const Text(
          'Money in Cashe is simulated for this demo.',
          style: TextStyle(fontSize: 13, color: CasheColors.muted),
        ),
      ],
    );
  }
}
