import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/appwrite_providers.dart';
import '../auth/jwt_source.dart';
import '../config/env.dart';
import '../errors/failure.dart';
import 'api_result.dart';
import 'http_transport.dart';

typedef Decoder<T> = T Function(Map<String, dynamic> json);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: Uri.parse(Env.apiUrl),
    jwt: ref.watch(jwtSourceProvider),
    transport: IoHttpTransport(),
  );
});

/// Calls the Cashe API with the user's Appwrite JWT and returns typed results.
class ApiClient {
  ApiClient({
    required this._baseUrl,
    required this._jwt,
    required this._transport,
  });

  final Uri _baseUrl;
  final JwtSource _jwt;
  final HttpTransport _transport;

  Future<ApiResult<T>> get<T>(String path, Decoder<T> decode) =>
      _request('GET', path, decode);

  Future<ApiResult<T>> post<T>(
    String path,
    Decoder<T> decode, {
    Object? body,
    bool signedIn = true,
  }) => _request('POST', path, decode, body: body, signedIn: signedIn);

  Future<ApiResult<T>> _request<T>(
    String method,
    String path,
    Decoder<T> decode, {
    Object? body,
    bool signedIn = true,
  }) async {
    try {
      var response = await _send(method, path, body, signedIn);
      if (signedIn && response.statusCode == HttpStatus.unauthorized) {
        // The JWT may have been revoked or expired early: mint a new one once.
        _jwt.invalidate();
        response = await _send(method, path, body, signedIn);
      }
      return _decode(response, decode);
    } on AppwriteException catch (error) {
      return ApiFailure(Failure.fromAppwrite(error));
    } on IOException {
      return const ApiFailure(Failure(Failure.network));
    } on TimeoutException {
      return const ApiFailure(Failure(Failure.network));
    }
  }

  Future<TransportResponse> _send(
    String method,
    String path,
    Object? body,
    bool signedIn,
  ) async {
    return _transport.send(
      method,
      _baseUrl.resolve('/api/v1$path'),
      headers: {
        if (signedIn)
          HttpHeaders.authorizationHeader: 'Bearer ${await _jwt.token()}',
        HttpHeaders.acceptHeader: 'application/json',
        if (body != null) HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    );
  }

  ApiResult<T> _decode<T>(TransportResponse response, Decoder<T> decode) {
    final json = _parse(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        json != null) {
      return ApiSuccess(decode(json));
    }
    final error = json?['error'] as Map<String, dynamic>?;
    final details = (error?['details'] as List?)?.cast<String>() ?? const [];
    return ApiFailure(
      Failure(error?['code'] as String? ?? Failure.unknown, details),
    );
  }

  Map<String, dynamic>? _parse(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
