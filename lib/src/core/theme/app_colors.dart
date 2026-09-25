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

  // ── Medallas (insignias y niveles) ────────────────────────────────────────
  static const Color medalNone = Color(0xFFC7C0B0);
  static const Color medalBronze = Color(0xFFB08D57);
  static const Color medalSilver = Color(0xFFAEB4BD);
  static const Color medalGold = Color(0xFFE0B84C);

  // ── Circuitos creativos (oficiales de las alcaldías) ──────────────────────
  /// Dorado como las medallas: completarlos da insignias extra.
  static const Color creativeCircuit = medalGold;
  static const Color onCreativeCircuit = primary60;

  // ── Mapa (estilo de las calles y textura de papel) ────────────────────────
  /// La tierra: el papel del mapa, un poco más tostado que el fondo.
  static const Color mapLand = Color(0xFFF1E8D2);

  /// Manzanas y zonas urbanas.
  static const Color mapBlock = Color(0xFFEBDFC4);
  static const Color mapBuilding = Color(0xFFE2D2B0);
  static const Color mapBuildingOutline = Color(0xFFD3C09A);

  /// Calles: blanco hueso con borde arena.
  static const Color mapRoad = Color(0xFFFFFCF3);
  static const Color mapRoadCasing = Color(0xFFD9C8A4);

  /// Agua en azul acuarela, de la familia de [accentSecondaryBlue].
  static const Color mapWater = Color(0xFFA7C4D2);
  static const Color mapWaterEdge = Color(0xFF86ABC0);

  /// Parques y bosques en verde suave, de la familia de
  /// [accentSecondaryGreen].
  static const Color mapPark = Color(0xFFCEDBB8);
  static const Color mapWood = Color(0xFFBFD0A8);

  /// Nombres de calles, barrios y ciudades, con halo del color del papel.
  static const Color mapLabel = secondaryText;
  static const Color mapLabelHalo = primary10;
  static const Color mapWaterLabel = accentSecondaryBlue;

  /// Grano, fibras y viñeta de la textura de papel.
  static const Color paperGrain = Color(0xFF7A6A4E);

  // ── Recorrido sobre el mapa ───────────────────────────────────────────────
  /// Tramos ya recorridos.
  static const Color routeDone = primary30;

  /// El tramo hacia la siguiente parada.
  static const Color routeCurrent = star;

  /// Lo que falta del recorrido.
  static const Color routeUpcoming = accentSecondaryBlue;

  /// Tramos hacia paradas que el turista saltó.
  static const Color routeSkipped = outline;

  /// La flecha de "estás aquí".
  static const Color userLocation = star;
}
