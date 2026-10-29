import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../state/auth_controller.dart';
import '../../state/history_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/agro_header.dart';
import '../../widgets/agro_icon.dart';
import '../../widgets/agro_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import 'auth_layout.dart';

class InicioSesionScreen extends StatefulWidget {
  const InicioSesionScreen({super.key});

  @override
  State<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State<InicioSesionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fillDemo() {
    _email.text = AppConfig.demoEmail;
    _password.text = AppConfig.demoPassword;
    setState(() => _error = null);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthController>();
    final history = context.read<HistoryController>();
    try {
      await auth.login(_email.text, _password.text);
      await history.load(auth.user!.id);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (_) => false);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Ocurrió un error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useMock = context.watch<SettingsController>().useMockAuth;

    return AuthLayout(
      children: [
        const SizedBox(height: 8),
        const Align(alignment: Alignment.centerLeft, child: AgroLogo(large: true)),
        const SizedBox(height: 36),
        const ScreenHeading(
          kicker: 'Bienvenido',
          title: 'Inicia sesión',
          subtitle: 'Accede para analizar tus cultivos y consultar tu historial de diagnósticos.',
        ),
        const SizedBox(height: 26),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                AgroTextField(
                  label: 'Correo electrónico',
                  controller: _email,
                  hint: 'tucorreo@ejemplo.com',
                  icon: AgroIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  enabled: !_loading,
                ),
                const SizedBox(height: 16),
                AgroTextField(
                  label: 'Contraseña',
                  controller: _password,
                  hint: '••••••••',
                  icon: AgroIcons.lock,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: Validators.password,
                  onSubmitted: (_) => _submit(),
                  enabled: !_loading,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading
                ? null
                : () => Navigator.of(context).pushNamed(AppRoutes.recoverPassword),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
        if (_error != null) ...[
          ErrorBox(title: 'No pudimos iniciar sesión', message: _error!),
          const SizedBox(height: 14),
        ] else
          const SizedBox(height: 6),
        PrimaryButton(
          label: 'Iniciar sesión',
          icon: AgroIcons.chevron,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              '¿No tienes cuenta?',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).pushNamed(AppRoutes.register),
              child: const Text('Regístrate'),
            ),
          ],
        ),
        if (useMock) ...[
          const SizedBox(height: 14),
          InfoNote(
            icon: AgroIcons.sparkles,
            boldText: 'Modo demo activo.',
            text:
                'Usa ${AppConfig.demoEmail} / ${AppConfig.demoPassword} o crea una cuenta de prueba.',
            background: AppColors.mintSurface,
            borderColor: AppColors.borderMint,
            trailing: TextButton(onPressed: _loading ? null : _fillDemo, child: const Text('Usar')),
          ),
        ],
      ],
    );
  }
}
