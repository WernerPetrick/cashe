import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Whether the app may read the device's location right now.
enum LocationAccess { granted, denied, deniedForever, serviceOff }

/// One location reading. Sent to the API for a check and then dropped.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.isMocked,
  });

  final double latitude;
  final double longitude;
  final double accuracyM;
  final bool isMocked;

  @override
  String toString() => 'LocationFix([redacted])';
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

/// The app's only access to location (CLAUDE.md privacy rules): foreground only,
/// and only while the unlock screen is open. It never stores readings.
abstract interface class LocationService {
  /// Why the app wants location, shown before the system prompt.
  static const rationale =
      'Cashe checks that you are at the place, only while this screen is open. '
      'Your location is never stored or shown to anyone.';

  Future<LocationAccess> requestAccess();

  /// Readings every few seconds until the subscription is cancelled.
  Stream<LocationFix> watch();

  Future<void> openSettings();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationAccess> requestAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  @override
  Stream<LocationFix> watch() {
    return Geolocator.getPositionStream(locationSettings: _settings()).map(
      (position) => LocationFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyM: position.accuracy,
        isMocked: position.isMocked,
      ),
    );
  }

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();

  LocationSettings _settings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: const Duration(seconds: 5),
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }
}
