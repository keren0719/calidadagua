import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/models/analysis_result.dart';
import '../../data/models/analysis_type.dart';
import '../../screens/auth/inicio_sesion.dart';
import '../../screens/auth/recuperar_contrasena.dart';
import '../../screens/auth/registro.dart';
import '../../screens/captura_imagen.dart';
import '../../screens/configuracion.dart';
import '../../screens/navegacion_principal.dart';
import '../../screens/procesando_analisis.dart';
import '../../screens/resultados_analisis.dart';
import '../../screens/splash.dart';
import '../../screens/validacion_imagen.dart';
import '../utils/image_validator.dart';

/// Argumentos de las pantallas del flujo de análisis.
class AnalysisArgs {
  const AnalysisArgs(this.type, this.image);

  final AnalysisType type;
  final ValidatedImage image;
}

class ResultArgs {
  const ResultArgs(this.result, {this.imageBytes, this.fromHistory = false});

  final AnalysisResult result;
  final Uint8List? imageBytes;
  final bool fromHistory;
}

/// Rutas de la app. Navegar: `Navigator.pushNamed(context, AppRoutes.capture, arguments: ...)`.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/registro';
  static const recoverPassword = '/recuperar-contrasena';
  static const main = '/inicio';
  static const capture = '/captura';
  static const validation = '/validacion';
  static const processing = '/procesando';
  static const result = '/resultado';
  static const settings = '/configuracion';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget page = switch (settings.name) {
      splash => const SplashScreen(),
      login => const InicioSesionScreen(),
      register => const RegistroScreen(),
      recoverPassword => const RecuperarContrasenaScreen(),
      main => const NavegacionPrincipal(),
      capture => CapturaImagenScreen(type: args as AnalysisType),
      validation => ValidacionImagenScreen(args: args as AnalysisArgs),
      processing => ProcesandoAnalisisScreen(args: args as AnalysisArgs),
      result => ResultadosAnalisisScreen(args: args as ResultArgs),
      AppRoutes.settings => const ConfiguracionScreen(),
      _ => const SplashScreen(),
    };

    if (settings.name == processing || settings.name == result || settings.name == main) {
      return PageRouteBuilder(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      );
    }
    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }

  /// Vuelve a la pantalla principal (con la barra inferior).
  static void backToMain(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.settings.name == main || route.isFirst);
  }
}
