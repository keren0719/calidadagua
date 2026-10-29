import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/analysis_type.dart';
import 'agro_icon.dart';
import 'analysis_image.dart';

/// Tarjeta grande con foto de "Analizar planta" / "Analizar agua".
class AnalysisCard extends StatefulWidget {
  const AnalysisCard({super.key, required this.type, required this.onTap, this.height = 142});

  final AnalysisType type;
  final VoidCallback onTap;
  final double height;

  @override
  State<AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<AnalysisCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final isPlant = type == AnalysisType.plant;

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 180),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x21123F33), blurRadius: 28, offset: Offset(0, 12)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: Semantics(
              button: true,
              label: '${type.title}. ${type.description}',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnalysisImage(
                    type: type,
                    url: type.photoUrl,
                    fallbackIcon: false,
                    alignment: Alignment(0, isPlant ? -0.04 : 0.04),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPlant ? AppColors.plantOverlay : AppColors.waterOverlay,
                        stops: const [0, 0.56, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 18,
                    child: Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      alignment: Alignment.center,
                      child: AgroIcon(
                        isPlant ? AgroIcons.leaf : AgroIcons.droplet,
                        size: 23,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 76,
                    top: 19,
                    right: 60,
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.category.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            type.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.7,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.74),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 17,
                    bottom: 17,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const AgroIcon(AgroIcons.chevron, size: 20, color: Colors.white),
                    ),
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
