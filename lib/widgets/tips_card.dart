import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'agro_icon.dart';
import 'common.dart';

/// "Para obtener un mejor resultado" (`.tips-card`).
class TipsCard extends StatelessWidget {
  const TipsCard({super.key});

  static const _tips = [
    (AgroIcons.sparkles, 'Buena iluminación', 'Evita sombras y reflejos directos.'),
    (AgroIcons.scan, 'Imagen enfocada', 'Mantén el teléfono estable.'),
    (AgroIcons.camera, 'Encuadre cercano', 'Haz que el detalle ocupe la imagen.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AgroCard(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.borderSoft,
      radius: 23,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Para obtener un mejor resultado',
            style: TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          for (final (icon, title, text) in _tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  IconTile(
                    icon: icon,
                    size: 34,
                    iconSize: 17,
                    radius: 11,
                    background: AppColors.mintSoft,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(text, style: const TextStyle(color: Color(0xFF82938D), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
