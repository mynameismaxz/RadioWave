import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../../../data/models/station.dart';
import '../../state/radio_controller.dart';
import 'glass.dart';

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

        final c = AppColorScheme.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              // ── Translucent gradient background (lets orbs show through) ──
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const <double>[0.0, 0.5, 1.0],
                          colors: <Color>[
                            (isDark
                                    ? const Color(0xFF0D1A12)
                                    : const Color(0xFFD8EDFF))
                                .withValues(alpha: 0.82),
                            c.background.withValues(alpha: 0.88),
                            c.background.withValues(alpha: 0.96),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // ── Main content ──
              if (kIsWeb)
                Positioned.fill(
                  child: SafeArea(
                    child: _WebNowPlayingLayout(
                      station: station,
                      controller: controller,
                      isFavorite: isFavorite,
                    ),
                  ),
                )
              else
                SafeArea(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) {
                      final nativeLandscape =
                          box.maxWidth > box.maxHeight && box.maxWidth >= 700;

                      if (nativeLandscape) {
                        return _NativeLandscapeNowPlayingLayout(
                          station: station,
                          controller: controller,
                          isFavorite: isFavorite,
                        );
                      }

                      return Column(
                        children: <Widget>[
                          _TopBar(controller: controller),
                          Expanded(
                            flex: 5,
                            child: _ArtworkSection(station: station),
                          ),
                          _StationInfo(
                            station: station,
                            isFavorite: isFavorite,
                            controller: controller,
                          ),
                          const _LiveIndicator(),
                          _PlaybackControls(controller: controller),
                          _BottomActions(controller: controller),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Top Bar — chevron down to dismiss + "Now Playing" label
// ─────────────────────────────────────────────────────────────────

class _NativeLandscapeNowPlayingLayout extends StatelessWidget {
  const _NativeLandscapeNowPlayingLayout({
    required this.station,
    required this.controller,
    required this.isFavorite,
  });

  final Station? station;
  final RadioController controller;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _TopBar(controller: controller),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      final side = math
                          .min(
                            constraints.maxWidth,
                            constraints.maxHeight * 0.92,
                          )
                          .clamp(140.0, 360.0)
                          .toDouble();

                      return Center(
                        child: SizedBox(
                          width: side,
                          height: side,
                          child: _ArtworkSection(station: station),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 6,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 520,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _StationInfo(
                            station: station,
                            isFavorite: isFavorite,
                            controller: controller,
                          ),
                          const _LiveIndicator(),
                          _PlaybackControls(controller: controller),
                          _BottomActions(controller: controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WebNowPlayingLayout extends StatelessWidget {
  const _WebNowPlayingLayout({
    required this.controller,
    required this.station,
    required this.isFavorite,
  });

  final RadioController controller;
  final Station? station;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720 || size.width < 480;
    final sidePadding = size.width < 480
        ? 28.0
        : size.width < 900
            ? 36.0
            : 48.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? <Color>[
                  const Color(0xFF04110A).withValues(alpha: 0.96),
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.98),
                ]
              : <Color>[
                  const Color(0xFFE8F0F8).withValues(alpha: 0.90),
                  const Color(0xFFE3EAF2).withValues(alpha: 0.88),
                  const Color(0xFFE9EEF5).withValues(alpha: 0.96),
                ],
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final topPadding = compact ? 6.0 : 12.0;
          final bottomPadding = compact ? 6.0 : 12.0;
          final controlsWidth =
              (constraints.maxWidth - (sidePadding * 2)).clamp(160.0, 1200.0);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              topPadding,
              sidePadding,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _WebTopBar(controller: controller),
                SizedBox(height: compact ? 8 : 12),
                Expanded(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints bodyConstraints) {
                      final bodyHeight =
                          math.max(0.0, bodyConstraints.maxHeight);
                      final preferredBottomHeight = math.min(
                        bodyHeight * (compact ? 0.40 : 0.36),
                        compact ? 258.0 : 300.0,
                      );
                      final minBottomHeight = math.min(
                        compact ? 180.0 : 210.0,
                        bodyHeight * 0.70,
                      );
                      final maxBottomHeight = math.max(
                        minBottomHeight,
                        math.min(compact ? 258.0 : 300.0, bodyHeight * 0.58),
                      );
                      final bottomSlotHeight = preferredBottomHeight
                          .clamp(minBottomHeight, maxBottomHeight)
                          .toDouble();
                      final artworkSlotHeight =
                          math.max(0.0, bodyHeight - bottomSlotHeight);
                      final artworkSide = math.min(
                        math.max(0.0, constraints.maxWidth - (sidePadding * 2)),
                        math.min(
                          artworkSlotHeight * (compact ? 0.84 : 0.90),
                          520.0,
                        ),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(
                            height: artworkSlotHeight,
                            child: Center(
                              child: _SmallArtwork(
                                station: station,
                                size: artworkSide,
                                radius: (artworkSide * 0.055).clamp(8.0, 22.0),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: bottomSlotHeight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                width: controlsWidth,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    _WebStationHeader(
                                      station: station,
                                      controller: controller,
                                      isFavorite: isFavorite,
                                      compact: compact,
                                    ),
                                    SizedBox(height: compact ? 4 : 8),
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color:
                                          c.textPrimary.withValues(alpha: 0.18),
                                    ),
                                    SizedBox(height: compact ? 6 : 10),
                                    const _WebLiveRow(),
                                    SizedBox(height: compact ? 6 : 10),
                                    _WebPlaybackControls(
                                      controller: controller,
                                      compact: compact,
                                    ),
                                    SizedBox(height: compact ? 2 : 8),
                                    _WebVolumeRow(controller: controller),
                                    _WebBottomActions(controller: controller),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WebTopBar extends StatelessWidget {
  const _WebTopBar({required this.controller});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return SizedBox(
      height: 32,
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 30,
              color: c.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              'NOW PLAYING',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Options',
            onPressed: () {},
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.more_vert_rounded, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SmallArtwork extends StatelessWidget {
  const _SmallArtwork({
    required this.station,
    required this.size,
    required this.radius,
  });

  final Station? station;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final url = station?.favicon ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: c.card,
        child: url.isEmpty
            ? Icon(Icons.radio_rounded, size: size * 0.5, color: c.textTertiary)
            : Image.network(
                url,
                key: ValueKey(station == null ? url : '${station!.uuid}|$url'),
                fit: BoxFit.cover,
                gaplessPlayback: false,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.radio_rounded,
                  size: size * 0.5,
                  color: c.textTertiary,
                ),
              ),
      ),
    );
  }
}

class _WebStationHeader extends StatelessWidget {
  const _WebStationHeader({
    required this.station,
    required this.controller,
    required this.isFavorite,
    required this.compact,
  });

  final Station? station;
  final RadioController controller;
  final bool isFavorite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                station?.name ?? 'No Station',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: compact ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 3 : 6),
              Text(
                _stationSubtitle(station),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: compact ? 15 : 18,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          onPressed: station == null
              ? null
              : () => unawaited(controller.toggleFavoriteStation(station!)),
          iconSize: compact ? 32 : 38,
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _WebLiveRow extends StatelessWidget {
  const _WebLiveRow();

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.circle, size: 6, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Icon(Icons.cast_rounded, size: 22, color: c.textSecondary),
      ],
    );
  }
}

class _WebPlaybackControls extends StatelessWidget {
  const _WebPlaybackControls({
    required this.controller,
    required this.compact,
  });

  final RadioController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final hasStation = controller.currentStation != null;
    final skipSize = compact ? 32.0 : 38.0;
    final gapOuter = compact ? 18.0 : 34.0;
    final gapInner = compact ? 12.0 : 18.0;
    final playSize = compact ? 64.0 : 78.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.shuffle_rounded, size: 24, color: c.textSecondary),
        SizedBox(width: gapOuter),
        IconButton(
          tooltip: 'Previous station',
          onPressed: hasStation
              ? () => unawaited(controller.playPreviousStation())
              : null,
          iconSize: skipSize,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.skip_previous_rounded, color: c.textPrimary),
        ),
        SizedBox(width: gapInner),
        _LargePlayButton(
          controller: controller,
          size: playSize,
        ),
        SizedBox(width: gapInner),
        IconButton(
          tooltip: 'Next station',
          onPressed:
              hasStation ? () => unawaited(controller.playNextStation()) : null,
          iconSize: skipSize,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.skip_next_rounded, color: c.textPrimary),
        ),
        SizedBox(width: gapOuter),
        Icon(Icons.repeat_rounded, size: 24, color: c.textSecondary),
      ],
    );
  }
}

class _WebVolumeRow extends StatelessWidget {
  const _WebVolumeRow({required this.controller});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Row(
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
            size: 22,
            color: c.textPrimary,
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
    );
  }
}

class _WebBottomActions extends StatelessWidget {
  const _WebBottomActions({required this.controller});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Row(
      children: <Widget>[
        TextButton.icon(
          onPressed: () => _showSleepTimerSheet(context),
          icon: Icon(
            Icons.bedtime_outlined,
            size: 18,
            color: controller.hasSleepTimer ? c.accent : c.textTertiary,
          ),
          label: Text(
            controller.hasSleepTimer
                ? _formatRemaining(controller.sleepTimerRemaining!)
                : 'Sleep Timer',
            style: TextStyle(
              color: controller.hasSleepTimer ? c.accent : c.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Queue',
          onPressed: () {},
          icon:
              Icon(Icons.queue_music_rounded, size: 22, color: c.textTertiary),
        ),
      ],
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _SleepTimerSheet(controller: controller);
      },
    );
  }
}

String _stationSubtitle(Station? station) {
  if (station == null) return '';
  final parts = <String>[];
  if (station.country.isNotEmpty) parts.add(station.country);
  final tags = station.tags.take(2).join(', ');
  if (tags.isNotEmpty) parts.add(tags);
  if (station.bitrate > 0) parts.add('${station.bitrate} kbps');
  return parts.join(' - ');
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 30,
              color: c.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              'NOW PLAYING',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Options',
            onPressed: () => _showOptionsSheet(context),
            icon: Icon(
              Icons.more_vert_rounded,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final sc = AppColorScheme.of(sheetCtx);
        final isDarkSheet = Theme.of(sheetCtx).brightness == Brightness.dark;
        final station = controller.currentStation;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [sc.glassHighlight, sc.glassBase, sc.glassDeep],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: sc.glassEdge, width: 0.8),
                ),
              ),
              child: SafeArea(
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
                          color: isDarkSheet
                              ? Colors.white.withValues(alpha: 0.30)
                              : Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      if (station != null) ...<Widget>[
                        ListTile(
                          leading: Icon(Icons.info_outline_rounded,
                              color: sc.textSecondary),
                          title: const Text('Station Info'),
                          subtitle: Text(
                            '${station.codec.isNotEmpty ? station.codec : "Unknown"} · ${station.bitrate > 0 ? "${station.bitrate} kbps" : "Unknown bitrate"}',
                            style:
                                TextStyle(color: sc.textTertiary, fontSize: 12),
                          ),
                        ),
                        if (station.homepage.isNotEmpty)
                          ListTile(
                            leading: Icon(Icons.language_rounded,
                                color: sc.textSecondary),
                            title: const Text('Visit Website'),
                            subtitle: Text(
                              station.homepage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: sc.textTertiary, fontSize: 12),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
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
    final c = AppColorScheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: LiquidGlassContainer(
            borderRadius: 20,
            blurSigma: 20,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildArtwork(),
                ),
                // subtle glow overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.18),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
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
      key: ValueKey(
        station == null ? url : '${station!.uuid}|$url',
      ),
      fit: BoxFit.cover,
      gaplessPlayback: false,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, __, ___) => const _FallbackArtwork(),
    );
  }
}

