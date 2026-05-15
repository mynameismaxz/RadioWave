import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.radio_rounded,
            color: c.background,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'RadioWave',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}
