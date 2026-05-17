import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_color_scheme.dart';
import '../domain/radio_tab.dart';
import '../state/radio_controller.dart';
import 'widgets/add_station_panel.dart';
import 'widgets/app_header.dart';
import 'widgets/country_filter.dart';
import 'widgets/player_bar.dart';
import 'widgets/station_viewport.dart';
import 'widgets/tab_nav.dart';
import 'widgets/toast_overlay.dart';

class RadioWaveHome extends StatefulWidget {
  const RadioWaveHome({super.key});

  @override
  State<RadioWaveHome> createState() => _RadioWaveHomeState();
}

class _RadioWaveHomeState extends State<RadioWaveHome>
    with WidgetsBindingObserver {
  late final RadioController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = RadioController();
    unawaited(controller.init());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(controller.stopPlayback());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: <Widget>[
              // ── Clean solid background ──
              const Positioned.fill(child: RadioBackground()),

              // ── Main content ──
              SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: <Widget>[
                        AppHeader(controller: controller),
                        if (controller.currentTab == RadioTab.discover)
                          CountryFilter(controller: controller),
                        TabNav(controller: controller),
                        if (controller.currentTab == RadioTab.add)
                          AddStationPanel(controller: controller),
                        Expanded(child: StationViewport(controller: controller)),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Now playing bar ──
              Align(
                alignment: Alignment.bottomCenter,
                child: PlayerBar(controller: controller),
              ),

              // ── Toast notifications ──
              ToastOverlay(toasts: controller.toasts),
            ],
          ),
        );
      },
    );
  }
}

/// Minimal background — subtle gradient that adapts to theme.
class RadioBackground extends StatelessWidget {
  const RadioBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const <double>[0.0, 0.35, 1.0],
          colors: <Color>[
            isDark ? const Color(0xFF0F1210) : const Color(0xFFE8EBE9),
            c.background,
            c.background,
          ],
        ),
      ),
    );
  }
}