class _FallbackArtwork extends StatelessWidget {
  const _FallbackArtwork();

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            c.accent.withValues(alpha: 0.3),
            c.surfaceHighlight,
            const Color(0xFF1A1A2E),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.radio_rounded,
          size: 80,
          color: c.textTertiary,
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
    final c = AppColorScheme.of(context);
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildSubtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: c.textSecondary,
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
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                size: 28,
                color: isFavorite ? c.accent : c.textTertiary,
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
    final c = AppColorScheme.of(context);
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
                      color: c.accent,
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
                  color: c.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.circle, size: 6, color: c.accent),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: c.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.cast_rounded,
                size: 18,
                color: c.textTertiary,
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
    final rect =
        Rect.fromLTWH(center - shimmerWidth / 2, 0, shimmerWidth, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
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
    final c = AppColorScheme.of(context);
    final hasStation = controller.currentStation != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Shuffle (decorative for radio)
          Icon(
            Icons.shuffle_rounded,
            size: 22,
            color: c.textTertiary,
          ),

          const SizedBox(width: 24),

          // Previous station
          IconButton(
            tooltip: 'Previous station',
            onPressed: hasStation
                ? () => unawaited(controller.playPreviousStation())
                : null,
            iconSize: 36,
            icon: Icon(
              Icons.skip_previous_rounded,
              color: c.textPrimary,
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
            icon: Icon(
              Icons.skip_next_rounded,
              color: c.textPrimary,
            ),
          ),

          const SizedBox(width: 24),

          // Repeat (decorative for radio)
          Icon(
            Icons.repeat_rounded,
            size: 22,
            color: c.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _LargePlayButton extends StatelessWidget {
  const _LargePlayButton({
    required this.controller,
    this.size = 68,
  });

  final RadioController controller;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color:
                isDark ? Colors.white.withValues(alpha: 0.92) : c.textPrimary,
            shape: const CircleBorder(),
            elevation: 0,
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
                  size: size * 0.53,
                  color: isDark ? const Color(0xFF080C10) : c.background,
                ),
              ),
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
    final c = AppColorScheme.of(context);
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
                  color: c.textSecondary,
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
                  color: controller.hasSleepTimer ? c.accent : c.textTertiary,
                ),
                label: Text(
                  controller.hasSleepTimer
                      ? _formatRemaining(controller.sleepTimerRemaining!)
                      : 'Sleep Timer',
                  style: TextStyle(
                    color: controller.hasSleepTimer ? c.accent : c.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Share / queue placeholder
              IconButton(
                tooltip: 'Queue',
                onPressed: () {},
                icon: Icon(
                  Icons.queue_music_rounded,
                  size: 20,
                  color: c.textTertiary,
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

class _SleepTimerSheet extends StatefulWidget {
  const _SleepTimerSheet({required this.controller});

  final RadioController controller;

  static const _presets = <int>[5, 10, 15, 30, 45, 60, 90, 120];

  @override
  State<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<_SleepTimerSheet> {
  late final TextEditingController _customMinutesController;

  int? get _customMinutes {
    final value = int.tryParse(_customMinutesController.text.trim());
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _customMinutesController = TextEditingController();
    final total = widget.controller.sleepTimerTotal;
    if (total != null && !_SleepTimerSheet._presets.contains(total.inMinutes)) {
      _customMinutesController.text = total.inMinutes.toString();
    }
  }

  @override
  void dispose() {
    _customMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final customMinutes = _customMinutes;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.glassHighlight, c.glassBase, c.glassDeep],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: c.glassEdge, width: 0.8),
            ),
          ),
          child: SafeArea(
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
                      color: c.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Row(
                    children: <Widget>[
                      Icon(Icons.bedtime_outlined, size: 20, color: c.accent),
                      const SizedBox(width: 10),
                      Text(
                        'Sleep Timer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Preset grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _SleepTimerSheet._presets.map((minutes) {
                      final isActive = widget.controller.hasSleepTimer &&
                          widget.controller.sleepTimerTotal?.inMinutes ==
                              minutes;
                      return _TimerChip(
                        label: _chipLabel(minutes),
                        isActive: isActive,
                        onTap: () {
                          widget.controller.startSleepTimer(
                            Duration(minutes: minutes),
                          );
                          Navigator.of(context).pop();
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _customMinutesController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: c.surfaceHighlight,
                            hintText: 'Custom time',
                            hintStyle: TextStyle(color: c.textTertiary),
                            suffixText: 'min',
                            suffixStyle: TextStyle(color: c.textTertiary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: customMinutes == null
                            ? null
                            : () {
                                widget.controller.startSleepTimer(
                                  Duration(minutes: customMinutes),
                                );
                                Navigator.of(context).pop();
                              },
                        icon: const Icon(Icons.timer_rounded, size: 18),
                        label: const Text('Set'),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: c.background,
                          disabledBackgroundColor: c.surfaceHighlight,
                          disabledForegroundColor: c.textTertiary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Cancel button
                  if (widget.controller.hasSleepTimer) ...<Widget>[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          widget.controller.cancelSleepTimer();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.red,
                          side: BorderSide(color: c.red.withValues(alpha: 0.4)),
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
          ),
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
    final c = AppColorScheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          c.accent.withValues(alpha: 0.85),
                          c.accent.withValues(alpha: 0.65),
                        ],
                      )
                    : LinearGradient(
                        colors: [c.glassHighlight, c.glassBase],
                      ),
                border: Border.all(
                  color:
                      isActive ? c.accent.withValues(alpha: 0.50) : c.glassEdge,
                  width: 0.8,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : c.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
