import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_color_scheme.dart';
import '../../../data/services/android_rotary_input.dart';
import 'radio_responsive_metrics.dart';
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
  final FocusNode _controllerFocusNode =
      FocusNode(debugLabel: 'RadioWave controller input');
  final ScrollController _stationScrollController = ScrollController();
  StreamSubscription<RotaryInputEvent>? _rotaryInputSub;
  int _selectedStationIndex = 0;
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = RadioController();
    AndroidRotaryInput.init();
    _rotaryInputSub = AndroidRotaryInput.events.listen(_handleRotaryInput);
    unawaited(controller.init());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllerFocusNode.requestFocus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(controller.stopPlayback());
    } else if (state == AppLifecycleState.resumed) {
      _controllerFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rotaryInputSub?.cancel();
    _controllerFocusNode.dispose();
    _stationScrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final c = AppColorScheme.of(context);

        return Focus(
          focusNode: _controllerFocusNode,
          autofocus: true,
          onKeyEvent: _handleControllerKey,
          child: Scaffold(
            backgroundColor: c.background,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final metrics = RadioResponsiveMetrics.fromConstraints(
                  constraints,
                  MediaQuery.paddingOf(context),
                );

                return _RadioHomeBody(
                  controller: controller,
                  stationScrollController: _stationScrollController,
                  metrics: metrics,
                  sidebarCollapsed: _sidebarCollapsed,
                  selectedStationIndex: _selectedStationIndex,
                  onToggleSidebar: _toggleSidebar,
                );
              },
            ),
          ),
        );
      },
    );
  }

  KeyEventResult _handleControllerKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (_isPreviousKey(key)) {
      _moveStationSelection(-1);
      return KeyEventResult.handled;
    }

    if (_isNextKey(key)) {
      _moveStationSelection(1);
      return KeyEventResult.handled;
    }

    if (_isLeftKey(key)) {
      _switchTab(-1);
      return KeyEventResult.handled;
    }

    if (_isRightKey(key)) {
      _switchTab(1);
      return KeyEventResult.handled;
    }

    if (_isSelectKey(key)) {
      _activateControllerSelection();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyM) {
      _toggleSidebar();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.mediaPlayPause) {
      unawaited(controller.togglePlayPause());
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.mediaStop) {
      unawaited(controller.stopPlayback());
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.mediaTrackNext) {
      unawaited(controller.playNextStation());
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.mediaTrackPrevious) {
      unawaited(controller.playPreviousStation());
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleRotaryInput(RotaryInputEvent event) {
    switch (event.type) {
      case RotaryInputEventType.rotate:
        _moveStationSelection(event.delta);
        break;
      case RotaryInputEventType.key:
        _handleRotaryKey(event.key);
        break;
    }
  }

  void _handleRotaryKey(String key) {
    switch (key) {
      case 'up':
        _moveStationSelection(-1);
        break;
      case 'down':
        _moveStationSelection(1);
        break;
      case 'left':
        _switchTab(-1);
        break;
      case 'right':
        _switchTab(1);
        break;
      case 'select':
        _activateControllerSelection();
        break;
      case 'playPause':
        unawaited(controller.togglePlayPause());
        break;
      case 'stop':
        unawaited(controller.stopPlayback());
        break;
      case 'next':
        unawaited(controller.playNextStation());
        break;
      case 'previous':
        unawaited(controller.playPreviousStation());
        break;
    }
  }

  bool _isPreviousKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp;
  }

  bool _isNextKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowDown;
  }

  bool _isLeftKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowLeft;
  }

  bool _isRightKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowRight;
  }

  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  void _moveStationSelection(int delta) {
    if (controller.stations.isEmpty) {
      return;
    }

    setState(() {
      final nextIndex = _selectedStationIndex + delta;
      _selectedStationIndex = nextIndex.clamp(
        0,
        controller.stations.length - 1,
      );
    });
    _scrollSelectedStationIntoView();
  }

  void _switchTab(int delta) {
    const tabs = RadioTab.values;
    final currentIndex = tabs.indexOf(controller.currentTab);
    final nextIndex = (currentIndex + delta) % tabs.length;
    final normalizedIndex = nextIndex < 0 ? tabs.length - 1 : nextIndex;
    setState(() {
      _selectedStationIndex = 0;
    });
    unawaited(controller.switchTab(tabs[normalizedIndex]));
    _scrollSelectedStationIntoView();
  }

  void _activateControllerSelection() {
    if (controller.stations.isNotEmpty) {
      final selectedIndex = _selectedStationIndex.clamp(
        0,
        controller.stations.length - 1,
      );
      unawaited(controller.playStation(controller.stations[selectedIndex]));
      return;
    }

    if (controller.currentStation != null) {
      unawaited(controller.togglePlayPause());
    }
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
    _controllerFocusNode.requestFocus();
  }

  void _scrollSelectedStationIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_stationScrollController.hasClients || controller.stations.isEmpty) {
        return;
      }

      final targetOffset = (_selectedStationIndex * 84.0).clamp(
        0.0,
        _stationScrollController.position.maxScrollExtent,
      );
      unawaited(
        _stationScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }
}

