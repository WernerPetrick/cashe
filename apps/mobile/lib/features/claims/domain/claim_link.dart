/// Reads the token from a gift claim link (`cashe://claim/<token>`, ADR 0003),
/// or accepts a bare token pasted on its own.
abstract final class ClaimLink {
  static final _token = RegExp(r'^[A-Za-z0-9_-]{20,}$');

  static String? tokenFrom(String input) {
    final text = input.trim();
    if (_token.hasMatch(text)) return text;
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != 'cashe' || uri.host != 'claim') {
      return null;
    }
    final token = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
    return _token.hasMatch(token) ? token : null;
  }
}
