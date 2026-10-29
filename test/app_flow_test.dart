import 'package:agrovision_ai/core/config/app_config.dart';
import 'package:agrovision_ai/core/routes/app_routes.dart';
import 'package:agrovision_ai/core/utils/image_validator.dart';
import 'package:agrovision_ai/data/models/analysis_type.dart';
import 'package:agrovision_ai/screens/auth/registro.dart';
import 'package:agrovision_ai/screens/procesando_analisis.dart';
import 'package:agrovision_ai/state/app_services.dart';
import 'package:agrovision_ai/state/auth_controller.dart';
import 'package:agrovision_ai/state/history_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';

/// Avanza el tiempo sin esperar a que terminen animaciones infinitas.
Future<void> settle(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('login demo → inicio → historial → perfil → cerrar sesión', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final services = await makeServices();
    await tester.pumpWidget(makeApp(services));
    await settle(tester, 15);

    // Login
    expect(find.text('Inicia sesión'), findsOneWidget);
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);

    await tester.tap(find.text('Usar'));
    await tester.pump();
    await tester.tap(find.text('Iniciar sesión'));
    await settle(tester);

    // Inicio
    expect(find.text('Analizar planta'), findsOneWidget);
    expect(find.text('Analizar agua'), findsOneWidget);
    expect(find.text('Último análisis'), findsOneWidget);

    // Historial con los datos de ejemplo de la cuenta demo
    await tester.tap(find.text('Historial'));
    await settle(tester, 5);
    expect(find.text('Hoja saludable'), findsWidgets);
    expect(find.text('Mildiu velloso'), findsOneWidget);
    expect(find.text('Todos · 3'), findsOneWidget);

    // Perfil
    await tester.tap(find.text('Perfil'));
    await settle(tester, 5);
    expect(find.text(AppConfig.demoName), findsOneWidget);
    expect(find.text(AppConfig.demoEmail), findsOneWidget);

    // Cerrar sesión
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await settle(tester, 5);
    await tester.tap(find.widgetWithText(TextButton, 'Cerrar sesión'));
    await settle(tester, 10);
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(services.session.read(), isNull);
  });

  testWidgets('credenciales incorrectas muestran error', (tester) async {
    final services = await makeServices();
    await tester.pumpWidget(makeApp(services));
    await settle(tester, 15);

    await tester.enterText(find.byType(TextFormField).at(0), 'otro@correo.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'malaclave1');
    await tester.tap(find.text('Iniciar sesión'));
    await settle(tester, 5);

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('registro crea la cuenta y entra a la app', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final services = await makeServices();
    await tester.pumpWidget(makeApp(services));
    await settle(tester, 15);

    await tester.tap(find.text('Regístrate'));
    await settle(tester, 5);
    // El login sigue debajo en la pila de navegación: buscar solo en Registro.
    final fields = find.descendant(
      of: find.byType(RegistroScreen),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'Ana Gómez');
    await tester.enterText(fields.at(1), 'ana@correo.com');
    await tester.enterText(fields.at(2), 'Clave1234');
    await tester.enterText(fields.at(3), 'Clave1234');
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await settle(tester);

    expect(find.text('Analizar planta'), findsOneWidget);
    expect(services.session.read()?.user.email, 'ana@correo.com');
  });

  testWidgets('procesar análisis (mock) → resultado → queda en historial', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final services = await makeServices();
    final bytes = (await tester.runAsync(() => makePng(640, 480)))!;
    final image = ValidatedImage(
      bytes: bytes,
      fileName: 'muestra.png',
      mimeType: 'image/png',
      width: 640,
      height: 480,
    );

    final auth = AuthController(services);
    final history = HistoryController(services);
    // Los Future.delayed del mock solo avanzan con tiempo real fuera del FakeAsync.
    await tester.runAsync(() async {
      await auth.login(AppConfig.demoEmail, AppConfig.demoPassword);
      await history.load(auth.user!.id);
    });
    final before = history.items.length;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppServices>.value(value: services),
          ChangeNotifierProvider.value(value: services.settings),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: history),
        ],
        child: MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ProcesandoAnalisisScreen(args: AnalysisArgs(AnalysisType.water, image)),
        ),
      ),
    );
    expect(find.text('Analizando imagen…'), findsOneWidget);
    await settle(tester, 15);

    expect(find.text('Resultado'), findsOneWidget);
    expect(find.text('Recomendaciones'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Resultado simulado.', findRichText: true),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Resultado simulado.', findRichText: true), findsOneWidget);
    expect(history.items.length, before + 1);
    expect(history.items.first.type, AnalysisType.water);
  });
}
