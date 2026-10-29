import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'agro_icon.dart';

class AgroNavItem {
  const AgroNavItem(this.icon, this.label);

  final AgroIcons icon;
  final String label;
}

/// Barra inferior del diseño (blanca, borde superior, ícono + texto).
class AgroBottomNav extends StatelessWidget {
  const AgroBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AgroNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        border: Border(top: BorderSide(color: Color(0xFFDCEAE4))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(item: items[i], active: i == currentIndex, onTap: () => onTap(i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap});

  final AgroNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.greenStrong : AppColors.navInactive;
    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: SizedBox(
          width: 80,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AgroIcon(item.icon, size: 20, color: color),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
