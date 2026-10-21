import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Shown once, straight after creating a gift: the only time its claim link exists
/// in the app (only a digest is stored on the server).
class GiftLinkScreen extends StatelessWidget {
  const GiftLinkScreen({
    super.key,
    required this.walletId,
    required this.claimUrl,
  });

  final int walletId;
  final String? claimUrl;

  static String message(String url) =>
      'I sent you a Cashe gift! Open this link in the Cashe app to claim it: $url';

  @override
  Widget build(BuildContext context) {
    final url = claimUrl;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send your gift'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Send this link to the person the gift is for.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'It works once. You won’t be able to see it again, so share it now. '
            'If nobody claims it within 3 days, the money comes back to you.',
          ),
          const SizedBox(height: 24),
          if (url == null)
            const Text('This gift has no link. Cancel it and create a new one.')
          else ...[
            SelectableText(
              url,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  SharePlus.instance.share(ShareParams(text: message(url))),
              icon: const Icon(Icons.share),
              label: const Text('Share link'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _copy(context, url),
              icon: const Icon(Icons.copy),
              label: const Text('Copy link'),
            ),
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/wallets/$walletId'),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Link copied')));
    }
  }
}
