import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/station_view_state.dart';
import '../../state/radio_controller.dart';
import 'station_card.dart';

class StationViewport extends StatelessWidget {
  const StationViewport({required this.controller, super.key});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.viewState) {
      case StationViewState.loading:
        return const LoadingStationList();
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
              backgroundColor: AppColors.textPrimary,
              foregroundColor: AppColors.background,
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
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 120),
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
  const LoadingStationList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 120),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmerOpacity = 0.03 + (_controller.value * 0.05);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              // Artwork skeleton
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: shimmerOpacity),
                  borderRadius: BorderRadius.circular(6),
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
                        color: AppColors.textPrimary.withValues(alpha: shimmerOpacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle skeleton
                    Container(
                      height: 11,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: shimmerOpacity * 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 60, 40, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textTertiary,
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
    );
  }
}
