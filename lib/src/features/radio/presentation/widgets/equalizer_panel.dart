import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../state/radio_controller.dart';

class EqualizerPanel extends StatelessWidget {
  const EqualizerPanel({
    required this.controller,
    required this.bottomInset,
    this.dense = false,
    super.key,
  });

  final RadioController controller;
  final double bottomInset;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset),
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(22, dense ? 14 : 20, 22, 20),
          decoration: BoxDecoration(
            color: c.surfaceHighlight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _EqualizerHeader(controller: controller),
                  SizedBox(height: dense ? 12 : 20),
                  _PresetPicker(controller: controller, compact: compact),
                  SizedBox(height: dense ? 14 : 24),
                  _BandEditor(
                    controller: controller,
                    compact: compact,
                    dense: dense,
                  ),
                  SizedBox(height: dense ? 12 : 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => unawaited(controller.resetEqualizer()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textPrimary,
                        side: BorderSide(color: c.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 11,
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EqualizerHeader extends StatelessWidget {
  const _EqualizerHeader({required this.controller});

  final RadioController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Equalizer',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Switch(
          value: controller.equalizerEnabled,
          activeThumbColor: c.green,
          onChanged: (value) =>
              unawaited(controller.setEqualizerEnabled(value)),
        ),
      ],
    );
  }
}

class _PresetPicker extends StatelessWidget {
  const _PresetPicker({
    required this.controller,
    required this.compact,
  });

  final RadioController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final picker = PopupMenuButton<String>(
      tooltip: 'Choose preset',
      color: c.surfaceElevated,
      initialValue: controller.equalizerPreset == 'Custom'
          ? null
          : controller.equalizerPreset,
      onSelected: (preset) => unawaited(controller.setEqualizerPreset(preset)),
      itemBuilder: (context) {
        return RadioController.equalizerPresets.keys.map((preset) {
          return PopupMenuItem<String>(
            value: preset,
            child: Text(preset),
          );
        }).toList();
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              controller.equalizerPreset,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 28),
            Icon(Icons.keyboard_arrow_down_rounded, color: c.textSecondary),
          ],
        ),
      ),
    );

    final label = Text(
      'Presets',
      style: TextStyle(
        color: c.textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          label,
          const SizedBox(height: 10),
          picker,
        ],
      );
    }

    return Row(
      children: <Widget>[
        label,
        const SizedBox(width: 26),
        picker,
      ],
    );
  }
}

class _BandEditor extends StatelessWidget {
  const _BandEditor({
    required this.controller,
    required this.compact,
    required this.dense,
  });

  final RadioController controller;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final minWidth = compact ? 580.0 : 0.0;
    final graph = Container(
      constraints: BoxConstraints(minWidth: minWidth),
      height: dense
          ? 220
          : compact
              ? 300
              : 292,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(
            width: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DbLabel('+12dB'),
                _DbLabel('0dB', subdued: true),
                _DbLabel('-12dB'),
                SizedBox(height: 28),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  bottom: 40,
                  child: CustomPaint(
                    painter: _EqualizerCurvePainter(
                      gains: controller.equalizerGains,
                      lineColor: c.green,
                      gridColor: c.textPrimary.withValues(alpha: 0.11),
                    ),
                  ),
                ),
                Row(
                  children: List<Widget>.generate(
                    RadioController.equalizerBands.length,
                    (index) => Expanded(
                      child: _BandSlider(
                        label: RadioController.equalizerBands[index],
                        value: controller.equalizerGains[index],
                        onChanged: (value) => unawaited(
                          controller.setEqualizerBand(index, value),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!compact) {
      return graph;
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: minWidth + 68, child: graph),
      ),
    );
  }
}

class _DbLabel extends StatelessWidget {
  const _DbLabel(this.text, {this.subdued = false});

  final String text;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Text(
      text,
      style: TextStyle(
        color: subdued ? c.textDisabled : c.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  const _BandSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);

    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: SizedBox(
                width: 210,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: c.green,
                    inactiveTrackColor: c.textPrimary.withValues(alpha: 0.12),
                    thumbColor: c.textPrimary,
                    overlayColor: c.green.withValues(alpha: 0.14),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    min: -12,
                    max: 12,
                    divisions: 48,
                    value: value.clamp(-12.0, 12.0),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EqualizerCurvePainter extends CustomPainter {
  const _EqualizerCurvePainter({
    required this.gains,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double> gains;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (gains.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= 2; i += 1) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < gains.length; i += 1) {
      final x = gains.length == 1
          ? size.width / 2
          : size.width * i / (gains.length - 1);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final points = <Offset>[
      for (var i = 0; i < gains.length; i += 1)
        Offset(
          gains.length == 1
              ? size.width / 2
              : size.width * i / (gains.length - 1),
          size.height - ((gains[i].clamp(-12.0, 12.0) + 12) / 24 * size.height),
        ),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i += 1) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      path.cubicTo(
          controlX, previous.dy, controlX, current.dy, current.dx, current.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          lineColor.withValues(alpha: 0.48),
          lineColor.withValues(alpha: 0.06),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _EqualizerCurvePainter oldDelegate) {
    return oldDelegate.gains != gains ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
