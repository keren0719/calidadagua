import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Íconos de trazo del diseño de Figma (mismos paths SVG del prototipo),
/// más algunos adicionales con el mismo estilo para las pantallas nuevas.
enum AgroIcons {
  arrowLeft('<path d="m15 18-6-6 6-6"/>'),
  camera(
    '<path d="M14.5 4 16 7h3a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h3l1.5-3z"/>'
    '<circle cx="12" cy="13" r="3"/>',
  ),
  check('<path d="m5 12 4 4L19 6"/>'),
  chevron('<path d="m9 18 6-6-6-6"/>'),
  clock('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'),
  droplet('<path d="M12 3s6 6.2 6 11a6 6 0 0 1-12 0c0-4.8 6-11 6-11Z"/>'),
  gallery(
    '<rect x="3" y="4" width="18" height="16" rx="2"/>'
    '<circle cx="8.5" cy="9" r="1.5"/><path d="m21 15-5-5L5 20"/>',
  ),
  home('<path d="m3 11 9-8 9 8"/><path d="M5 10v10h14V10M9 20v-6h6v6"/>'),
  leaf(
    '<path d="M20 4C12 4 5 7 5 14c0 3 2 5 5 5 7 0 10-7 10-15Z"/>'
    '<path d="M4 21c2-5 6-8 12-11"/>',
  ),
  scan(
    '<path d="M4 9V6a2 2 0 0 1 2-2h3M15 4h3a2 2 0 0 1 2 2v3M20 15v3a2 2 0 0 1-2 2h-3M9 20H6a2 2 0 0 1-2-2v-3"/>'
    '<path d="M8 12h8"/>',
  ),
  shield('<path d="M12 3 5 6v5c0 4.6 2.8 8 7 10 4.2-2 7-5.4 7-10V6z"/><path d="m9 12 2 2 4-4"/>'),
  sparkles(
    '<path d="m12 3 1.2 3.8L17 8l-3.8 1.2L12 13l-1.2-3.8L7 8l3.8-1.2z"/>'
    '<path d="m19 14 .7 2.3L22 17l-2.3.7L19 20l-.7-2.3L16 17l2.3-.7zM5 14l.6 1.9 1.9.6-1.9.6L5 19l-.6-1.9-1.9-.6 1.9-.6z"/>',
  ),
  // --- Adicionales (mismo estilo de trazo) ---
  user('<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 3.6-7 8-7s8 3 8 7"/>'),
  mail('<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>'),
  lock('<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>'),
  eye(
    '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
  ),
  eyeOff(
    '<path d="M3 3l18 18"/>'
    '<path d="M10.6 5.1A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-3.2 4.2M6.6 6.6C3.9 8.4 2 12 2 12s3.5 7 10 7c1.9 0 3.6-.6 5-1.4"/>'
    '<path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
  ),
  logout(
    '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
  ),
  settings(
    '<path d="M12.2 2h-.4a2 2 0 0 0-2 2v.2a2 2 0 0 1-1 1.7l-.4.3a2 2 0 0 1-2 0l-.2-.1a2 2 0 0 0-2.7.7l-.2.4a2 2 0 0 0 .7 2.7l.2.1a2 2 0 0 1 1 1.7v.5a2 2 0 0 1-1 1.7l-.2.1a2 2 0 0 0-.7 2.7l.2.4a2 2 0 0 0 2.7.7l.2-.1a2 2 0 0 1 2 0l.4.3a2 2 0 0 1 1 1.7v.2a2 2 0 0 0 2 2h.4a2 2 0 0 0 2-2v-.2a2 2 0 0 1 1-1.7l.4-.3a2 2 0 0 1 2 0l.2.1a2 2 0 0 0 2.7-.7l.2-.4a2 2 0 0 0-.7-2.7l-.2-.1a2 2 0 0 1-1-1.7v-.5a2 2 0 0 1 1-1.7l.2-.1a2 2 0 0 0 .7-2.7l-.2-.4a2 2 0 0 0-2.7-.7l-.2.1a2 2 0 0 1-2 0l-.4-.3a2 2 0 0 1-1-1.7V4a2 2 0 0 0-2-2z"/>'
    '<circle cx="12" cy="12" r="3"/>',
  ),
  trash('<path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="m19 6-1 14H6L5 6"/>'),
  server(
    '<rect x="3" y="4" width="18" height="7" rx="2"/><rect x="3" y="13" width="18" height="7" rx="2"/>'
    '<path d="M7 7.5h.01M7 16.5h.01"/>',
  ),
  info('<circle cx="12" cy="12" r="9"/><path d="M12 16v-5M12 8h.01"/>'),
  alert('<path d="M12 3 2 20h20L12 3Z"/><path d="M12 10v4M12 17h.01"/>'),
  refresh('<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/>'),
  close('<path d="M18 6 6 18M6 6l12 12"/>'),
  chart('<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>'),
  help(
    '<circle cx="12" cy="12" r="9"/>'
    '<path d="M9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.6v.6M12 17h.01"/>',
  ),
  userPlus(
    '<circle cx="10" cy="8" r="4"/><path d="M3 21c0-4 3.1-7 7-7 1.4 0 2.7.4 3.8 1"/>'
    '<path d="M19 14v6M16 17h6"/>',
  ),
  target(
    '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
  );

  const AgroIcons(this.paths);

  final String paths;

  String get svg =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#000" stroke-width="1.8" stroke-linecap="round" '
      'stroke-linejoin="round">$paths</svg>';
}

class AgroIcon extends StatelessWidget {
  const AgroIcon(this.icon, {super.key, this.size = 24, this.color});

  final AgroIcons icon;
  final double size;

  /// Si es null usa el color del [IconTheme] actual (como `currentColor` en SVG).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effective = color ?? IconTheme.of(context).color ?? Colors.black;
    return SvgPicture.string(
      icon.svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effective, BlendMode.srcIn),
    );
  }
}
