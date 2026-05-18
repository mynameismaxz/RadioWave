import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';

class Logo extends StatelessWidget {
  const Logo({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    if (compact) {
      return Text(
        'RadioWave',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: c.textPrimary,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.radio_rounded, color: c.textPrimary, size: 28),
        const SizedBox(width: 8),
        Text(
          'RadioWave',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}
