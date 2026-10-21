import 'package:flutter/material.dart';

import '../errors/failure.dart';

/// A full-area error with a retry button. Any error becomes its user-facing message.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  static String messageFor(Object error) => switch (error) {
    Failure() => error.message,
    String() => error,
    _ => const Failure(Failure.unknown).message,
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(messageFor(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Shows a failure (or any error) as a snackbar.
void showErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(ErrorView.messageFor(error))));
}
