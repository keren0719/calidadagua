import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/errors/app_exception.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../state/app_services.dart';
import '../state/history_controller.dart';
import '../widgets/agro_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

/// "Analizando imagen…": llama al repositorio y muestra el progreso.
class ProcesandoAnalisisScreen extends StatefulWidget {
  const ProcesandoAnalisisScreen({super.key, required this.args});

  final AnalysisArgs args;

  @override
  State<ProcesandoAnalisisScreen> createState() => _ProcesandoAnalisisScreenState();
}

class _ProcesandoAnalisisScreenState extends State<ProcesandoAnalisisScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  Timer? _ticker;
  int _progress = 8;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    _ticker?.cancel();
    setState(() {
      _error = null;
      _progress = 8;
    });
    // Progreso visual: avanza hasta 93% mientras se espera la respuesta.
    _ticker = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (mounted && _progress < 93) setState(() => _progress = (_progress + 7).clamp(0, 93));
    });

    final services = context.read<AppServices>();
    final history = context.read<HistoryController>();
    final image = widget.args.image;

    try {
      final result = await services.analysis.analyze(widget.args.type, image);
      final stored = await history.add(
        result,
        imageBytes: image.bytes,
        imageExtension: image.mimeType == 'image/png' ? 'png' : 'jpg',
      );
      _ticker?.cancel();
      if (!mounted) return;
      setState(() => _progress = 100);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.result,
        arguments: ResultArgs(stored, imageBytes: image.bytes),
      );
    } on AppException catch (e) {
      _fail(e);
    } catch (e) {
      _fail(AppException('Ocurrió un error inesperado al analizar la imagen.', cause: e));
    }
  }

  void _fail(AppException e) {
    _ticker?.cancel();
    if (mounted) setState(() => _error = e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.background,
          gradient: RadialGradient(
            center: Alignment(0, -0.24),
            radius: 0.6,
            colors: [Color(0x2930B483), Color(0x0030B483)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: _error == null ? _buildLoading() : _buildError(_error!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Semantics(
      liveRegion: true,
      label: 'Analizando imagen, $_progress por ciento',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              children: [
                for (final delay in [0.0, 0.5])
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) {
                          final t = (_pulse.value + delay) % 1;
                          return Opacity(
                            opacity: 1 - t,
                            child: Transform.scale(scale: 0.82 + t * 0.53, child: child),
                          );
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0x472AA678)),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 20,
                  top: 20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 7),
                      boxShadow: const [
                        BoxShadow(color: Color(0x38123F33), blurRadius: 45, offset: Offset(0, 18)),
                      ],
                      image: DecorationImage(
                        image: MemoryImage(widget.args.image.bytes),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 20,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.background, width: 5),
                    ),
                    alignment: Alignment.center,
                    child: const AgroIcon(AgroIcons.scan, size: 26, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 42),
          const SectionKicker('Agrovision AI'),
          const Text(
            'Analizando imagen…',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              'Nuestra IA está buscando patrones y señales visibles.',
              textAlign: TextAlign.center,
              style: AppText.screenSubtitle.copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 7,
              color: const Color(0xFFDCEBE5),
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 140),
                widthFactor: _progress / 100,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    gradient: LinearGradient(
                      colors: [AppColors.progressStart, AppColors.progressEnd],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$_progress% completado',
            style: const TextStyle(
              color: Color(0xFF739087),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppException error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const IconTile(
          icon: AgroIcons.alert,
          size: 74,
          iconSize: 32,
          radius: 24,
          background: AppColors.errorSurface,
          foreground: AppColors.errorStrong,
        ),
        const SizedBox(height: 19),
        Text(
          error.title ?? 'No pudimos completar el análisis',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            error.message,
            textAlign: TextAlign.center,
            style: AppText.screenSubtitle.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 26),
        PrimaryButton(label: 'Reintentar', icon: AgroIcons.refresh, onPressed: _run),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Elegir otra imagen', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
