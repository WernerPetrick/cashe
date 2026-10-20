import 'dart:io';

import 'package:cashe/core/api/api_client.dart';
import 'package:cashe/core/api/api_result.dart';
import 'package:cashe/core/api/http_transport.dart';
import 'package:cashe/core/auth/jwt_source.dart';
import 'package:cashe/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransport implements HttpTransport {
  FakeTransport(this.responses);

  final List<Object> responses;
  final requests = <({String method, Uri uri, Map<String, String> headers})>[];

  @override
  Future<TransportResponse> send(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    String? body,
  }) async {
    requests.add((method: method, uri: uri, headers: headers));
    final next = responses.removeAt(0);
    if (next is Exception) throw next;
    return next as TransportResponse;
  }
}

void main() {
  late int minted;

  ApiClient clientWith(FakeTransport transport) {
    minted = 0;
    return ApiClient(
      baseUrl: Uri.parse('http://10.0.2.2:3000'),
      jwt: JwtSource(mint: () async => 'jwt-${++minted}'),
      transport: transport,
    );
  }

  Map<String, dynamic> identity(Map<String, dynamic> json) => json;

  test('sends the JWT and decodes a success', () async {
    final transport = FakeTransport([const TransportResponse(200, '{"id":1}')]);

    final result = await clientWith(transport).get('/me', identity);

    expect((result as ApiSuccess).value, {'id': 1});
    expect(
      transport.requests.single.uri.toString(),
      'http://10.0.2.2:3000/api/v1/me',
    );
    expect(transport.requests.single.headers['authorization'], 'Bearer jwt-1');
  });

  test('maps the error envelope to a failure code', () async {
    final transport = FakeTransport([
      const TransportResponse(
        503,
        '{"error":{"code":"auth_unavailable","message":"x"}}',
      ),
    ]);

    final result = await clientWith(transport).get('/me', identity);

    expect(
      (result as ApiFailure).failure,
      const Failure(Failure.authUnavailable),
    );
  });

  test('retries once with a fresh JWT after a 401', () async {
    final transport = FakeTransport([
      const TransportResponse(
        401,
        '{"error":{"code":"unauthorized","message":"x"}}',
      ),
      const TransportResponse(200, '{"id":1}'),
    ]);

    final result = await clientWith(transport).post('/session', identity);

    expect(result, isA<ApiSuccess>());
    expect(transport.requests.last.headers['authorization'], 'Bearer jwt-2');
  });

  test('reports a network failure when the API is unreachable', () async {
    final transport = FakeTransport([const SocketException('refused')]);

    final result = await clientWith(transport).get('/me', identity);

    expect((result as ApiFailure).failure, const Failure(Failure.network));
  });
}
