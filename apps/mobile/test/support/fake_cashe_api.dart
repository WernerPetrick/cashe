import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cashe/core/api/http_transport.dart';
import 'package:mocktail/mocktail.dart';

/// A small in-memory stand-in for the Rails API, for driving the whole app in
/// the happy-path test. Responses copy the Rails serializers' JSON; the rules
/// themselves (geofence, time windows, dwell) are Rails's and tested there, so
/// here dwell simply grows by [dwellStep] seconds per ping.
class FakeCasheApi implements HttpTransport {
  FakeCasheApi({
    required this.places,
    required this.names,
    this.dwellStep = 15,
  });

  final List<Map<String, Object?>> places;

  /// The display name of each email's Cashe user (from their Appwrite account).
  final Map<String, String> names;
  final int dwellStep;

  final _users = <String, Map<String, Object?>>{};
  final _wallets = <int, _Wallet>{};
  final _keys = <String>{};

  /// Every request the app made, as "METHOD /path".
  final requests = <String>[];

  /// Request bodies, keyed like [requests].
  final bodies = <String, Map<String, dynamic>>{};

  /// Requests this fake doesn't know: the app called something unexpected.
  final unhandled = <String>[];

  /// The JWT [FakeAccount] mints for [email].
  static String tokenFor(String email) => 'jwt-$email';

  @override
  Future<TransportResponse> send(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    String? body,
  }) async {
    final path = uri.path.replaceFirst('/api/v1', '');
    final call = '$method $path';
    requests.add(call);
    final json = body == null
        ? const <String, dynamic>{}
        : jsonDecode(body) as Map<String, dynamic>;
    bodies[call] = json;

    if (call == 'POST /account_lookups') {
      return _ok({'exists': names.containsKey(json['email'])});
    }
    final viewer = _viewer(headers['authorization']);
    if (viewer == null) return _error(401, 'unauthorized');
    final response = _route(method, path, uri, json, viewer);
    if (response == null) {
      unhandled.add(call);
      return _error(404, 'not_found');
    }
    return response;
  }

  TransportResponse? _route(
    String method,
    String path,
    Uri uri,
    Map<String, dynamic> body,
    Map<String, Object?> viewer,
  ) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final wallet = segments.length > 1 && segments.first == 'wallets'
        ? _wallets[int.tryParse(segments[1])]
        : null;
    return switch ((method, segments)) {
      ('POST', ['session']) || ('GET', ['me']) => _ok(viewer),
      ('GET', ['places']) => _ok({'places': places}),
      ('GET', ['wallets']) => _ok({
        'wallets': [
          for (final w in _wallets.values)
            if (w.visibleTo(viewer)) w.summary(viewer),
        ],
      }),
      ('POST', ['wallets']) => _create(body, viewer),
      ('POST', ['gift_claims']) => _claim(body['token'] as String, viewer),
      ('GET', ['wallets', _]) when wallet != null => _ok(wallet.detail(viewer)),
      ('GET', ['wallets', _, 'ledger_entries']) when wallet != null => _ok({
        'entries': [for (final e in wallet.newestFirst) wallet.entryJson(e)],
        'next_before': null,
      }),
      ('POST', ['wallets', _, 'deposits']) when wallet != null => _write(
        wallet,
        'deposit',
        body,
      ),
      ('POST', ['wallets', _, 'presence_pings']) when wallet != null => _ok(
        wallet.ping(dwellStep),
      ),
      ('POST', ['wallets', _, 'spends']) when wallet != null => _spend(
        wallet,
        body,
      ),
      _ => null,
    };
  }

  Map<String, Object?>? _viewer(String? authorization) {
    final email = authorization?.replaceFirst('Bearer jwt-', '');
    if (email == null) return null;
    return _users.putIfAbsent(
      email,
      () => {
        'id': _users.length + 1,
        'display_name': names[email] ?? 'Cashe user',
        'role': 'adult',
      },
    );
  }

  TransportResponse _create(
    Map<String, dynamic> body,
    Map<String, Object?> viewer,
  ) {
    final place = places.firstWhere((p) => p['id'] == body['place_id']);
    final gift = body['kind'] == 'gift';
    final wallet = _Wallet(
      id: _wallets.length + 1,
      body: body,
      place: place,
      funder: viewer,
      owner: gift ? null : viewer,
      claimToken: gift ? 'claim-token-${_wallets.length + 1}' : null,
    );
    _wallets[wallet.id] = wallet;
    return _ok({
      ...wallet.detail(viewer),
      'claim_url': gift ? 'cashe://claim/${wallet.claimToken}' : null,
    }, status: 201);
  }

  TransportResponse _claim(String token, Map<String, Object?> viewer) {
    final wallet = _wallets.values
        .where((w) => w.claimToken == token && w.owner == null)
        .firstOrNull;
    if (wallet == null) return _error(422, 'invalid_claim');
    wallet
      ..owner = viewer
      ..claimedAt = DateTime.now().toUtc();
    return _ok(wallet.detail(viewer));
  }

  TransportResponse _spend(_Wallet wallet, Map<String, dynamic> body) {
    final until = wallet.unlockedUntil;
    if (until == null || until.isBefore(DateTime.now())) {
      return _error(422, 'wallet_locked');
    }
    if ((body['amount_cents'] as int) > wallet.balance) {
      return _error(422, 'insufficient_funds');
    }
    return _write(wallet, 'spend', body);
  }

  TransportResponse _write(
    _Wallet wallet,
    String kind,
    Map<String, dynamic> body,
  ) {
    if (!_keys.add(body['idempotency_key'] as String)) {
      return _error(409, 'idempotency_conflict');
    }
    final cents = body['amount_cents'] as int;
    final entry = wallet.add(kind, kind == 'spend' ? -cents : cents);
    return _ok(wallet.entryJson(entry), status: 201);
  }

  TransportResponse _ok(Object json, {int status = 200}) =>
      TransportResponse(status, jsonEncode(json));

  TransportResponse _error(int status, String code) => TransportResponse(
    status,
    jsonEncode({
      'error': {'code': code, 'message': code},
    }),
  );
}

