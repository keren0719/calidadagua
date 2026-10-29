import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../data/models/analysis_type.dart';
import '../state/auth_controller.dart';
import '../state/history_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/agro_icon.dart';
import '../widgets/common.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tendrás que volver a ingresar tu correo y contraseña.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final history = context.read<HistoryController>();
    await context.read<AuthController>().logout();
    history.reset();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _showTips(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consejos para un buen análisis',
                style: TextStyle(color: AppColors.title, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 16),
              _Tip(
                icon: AgroIcons.sparkles,
                title: 'Buena iluminación',
                text: 'Usa luz natural y evita sombras o reflejos directos.',
              ),
              _Tip(
                icon: AgroIcons.scan,
                title: 'Imagen enfocada',
                text: 'Mantén el teléfono estable y toca la pantalla para enfocar.',
              ),
              _Tip(
                icon: AgroIcons.leaf,
                title: 'Plantas',
                text: 'Fotografía una sola hoja o fruto, mostrando la zona afectada.',
              ),
              _Tip(
                icon: AgroIcons.droplet,
                title: 'Agua',
                text: 'Usa un recipiente transparente y limpio sobre un fondo claro.',
              ),
              _Tip(
                icon: AgroIcons.info,
                title: 'Resultado orientativo',
                text: 'El análisis visual no reemplaza una prueba de laboratorio.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final history = context.watch<HistoryController>();
    final mockAuth = context.select<SettingsController, bool>((s) => s.useMockAuth);
    if (user == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const SectionKicker('Tu cuenta'),
        const Text(
          'Perfil',
          style: TextStyle(
            color: AppColors.title,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.26,
          ),
        ),
        const SizedBox(height: 18),
        AgroCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(user.email, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    if (user.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Miembro desde ${Formatters.monthYear(user.createdAt!)}',
                        style: const TextStyle(color: AppColors.mutedLight, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
              if (mockAuth)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      color: AppColors.greenDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Stat(value: history.items.length, label: 'Análisis', icon: AgroIcons.chart),
            const SizedBox(width: 10),
            _Stat(
              value: history.countOf(AnalysisType.plant),
              label: 'Plantas',
              icon: AgroIcons.leaf,
            ),
            const SizedBox(width: 10),
            _Stat(
              value: history.countOf(AnalysisType.water),
              label: 'Agua',
              icon: AgroIcons.droplet,
              blue: true,
            ),
          ],
        ),
        if (history.issuesCount > 0) ...[
          const SizedBox(height: 12),
          InfoNote(
            icon: AgroIcons.alert,
            iconColor: AppColors.warningStrong,
            background: AppColors.warningSurface,
            borderColor: AppColors.warningBorder,
            boldText:
                '${history.issuesCount} '
                '${history.issuesCount == 1 ? 'análisis requiere' : 'análisis requieren'} atención.',
            text: 'Revísalos en tu historial.',
          ),
        ],
        const SizedBox(height: 22),
        const SectionKicker('Opciones'),
        const SizedBox(height: 4),
        AgroCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _MenuItem(
                icon: AgroIcons.settings,
                title: 'Configuración',
                subtitle: 'Conexión con la API, modo demo y datos',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
              ),
              const Divider(height: 1, color: AppColors.borderSoft),
              _MenuItem(
                icon: AgroIcons.help,
                title: 'Consejos de uso',
                subtitle: 'Cómo tomar fotos para mejores resultados',
                onTap: () => _showTips(context),
              ),
              const Divider(height: 1, color: AppColors.borderSoft),
              _MenuItem(
                icon: AgroIcons.info,
                title: 'Acerca de ${AppConfig.appName}',
                subtitle: 'Versión ${AppConfig.appVersion}',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: AppConfig.appName,
                  applicationVersion: AppConfig.appVersion,
                  applicationIcon: const IconTile(icon: AgroIcons.leaf, size: 44, iconSize: 22),
                  children: const [
                    Text(
                      'Diagnóstico visual de plantas y calidad del agua con inteligencia '
                      'artificial. Los resultados son orientativos y no sustituyen un '
                      'análisis de laboratorio.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AgroCard(
          padding: EdgeInsets.zero,
          borderColor: AppColors.errorBorder,
          child: _MenuItem(
            icon: AgroIcons.logout,
            title: 'Cerrar sesión',
            destructive: true,
            onTap: () => _logout(context),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon, this.blue = false});

  final int value;
  final String label;
  final AgroIcons icon;
  final bool blue;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AgroCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            blue
                ? IconTile.blue(icon: icon, size: 32, iconSize: 16, radius: 10)
                : IconTile(icon: icon, size: 32, iconSize: 16, radius: 10),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: const TextStyle(
                color: AppColors.title,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });

  final AgroIcons icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            destructive
                ? const IconTile(
                    icon: AgroIcons.logout,
                    background: AppColors.errorSurface,
                    foreground: AppColors.errorText,
                  )
                : IconTile(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: destructive ? AppColors.errorText : AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(color: AppColors.mutedLight, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (!destructive)
              const AgroIcon(AgroIcons.chevron, size: 18, color: AppColors.mutedLight),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.title, required this.text});

  final AgroIcons icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, size: 34, iconSize: 17, radius: 11),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
