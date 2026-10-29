import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'agro_icon.dart';

/// Campo de texto con etiqueta superior e ícono, al estilo del diseño.
class AgroTextField extends StatefulWidget {
  const AgroTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onSubmitted,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final AgroIcons? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final TextCapitalization textCapitalization;

  @override
  State<AgroTextField> createState() => _AgroTextFieldState();
}

class _AgroTextFieldState extends State<AgroTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppText.label),
        const SizedBox(height: 7),
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          textCapitalization: widget.textCapitalization,
          autocorrect: !widget.obscure,
          enableSuggestions: !widget.obscure,
          style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: AgroIcon(widget.icon!, size: 19, color: AppColors.mutedLight),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: AgroIcon(
                      _hidden ? AgroIcons.eye : AgroIcons.eyeOff,
                      size: 19,
                      color: AppColors.mutedLight,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Validaciones comunes de formularios.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo electrónico.';
    if (!_email.hasMatch(v)) return 'Ingresa un correo válido.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña.';
    return null;
  }

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Usa al menos 8 caracteres.';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Combina letras y números.';
    }
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 3) return 'Ingresa tu nombre completo.';
    return null;
  }
}
