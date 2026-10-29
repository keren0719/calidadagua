import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'agro_icon.dart';

/// Logo "Agrovision · Inteligencia agrícola" del encabezado.
class AgroLogo extends StatelessWidget {
  const AgroLogo({super.key, this.large = false});

  /// Versión grande para login y splash.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final box = large ? 64.0 : 40.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AgroLogoMark(size: box),
        SizedBox(width: large ? 14 : 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Agrovision',
                style: TextStyle(
                  color: AppColors.forest,
                  fontSize: large ? 26 : 17,
                  height: large ? 1.1 : 1.18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: large ? -0.8 : -0.5,
                ),
              ),
              Text(
                'INTELIGENCIA AGRÍCOLA',
                style: TextStyle(
                  color: const Color(0xFF27A374),
                  fontSize: large ? 11 : 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: large ? 2.6 : 2.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AgroLogoMark extends StatelessWidget {
  const AgroLogoMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(size * 0.35),
        boxShadow: const [
          BoxShadow(color: Color(0x26022C22), blurRadius: 15, offset: Offset(0, 10)),
        ],
      ),
      alignment: Alignment.center,
      child: AgroIcon(AgroIcons.leaf, size: size / 2, color: Colors.white),
    );
  }
}

/// Píldora "AI" de la esquina superior derecha.
class AiPill extends StatelessWidget {
  const AiPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD1FAE5)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          color: Color(0xFF17805E),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Botón cuadrado redondeado (volver, cerrar, etc.).
class AgroIconButton extends StatelessWidget {
  const AgroIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final AgroIcons icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFDBE9E3)),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(child: AgroIcon(icon, color: AppColors.text)),
          ),
        ),
      ),
    );
  }
}

/// Encabezado de 72 px del diseño.
///
/// - Sin [onBack]: muestra el logo.
/// - Con [onBack]: botón volver + [title] centrado.
class AgroHeader extends StatelessWidget implements PreferredSizeWidget {
  const AgroHeader({super.key, this.title, this.onBack, this.trailing});

  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    if (onBack != null) ...[
                      AgroIconButton(
                        icon: AgroIcons.arrowLeft,
                        onPressed: onBack,
                        tooltip: 'Volver',
                      ),
                      const Spacer(),
                    ] else
                      const Expanded(
                        child: Align(alignment: Alignment.centerLeft, child: AgroLogo()),
                      ),
                    const SizedBox(width: 12),
                    trailing ?? const AiPill(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
