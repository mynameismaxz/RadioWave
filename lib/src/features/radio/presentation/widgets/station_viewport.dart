import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../domain/station_view_state.dart';
import '../../state/radio_controller.dart';
import 'station_card.dart';

class StationViewport extends StatelessWidget {
  const StationViewport({required this.controller, super.key});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomInset = width < 420
        ? 96.0 + safeBottom
        : width < 720
            ? 108.0 + safeBottom
            : 120.0 + safeBottom;
    final horizontalInset = width < 420
        ? 0.0
        : width < 720
            ? 4.0
            : 8.0;
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 60, 40, 120),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: c.surfaceHighlight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 56, color: c.textTertiary),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textTertiary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: 24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
