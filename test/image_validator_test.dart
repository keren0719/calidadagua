import 'dart:typed_data';

import 'package:agrovision_ai/core/errors/app_exception.dart';
import 'package:agrovision_ai/core/utils/image_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('acepta un PNG de 300 × 300 px', (tester) async {
    await tester.runAsync(() async {
      final bytes = await makePng(300, 320);
      final image = await ImageValidator.validateBytes(bytes, fileName: 'foto.PNG');
      expect(image.width, 300);
      expect(image.height, 320);
      expect(image.mimeType, 'image/png');
      expect(image.fileName, 'foto.png');
    });
  });

  testWidgets('rechaza imágenes menores a 300 px', (tester) async {
    await tester.runAsync(() async {
      final bytes = await makePng(200, 600);
      await expectLater(
        ImageValidator.validateBytes(bytes, fileName: 'chica.png'),
        throwsA(
          isA<ImageValidationException>().having(
            (e) => e.message,
            'message',
            contains('demasiado pequeña'),
          ),
        ),
      );
    });
  });

  test('rechaza formatos que no son JPG ni PNG', () async {
    final gif = Uint8List.fromList('GIF89a....'.codeUnits);
    await expectLater(
      ImageValidator.validateBytes(gif, fileName: 'animado.gif'),
      throwsA(
        isA<ImageValidationException>().having(
          (e) => e.message,
          'message',
          contains('Formato no compatible'),
        ),
      ),
    );
  });

  test('detecta JPEG por su firma', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0]);
    expect(ImageValidator.detectMimeType(jpeg), 'image/jpeg');
  });
}
