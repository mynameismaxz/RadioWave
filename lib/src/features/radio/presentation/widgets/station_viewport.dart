import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../domain/station_view_state.dart';
import '../../state/radio_controller.dart';
import 'station_card.dart';

class StationViewport extends StatelessWidget {
  const StationViewport({
    required this.controller,
    required this.bottomInset,
    required this.horizontalInset,
    this.scrollController,
    this.selectedStationIndex = 0,
    super.key,
  });

  final RadioController controller;
  final double bottomInset;
  final double horizontalInset;
  final ScrollController? scrollController;
  final int selectedStationIndex;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    switch (controller.viewState) {
      case StationViewState.loading:
        return LoadingStationList(
          bottomInset: bottomInset,
          horizontalInset: horizontalInset,
        );
      case StationViewState.empty:
        return StateMessage(
          icon: Icons.radio_rounded,
          title: 'No stations found',
          message: controller.emptyMessage,
        );
      case StationViewState.error:
        return StateMessage(
          icon: Icons.wifi_off_rounded,
          title: controller.errorTitle,
          message: controller.errorDesc,
          action: FilledButton(
            onPressed: () => unawaited(controller.retry()),
            style: FilledButton.styleFrom(
              backgroundColor: c.textPrimary,
              foregroundColor: c.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      case StationViewState.list:
        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            horizontalInset,
            0,
            horizontalInset,
            bottomInset,
          ),
          itemCount: controller.stations.length,
          itemBuilder: (context, index) {
            return StationCard(
              station: controller.stations[index],
              controller: controller,
              selected: index == selectedStationIndex,
            );
          },
        );
    }
  }
}

class LoadingStationList extends StatelessWidget {
  const LoadingStationList({
    required this.bottomInset,
    required this.horizontalInset,
    super.key,
  });

  final double bottomInset;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        0,
        horizontalInset,
        bottomInset,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return const SkeletonCard();
      },
    );
  }
}

class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: c.surfaceHighlight,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final shimmerOpacity = 0.04 + (_controller.value * 0.05);
            return Row(
              children: <Widget>[
                // Artwork skeleton
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.textPrimary.withValues(alpha: shimmerOpacity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Title skeleton
                      Container(
                        height: 14,
                        width: 160,
                        decoration: BoxDecoration(
                          color:
                              c.textPrimary.withValues(alpha: shimmerOpacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle skeleton
                      Container(
                        height: 11,
                        width: 100,
                        decoration: BoxDecoration(
                          color: c.textPrimary
                              .withValues(alpha: shimmerOpacity * 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class StateMessage extends StatelessWidget {
  const StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 360;
        final edgePadding = EdgeInsets.fromLTRB(
          constraints.maxWidth < 720 ? 24 : 40,
          short ? 16 : 60,
          constraints.maxWidth < 720 ? 24 : 40,
          short ? 96 : 120,
        );

        return Center(
          child: SingleChildScrollView(
            padding: edgePadding,
            child: Container(
              padding: EdgeInsets.all(short ? 18 : 28),
              decoration: BoxDecoration(
                color: c.surfaceHighlight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    icon,
                    size: short ? 40 : 56,
                    color: c.textTertiary,
                  ),
                  SizedBox(height: short ? 12 : 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: short ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      color: c.textPrimary,
                    ),
                  ),
                  SizedBox(height: short ? 4 : 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.textTertiary,
                      fontSize: short ? 13 : 14,
                      height: short ? 1.35 : 1.5,
                    ),
                  ),
                  if (action != null) ...<Widget>[
                    SizedBox(height: short ? 14 : 24),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
