import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/places_repository.dart';
import '../domain/place.dart';

/// A map centre rounded to ~100 m, so small pans reuse the same search.
typedef MapCentre = ({double latitude, double longitude});

MapCentre roundCentre(double latitude, double longitude) {
  double round(double value) => (value * 1000).roundToDouble() / 1000;
  return (latitude: round(latitude), longitude: round(longitude));
}

final nearbyPlacesProvider = FutureProvider.autoDispose
    .family<List<Place>, MapCentre>(
      (ref, centre) => ref
          .watch(placesRepositoryProvider)
          .near(centre.latitude, centre.longitude),
    );
