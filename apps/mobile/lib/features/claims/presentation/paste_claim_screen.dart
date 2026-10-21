import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/claim_link.dart';

/// For when a messaging app doesn't make the cashe:// link tappable.
class PasteClaimScreen extends StatefulWidget {
  const PasteClaimScreen({super.key});

  @override
  State<PasteClaimScreen> createState() => _PasteClaimScreenState();
}

class _PasteClaimScreenState extends State<PasteClaimScreen> {
  final _link = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _submit() {
    final token = ClaimLink.tokenFrom(_link.text);
    if (token == null) {
      setState(() => _error = 'That doesn’t look like a Cashe gift link.');
      return;
    }
    context.pushReplacement('/claim/$token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Claim a gift')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Paste the gift link someone sent you.'),
          const SizedBox(height: 16),
          TextField(
            controller: _link,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'cashe://claim/…',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('Claim gift')),
        ],
      ),
    );
  }
}