class _RadioHomeBody extends StatelessWidget {
  const _RadioHomeBody({
    required this.controller,
    required this.stationScrollController,
    required this.metrics,
    required this.sidebarCollapsed,
    required this.selectedStationIndex,
    required this.onToggleSidebar,
  });

  final RadioController controller;
  final ScrollController stationScrollController;
  final RadioResponsiveMetrics metrics;
  final bool sidebarCollapsed;
  final int selectedStationIndex;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: metrics.wide
              ? _WideHomeLayout(
                  controller: controller,
                  stationScrollController: stationScrollController,
                  metrics: metrics,
                  sidebarCollapsed: sidebarCollapsed,
                  selectedStationIndex: selectedStationIndex,
                  onToggleSidebar: onToggleSidebar,
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _MainColumn(
                      controller: controller,
                      stationScrollController: stationScrollController,
                      metrics: metrics,
                      showTabNav: true,
                      selectedStationIndex: selectedStationIndex,
                    ),
                  ),
                ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PlayerBar(
            controller: controller,
            height: metrics.playerHeight,
            short: metrics.short,
          ),
        ),
        ToastOverlay(toasts: controller.toasts),
      ],
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({
    required this.controller,
    required this.stationScrollController,
    required this.metrics,
    required this.showTabNav,
    required this.selectedStationIndex,
  });

  final RadioController controller;
  final ScrollController stationScrollController;
  final RadioResponsiveMetrics metrics;
  final bool showTabNav;
  final int selectedStationIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppHeader(
          controller: controller,
          metrics: metrics,
          wide: !showTabNav,
        ),
        if (controller.currentTab == RadioTab.discover)
          CountryFilter(controller: controller, dense: metrics.short),
        if (showTabNav) TabNav(controller: controller),
        if (controller.currentTab == RadioTab.add)
          AddStationPanel(
            controller: controller,
            dense: metrics.short,
          ),
        Expanded(
          child: controller.currentTab == RadioTab.equalizer
              ? EqualizerPanel(
                  controller: controller,
                  bottomInset: metrics.playerBottomInset,
                  dense: metrics.short,
                )
              : StationViewport(
                  controller: controller,
                  scrollController: stationScrollController,
                  selectedStationIndex: selectedStationIndex,
                  bottomInset: metrics.playerBottomInset,
                  horizontalInset: metrics.listHorizontalInset,
                ),
        ),
      ],
    );
  }
}

class _WideHomeLayout extends StatelessWidget {
  const _WideHomeLayout({
    required this.controller,
    required this.stationScrollController,
    required this.metrics,
    required this.sidebarCollapsed,
    required this.selectedStationIndex,
    required this.onToggleSidebar,
  });

  final RadioController controller;
  final ScrollController stationScrollController;
  final RadioResponsiveMetrics metrics;
  final bool sidebarCollapsed;
  final int selectedStationIndex;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = sidebarCollapsed
        ? 88.0
        : metrics.size.width < 900
            ? 188.0
            : 240.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SidebarNav(
          controller: controller,
          collapsed: sidebarCollapsed,
          onToggleCollapsed: onToggleSidebar,
          width: sidebarWidth,
          dense: metrics.short,
        ),
        Expanded(
          child: _MainColumn(
            controller: controller,
            stationScrollController: stationScrollController,
            metrics: metrics,
            showTabNav: false,
            selectedStationIndex: selectedStationIndex,
          ),
        ),
      ],
    );
  }
}
