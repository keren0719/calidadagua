import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'agro_icon.dart';

/// Botón principal verde oscuro del diseño (`.main-button`).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AgroIcons? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: onPressed == null ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x33123F33), blurRadius: 22, offset: Offset(0, 10)),
          ],
        ),
        child: Material(
          color: AppColors.forest,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 55),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: loading
                      ? const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          ),
                        ]
                      : [
                          Flexible(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (icon != null) ...[
                            const SizedBox(width: 9),
                            AgroIcon(icon!, size: 20, color: Colors.white),
                          ],
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: button,
    );
  }
}

/// Botón blanco con borde (acciones secundarias).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AgroIcons? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.errorText : AppColors.textSoft;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: destructive ? AppColors.errorBorder : AppColors.borderInput),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                AgroIcon(icon!, size: 19, color: color),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botones "Tomar foto" / "Galería" de la pantalla de captura.
class SourceButton extends StatelessWidget {
  const SourceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final AgroIcons icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : AppColors.textSoft;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(color: Color(0x0D204B3D), blurRadius: 18, offset: Offset(0, 7)),
        ],
      ),
      child: Material(
        color: primary ? AppColors.forest : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: BorderSide(color: primary ? AppColors.forestBorder : AppColors.borderInput),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
          child: SizedBox(
            height: 94,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AgroIcon(icon, color: fg),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
