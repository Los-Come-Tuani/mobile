import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';

/// Pinta los widgets de los pines fuera de pantalla y los entrega en PNG,
/// que es como MapLibre recibe sus íconos. Así el pin del mapa nativo es el
/// mismo widget que el del mapa de papel.
abstract final class MapIconRenderer {
  /// Aire alrededor del widget para que su sombra no quede cortada. El mapa
  /// lo descuenta al anclar cada ícono.
  static const double margin = 8;

  /// Ningún pin ni nombre pasa de esto.
  static const Size _maxSize = Size(400, 200);

  /// [widget] en PNG a [pixelRatio], con [margin] alrededor. MapLibre lo
  /// muestra a la densidad de la pantalla, así que mide lo mismo que el
  /// widget.
  static Future<Uint8List> render(
    Widget widget, {
    required ui.FlutterView view,
    required double pixelRatio,
  }) async {
    // Sin esperar, los números y los nombres saldrían con otra fuente.
    try {
      await GoogleFonts.pendingFonts([AppTextStyles.mapPin]);
    } catch (e) {
      log.w('MapIconRenderer: no cargó la fuente de los pines: $e');
    }

    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: view,
      child: boundary,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.loose(_maxSize),
        physicalConstraints: BoxConstraints.loose(_maxSize * pixelRatio),
        devicePixelRatio: pixelRatio,
      ),
    );
    final pipelineOwner = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();

    final focusManager = FocusManager();
    final buildOwner = BuildOwner(focusManager: focusManager);
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        data: MediaQueryData(devicePixelRatio: pixelRatio),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(padding: const EdgeInsets.all(margin), child: widget),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    try {
      buildOwner
        ..buildScope(root)
        ..finalizeTree();
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        return bytes!.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      RenderObjectToWidgetAdapter<RenderBox>(
        container: boundary,
      ).attachToRenderTree(buildOwner, root);
      buildOwner
        ..buildScope(root)
        ..finalizeTree();
      pipelineOwner.rootNode = null;
      renderView.dispose();
      pipelineOwner.dispose();
      focusManager.dispose();
    }
  }
}
