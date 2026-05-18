import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../state/radio_controller.dart';
import 'now_playing_page.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({required this.controller, super.key});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final station = controller.currentStation;
    final currentIsFavorite =
        station != null && controller.isFavorite(station.uuid);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1920),
          child: GestureDetector(
            onTap: controller.playerBarVisible
                ? () => unawaited(NowPlayingPage.open(context, controller))
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 96,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: c.surfaceHighlight.withValues(
                    alpha: isDark ? 0.82 : 0.88,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: c.border.withValues(alpha: isDark ? 0.35 : 0.4),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 720;
                    if (compact) {
                      return _CompactPlayerBar(
                        controller: controller,
                        stationName: station?.name ?? 'No station selected',
                        stationFavicon: station?.favicon ?? '',
                        currentIsFavorite: currentIsFavorite,
                      );
                    }
                    return _ExpandedPlayerBar(
                      controller: controller,
                      stationName: station?.name ?? 'No station selected',
                      stationFavicon: station?.favicon ?? '',
                      currentIsFavorite: currentIsFavorite,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedPlayerBar extends StatelessWidget {
  const _ExpandedPlayerBar({
    required this.controller,
    required this.stationName,
    required this.stationFavicon,
    required this.currentIsFavorite,
  });

  final RadioController controller;
  final String stationName;
  final String stationFavicon;
  final bool currentIsFavorite;

  @override
  Widget build(BuildContext context) {
    final station = controller.currentStation;

    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              _PlayerArtwork(
                isPlaying: controller.playerIsPlaying,
                url: stationFavicon,
                size: 58,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: PlayerInfo(
                  stationName: stationName,
                  status: controller.playerStatus,
                  active: controller.playerBarVisible,
                ),
              ),
              const SizedBox(width: 8),
              _GlassIconButton(
                tooltip: currentIsFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onPressed: station == null
                    ? null
                    : () => unawaited(
                          controller.toggleFavoriteStation(station),
                        ),
                icon: currentIsFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                active: currentIsFavorite,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _TransportControls(controller: controller, large: true),
              const SizedBox(height: 8),
              const _LiveRail(),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                VolumeControl(controller: controller, compact: false),
                const SizedBox(width: 12),
                _QualityPill(label: _qualityLabel(controller)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _qualityLabel(RadioController controller) {
    final station = controller.currentStation;
    if (station == null) return 'LIVE RADIO';
    final parts = <String>[];
    if (station.codec.isNotEmpty) parts.add(station.codec.toUpperCase());
    if (station.bitrate > 0) parts.add('${station.bitrate} kbps');
    return parts.isEmpty ? 'LIVE RADIO' : parts.join(' ');
  }
}

class _CompactPlayerBar extends StatelessWidget {
  const _CompactPlayerBar({
    required this.controller,
    required this.stationName,
    required this.stationFavicon,
    required this.currentIsFavorite,
  });

  final RadioController controller;
  final String stationName;
  final String stationFavicon;
  final bool currentIsFavorite;

  @override
  Widget build(BuildContext context) {
    final station = controller.currentStation;

    return Row(
      children: <Widget>[
        _PlayerArtwork(
          isPlaying: controller.playerIsPlaying,
          url: stationFavicon,
          size: 48,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PlayerInfo(
            stationName: stationName,
            status: controller.playerStatus,
            active: controller.playerBarVisible,
          ),
        ),
        const SizedBox(width: 6),
        _GlassIconButton(
          tooltip:
              currentIsFavorite ? 'Remove from favorites' : 'Add to favorites',
          onPressed: station == null
              ? null
              : () => unawaited(controller.toggleFavoriteStation(station)),
          icon: currentIsFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          active: currentIsFavorite,
        ),
        const SizedBox(width: 4),
        _PlayButton(
          isPlaying: controller.playerIsPlaying,
          isLoading: controller.playerIsLoading,
          enabled: station != null,
          onPressed: station == null
              ? null
              : () => unawaited(controller.togglePlayPause()),
        ),
        VolumeControl(controller: controller, compact: true),
      ],
    );
  }
}

// ── Artwork ──────────────────────────────────────────────────────────────────

class _PlayerArtwork extends StatelessWidget {
  const _PlayerArtwork({
    required this.isPlaying,
    required this.url,
    this.size = 54,
  });

  final bool isPlaying;
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: size,
        height: size,
        color: isDark ? c.card : c.surfaceElevated,
        child: url.isEmpty
            ? Icon(
                isPlaying ? Icons.graphic_eq_rounded : Icons.radio_rounded,
                color: isPlaying ? c.textPrimary : c.textTertiary,
                size: size * 0.45,
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  isPlaying ? Icons.graphic_eq_rounded : Icons.radio_rounded,
                  color: isPlaying ? c.textPrimary : c.textTertiary,
                  size: size * 0.45,
                ),
              ),
      ),
    );
  }
}

// ── Transport Controls ────────────────────────────────────────────────────────

class _TransportControls extends StatelessWidget {
  const _TransportControls({required this.controller, required this.large});

  final RadioController controller;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final station = controller.currentStation;
    final hasStations = controller.stations.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _GlassIconButton(
          tooltip: 'Previous station',
          onPressed: hasStations
              ? () => unawaited(controller.playPreviousStation())
              : null,
          icon: Icons.skip_previous_rounded,
          size: large ? 40 : 34,
          iconSize: large ? 28 : 24,
        ),
        const SizedBox(width: 18),
        _PlayButton(
          isPlaying: controller.playerIsPlaying,
          isLoading: controller.playerIsLoading,
          enabled: station != null,
          onPressed: station == null
              ? null
              : () => unawaited(controller.togglePlayPause()),
          large: large,
        ),
        const SizedBox(width: 18),
        _GlassIconButton(
          tooltip: 'Next station',
          onPressed: hasStations
              ? () => unawaited(controller.playNextStation())
              : null,
          icon: Icons.skip_next_rounded,
          size: large ? 40 : 34,
          iconSize: large ? 28 : 24,
        ),
      ],
    );
  }
}

