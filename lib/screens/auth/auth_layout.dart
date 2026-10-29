import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/agro_header.dart';
import '../../widgets/agro_icon.dart';

/// Fondo con los degradados suaves del diseño (`.app-background`).
class AgroBackground extends StatelessWidget {
  const AgroBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.7, -0.75),
                  radius: 0.9,
                  colors: [Color(0x293DB885), Color(0x003DB885)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.8, 0.7),
                  radius: 0.9,
                  colors: [Color(0x1F3897CB), Color(0x003897CB)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Estructura común de Login, Registro y Recuperar contraseña.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.children, this.onBack});

  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AgroBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                children: [
                  SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: onBack == null
                          ? null
                          : AgroIconButton(
                              icon: AgroIcons.arrowLeft,
                              onPressed: onBack,
                              tooltip: 'Volver',
                            ),
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
