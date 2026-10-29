import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../data/models/analysis_result.dart';
import '../data/models/analysis_type.dart';
import '../state/history_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/agro_icon.dart';
import '../widgets/analysis_card.dart';
import '../widgets/common.dart';
import 'historial.dart';

/// Inicio: "Cultiva con más certeza." + tarjetas de planta y agua.
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key, required this.onOpenHistory});

  final VoidCallback onOpenHistory;

  void _start(BuildContext context, AnalysisType type) {
    Navigator.of(context).pushNamed(AppRoutes.capture, arguments: type);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;
    final latest = context.select<HistoryController, AnalysisResult?>(
      (h) => h.items.isEmpty ? null : h.items.first,
    );
    final mockAnalysis = context.select<SettingsController, bool>((s) => s.useMockAnalysis);

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, compact ? 6 : 18, 20, compact ? 14 : 21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AgroIcon(AgroIcons.sparkles, size: 14, color: AppColors.greenDark),
                    SizedBox(width: 6),
                    Text(
                      'ANÁLISIS INTELIGENTE',
                      style: TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Cultiva con\n'),
                    TextSpan(
                      text: 'más certeza.',
                      style: TextStyle(color: AppColors.green),
                    ),
                  ],
                ),
                style: TextStyle(
                  color: AppColors.title,
                  fontSize: (MediaQuery.sizeOf(context).width * 0.1).clamp(36, 43),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2.2,
                  height: 1.03,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Diagnósticos visuales en segundos para cuidar tus cultivos y el agua '
                'que los alimenta.',
                style: TextStyle(
                  color: Color(0xFF688078),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              AnalysisCard(
                type: AnalysisType.plant,
                height: compact ? 124 : 142,
                onTap: () => _start(context, AnalysisType.plant),
              ),
              const SizedBox(height: 12),
              AnalysisCard(
                type: AnalysisType.water,
                height: compact ? 124 : 142,
                onTap: () => _start(context, AnalysisType.water),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, compact ? 12 : 18, 20, 0),
          child: const InfoNote(
            icon: AgroIcons.shield,
            boldText: 'Tus datos están protegidos.',
            text: 'Las imágenes se usan únicamente para realizar el análisis.',
          ),
        ),
        if (mockAnalysis)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: InfoNote(
              icon: AgroIcons.info,
              boldText: 'Modo demo.',
              text: 'Los resultados son simulados. Conecta tu API en Perfil › Configuración.',
              iconColor: AppColors.blue,
              background: Color(0xFFF2F9FC),
              borderColor: Color(0xFFD3E9F2),
            ),
          ),
        if (latest != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Último análisis',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(onPressed: onOpenHistory, child: const Text('Ver todo')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: HistoryTile(result: latest),
          ),
        ],
      ],
    );
  }
}
