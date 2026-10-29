import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Carga la fuente Manrope real en las pruebas para que el texto mida lo mismo
/// que en el teléfono (por defecto los tests usan una fuente cuadrada más ancha).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final loader = FontLoader('Manrope');
  for (final weight in [400, 500, 600, 700, 800]) {
    final bytes = File('assets/fonts/Manrope-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  }
  await loader.load();
  await testMain();
}