class _Wallet {
  _Wallet({
    required this.id,
    required this.body,
    required this.place,
    required this.funder,
    required this.owner,
    required this.claimToken,
  });

  final int id;
  final Map<String, dynamic> body;
  final Map<String, Object?> place;
  final Map<String, Object?> funder;
  Map<String, Object?>? owner;
  final String? claimToken;
  DateTime? claimedAt;
  final _claimExpiresAt = DateTime.now().toUtc().add(const Duration(days: 3));
  DateTime? unlockedUntil;
  int _dwell = 0;
  int _nextEntry = 1;
  final _entries = <({int id, String kind, int cents, DateTime at})>[];

  bool get _gift => body['kind'] == 'gift';
  int get balance => _entries.fold<int>(0, (sum, e) => sum + e.cents);
  Iterable<({int id, String kind, int cents, DateTime at})> get newestFirst =>
      _entries.reversed;

  bool visibleTo(Map<String, Object?> viewer) =>
      viewer == funder || viewer == owner;

  ({int id, String kind, int cents, DateTime at}) add(String kind, int cents) {
    final entry = (
      id: id * 100 + _nextEntry++,
      kind: kind,
      cents: cents,
      at: DateTime.now().toUtc(),
    );
    _entries.add(entry);
    return entry;
  }

  /// Dwelling until the place's dwell time is reached, then a 10-minute unlock.
  Map<String, Object?> ping(int step) {
    final required = place['dwell_seconds'] as int;
    final progress = _dwell;
    _dwell += step;
    if (progress >= required) {
      unlockedUntil ??= DateTime.now().add(const Duration(minutes: 10));
    }
    final unlocked = unlockedUntil != null;
    return {
      'status': unlocked ? 'unlocked' : 'dwelling',
      'inside_zone': true,
      'in_time_window': true,
      'dwell_progress_seconds': unlocked ? required : progress,
      'dwell_required_seconds': required,
      'unlocked_until': unlockedUntil?.toUtc().toIso8601String(),
      'reason': null,
    };
  }

  Map<String, Object?> entryJson(
    ({int id, String kind, int cents, DateTime at}) entry,
  ) => {
    'id': entry.id,
    'kind': entry.kind,
    'amount_cents': entry.cents,
    'currency': body['currency'],
    'place_name': entry.kind == 'spend' ? place['name'] : null,
    'created_at': entry.at.toIso8601String(),
  };

  /// WalletSerializer.
  Map<String, Object?> summary(Map<String, Object?> viewer) => {
    'id': id,
    'kind': body['kind'],
    'name': body['name'],
    'status': _gift && owner == null ? 'pending' : 'active',
    'role': viewer == owner ? 'owner' : 'funder',
    'place': {'id': place['id'], 'name': place['name']},
    'currency': body['currency'],
    'balance_cents': balance,
    'funded_cents': _entries
        .where((e) => e.kind == 'deposit')
        .fold<int>(0, (sum, e) => sum + e.cents),
    'target_cents': body['target_cents'],
    'expires_at': body['expires_at'],
    'claim_expires_at': _gift ? _claimExpiresAt.toIso8601String() : null,
    'claimed_at': claimedAt?.toIso8601String(),
    'funder_name': funder['display_name'],
    'owner_name': owner?['display_name'],
  };

  /// WalletDetailSerializer: only the owner sees the unlock.
  Map<String, Object?> detail(Map<String, Object?> viewer) => {
    ...summary(viewer),
    'place': place,
    'time_windows': body['time_windows'] ?? const [],
    'recent_entries': [for (final e in newestFirst.take(10)) entryJson(e)],
    'unlocked_until': viewer == owner
        ? unlockedUntil?.toUtc().toIso8601String()
        : null,
  };
}

/// Appwrite Auth for a fixed set of accounts; the JWT names the signed-in email.
class FakeAccount extends Fake implements Account {
  FakeAccount(this.passwords);

  final Map<String, String> passwords;
  String? _signedIn;

  @override
  Future<models.User> get() async =>
      throw AppwriteException('No session', 401, 'user_unauthorized');

  @override
  Future<models.Session> createEmailPasswordSession({
    required String email,
    required String password,
    int? duration,
  }) async {
    if (passwords[email] != password) {
      throw AppwriteException('Invalid', 401, 'user_invalid_credentials');
    }
    _signedIn = email;
    return models.Session.fromMap({'userId': email});
  }

  @override
  Future<models.Jwt> createJWT({int? duration}) async {
    final email = _signedIn;
    if (email == null) throw AppwriteException('No session', 401);
    return models.Jwt(jwt: FakeCasheApi.tokenFor(email));
  }

  @override
  Future deleteSession({required String sessionId}) async => _signedIn = null;
}
