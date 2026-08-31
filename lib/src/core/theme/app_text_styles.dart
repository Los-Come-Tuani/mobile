import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografías de K'Plan.
///
/// Display serif para títulos de marca, sans para el resto de la interfaz.
abstract final class AppTextStyles {
  static TextStyle get display => GoogleFonts.playfairDisplay(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    height: 1.1,
    color: AppColors.primaryText,
  );

  static TextStyle get headline => GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.primaryText,
  );

  static TextStyle get title => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  /// Etiqueta de los botones: mayúsculas y con tracking, como en el diseño.
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  static TextStyle get link => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
  );

  static TextStyle get hint =>
      GoogleFonts.inter(fontSize: 15, color: AppColors.hintText);

  /// Título de sección del home ("Circuitos completos").
  static TextStyle get sectionTitle => GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
  );

  /// Título de una tarjeta de contenido.
  static TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.primaryText,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  /// Precio y montos.
  static TextStyle get price => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  /// Etiqueta de los bloques de información del recorrido.
  static TextStyle get infoLabel => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary30,
  );
}
