import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../wallets/domain/wallet_text.dart';
import '../domain/place.dart';
import 'new_place_sheet.dart';
import 'place_providers.dart';

/// Picks the place a wallet unlocks at. It searches around the visible map's centre
/// and never reads the device's location (location is for the unlock screen only).
/// Pops with the chosen [Place].
class PlacePickerScreen extends ConsumerStatefulWidget {
  const PlacePickerScreen({super.key});

  /// Where the map opens: central Cape Town.
  static const start = LatLng(-33.9249, 18.4241);

  @override
  ConsumerState<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends ConsumerState<PlacePickerScreen> {
  MapCentre _centre = roundCentre(
    PlacePickerScreen.start.latitude,
    PlacePickerScreen.start.longitude,
  );
  Place? _selected;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onMoved(MapCamera camera) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(
          () => _centre = roundCentre(
            camera.center.latitude,
            camera.center.longitude,
          ),
        );
      }
    });
  }

  Future<void> _addPlace(LatLng point) async {
    final place = await NewPlaceSheet.show(context, point);
    if (place == null || !mounted) return;
    ref.invalidate(nearbyPlacesProvider);
    setState(() => _selected = place);
  }

  @override
  Widget build(BuildContext context) {
    final places =
        ref.watch(nearbyPlacesProvider(_centre)).value ?? const <Place>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a place')),
      body: Stack(
        children: [
          _Map(
            places: places,
            selected: _selected,
            onMoved: _onMoved,
            onSelect: (place) => setState(() => _selected = place),
            onLongPress: _addPlace,
          ),
          const _Hint(),
          if (_selected case final place?)
            _SelectedCard(
              place: place,
              onUse: () => Navigator.pop(context, place),
            ),
        ],
      ),
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({
    required this.places,
    required this.selected,
    required this.onMoved,
    required this.onSelect,
    required this.onLongPress,
  });

  final List<Place> places;
  final Place? selected;
  final ValueChanged<MapCamera> onMoved;
  final ValueChanged<Place> onSelect;
  final ValueChanged<LatLng> onLongPress;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final shown = {
      for (final place in [...places, ?selected]) place.id: place,
    }.values;
    return FlutterMap(
      options: MapOptions(
        initialCenter: PlacePickerScreen.start,
        initialZoom: 15,
        onPositionChanged: (camera, _) => onMoved(camera),
        onLongPress: (_, point) => onLongPress(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'app.cashe.cashe',
        ),
        CircleLayer(
          circles: [
            for (final place in shown)
              CircleMarker(
                point: LatLng(place.latitude, place.longitude),
                radius: place.radiusM.toDouble(),
                useRadiusInMeter: true,
                color: colours.primary.withValues(
                  alpha: place.id == selected?.id ? 0.3 : 0.12,
                ),
                borderColor: colours.primary,
                borderStrokeWidth: 1.5,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final place in shown)
              Marker(
                point: LatLng(place.latitude, place.longitude),
                width: 44,
                height: 44,
                child: IconButton(
                  tooltip: place.name,
                  icon: Icon(Icons.place, color: colours.primary, size: 36),
                  onPressed: () => onSelect(place),
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Tap a pin to choose it, or long-press the map to add a new place.',
          ),
        ),
      ),
    );
  }
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({required this.place, required this.onUse});

  final Place place;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 32,
      child: Card(
        child: ListTile(
          title: Text(place.name),
          subtitle: Text(
            'Stay ${WalletText.dwell(place.dwellSeconds)} within ${place.radiusM} m',
          ),
          trailing: FilledButton(onPressed: onUse, child: const Text('Use')),
        ),
      ),
    );
  }
}
