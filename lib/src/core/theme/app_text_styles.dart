import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografías de K'Plan.
///
/// Inknut Antiqua solo para el titular de marca ("Bienvenido"), Poppins para
/// el resto de la interfaz, como en los wireframes.
abstract final class AppTextStyles {
  /// Titular de marca del manual: -0.2 % de tracking e interlineado de 1.4.
  static TextStyle get display => GoogleFonts.inknutAntiqua(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 40 * -0.002,
    color: AppColors.primaryText,
  );

  static TextStyle get headline => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.primaryText,
  );

  /// Encabezado de las pantallas principales ("Descubre tu próximo plan").
  static TextStyle get pageTitle => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
    color: AppColors.primaryText,
  );

  /// Pregunta de cada paso del registro ("¿Cómo te llamas?").
  static TextStyle get stepTitle => GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.primaryText,
  );

  /// Etiqueta en mayúsculas sobre un campo ("CORREO ELECTRÓNICO").
  static TextStyle get fieldLabel => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  static TextStyle get title => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  /// Etiqueta de los botones: mayúsculas y con tracking, como en el diseño.
  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  static TextStyle get link => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
  );

  static TextStyle get hint =>
      GoogleFonts.poppins(fontSize: 15, color: AppColors.hintText);

  /// Título de sección del home ("Circuitos completos").
  static TextStyle get sectionTitle => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
  );

  /// Título de una tarjeta de contenido.
  static TextStyle get cardTitle => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.primaryText,
  );

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  /// Precio y montos.
  static TextStyle get price => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  /// Etiqueta de los bloques de información del recorrido.
  static TextStyle get infoLabel => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary30,
  );

  /// Nombres de calles y barrios dentro del mapa.
  static TextStyle get mapLabel => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mapLabel,
  );

  /// Pueblos y ciudades dentro del mapa.
  static TextStyle get mapPlace => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  /// Ríos, lagos y mares dentro del mapa.
  static TextStyle get mapWater => GoogleFonts.poppins(
    fontSize: 12,
    fontStyle: FontStyle.italic,
    color: AppColors.mapWaterLabel,
  );

  /// Nombre de una parada en la píldora bajo su pin.
  static TextStyle get mapPin => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.primaryText,
  );
}
