import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../data/models/api_responses.dart';
import '../state/app_services.dart';
import '../state/history_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/agro_header.dart';
import '../widgets/agro_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

/// Ajustes: modo demo/API, URL del servidor, parámetros del modelo y datos.
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  late final TextEditingController _url = TextEditingController(
    text: context.read<SettingsController>().apiBaseUrl,
  );
  bool _testing = false;
  ApiHealth? _health;
  String? _healthError;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  String? _validateUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https')) || uri.host.isEmpty) {
      return 'Escribe una URL completa, por ejemplo http://192.168.1.50:8000';
    }
    return null;
  }

  Future<void> _saveUrl() async {
    final error = _validateUrl(_url.text);
    if (error != null) {
      showAgroSnackBar(context, error);
      return;
    }
    FocusScope.of(context).unfocus();
    await context.read<SettingsController>().setApiBaseUrl(_url.text);
    if (mounted) showAgroSnackBar(context, 'URL de la API guardada');
  }

  Future<void> _testConnection() async {
    final settings = context.read<SettingsController>();
    final services = context.read<AppServices>();
    if (_url.text.trim() != settings.apiBaseUrl) {
      if (_validateUrl(_url.text) != null) {
        showAgroSnackBar(context, _validateUrl(_url.text)!);
        return;
      }
      await settings.setApiBaseUrl(_url.text);
    }
    setState(() {
      _testing = true;
      _health = null;
      _healthError = null;
    });
    try {
      final health = await services.apiAnalysis.checkHealth();
      if (mounted) setState(() => _health = health);
    } on AppException catch (e) {
      if (mounted) setState(() => _healthError = e.message);
    } catch (e) {
      if (mounted) setState(() => _healthError = 'No se pudo conectar: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todo el historial?'),
        content: const Text('Se eliminarán todos tus análisis guardados en este teléfono.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<HistoryController>().clear();
    if (mounted) showAgroSnackBar(context, 'Historial borrado');
  }

  Future<void> _reset() async {
    final settings = context.read<SettingsController>();
    await settings.resetToDefaults();
    _url.text = settings.apiBaseUrl;
    setState(() {
      _health = null;
      _healthError = null;
    });
    if (mounted) showAgroSnackBar(context, 'Valores restablecidos');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AgroHeader(title: 'Configuración', onBack: () => Navigator.of(context).pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          // --- Modo de datos ---
          const SectionKicker('Modo de datos'),
          AgroCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SwitchRow(
                  icon: AgroIcons.sparkles,
                  title: 'Análisis de prueba',
                  subtitle: settings.useMockAnalysis
                      ? 'Resultados simulados, sin llamar a la API.'
                      : 'Usando el modelo real de la API.',
                  value: settings.useMockAnalysis,
                  onChanged: settings.setUseMockAnalysis,
                ),
                const Divider(height: 1, color: AppColors.borderSoft),
                _SwitchRow(
                  icon: AgroIcons.lock,
                  title: 'Login de prueba',
                  subtitle: settings.useMockAuth
                      ? 'Cuentas locales. Aplica en el próximo inicio de sesión.'
                      : 'Usa /auth/login del backend (aún no implementado).',
                  value: settings.useMockAuth,
                  onChanged: settings.setUseMockAuth,
                ),
              ],
            ),
          ),

          // --- Servidor ---
          const SizedBox(height: 22),
          const SectionKicker('Servidor API'),
          AgroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('URL base de la API', style: AppText.label),
                const SizedBox(height: 7),
                TextField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  onSubmitted: (_) => _saveUrl(),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: AppConfig.defaultApiBaseUrl,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 10),
                      child: AgroIcon(AgroIcons.server, size: 18, color: AppColors.mutedLight),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
                    suffixIcon: TextButton(onPressed: _saveUrl, child: const Text('Guardar')),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Emulador Android: http://10.0.2.2:8000 · Celular físico: la IP de tu PC '
                  '(ej. http://192.168.1.50:8000) con uvicorn en --host 0.0.0.0.',
                  style: TextStyle(color: AppColors.mutedLight, fontSize: 10, height: 1.5),
                ),
                const SizedBox(height: 14),
                SecondaryButton(
                  label: _testing ? 'Probando…' : 'Probar conexión',
                  icon: AgroIcons.refresh,
                  onPressed: _testing ? null : _testConnection,
                ),
                if (_health != null) ...[
                  const SizedBox(height: 12),
                  _HealthResult(health: _health!),
                ],
                if (_healthError != null) ...[
                  const SizedBox(height: 12),
                  ErrorBox(title: 'Sin conexión', message: _healthError!),
                ],
              ],
            ),
          ),

          // --- Modelo ---
          const SizedBox(height: 22),
          const SectionKicker('Análisis de plantas (YOLO)'),
          AgroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Confianza mínima de detección', style: AppText.cardTitle),
                    ),
                    Text(
                      '${(settings.detectionConfidence * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.greenStrong,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.detectionConfidence,
                  min: 0.1,
                  max: 0.9,
                  divisions: 16,
                  label: '${(settings.detectionConfidence * 100).round()}%',
                  onChanged: settings.setDetectionConfidence,
                ),
                const Text(
                  'Parámetro "conf" de /predict/cucumber. Valores altos muestran menos '
                  'detecciones pero más seguras.',
                  style: TextStyle(color: AppColors.mutedLight, fontSize: 10, height: 1.5),
                ),
              ],
            ),
          ),

          // --- Datos ---
          const SizedBox(height: 22),
          const SectionKicker('Datos'),
          AgroCard(
            padding: EdgeInsets.zero,
            child: _SwitchRow(
              icon: AgroIcons.clock,
              title: 'Guardar en historial',
              subtitle: 'Guarda cada análisis y su foto en este teléfono.',
              value: settings.saveHistory,
              onChanged: settings.setSaveHistory,
            ),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Borrar historial',
            icon: AgroIcons.trash,
            destructive: true,
            onPressed: _clearHistory,
          ),
          const SizedBox(height: 10),
          SecondaryButton(label: 'Restablecer valores', icon: AgroIcons.refresh, onPressed: _reset),
          const SizedBox(height: 22),
          const Text(
            '${AppConfig.appName} · versión ${AppConfig.appVersion}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedLight, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final AgroIcons icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              IconTile(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.cardTitle.copyWith(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.mutedLight,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthResult extends StatelessWidget {
  const _HealthResult({required this.health});

  final ApiHealth health;

  @override
  Widget build(BuildContext context) {
    Widget model(String name, bool loaded) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          AgroIcon(
            loaded ? AgroIcons.check : AgroIcons.close,
            size: 16,
            color: loaded ? AppColors.greenStrong : AppColors.errorStrong,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name, style: const TextStyle(color: AppColors.textSoft, fontSize: 12)),
          ),
          Text(
            loaded ? 'Cargado' : 'No cargado',
            style: TextStyle(
              color: loaded ? AppColors.greenStrong : AppColors.errorText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conexión exitosa',
            style: TextStyle(color: Color(0xFF166D51), fontSize: 12, fontWeight: FontWeight.w800),
          ),
          if (health.message.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(health.message, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
          const SizedBox(height: 4),
          model('YOLOv11 · plantas (pepino)', health.yoloCucumberLoaded),
          model('EfficientNet · bacterias (agua)', health.bacteriaLoaded),
        ],
      ),
    );
  }
}
