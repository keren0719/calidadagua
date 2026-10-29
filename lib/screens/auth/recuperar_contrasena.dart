import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_exception.dart';
import '../../state/auth_controller.dart';
import '../../widgets/agro_icon.dart';
import '../../widgets/agro_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import 'auth_layout.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  State<RecuperarContrasenaScreen> createState() => _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().requestPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AuthLayout(
        onBack: () => Navigator.of(context).pop(),
        children: [
          const SizedBox(height: 70),
          EmptyState(
            icon: AgroIcons.mail,
            title: 'Revisa tu correo',
            message:
                'Si existe una cuenta con ${_email.text.trim()}, te enviamos las instrucciones '
                'para restablecer tu contraseña.',
            action: PrimaryButton(
              label: 'Volver a iniciar sesión',
              expand: false,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    }

    return AuthLayout(
      onBack: _loading ? null : () => Navigator.of(context).pop(),
      children: [
        const SizedBox(height: 12),
        const ScreenHeading(
          kicker: 'Recuperar acceso',
          title: '¿Olvidaste tu contraseña?',
          subtitle:
              'Escribe el correo con el que te registraste y te enviaremos un enlace '
              'para crear una nueva.',
        ),
        const SizedBox(height: 26),
        Form(
          key: _formKey,
          child: AgroTextField(
            label: 'Correo electrónico',
            controller: _email,
            hint: 'tucorreo@ejemplo.com',
            icon: AgroIcons.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
            enabled: !_loading,
          ),
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          ErrorBox(title: 'No pudimos enviar el enlace', message: _error!),
          const SizedBox(height: 14),
        ],
        PrimaryButton(
          label: 'Enviar enlace',
          icon: AgroIcons.mail,
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
