import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'agro_icon.dart';

/// Texto pequeño en mayúsculas verde ("PASO 1 DE 2", "TU ACTIVIDAD").
class SectionKicker extends StatelessWidget {
  const SectionKicker(this.text, {super.key, this.color = AppColors.green});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(), style: AppText.kicker.copyWith(color: color)),
  );
}

/// Kicker + título + subtítulo de cada pantalla.
class ScreenHeading extends StatelessWidget {
  const ScreenHeading({super.key, this.kicker, required this.title, this.subtitle});

  final String? kicker;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kicker != null) SectionKicker(kicker!),
        Text(title, style: AppText.screenTitle),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: AppText.screenSubtitle),
        ],
      ],
    );
  }
}

/// Cuadro redondeado con un ícono (`.section-icon`, `.scan-mark`, etc.).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 37,
    this.iconSize = 18,
    this.radius = 12,
    this.background = AppColors.mint,
    this.foreground = const Color(0xFF208966),
  });

  const IconTile.blue({
    super.key,
    required this.icon,
    this.size = 37,
    this.iconSize = 18,
    this.radius = 12,
  }) : background = AppColors.blueSurface,
       foreground = AppColors.blue;

  final AgroIcons icon;
  final double size;
  final double iconSize;
  final double radius;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: AgroIcon(icon, size: iconSize, color: foreground),
    );
  }
}

/// Tarjeta blanca con borde suave.
class AgroCard extends StatelessWidget {
  const AgroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(17),
    this.color = Colors.white,
    this.borderColor = AppColors.border,
    this.radius = 21,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Caja de error rosada del diseño (`.error-box`).
class ErrorBox extends StatelessWidget {
  const ErrorBox({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.errorSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.errorBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: AppColors.errorStrong, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text(
                '!',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.errorText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(color: AppColors.errorText, fontSize: 11, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nota de confianza con escudo (`.trust-note`) y variantes informativas.
class InfoNote extends StatelessWidget {
  const InfoNote({
    super.key,
    required this.icon,
    required this.boldText,
    required this.text,
    this.iconColor = const Color(0xFF17805E),
    this.background = const Color(0xCCFFFFFF),
    this.borderColor = const Color(0xFFDCECE5),
    this.trailing,
  });

  final AgroIcons icon;
  final String boldText;
  final String text;
  final Color iconColor;
  final Color background;
  final Color borderColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgroIcon(icon, size: 20, color: iconColor),
          const SizedBox(width: 11),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: Color(0xFF688078), fontSize: 11, height: 1.5),
                children: [
                  TextSpan(
                    text: '$boldText ',
                    style: const TextStyle(color: Color(0xFF31584D), fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Estado vacío con ícono grande (`.empty-history`).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final AgroIcons icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTile(
          icon: icon,
          size: 74,
          iconSize: 32,
          radius: 24,
          background: const Color(0xFFE2F4EC),
          foreground: const Color(0xFF258B69),
        ),
        const SizedBox(height: 19),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF778A84), fontSize: 12, height: 1.55),
          ),
        ),
        if (action != null) ...[const SizedBox(height: 22), action!],
      ],
    );
  }
}

/// Muestra un SnackBar con el estilo de la app.
void showAgroSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
