import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../data/interpreters/diagnosis_catalog.dart';
import '../data/interpreters/result_interpreter.dart';
import '../data/models/analysis_result.dart';
import '../data/models/analysis_type.dart';
import '../state/history_controller.dart';
import '../widgets/agro_header.dart';
import '../widgets/agro_icon.dart';
import '../widgets/analysis_image.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/result_widgets.dart';

class ResultadosAnalisisScreen extends StatelessWidget {
  const ResultadosAnalisisScreen({super.key, required this.args});

  final ResultArgs args;

  AnalysisResult get result => args.result;

  void _close(BuildContext context) {
    if (args.fromHistory) {
      Navigator.of(context).pop();
    } else {
      AppRoutes.backToMain(context);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar análisis?'),
        content: const Text('Este diagnóstico se eliminará de tu historial.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<HistoryController>().remove(result.id);
    if (context.mounted) _close(context);
  }

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(result.status);
    final hasBoxes =
        result.type == AnalysisType.plant &&
        result.detections.isNotEmpty &&
        (result.imageWidth ?? 0) > 0;

    return PopScope(
      canPop: args.fromHistory,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(context);
      },
      child: Scaffold(
        appBar: AgroHeader(
          title: 'Resultado',
          onBack: () => _close(context),
          trailing: args.fromHistory
              ? AgroIconButton(
                  icon: AgroIcons.trash,
                  tooltip: 'Eliminar del historial',
                  onPressed: () => _delete(context),
                )
              : null,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            // --- Imagen + encabezado del resultado ---
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(
                height: 260,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnalysisImage(
                      type: result.type,
                      bytes: args.imageBytes,
                      path: result.imagePath,
                      url: result.imageUrl,
                      semanticLabel: 'Imagen analizada',
                    ),
                    if (hasBoxes)
                      DetectionOverlay(
                        detections: result.detections,
                        imageWidth: result.imageWidth!,
                        imageHeight: result.imageHeight!,
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xED092D23), Color(0x0D092D23)],
                          stops: [0, 0.75],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 15,
                      left: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 19,
                              height: 19,
                              decoration: BoxDecoration(
                                color: style.strong,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: AgroIcon(style.icon, size: 12, color: Colors.white),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Análisis completado · ${style.label}',
                              style: TextStyle(
                                color: style.text,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.type.eyebrow.toUpperCase(),
                            style: TextStyle(
                              color: style.heroAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            result.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            result.finding,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Confianza ---
            const SizedBox(height: 13),
            AgroCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confianza del análisis',
                          style: TextStyle(
                            color: Color(0xFF73877F),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ResultInterpreter.confidenceLabel(result.confidence),
                          style: AppText.cardTitle.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.relativeDateTime(result.createdAt),
                          style: const TextStyle(color: AppColors.mutedLight, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  ConfidenceRing(value: result.confidence, color: style.strong),
                ],
              ),
            ),

            // --- Explicación ---
            const SizedBox(height: 13),
            AgroCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconTile.blue(icon: AgroIcons.sparkles),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('¿Qué encontramos?', style: AppText.cardTitle),
                        const SizedBox(height: 6),
                        Text(result.explanation, style: AppText.cardBody),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Detecciones de YOLO ---
            if (result.detections.isNotEmpty) ...[
              const SizedBox(height: 13),
              AgroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconTile(icon: AgroIcons.target),
                        const SizedBox(width: 12),
                        Text('Detecciones (${result.detections.length})', style: AppText.cardTitle),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final d in result.detections)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: StatusStyle.of(
                                  DiagnosisCatalog
                                          .plant[DiagnosisCatalog.normalize(d.className)]
                                          ?.status ??
                                      ResultStatus.warning,
                                ).strong,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DiagnosisCatalog
                                        .plant[DiagnosisCatalog.normalize(d.className)]
                                        ?.title ??
                                    DiagnosisCatalog.prettify(d.className),
                                style: const TextStyle(
                                  color: AppColors.textSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${(d.confidence * 100).round()}%',
                              style: const TextStyle(
                                color: Color(0xFF185B47),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // --- Recomendaciones ---
            const SizedBox(height: 13),
            AgroCard(
              color: style.surface,
              borderColor: style.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconTile(
                        icon: AgroIcons.leaf,
                        background: result.status == ResultStatus.good
                            ? AppColors.mint
                            : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      const Text('Recomendaciones', style: AppText.cardTitle),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final item in result.recommendations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 19,
                            height: 19,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCFEEE0),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const AgroIcon(
                              AgroIcons.check,
                              size: 13,
                              color: Color(0xFF167653),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: Color(0xFF536F66),
                                fontSize: 11,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            if (result.isSimulated) ...[
              const SizedBox(height: 13),
              const InfoNote(
                icon: AgroIcons.info,
                boldText: 'Resultado simulado.',
                text: 'Generado en modo demo, sin usar el modelo de IA real.',
                iconColor: AppColors.blue,
                background: Color(0xFFF2F9FC),
                borderColor: Color(0xFFD3E9F2),
              ),
            ],

            const SizedBox(height: 20),
            if (args.fromHistory)
              PrimaryButton(
                label: 'Volver al historial',
                icon: AgroIcons.clock,
                onPressed: () => Navigator.of(context).pop(),
              )
            else ...[
              PrimaryButton(
                label: 'Analizar otra imagen',
                icon: AgroIcons.camera,
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.capture,
                  ModalRoute.withName(AppRoutes.main),
                  arguments: result.type,
                ),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Volver al inicio',
                icon: AgroIcons.home,
                onPressed: () => AppRoutes.backToMain(context),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Este resultado es orientativo y se basa en señales visuales.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8A9B95), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
