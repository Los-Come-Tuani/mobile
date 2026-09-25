import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/trip_progress.dart';

/// Pin en forma de gota de una parada: cabeza redonda con un círculo blanco
/// (el número, o un check si ya se visitó) y la punta sobre el lugar.
class StopPin extends StatelessWidget {
  const StopPin({
    super.key,
    this.number,
    this.status = TripStopStatus.pending,
    this.emphasized = false,
    this.icon = Icons.place,
  });

  /// `null` en un lugar suelto: se muestra [icon] en su lugar.
  final int? number;
  final TripStopStatus status;

  /// La siguiente parada o la elegida: más grande y con un halo que late.
  final bool emphasized;
  final IconData icon;

  static const Size _normal = Size(32, 43);
  static const Size _emphasized = Size(42, 56);

  static Size sizeFor({required bool emphasized}) =>
      emphasized ? _emphasized : _normal;

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(emphasized: emphasized);
    final color = switch (status) {
      TripStopStatus.done => AppColors.accentSecondaryGreen,
      TripStopStatus.skipped => AppColors.hintText,
      TripStopStatus.next || TripStopStatus.pending => AppColors.primary30,
    };
    final inner = size.width * 0.62;
    final content = switch (status) {
      TripStopStatus.done => Icon(
        Icons.check,
        size: inner * 0.72,
        color: color,
      ),
      TripStopStatus.skipped => Icon(
        Icons.remove,
        size: inner * 0.72,
        color: color,
      ),
      _ when number == null => Icon(icon, size: inner * 0.7, color: color),
      _ => Text(
        '$number',
        textScaler: TextScaler.noScaling,
        style: AppTextStyles.mapPin.copyWith(
          fontSize: inner * 0.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    };

    return SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (emphasized)
            Positioned(
              left: size.width / 2 - _Pulse.size / 2,
              top: size.width / 2 - _Pulse.size / 2,
              child: _Pulse(color: color),
            ),
          Positioned.fill(child: CustomPaint(painter: _DropPainter(color))),
          Positioned(
            left: (size.width - inner) / 2,
            top: (size.width - inner) / 2,
            width: inner,
            height: inner,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Center(child: content),
            ),
          ),
        ],
      ),
    );
  }
}

/// El punto de encuentro del circuito: gota verde con "Inicio" y una
/// bandera.
class StartPin extends StatelessWidget {
  const StartPin({super.key});

  static const Size size = Size(42, 56);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _DropPainter(AppColors.accentSecondaryGreen),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 5,
            height: size.width - 10,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Inicio',
                    maxLines: 1,
                    textScaler: TextScaler.noScaling,
                    style: AppTextStyles.mapPin.copyWith(
                      fontSize: 9,
                      height: 1,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(Icons.flag, size: 14, color: AppColors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El nombre de un lugar en una píldora blanca, bajo su pin.
class PinLabel extends StatelessWidget {
  const PinLabel(this.text, {super.key, this.emphasized = false});

  final String text;
  final bool emphasized;

  static const double maxWidth = 170;
  static const double height = 26;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      constraints: const BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(height / 2),
        border: emphasized
            ? Border.all(color: AppColors.primary30, width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary60.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        // La píldora tiene alto fijo: el marcador del mapa no crece.
        textScaler: TextScaler.noScaling,
        style: AppTextStyles.mapPin,
      ),
    );
  }
}

/// "Estás aquí": círculo blanco con aro amarillo y una flecha que apunta
/// hacia donde se mueve el turista (un punto si está quieto).
class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key, this.heading});

  /// Grados desde el norte; `null` si está quieto.
  final double? heading;

  static const double size = 36;

  @override
  Widget build(BuildContext context) {
    final heading = this.heading;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.userLocation, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary60.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: heading == null
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.userLocation,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : Transform.rotate(
              angle: heading * math.pi / 180,
              child: const Icon(
                Icons.navigation,
                size: 20,
                color: AppColors.userLocation,
              ),
            ),
    );
  }
}

/// Halo que se expande y se desvanece detrás del pin de la siguiente parada.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.color});

  final Color color;

  static const double size = 64;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_controller.value);
          return Container(
            width: _Pulse.size,
            height: _Pulse.size,
            alignment: Alignment.center,
            child: Container(
              width: _Pulse.size * (0.45 + 0.55 * t),
              height: _Pulse.size * (0.45 + 0.55 * t),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.35 * (1 - t)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// La gota: un círculo arriba que se afina hasta una punta abajo, con borde
/// blanco y sombra para que se despegue del papel.
class _DropPainter extends CustomPainter {
  const _DropPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final h = size.height;
    final path = Path()
      ..moveTo(r, h)
      ..cubicTo(r * 0.75, h - r * 0.5, 0, r * 1.55, 0, r)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..cubicTo(size.width, r * 1.55, r * 1.25, h - r * 0.5, r, h)
      ..close();

    canvas.drawShadow(path, AppColors.primary60, 3, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.white,
    );
  }

  @override
  bool shouldRepaint(_DropPainter oldDelegate) => oldDelegate.color != color;
}
