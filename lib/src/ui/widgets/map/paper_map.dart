import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_camera.dart';
import 'map_pins.dart';
import 'map_scene.dart';
import 'map_surface.dart';
import 'route_line_style.dart';

/// El mapa sin MapLibre, que sólo corre en Android e iOS: el recorrido y sus
/// pines sobre el papel, sin calles. Es lo que se ve en las pruebas y en
/// escritorio, con los mismos pines y la misma escena que el mapa nativo.
class PaperMap extends MapSurfaceWidget {
  const PaperMap({
    super.key,
    required super.map,
    required super.controller,
    required super.interactive,
    required super.compact,
    required super.padding,
    super.user,
    super.selectedId,
    super.onPointTap,
    super.onMapTap,
  });

  @override
  State<PaperMap> createState() => _PaperMapState();
}

class _PaperMapState extends State<PaperMap> implements MapSurface {
  /// Espacio entre la punta del pin y su nombre.
  static const double _labelGap = 3;

  MapCamera? _camera;
  Size _size = Size.zero;

  @override
  Size get size => _size;

  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);
  }

  @override
  void didUpdateWidget(PaperMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach(this);
      widget.controller.attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    super.dispose();
  }

  @override
  Future<MapCamera?> camera() => SynchronousFuture(_camera);

  @override
  Future<void> flyTo(MapCamera target) {
    if (mounted) setState(() => _camera = target);
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        if (_size.isEmpty || !_size.isFinite) return const SizedBox.shrink();
        final camera = _camera ??= fitRoute(
          widget.map,
          user: widget.user?.point,
          padding: widget.padding,
          size: _size,
        );
        final scene = MapScene.of(
          widget.map,
          user: widget.user,
          selectedId: widget.selectedId,
          compact: widget.compact,
        );
        final zoomedLabels = camera.zoom >= MapZoom.labels;
        final user = widget.user;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onMapTap,
          child: SizedBox.fromSize(
            size: _size,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _RoutePainter(scene, camera)),
                ),
                for (final pin in scene.pins)
                  _pinAt(
                    pin,
                    camera.toScreen(pin.position, _size),
                    withLabel:
                        pin.label != null && (pin.labelAlways || zoomedLabels),
                  ),
                if (user != null)
                  _centeredAt(
                    camera.toScreen(user.point, _size),
                    UserLocationMarker.size,
                    IgnorePointer(
                      child: UserLocationMarker(heading: user.heading),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// La punta del pin queda sobre el lugar y el nombre, debajo.
  Widget _pinAt(ScenePin pin, Offset tip, {required bool withLabel}) {
    final emphasized = pin.pulse != null;
    final pinSize = pin.point == null
        ? StartPin.size
        : StopPin.sizeFor(emphasized: emphasized);
    final width = withLabel ? PinLabel.maxWidth : pinSize.width;
    final point = pin.point;
    final pulse = pin.pulse;

    return Positioned(
      left: tip.dx - width / 2,
      top: tip.dy - pinSize.height,
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: point == null || widget.onPointTap == null
            ? null
            : () => widget.onPointTap!(point),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            if (pulse != null)
              Positioned(
                left: width / 2 - PinPulse.size / 2,
                top: pinSize.width / 2 - PinPulse.size / 2,
                child: PinPulse(color: pulse),
              ),
            Column(
              children: [
                pin.pin.widget,
                if (withLabel) ...[
                  const SizedBox(height: _labelGap),
                  pin.label!.widget,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _centeredAt(Offset center, double size, Widget child) =>
      Positioned(
        left: center.dx - size / 2,
        top: center.dy - size / 2,
        width: size,
        height: size,
        child: child,
      );
}

/// Los tramos como trazos lisos: en el papel no hace falta más.
class _RoutePainter extends CustomPainter {
  _RoutePainter(this.scene, this.camera);

  final MapScene scene;
  final MapCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    for (final style in RouteLineStyle.drawOrder) {
      final line = RouteLineStyle.of(style);
      for (final segment in scene.segments.where((s) => s.style == style)) {
        final path = Path()
          ..addPolygon([
            for (final point in segment.points) camera.toScreen(point, size),
          ], false);
        if (line.bordered) {
          canvas.drawPath(
            path,
            _stroke(
              RouteLineStyle.borderColor,
              line.width + 2 * RouteLineStyle.borderWidth,
            ),
          );
        }
        canvas.drawPath(path, _stroke(line.color, line.width));
      }
    }
  }

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) => true;
}
