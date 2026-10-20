import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TransportResponse {
  const TransportResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

/// The raw HTTP seam under [ApiClient]; swapped for a fake in tests.
abstract interface class HttpTransport {
  Future<TransportResponse> send(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    String? body,
  });
}

class IoHttpTransport implements HttpTransport {
  IoHttpTransport({Duration timeout = const Duration(seconds: 15)})
    : _timeout = timeout,
      _client = HttpClient()..connectionTimeout = timeout;

  final Duration _timeout;
  final HttpClient _client;

  @override
  Future<TransportResponse> send(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    String? body,
  }) async {
    final request = await _client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    if (body != null) request.write(body);
    final response = await request.close().timeout(_timeout);
    final text = await response.transform(utf8.decoder).join();
    return TransportResponse(response.statusCode, text);
  }
}
