import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/env.dart';
import '../../../core/widgets/error_view.dart';
import '../../wallets/domain/wallet_text.dart';
import '../data/places_repository.dart';
import '../domain/place.dart';

/// Names a new place at a point on the map and sets its zone and dwell time.
class NewPlaceSheet extends ConsumerStatefulWidget {
  const NewPlaceSheet({super.key, required this.point});

  final LatLng point;

  static Future<Place?> show(BuildContext context, LatLng point) =>
      showModalBottomSheet<Place>(
        context: context,
        isScrollControlled: true,
        builder: (_) => NewPlaceSheet(point: point),
      );

  @override
  ConsumerState<NewPlaceSheet> createState() => _NewPlaceSheetState();
}

class _NewPlaceSheetState extends ConsumerState<NewPlaceSheet> {
  static const _dwellChoices = [30, 60, 120, 300];

  final _name = TextEditingController();
  double _radius = 50;
  int _dwell = Env.isDev ? 30 : 120;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      return showErrorSnackBar(context, 'Give the place a name.');
    }
    setState(() => _saving = true);
    try {
      final place = await ref.read(placesRepositoryProvider).create(_draft());
      if (mounted) Navigator.pop(context, place);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnackBar(context, error);
    }
  }

  PlaceDraft _draft() => PlaceDraft(
    name: _name.text.trim(),
    latitude: widget.point.latitude,
    longitude: widget.point.longitude,
    radiusM: _radius.round(),
    dwellSeconds: _dwell,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New place', style: Theme.of(context).textTheme.titleLarge),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name, e.g. School tuckshop',
            ),
          ),
          const SizedBox(height: 16),
          Text('Zone: within ${_radius.round()} m'),
          Slider(
            value: _radius,
            min: 20,
            max: 300,
            divisions: 28,
            onChanged: (value) => setState(() => _radius = value),
          ),
          Text('Stay for ${WalletText.dwell(_dwell)} to unlock'),
          Wrap(
            spacing: 8,
            children: [
              for (final seconds in _dwellChoices)
                ChoiceChip(
                  label: Text(WalletText.dwell(seconds)),
                  selected: _dwell == seconds,
                  onSelected: (_) => setState(() => _dwell = seconds),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save place'),
          ),
        ],
      ),
    );
  }
}
