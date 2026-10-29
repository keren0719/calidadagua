import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../data/models/analysis_result.dart';
import '../data/models/analysis_type.dart';
import '../state/history_controller.dart';
import '../widgets/agro_icon.dart';
import '../widgets/analysis_image.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/result_widgets.dart';

/// Historial de análisis con filtros por tipo.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key, required this.onStartAnalysis});

  final VoidCallback onStartAnalysis;

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  AnalysisType? _filter;

  Future<bool> _confirmDelete() async {
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
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryController>();
    final all = history.items;
    final items = _filter == null ? all : all.where((r) => r.type == _filter).toList();

    if (history.loading && all.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: ScreenHeading(kicker: 'Tu actividad', title: 'Historial'),
          ),
        ),
        if (all.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: EmptyState(
                  icon: AgroIcons.clock,
                  title: 'Aún no hay análisis',
                  message:
                      'Tus diagnósticos recientes aparecerán aquí para que puedas consultarlos.',
                  action: PrimaryButton(
                    label: 'Crear primer análisis',
                    expand: false,
                    onPressed: widget.onStartAnalysis,
                  ),
                ),
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos · ${all.length}',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final type in AnalysisType.values)
                    _FilterChip(
                      label: '${type.shortLabel} · ${history.countOf(type)}',
                      icon: type == AnalysisType.plant ? AgroIcons.leaf : AgroIcons.droplet,
                      selected: _filter == type,
                      onTap: () => setState(() => _filter = type),
                    ),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No hay análisis de este tipo todavía.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final result = items[i];
                return Dismissible(
                  key: ValueKey(result.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(),
                  onDismissed: (_) {
                    context.read<HistoryController>().remove(result.id);
                    showAgroSnackBar(context, 'Análisis eliminado');
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: const AgroIcon(AgroIcons.trash, color: AppColors.errorText),
                  ),
                  child: HistoryTile(result: result),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Desliza un análisis hacia la izquierda para eliminarlo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedLight, fontSize: 10),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AgroIcons? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textSoft;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.forest : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppColors.forest : AppColors.borderInput),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  AgroIcon(icon!, size: 14, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila del historial: miniatura, diagnóstico, fecha y confianza.
class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(result.status);
    return AgroCard(
      padding: const EdgeInsets.all(12),
      onTap: () =>
          Navigator.of(context)
              .pushNamed(AppRoutes.result, arguments: ResultArgs(result, fromHistory: true)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 58,
              height: 58,
              child: AnalysisImage(type: result.type, path: result.imagePath, url: result.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AgroIcon(
                      result.type == AnalysisType.plant ? AgroIcons.leaf : AgroIcons.droplet,
                      size: 12,
                      color: result.type == AnalysisType.plant ? AppColors.green : AppColors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      result.type.eyebrow.toUpperCase(),
                      style: AppTextKicker.small(
                        result.type == AnalysisType.plant ? AppColors.green : AppColors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.relativeDateTime(result.createdAt),
                  style: const TextStyle(color: AppColors.mutedLight, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: style.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: style.border),
                ),
                child: Text(
                  style.label,
                  style: TextStyle(color: style.text, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                result.confidence > 0 ? '${result.confidencePercent}%' : '—',
                style: const TextStyle(
                  color: Color(0xFF185B47),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kicker pequeño de una sola línea para filas.
class AppTextKicker {
  AppTextKicker._();

  static TextStyle small(Color color) =>
      TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2);
}
