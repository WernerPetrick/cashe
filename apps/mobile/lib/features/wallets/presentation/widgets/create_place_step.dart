import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/money/money.dart';
import '../../../places/domain/place.dart';
import '../../../places/presentation/place_picker_screen.dart';
import '../../../places/presentation/place_providers.dart';
import '../../domain/wallet_text.dart';

/// Step 2: where the money can be spent. Lists saved places around the map's
/// starting point (never the device's location); the map opens for anything else.
class CreatePlaceStep extends ConsumerStatefulWidget {
  const CreatePlaceStep({
    super.key,
    required this.amount,
    required this.selected,
    required this.onPick,
    required this.onNext,
  });

  final Money amount;
  final Place? selected;
  final ValueChanged<Place> onPick;
  final VoidCallback? onNext;

  @override
  ConsumerState<CreatePlaceStep> createState() => _CreatePlaceStepState();
}

class _CreatePlaceStepState extends ConsumerState<CreatePlaceStep> {
  String _query = '';

  Future<void> _openMap() async {
    final place = await context.push<Place>('/places/pick');
    if (place != null) widget.onPick(place);
  }

  @override
  Widget build(BuildContext context) {
    final centre = roundCentre(
      PlacePickerScreen.start.latitude,
      PlacePickerScreen.start.longitude,
    );
    final places =
        ref.watch(nearbyPlacesProvider(centre)).value ?? const <Place>[];
    final query = _query.trim().toLowerCase();
    final shown =
        [
              ?widget.selected,
              ...places.where((place) => place.id != widget.selected?.id),
            ]
            .where(
              (place) =>
                  query.isEmpty || place.name.toLowerCase().contains(query),
            )
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Where can this ${widget.amount.format()} be spent?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(hintText: 'Search places'),
          onChanged: (text) => setState(() => _query = text),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            children: [
              for (final place in shown)
                _PlaceTile(
                  place: place,
                  selected: place.id == widget.selected?.id,
                  onTap: () => widget.onPick(place),
                ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    query.isEmpty
                        ? 'No places saved nearby yet.'
                        : 'No places match "$_query".',
                    style: const TextStyle(color: CasheColors.muted),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _MapButton(onTap: _openMap),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: widget.onNext,
          child: const Text('Next: review'),
        ),
      ],
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final Place place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? CasheColors.background : CasheColors.text;
    final distance = place.distanceM;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? CasheColors.amber : CasheColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? CasheColors.amber : CasheColors.border,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          title: Text(
            place.name,
            style: TextStyle(fontWeight: FontWeight.w700, color: foreground),
          ),
          subtitle: Text(
            'Stay ${WalletText.dwell(place.dwellSeconds)} within ${place.radiusM} m',
            style: TextStyle(
              fontSize: 12.5,
              color: foreground.withValues(alpha: 0.75),
            ),
          ),
          trailing: distance == null
              ? null
              : Text(
                  distance < 1000
                      ? '$distance m'
                      : '${(distance / 1000).toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: foreground.withValues(alpha: 0.75),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CasheColors.border),
          color: CasheColors.surface,
        ),
        child: const Text(
          'OPEN MAP · FIND OR ADD A PLACE',
          style: TextStyle(
            fontFamily: mono,
            fontSize: 10.5,
            letterSpacing: 0.6,
            color: CasheColors.faint,
          ),
        ),
      ),
    );
  }
}
