import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/interpreters/diagnosis_catalog.dart';
import '../data/models/analysis_result.dart';
import '../data/models/api_responses.dart';
import 'agro_icon.dart';

/// Colores e íconos según el estado del resultado.
class StatusStyle {
  const StatusStyle({
    required this.label,
    required this.icon,
    required this.strong,
    required this.surface,
    required this.text,
    required this.border,
    required this.heroAccent,
  });

  factory StatusStyle.of(ResultStatus status) => switch (status) {
    ResultStatus.good => const StatusStyle(
      label: 'Sin riesgos',
      icon: AgroIcons.check,
      strong: Color(0xFF28A877),
      surface: AppColors.mintSurface,
      text: Color(0xFF166D51),
      border: AppColors.borderMint,
      heroAccent: Color(0xFF9DE4C7),
    ),
    ResultStatus.warning => const StatusStyle(
      label: 'Requiere atención',
      icon: AgroIcons.alert,
      strong: AppColors.warningStrong,
      surface: AppColors.warningSurface,
      text: AppColors.warningText,
      border: AppColors.warningBorder,
      heroAccent: Color(0xFFFFD98A),
    ),
    ResultStatus.danger => const StatusStyle(
      label: 'Riesgo alto',
      icon: AgroIcons.alert,
      strong: AppColors.errorStrong,
      surface: AppColors.errorSurface,
      text: AppColors.errorText,
      border: AppColors.errorBorder,
      heroAccent: Color(0xFFFFB4A8),
    ),
  };

  final String label;
  final AgroIcons icon;
  final Color strong;
  final Color surface;
  final Color text;
  final Color border;
  final Color heroAccent;
}

/// Anillo con el porcentaje de confianza (`.confidence-ring`).
class ConfidenceRing extends StatelessWidget {
  const ConfidenceRing({
    super.key,
    required this.value,
    this.size = 51,
    this.color = AppColors.progressStart,
  });

  /// Entre 0 y 1.
  final double value;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Confianza ${(value * 100).round()} por ciento',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(v, color),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Text(
                '${(v * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF185B47),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color);

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    canvas.drawArc(
      ring,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = const Color(0xFFE0EEE8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}

/// Dibuja las cajas de YOLO sobre la imagen, respetando `BoxFit.cover`.
class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  final List<Detection> detections;
  final int imageWidth;
  final int imageHeight;

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty || imageWidth <= 0 || imageHeight <= 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _DetectionPainter(detections, imageWidth.toDouble(), imageHeight.toDouble()),
        size: Size.infinite,
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  _DetectionPainter(this.detections, this.imageW, this.imageH);

  final List<Detection> detections;
  final double imageW;
  final double imageH;

  @override
  void paint(Canvas canvas, Size size) {
    // Misma transformación que BoxFit.cover centrado.
    final scale = math.max(size.width / imageW, size.height / imageH);
    final dx = (size.width - imageW * scale) / 2;
    final dy = (size.height - imageH * scale) / 2;

    for (final d in detections) {
      final info = DiagnosisCatalog.plant[DiagnosisCatalog.normalize(d.className)];
      final color = StatusStyle.of(info?.status ?? ResultStatus.warning).strong;
      final rect = Rect.fromLTRB(
        d.bbox.x1 * scale + dx,
        d.bbox.y1 * scale + dy,
        d.bbox.x2 * scale + dx,
        d.bbox.y2 * scale + dy,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );

      final label = TextPainter(
        text: TextSpan(
          text:
              ' ${info?.title ?? DiagnosisCatalog.prettify(d.className)} '
              '${(d.confidence * 100).round()}% ',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            fontFamily: 'Manrope',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max(rect.width, 60));
      // Etiqueta dentro de la caja, en la esquina superior izquierda.
      final bg = Rect.fromLTWH(rect.left + 4, rect.top + 4, label.width + 4, label.height + 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bg, const Radius.circular(6)),
        Paint()..color = color,
      );
      label.paint(canvas, Offset(bg.left + 2, bg.top + 1));
    }
  }

  @override
  bool shouldRepaint(_DetectionPainter old) => old.detections != detections;
}
