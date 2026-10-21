import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../domain/place.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepository(ref.watch(apiClientProvider));
});

class PlacesRepository {
  PlacesRepository(this._api);

  final ApiClient _api;

  /// Places within 5 km of a map centre (not the device's location).
  Future<List<Place>> near(double latitude, double longitude) async {
    final result = await _api.get('/places?near=$latitude,$longitude', (json) {
      return (json['places'] as List)
          .map((place) => Place.fromJson(place as Map<String, dynamic>))
          .toList();
    });
    return result.unwrap();
  }

  Future<Place> create(PlaceDraft draft) async => (await _api.post(
    '/places',
    Place.fromJson,
    body: draft.toJson(),
  )).unwrap();
}
