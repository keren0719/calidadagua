import 'package:flutter/material.dart';

/// Paleta tomada del diseño de Figma (Agrovision AI Mobile App).
class AppColors {
  AppColors._();

  // Marca
  static const forest = Color(0xFF123F33); // botones principales, logo
  static const forestBorder = Color(0xFF195F4B);
  static const green = Color(0xFF249B70); // acentos, "más certeza."
  static const greenStrong = Color(0xFF188461); // íconos activos
  static const greenDark = Color(0xFF167A59);
  static const greenBright = Color(0xFF34B784);
  static const progressStart = Color(0xFF26A676);
  static const progressEnd = Color(0xFF4EB4D7);

  // Texto
  static const title = Color(0xFF143D32);
  static const text = Color(0xFF173C33);
  static const textSoft = Color(0xFF30574C);
  static const muted = Color(0xFF71867F);
  static const mutedLight = Color(0xFF82978F);
  static const navInactive = Color(0xFF8AA097);

  // Superficies
  static const background = Color(0xFFF8FBF9);
  static const surface = Colors.white;
  static const mint = Color(0xFFDFF5EA);
  static const mintSoft = Color(0xFFE8F6EF);
  static const mintSurface = Color(0xFFF0FAF5);
  static const chip = Color(0xFFDCF6E9);

  // Bordes
  static const border = Color(0xFFDEEBE6);
  static const borderSoft = Color(0xFFE1EBE7);
  static const borderInput = Color(0xFFD8E8E1);
  static const borderMint = Color(0xFFCCE8DC);
  static const borderDashed = Color(0xFFA7C9BB);

  // Azul (agua / información)
  static const blue = Color(0xFF2585AC);
  static const blueSurface = Color(0xFFE1F1F7);

  // Estados
  static const errorText = Color(0xFF983E32);
  static const errorSurface = Color(0xFFFFF3F1);
  static const errorBorder = Color(0xFFF4CBC4);
  static const errorStrong = Color(0xFFE26D5D);

  static const warningText = Color(0xFF8A5A12);
  static const warningSurface = Color(0xFFFFF7E8);
  static const warningBorder = Color(0xFFF2DDB0);
  static const warningStrong = Color(0xFFE0A030);

  // Overlays de las tarjetas de análisis
  static const plantOverlay = [Color(0xF5082C22), Color(0xB3082C22), Color(0x1F082C22)];
  static const waterOverlay = [Color(0xF508354A), Color(0xB308415C), Color(0x1F08415C)];
  static const plantFallback = Color(0xFF2F7457);
  static const waterFallback = Color(0xFF286E8F);
}
