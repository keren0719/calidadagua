import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/errors/app_exception.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../core/utils/image_source_picker.dart';
import '../core/utils/image_validator.dart';
import '../widgets/agro_header.dart';
import '../widgets/agro_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/tips_card.dart';

/// Paso 2 de 2: revisar la imagen elegida antes de analizarla.
class ValidacionImagenScreen extends StatefulWidget {
  const ValidacionImagenScreen({super.key, required this.args, this.picker});

  final AnalysisArgs args;
  final ImageSourcePicker? picker;

  @override
  State<ValidacionImagenScreen> createState() => _ValidacionImagenScreenState();
}

class _ValidacionImagenScreenState extends State<ValidacionImagenScreen> {
  late final ImageSourcePicker _picker = widget.picker ?? ImageSourcePicker();
  late ValidatedImage _image = widget.args.image;
  String? _error;

  Future<void> _change() async {
    setState(() => _error = null);
    try {
      final image = await _picker.pick(ImageSource.gallery);
      if (image != null && mounted) setState(() => _image = image);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _analyze() {
    Navigator.of(context)
        .pushNamed(AppRoutes.processing, arguments: AnalysisArgs(widget.args.type, _image));
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.args.type;
    final format = _image.mimeType == 'image/png' ? 'PNG' : 'JPG';

    return Scaffold(
      appBar: AgroHeader(title: type.title, onBack: () => Navigator.of(context).pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const ScreenHeading(
            kicker: 'Paso 2 de 2',
            title: 'Revisa tu imagen',
            subtitle: 'Asegúrate de que el área a analizar se vea con claridad.',
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 285,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    _image.bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    semanticLabel: 'Vista previa para analizar',
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _GlassPill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.greenBright,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const AgroIcon(AgroIcons.check, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'Imagen lista',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Material(
                      color: const Color(0xC70E2C24),
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: _change,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Text(
                            'Cambiar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AgroCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const IconTile(icon: AgroIcons.check, size: 30, iconSize: 15, radius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_image.width} × ${_image.height} px · '
                    '${Formatters.bytes(_image.bytes.lengthInBytes)} · $format',
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBox(title: 'No pudimos usar esta imagen', message: _error!),
          ],
          const SizedBox(height: 18),
          const TipsCard(),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Analizar imagen', icon: AgroIcons.sparkles, onPressed: _analyze),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xC70E2C24),
        borderRadius: BorderRadius.circular(30),
      ),
      child: child,
    );
  }
}
