import 'dart:math';

/// A fresh random key for one money request. Retrying the same request must reuse
/// its key so the API replays it instead of charging twice.
String newIdempotencyKey() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
