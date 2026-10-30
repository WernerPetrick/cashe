import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/places_repository.dart';
import '../domain/place.dart';

/// A map centre rounded to ~100 m, so small pans reuse the same search.
typedef MapCentre = ({double latitude, double longitude});

MapCentre roundCentre(double latitude, double longitude) {
  double round(double value) => (value * 1000).roundToDouble() / 1000;
  return (latitude: round(latitude), longitude: round(longitude));
}

typedef PlaceQuery = ({String text, MapCentre centre});

/// Real-world places for a search box query (ADR 0006).
final placeSearchProvider = FutureProvider.autoDispose
    .family<List<PlaceSuggestion>, PlaceQuery>(
      (ref, query) => ref
          .watch(placesRepositoryProvider)
          .search(query.text, query.centre.latitude, query.centre.longitude),
    );

final nearbyPlacesProvider = FutureProvider.autoDispose
    .family<List<Place>, MapCentre>(
      (ref, centre) => ref
          .watch(placesRepositoryProvider)
          .near(centre.latitude, centre.longitude),
    );
