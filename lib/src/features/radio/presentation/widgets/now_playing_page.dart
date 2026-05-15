import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../data/models/station.dart';
import '../../state/radio_controller.dart';

/// Full-screen "Now Playing" page — Spotify style.
/// Opens as a modal route from the mini player bar.
class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({required this.controller, super.key});

  final RadioController controller;

  static Future<void> open(BuildContext context, RadioController controller) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) {
          return NowPlayingPage(controller: controller);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final station = controller.currentStation;
        final isFavorite =
            station != null && controller.isFavorite(station.uuid);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: <double>[0.0, 0.45, 1.0],
                colors: <Color>[
                  Color(0xFF1A2A1E),
                  Color(0xFF0D0D0D),
                  AppColors.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  // ── Top bar ──
                  _TopBar(controller: controller),

                  // ── Artwork ──
                  Expanded(
                    flex: 5,
                    child: _ArtworkSection(station: station),
                  ),

                  // ── Station info ──
                  _StationInfo(
                    station: station,
                    isFavorite: isFavorite,
                    controller: controller,
                  ),

                  // ── Live indicator bar ──
                  const _LiveIndicator(),

                  // ── Controls ──
                  _PlaybackControls(controller: controller),

                  // ── Bottom actions ──
                  _BottomActions(controller: controller),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Top Bar — chevron down to dismiss + "Now Playing" label
// ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 30,
              color: AppColors.textPrimary,
            ),
          ),
          const Expanded(
            child: Text(
              'NOW PLAYING',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Options',
            onPressed: () => _showOptionsSheet(context),
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final station = controller.currentStation;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (station != null) ...<Widget>[
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                    title: const Text('Station Info'),
                    subtitle: Text(
                      '${station.codec.isNotEmpty ? station.codec : "Unknown"} · ${station.bitrate > 0 ? "${station.bitrate} kbps" : "Unknown bitrate"}',
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ),
                  if (station.homepage.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.language_rounded, color: AppColors.textSecondary),
                      title: const Text('Visit Website'),
                      subtitle: Text(
                        station.homepage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Artwork Section — large image with glow
// ─────────────────────────────────────────────────────────────────

class _ArtworkSection extends StatelessWidget {
  const _ArtworkSection({required this.station});

  final Station? station;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildArtwork(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork() {
    final url = station?.favicon ?? '';
    if (url.isEmpty) {
      return const _FallbackArtwork();
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _FallbackArtwork(),
    );
  }
}

class _FallbackArtwork extends StatelessWidget {
  const _FallbackArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.accent.withValues(alpha: 0.3),
            AppColors.surfaceHighlight,
            const Color(0xFF1A1A2E),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.radio_rounded,
          size: 80,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Station Info — name + meta + favorite
// ─────────────────────────────────────────────────────────────────

class _StationInfo extends StatelessWidget {
  const _StationInfo({
    required this.station,
    required this.isFavorite,
    required this.controller,
  });

  final Station? station;
  final bool isFavorite;
  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  station?.name ?? 'No Station',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildSubtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: station == null
                ? null
                : () => unawaited(controller.toggleFavoriteStation(station!)),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                size: 28,
                color: isFavorite ? AppColors.accent : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    if (station == null) return '';
    final parts = <String>[];
    if (station!.country.isNotEmpty) parts.add(station!.country);
    final tags = station!.tags.take(2).join(', ');
    if (tags.isNotEmpty) parts.add(tags);
    return parts.join(' · ');
  }
}

// ─────────────────────────────────────────────────────────────────
// Live Indicator — animated bar for radio stream
// ─────────────────────────────────────────────────────────────────

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 4),
      child: Column(
        children: <Widget>[
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 3,
                  child: CustomPaint(
                    size: const Size(double.infinity, 3),
                    painter: _LiveBarPainter(
                      progress: _controller.value,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.circle, size: 6, color: AppColors.accent),
                    SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.cast_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveBarPainter extends CustomPainter {
  _LiveBarPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Background track
    final bgPaint = Paint()..color = color.withValues(alpha: 0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(2),
      ),
      bgPaint,
    );

    // Animated shimmering bar
    final shimmerWidth = size.width * 0.4;
    final center = progress * (size.width + shimmerWidth) - shimmerWidth / 2;
    final gradient = LinearGradient(
      colors: <Color>[
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.6),
        color,
        color.withValues(alpha: 0.6),
        color.withValues(alpha: 0.0),
      ],
    );
    final rect = Rect.fromLTWH(center - shimmerWidth / 2, 0, shimmerWidth, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LiveBarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────
// Playback Controls — prev / play-pause / next
// ─────────────────────────────────────────────────────────────────

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.controller});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final hasStation = controller.currentStation != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Shuffle (decorative for radio)
          const Icon(
            Icons.shuffle_rounded,
            size: 22,
            color: AppColors.textTertiary,
          ),

          const SizedBox(width: 24),

          // Previous station
          IconButton(
            tooltip: 'Previous station',
            onPressed: hasStation
                ? () => unawaited(controller.playPreviousStation())
                : null,
            iconSize: 36,
            icon: const Icon(
              Icons.skip_previous_rounded,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(width: 12),

          // Play / Pause — large circle
          _LargePlayButton(controller: controller),

          const SizedBox(width: 12),

          // Next station
          IconButton(
            tooltip: 'Next station',
            onPressed: hasStation
                ? () => unawaited(controller.playNextStation())
                : null,
            iconSize: 36,
            icon: const Icon(
              Icons.skip_next_rounded,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(width: 24),

          // Repeat (decorative for radio)
          const Icon(
            Icons.repeat_rounded,
            size: 22,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _LargePlayButton extends StatelessWidget {
  const _LargePlayButton({required this.controller});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: AppColors.textPrimary,
        shape: const CircleBorder(),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: controller.currentStation == null
              ? null
              : () => unawaited(controller.togglePlayPause()),
          child: Center(
            child: Icon(
              controller.playerIsLoading
                  ? Icons.stop_rounded
                  : controller.playerIsPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
              size: 34,
              color: AppColors.background,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bottom Actions — volume, sleep timer
// ─────────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.controller});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          // Volume row
          Row(
            children: <Widget>[
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
              Expanded(
                child: Slider(
                  value: controller.volume,
                  min: 0,
                  max: 100,
                  onChanged: (v) => unawaited(controller.setVolume(v)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Sleep timer row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Sleep timer button
              TextButton.icon(
                onPressed: () => _showSleepTimerSheet(context),
                icon: Icon(
                  Icons.bedtime_outlined,
                  size: 18,
                  color: controller.hasSleepTimer
                      ? AppColors.accent
                      : AppColors.textTertiary,
                ),
                label: Text(
                  controller.hasSleepTimer
                      ? _formatRemaining(controller.sleepTimerRemaining!)
                      : 'Sleep Timer',
                  style: TextStyle(
                    color: controller.hasSleepTimer
                        ? AppColors.accent
                        : AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Share / queue placeholder
              IconButton(
                tooltip: 'Queue',
                onPressed: () {},
                icon: const Icon(
                  Icons.queue_music_rounded,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showSleepTimerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _SleepTimerSheet(controller: controller);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sleep Timer Bottom Sheet
// ─────────────────────────────────────────────────────────────────

class _SleepTimerSheet extends StatelessWidget {
  const _SleepTimerSheet({required this.controller});

  final RadioController controller;

  static const _presets = <int>[5, 10, 15, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Row(
              children: <Widget>[
                Icon(Icons.bedtime_outlined, size: 20, color: AppColors.accent),
                SizedBox(width: 10),
                Text(
                  'Sleep Timer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Preset grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((minutes) {
                final isActive = controller.hasSleepTimer &&
                    controller.sleepTimerTotal?.inMinutes == minutes;
                return _TimerChip(
                  label: _chipLabel(minutes),
                  isActive: isActive,
                  onTap: () {
                    controller.startSleepTimer(Duration(minutes: minutes));
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),

            // Cancel button
            if (controller.hasSleepTimer) ...<Widget>[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    controller.cancelSleepTimer();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: BorderSide(color: AppColors.red.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel Timer',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _chipLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppColors.accent : AppColors.surfaceHighlight,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.background : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
