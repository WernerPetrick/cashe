import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/cashe_widgets.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../places/domain/place.dart';
import '../../../places/presentation/new_place_sheet.dart';
import '../../../places/presentation/place_picker_screen.dart';
import '../../../places/presentation/place_providers.dart';
import '../../domain/wallet_text.dart';

/// Step 2: where the money can be spent. Lists saved places around the map's
/// starting point (never the device's location), then real-world places that
/// match the search (ADR 0006); the map opens for anything else.
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
  /// Shorter queries only filter saved places.
  static const _minSearch = 3;

  final _centre = roundCentre(
    PlacePickerScreen.start.latitude,
    PlacePickerScreen.start.longitude,
  );
  String _query = '';
  String _searched = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Filters saved places at once; asks the outside search once typing pauses.
  void _onQuery(String text) {
    setState(() => _query = text);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _searched = text.trim());
    });
  }

  Future<void> _openMap() async {
    final place = await context.push<Place>('/places/pick');
    if (place != null) widget.onPick(place);
  }

  /// A search result becomes a Cashe place once its zone and dwell are set.
  Future<void> _useSuggestion(PlaceSuggestion suggestion) async {
    final point = LatLng(suggestion.latitude, suggestion.longitude);
    final place = await NewPlaceSheet.show(
      context,
      point,
      name: suggestion.name,
    );
    if (place == null || !mounted) return;
    ref.invalidate(nearbyPlacesProvider);
    widget.onPick(place);
  }

  @override
  Widget build(BuildContext context) {
    final places =
        ref.watch(nearbyPlacesProvider(_centre)).value ?? const <Place>[];
    final searching = _searched.length >= _minSearch;
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
          onChanged: _onQuery,
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
              if (searching)
                _SearchResults(
                  query: (text: _searched, centre: _centre),
                  onPick: _useSuggestion,
                )
              else if (shown.isEmpty)
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

/// Real-world places for the search box, under the saved ones.
class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.onPick});

  final PlaceQuery query;
  final ValueChanged<PlaceSuggestion> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(placeSearchProvider(query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: MonoLabel('Other places'),
        ),
        ...results.when(
          data: (suggestions) => suggestions.isEmpty
              ? [_Note('Nothing found for "${query.text}". Try the map.')]
              : [
                  for (final suggestion in suggestions)
                    _SuggestionTile(
                      suggestion: suggestion,
                      onTap: () => onPick(suggestion),
                    ),
                ],
          error: (error, _) => [_Note(ErrorView.messageFor(error))],
          loading: () => [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});

  final PlaceSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(Icons.place_outlined, color: CasheColors.muted),
      title: Text(
        suggestion.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: suggestion.address.isEmpty
          ? null
          : Text(
              suggestion.address,
              style: const TextStyle(fontSize: 12.5, color: CasheColors.muted),
            ),
      trailing: const Icon(Icons.add, color: CasheColors.muted),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(text, style: const TextStyle(color: CasheColors.muted)),
  );
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
