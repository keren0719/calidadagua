import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/image_source_picker.dart';
import '../data/models/analysis_type.dart';
import '../widgets/agro_header.dart';
import '../widgets/agro_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/tips_card.dart';

/// Paso 1 de 2: elegir la imagen desde la cámara o la galería.
class CapturaImagenScreen extends StatefulWidget {
  const CapturaImagenScreen({super.key, required this.type, this.picker});

  final AnalysisType type;

  /// Inyectable para pruebas.
  final ImageSourcePicker? picker;

  @override
  State<CapturaImagenScreen> createState() => _CapturaImagenScreenState();
}

class _CapturaImagenScreenState extends State<CapturaImagenScreen> {
  late final ImageSourcePicker _picker = widget.picker ?? ImageSourcePicker();
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = await _picker.pick(source);
      if (image == null || !mounted) return;
      await Navigator.of(context)
          .pushNamed(AppRoutes.validation, arguments: AnalysisArgs(widget.type, image));
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AgroHeader(title: widget.type.title, onBack: () => Navigator.of(context).pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          ScreenHeading(
            kicker: 'Paso 1 de 2',
            title: 'Añade una imagen',
            subtitle: 'Fotografía ${widget.type.captureHint} con buena luz.',
          ),
          const SizedBox(height: 20),
          const _EmptyFrame(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBox(title: 'No pudimos usar esta imagen', message: _error!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SourceButton(
                  icon: AgroIcons.camera,
                  label: 'Tomar foto',
                  primary: true,
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SourceButton(
                  icon: AgroIcons.gallery,
                  label: 'Galería',
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const TipsCard(),
        ],
      ),
    );
  }
}

/// Marco punteado "Encuadra el área a analizar" (`.empty-frame`).
class _EmptyFrame extends StatelessWidget {
  const _EmptyFrame();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 285,
          color: const Color(0xEBF5FBF8),
          child: CustomPaint(
            painter: _StripesPainter(),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTile(
                    icon: AgroIcons.scan,
                    size: 72,
                    iconSize: 36,
                    radius: 24,
                    foreground: AppColors.greenStrong,
                  ),
                  SizedBox(height: 17),
                  Text(
                    'Encuadra el área a analizar',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'JPG o PNG · mínimo ${AppConfig.minImageSide} × ${AppConfig.minImageSide} px',
                    style: TextStyle(color: AppColors.mutedLight, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius((Offset.zero & size).deflate(0.75), const Radius.circular(26)),
      );
    final paint = Paint()
      ..color = AppColors.borderDashed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x40E4F2EC)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
