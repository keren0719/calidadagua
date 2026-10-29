import 'package:flutter/material.dart';

import '../core/routes/app_routes.dart';
import '../widgets/agro_bottom_nav.dart';
import '../widgets/agro_header.dart';
import '../widgets/agro_icon.dart';
import 'historial.dart';
import 'pantalla_inicio.dart';
import 'perfil.dart';

/// Contenedor con la barra inferior: Inicio · Historial · Perfil.
class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _index = 0;

  static const _items = [
    AgroNavItem(AgroIcons.home, 'Inicio'),
    AgroNavItem(AgroIcons.clock, 'Historial'),
    AgroNavItem(AgroIcons.user, 'Perfil'),
  ];

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // En Historial/Perfil, "atrás" vuelve a Inicio en vez de cerrar la app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        appBar: AgroHeader(
          trailing: _index == 2
              ? AgroIconButton(
                  icon: AgroIcons.settings,
                  tooltip: 'Configuración',
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                )
              : null,
        ),
        body: IndexedStack(
          index: _index,
          children: [
            PantallaInicio(onOpenHistory: () => _goTo(1)),
            HistorialScreen(onStartAnalysis: () => _goTo(0)),
            const PerfilScreen(),
          ],
        ),
        bottomNavigationBar: AgroBottomNav(items: _items, currentIndex: _index, onTap: _goTo),
      ),
    );
  }
}
