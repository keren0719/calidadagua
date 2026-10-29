import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/analysis_type.dart';
import 'agro_icon.dart';

/// Muestra la imagen de un análisis desde memoria, archivo local o URL,
/// con un fondo de respaldo del color del tipo si no hay imagen o falla.
class AnalysisImage extends StatelessWidget {
  const AnalysisImage({
    super.key,
    required this.type,
    this.bytes,
    this.path,
    this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.fallbackIcon = true,
  });

  final AnalysisType type;
  final Uint8List? bytes;
  final String? path;
  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final String? semanticLabel;

  /// Muestra el ícono del tipo sobre el fondo de respaldo.
  final bool fallbackIcon;

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext _, Object _, StackTrace? _) =>
        _Fallback(type: type, showIcon: fallbackIcon);

    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        semanticLabel: semanticLabel,
        errorBuilder: fallback,
      );
    }
    if (path != null && !kIsWeb && File(path!).existsSync()) {
      return Image.file(
        File(path!),
        fit: fit,
        alignment: alignment,
        semanticLabel: semanticLabel,
        errorBuilder: fallback,
      );
    }
    final networkUrl = url ?? (path == null ? null : type.photoUrl);
    if (networkUrl != null) {
      return Image.network(
        networkUrl,
        fit: fit,
        alignment: alignment,
        semanticLabel: semanticLabel,
        errorBuilder: fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _Fallback(type: type, showIcon: false),
      );
    }
    return _Fallback(type: type, showIcon: fallbackIcon);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.type, this.showIcon = true});

  final AnalysisType type;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final isPlant = type == AnalysisType.plant;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPlant
              ? const [Color(0xFF3E8C66), AppColors.plantFallback, Color(0xFF1C4F3D)]
              : const [Color(0xFF3A8DB0), AppColors.waterFallback, Color(0xFF184E68)],
        ),
      ),
      child: showIcon
          ? Center(
              child: AgroIcon(
                isPlant ? AgroIcons.leaf : AgroIcons.droplet,
                size: 36,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