// ── Glass Icon Button ─────────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.active = false,
    this.size = 34,
    this.iconSize = 20,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool active;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: iconSize,
            color: !enabled
                ? c.textDisabled
                : active
                    ? c.textPrimary
                    : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Play Button ───────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
    this.large = false,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool enabled;
  final VoidCallback? onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnSize = large ? 52.0 : 44.0;

    return Tooltip(
      message: isLoading ? 'Stop' : (isPlaying ? 'Pause' : 'Play'),
      child: SizedBox(
        width: btnSize,
        height: btnSize,
        child: Material(
          color: enabled
              ? (isDark ? Colors.white : c.textPrimary)
              : c.textDisabled.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Center(
              child: isLoading
                  ? Icon(
                      Icons.stop_rounded,
                      size: large ? 28 : 24,
                      color: isDark ? Colors.black : c.background,
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: large ? 28 : 24,
                      color: isDark ? Colors.black : c.background,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Player Info ───────────────────────────────────────────────────────────────

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
    final c = AppColorScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          stationName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? c.textSecondary : c.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

// ── Live Rail ─────────────────────────────────────────────────────────────────

class _LiveRail extends StatelessWidget {
  const _LiveRail();

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return Row(
      children: <Widget>[
        Text(
          'LIVE',
          style: TextStyle(
            color: c.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.textPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'RADIO',
          style: TextStyle(
            color: c.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

// ── Quality Pill ──────────────────────────────────────────────────────────────

class _QualityPill extends StatelessWidget {
  const _QualityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return Container(
      height: 32,
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.amber, width: 1),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: c.amber,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ── Volume Control ────────────────────────────────────────────────────────────

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
    final c = AppColorScheme.of(context);
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
          color: c.textTertiary,
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
            color: c.textSecondary,
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

// ── Visualizer Bars ───────────────────────────────────────────────────────────

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
    final c = AppColorScheme.of(context);
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
                color: c.textPrimary,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
