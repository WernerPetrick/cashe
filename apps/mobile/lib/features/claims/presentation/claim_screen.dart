import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_view.dart';
import '../../wallets/presentation/wallet_providers.dart';

/// Opened from a claim link (or the paste screen): claims the gift right away.
class ClaimScreen extends ConsumerStatefulWidget {
  const ClaimScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends ConsumerState<ClaimScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _claim();
  }

  Future<void> _claim() async {
    setState(() => _error = null);
    try {
      final wallet = await ref.read(walletActionsProvider).claim(widget.token);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${wallet.name} is yours')));
      context.go('/wallets/${wallet.id}');
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('Claim a gift')),
      body: error == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ErrorView.messageFor(error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Back to my wallets'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
