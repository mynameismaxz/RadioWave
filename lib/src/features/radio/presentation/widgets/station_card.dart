import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../../../data/models/station.dart';
import '../../state/radio_controller.dart';

class StationCard extends StatelessWidget {
  const StationCard({
    required this.station,
    required this.controller,
    super.key,
  });

  final Station station;
  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isPlaying =
        controller.playerIsPlaying && controller.currentStation?.uuid == station.uuid;
    final isCurrent = controller.currentStation?.uuid == station.uuid;
    final isFavorite = controller.isFavorite(station.uuid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isCurrent ? c.cardHover : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => unawaited(controller.playStation(station)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: <Widget>[
                StationArtwork(url: station.favicon, isPlaying: isPlaying),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        station.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isCurrent ? c.textPrimary : c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StationMeta(station: station),
                    ],
                  ),
                ),
                if (isPlaying)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: PlayingBars(),
                  ),
                IconButton(
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: () =>
                      unawaited(controller.toggleFavoriteStation(station)),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFavorite ? c.textPrimary : c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StationArtwork extends StatelessWidget {
  const StationArtwork({
    required this.url,
    this.isPlaying = false,
    super.key,
  });

  final String url;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 48,
        height: 48,
        color: c.card,
        child: url.isEmpty
            ? Icon(Icons.radio_rounded, color: c.textTertiary, size: 22)
            : Image.network(
                url,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.radio_rounded, color: c.textTertiary, size: 22),
              ),
      ),
    );
  }
}

class StationMeta extends StatelessWidget {
  const StationMeta({required this.station, super.key});

  final Station station;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final parts = <String>[];
    if (station.country.isNotEmpty) parts.add(station.country);
    final visibleTags = station.tags.take(2).join(', ');
    if (visibleTags.isNotEmpty) parts.add(visibleTags);
    if (station.bitrate > 0) parts.add('${station.bitrate} kbps');

    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: c.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class PlayingBars extends StatefulWidget {
  const PlayingBars({super.key});

  @override
  State<PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<PlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (index) {
            final delays = <double>[0.0, 0.3, 0.6];
            final progress = (_controller.value + delays[index]) % 1.0;
            final height = 4.0 + (progress * 10.0);
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: c.textPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
