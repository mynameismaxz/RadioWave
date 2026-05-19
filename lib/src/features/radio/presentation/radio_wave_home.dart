import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_color_scheme.dart';
import '../domain/radio_tab.dart';
import '../state/radio_controller.dart';
import 'widgets/add_station_panel.dart';
import 'widgets/app_header.dart';
import 'widgets/country_filter.dart';
import 'widgets/equalizer_panel.dart';
import 'widgets/player_bar.dart';
import 'widgets/sidebar_nav.dart';
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
        final c = AppColorScheme.of(context);

        return Scaffold(
          backgroundColor: c.background,
          body: Stack(
            children: <Widget>[
              SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1024;

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SidebarNav(controller: controller),
                          Expanded(
                            child: _MainColumn(
                              controller: controller,
                              showTabNav: false,
                            ),
                          ),
                        ],
                      );
                    }

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _MainColumn(
                          controller: controller,
                          showTabNav: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PlayerBar(controller: controller),
              ),
              ToastOverlay(toasts: controller.toasts),
            ],
          ),
        );
      },
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({
    required this.controller,
    required this.showTabNav,
  });

  final RadioController controller;
  final bool showTabNav;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppHeader(controller: controller, wide: !showTabNav),
        if (controller.currentTab == RadioTab.discover)
          CountryFilter(controller: controller),
        if (showTabNav) TabNav(controller: controller),
        if (controller.currentTab == RadioTab.add)
          AddStationPanel(controller: controller),
        Expanded(
          child: controller.currentTab == RadioTab.equalizer
              ? EqualizerPanel(controller: controller)
              : StationViewport(controller: controller),
        ),
      ],
    );
  }
}
