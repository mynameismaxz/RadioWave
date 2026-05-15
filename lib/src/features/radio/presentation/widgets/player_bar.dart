import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../state/radio_controller.dart';
import 'now_playing_page.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({required this.controller, super.key});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final station = controller.currentStation;
    final currentIsFavorite = station != null && controller.isFavorite(station.uuid);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ── Now playing bar ──
              GestureDetector(
                onTap: controller.playerBarVisible
                    ? () => unawaited(NowPlayingPage.open(context, controller))
                    : null,
              child: Container(
                constraints: const BoxConstraints(minHeight: 68),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(
                      color: controller.playerIsPlaying
                          ? AppColors.accent.withValues(alpha: 0.3)
                          : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 520;
                    return Row(
                      children: <Widget>[
                        // Station icon
                        _PlayerArtwork(
                          isPlaying: controller.playerIsPlaying,
                        ),
                        const SizedBox(width: 12),

                        // Station info
                        Expanded(
                          child: PlayerInfo(
                            stationName: station?.name ?? 'No station selected',
                            status: controller.playerStatus,
                            active: controller.playerBarVisible,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Favorite button
                        IconButton(
                          tooltip: currentIsFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                          onPressed: station == null
                              ? null
                              : () => unawaited(
                                    controller.toggleFavoriteStation(station),
                                  ),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            currentIsFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: currentIsFavorite
                                ? AppColors.accent
                                : AppColors.textTertiary,
                          ),
                        ),

                        const SizedBox(width: 4),

                        // Play / Pause — Spotify-style circle button
                        _PlayButton(
                          isPlaying: controller.playerIsPlaying,
                          isLoading: controller.playerIsLoading,
                          enabled: station != null,
                          onPressed: station == null
                              ? null
                              : () => unawaited(controller.togglePlayPause()),
                        ),

                        // Volume
                        VolumeControl(controller: controller, compact: compact),
                      ],
                    );
                  },
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerArtwork extends StatelessWidget {
  const _PlayerArtwork({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        isPlaying ? Icons.graphic_eq_rounded : Icons.album_rounded,
        color: isPlaying ? AppColors.accent : AppColors.textTertiary,
        size: 22,
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Always tappable when enabled — loading can be cancelled
    return Tooltip(
      message: isLoading ? 'Stop' : (isPlaying ? 'Pause' : 'Play'),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: enabled ? AppColors.textPrimary : AppColors.surfaceHighlight,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Center(
              child: isLoading
                  ? const Icon(
                      Icons.stop_rounded,
                      size: 26,
                      color: AppColors.background,
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 26,
                      color: AppColors.background,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerInfo extends StatelessWidget {
  const PlayerInfo({
    required this.stationName,
    required this.status,
    required this.active,
    super.key,
  });

  final String stationName;
  final String status;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          stationName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? AppColors.accent : AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class VolumeControl extends StatelessWidget {
  const VolumeControl({
    required this.controller,
    required this.compact,
    super.key,
  });

  final RadioController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: controller.isMuted ? 'Unmute' : 'Mute',
        onPressed: () => unawaited(controller.toggleMute()),
        visualDensity: VisualDensity.compact,
        icon: Icon(
          controller.isMuted || controller.volume == 0
              ? Icons.volume_off_rounded
              : Icons.volume_up_rounded,
          size: 20,
          color: AppColors.textTertiary,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(width: 8),
        IconButton(
          tooltip: controller.isMuted ? 'Unmute' : 'Mute',
          onPressed: () => unawaited(controller.toggleMute()),
          visualDensity: VisualDensity.compact,
          icon: Icon(
            controller.isMuted || controller.volume == 0
                ? Icons.volume_off_rounded
                : controller.volume < 50
                    ? Icons.volume_down_rounded
                    : Icons.volume_up_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(
          width: 90,
          child: Slider(
            value: controller.volume,
            min: 0,
            max: 100,
            onChanged: (value) => unawaited(controller.setVolume(value)),
          ),
        ),
      ],
    );
  }
}

/// Animated visualizer bars (legacy — kept for compat but hidden in new design).
class VisualizerBars extends StatefulWidget {
  const VisualizerBars({super.key});

  @override
  State<VisualizerBars> createState() => _VisualizerBarsState();
}

class _VisualizerBarsState extends State<VisualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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
          children: List<Widget>.generate(5, (index) {
            final wave = math.sin((_controller.value * math.pi * 2) + index);
            final height = 7 + ((wave + 1) * 6);
            return Container(
              width: 4,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
