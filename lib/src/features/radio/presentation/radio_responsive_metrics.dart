import 'package:flutter/widgets.dart';

class RadioResponsiveMetrics {
  const RadioResponsiveMetrics({
    required this.size,
    required this.safeBottom,
    required this.landscape,
    required this.wide,
    required this.short,
    required this.tiny,
    required this.playerHeight,
    required this.playerBottomInset,
    required this.pageHorizontalPadding,
    required this.headerTopPadding,
    required this.headerBottomPadding,
    required this.listHorizontalInset,
  });

  factory RadioResponsiveMetrics.fromConstraints(
    BoxConstraints constraints,
    EdgeInsets padding,
  ) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    final landscape = size.width > size.height;
    final wide = size.width >= 1024 || (landscape && size.width >= 720);
    final short = size.height < 560;
    final tiny = size.width < 420 || size.height < 430;
    final playerHeight = tiny
        ? 68.0
        : short
            ? 74.0
            : size.width < 720
                ? 80.0
                : 88.0;
    final pageHorizontalPadding = size.width < 420
        ? 10.0
        : size.width < 720
            ? 16.0
            : 24.0;

    return RadioResponsiveMetrics(
      size: size,
      safeBottom: padding.bottom,
      landscape: landscape,
      wide: wide,
      short: short,
      tiny: tiny,
      playerHeight: playerHeight,
      playerBottomInset: playerHeight + padding.bottom + (short ? 18.0 : 28.0),
      pageHorizontalPadding: pageHorizontalPadding,
      headerTopPadding: short ? 10.0 : 20.0,
      headerBottomPadding: short ? 8.0 : 16.0,
      listHorizontalInset: size.width < 420
          ? 0.0
          : size.width < 720
              ? 4.0
              : 8.0,
    );
  }

  final Size size;
  final double safeBottom;
  final bool landscape;
  final bool wide;
  final bool short;
  final bool tiny;
  final double playerHeight;
  final double playerBottomInset;
  final double pageHorizontalPadding;
  final double headerTopPadding;
  final double headerBottomPadding;
  final double listHorizontalInset;
}
