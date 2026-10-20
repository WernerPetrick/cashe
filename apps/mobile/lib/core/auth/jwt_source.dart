/// Hands out an Appwrite JWT for API calls, minting a fresh one before the
/// current one expires (Appwrite JWTs live 15 minutes).
class JwtSource {
  JwtSource({
    required this._mint,
    this._now = DateTime.now,
    this._maxAge = const Duration(minutes: 12),
  });

  final Future<String> Function() _mint;
  final DateTime Function() _now;
  final Duration _maxAge;

  String? _token;
  DateTime? _mintedAt;
  Future<String>? _inFlight;

  Future<String> token() {
    final token = _token;
    if (token != null && _isFresh) return Future.value(token);
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  /// Forget the cached token, e.g. after sign-out or a 401.
  void invalidate() {
    _token = null;
    _mintedAt = null;
  }

  bool get _isFresh {
    final mintedAt = _mintedAt;
    return mintedAt != null && _now().difference(mintedAt) < _maxAge;
  }

  Future<String> _refresh() async {
    final token = await _mint();
    _token = token;
    _mintedAt = _now();
    return token;
  }
}
