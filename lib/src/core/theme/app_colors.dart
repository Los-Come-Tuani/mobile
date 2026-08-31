import 'package:flutter/material.dart';

/// Identidad visual de K'Plan.
///
/// Única fuente de verdad del color: nada en la app debe declarar un
/// `Color(0x...)` a mano, siempre se referencia desde aquí.
abstract final class AppColors {
  // ── Paleta base ───────────────────────────────────────────────────────────
  /// Tinta principal: títulos, textos y bordes.
  static const Color primary60 = Color(0xFF1E2022);

  /// Color de marca (terracota): acciones principales.
  static const Color primary30 = Color(0xFFD95D39);

  /// Fondo crema de toda la app.
  static const Color primary10 = Color(0xFFF8F4E6);

  /// Acentos secundarios (gráficas, chips, estados).
  static const Color accentSecondaryGreen = Color(0xFF2D6A4F);
  static const Color accentSecondaryBlue = Color(0xFF2F6690);

  // ── Neutros ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFCFC7B4);
  static const Color divider = Color(0xFFE6E0D0);
  static const Color hintText = Color(0xFF9A9484);
  static const Color error = Color(0xFFB3261E);

  // ── Alias semánticos ──────────────────────────────────────────────────────
  // Se usan en los widgets para no acoplarlos al nombre del tono.
  static const Color background = primary10;
  static const Color surface = primary10;
  static const Color card = white;
  static const Color primaryText = primary60;
  static const Color secondaryText = Color(0xFF5C5C5C);
  static const Color primaryButton = primary30;
  static const Color buttonTextLight = primary10;
  static const Color buttonBorder = primary60;
  static const Color fieldFill = Color(0xFFFDFBF3);

  // ── Contenido (chips de categoría, calificaciones) ────────────────────────
  static const Color chipCity = Color(0xFF2B8FD1);
  static const Color chipNature = Color(0xFF0E9AA7);
  static const Color chipCulture = Color(0xFF7B5EA7);
  static const Color star = Color(0xFFF5A623);
  static const Color placeholder = Color(0xFFEDE7D6);
}
