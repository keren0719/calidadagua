import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../state/auth_controller.dart';
import '../../state/history_controller.dart';
import '../../widgets/agro_icon.dart';
import '../../widgets/agro_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import 'auth_layout.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _acceptedTerms = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() => _error = 'Debes aceptar el uso de tus imágenes para el análisis.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthController>();
    final history = context.read<HistoryController>();
    try {
      await auth.register(_name.text, _email.text, _password.text);
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
    return AuthLayout(
      onBack: _loading ? null : () => Navigator.of(context).pop(),
      children: [
        const SizedBox(height: 12),
        const ScreenHeading(
          kicker: 'Nueva cuenta',
          title: 'Crea tu cuenta',
          subtitle: 'Guarda tus diagnósticos y lleva el control de tus cultivos y fuentes de agua.',
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                AgroTextField(
                  label: 'Nombre completo',
                  controller: _name,
                  hint: 'Ej. María Rodríguez',
                  icon: AgroIcons.user,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                  enabled: !_loading,
                ),
                const SizedBox(height: 16),
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
                  hint: 'Mínimo 8 caracteres',
                  icon: AgroIcons.lock,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.newPassword,
                  enabled: !_loading,
                ),
                const SizedBox(height: 16),
                AgroTextField(
                  label: 'Confirmar contraseña',
                  controller: _confirm,
                  hint: 'Repite tu contraseña',
                  icon: AgroIcons.lock,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => v != _password.text ? 'Las contraseñas no coinciden.' : null,
                  onSubmitted: (_) => _submit(),
                  enabled: !_loading,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _loading ? null : () => setState(() => _acceptedTerms = !_acceptedTerms),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _acceptedTerms,
                    activeColor: AppColors.green,
                    side: const BorderSide(color: AppColors.borderDashed, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    onChanged: _loading ? null : (v) => setState(() => _acceptedTerms = v ?? false),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Acepto que mis imágenes se usen únicamente para realizar el análisis.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_error != null) ...[
          ErrorBox(title: 'No pudimos crear tu cuenta', message: _error!),
          const SizedBox(height: 14),
        ],
        PrimaryButton(
          label: 'Crear cuenta',
          icon: AgroIcons.userPlus,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              '¿Ya tienes cuenta?',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Inicia sesión'),
            ),
          ],
        ),
      ],
    );
  }
}
