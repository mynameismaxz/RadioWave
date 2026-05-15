import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
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
    final isPlaying =
        controller.playerIsPlaying && controller.currentStation?.uuid == station.uuid;
    final isCurrent = controller.currentStation?.uuid == station.uuid;
    final isFavorite = controller.isFavorite(station.uuid);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => unawaited(controller.playStation(station)),
        hoverColor: AppColors.cardHover,
        splashColor: AppColors.accent.withValues(alpha: 0.06),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.surfaceHighlight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              StationArtwork(
                url: station.favicon,
                isPlaying: isPlaying,
              ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isCurrent
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StationMeta(station: station),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isPlaying)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: PlayingBars(),
                ),
              IconButton(
                tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                onPressed: () => unawaited(
                  controller.toggleFavoriteStation(station),
                ),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: isFavorite ? AppColors.accent : AppColors.textTertiary,
                ),
              ),
            ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: url.isEmpty
            ? const Icon(
                Icons.radio_rounded,
                color: AppColors.textTertiary,
                size: 22,
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.radio_rounded,
                    color: AppColors.textTertiary,
                    size: 22,
                  );
                },
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
    final parts = <String>[];

    if (station.country.isNotEmpty) {
      parts.add(station.country);
    }

    final visibleTags = station.tags.take(2).join(', ');
    if (visibleTags.isNotEmpty) {
      parts.add(visibleTags);
    }

    if (station.bitrate > 0) {
      parts.add('${station.bitrate} kbps');
    }

    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

/// Animated equalizer bars shown for currently playing station —
/// mimics Spotify's playing indicator.
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
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
