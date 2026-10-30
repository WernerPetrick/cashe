import 'package:freezed_annotation/freezed_annotation.dart';

part 'place.freezed.dart';
part 'place.g.dart';

/// A place with a public centre and a zone that wallets unlock in.
@freezed
abstract class Place with _$Place {
  const factory Place({
    required int id,
    required String name,
    required double latitude,
    required double longitude,
    required int radiusM,
    required int dwellSeconds,
    int? distanceM,
  }) = _Place;

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
}

/// A real-world place from the outside search (ADR 0006). Not a Cashe place
/// yet: picking one creates a [Place] at its point.
@freezed
abstract class PlaceSuggestion with _$PlaceSuggestion {
  const factory PlaceSuggestion({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) = _PlaceSuggestion;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) =>
      _$PlaceSuggestionFromJson(json);
}

/// What the app sends to create a place.
@freezed
abstract class PlaceDraft with _$PlaceDraft {
  const factory PlaceDraft({
    required String name,
    required double latitude,
    required double longitude,
    required int radiusM,
    required int dwellSeconds,
  }) = _PlaceDraft;

  factory PlaceDraft.fromJson(Map<String, dynamic> json) =>
      _$PlaceDraftFromJson(json);
}
