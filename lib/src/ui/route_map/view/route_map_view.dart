import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/repository/location_repository.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/stop.dart';
import '../../../data/models/trip_progress.dart';
import '../../../router/routes.dart';
import '../../stop_detail/view/qr_generator_view.dart';
import '../../stop_detail/view/qr_scanner_view.dart';
import '../../widgets/badge_earned_overlay.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/drop_reason_sheet.dart';
import '../../widgets/map/kplan_map.dart';
import '../../widgets/map/paper_texture.dart';
import '../../widgets/open_with_sheet.dart';
import '../viewmodels/route_map_viewmodel.dart';
import '../widgets/stop_sheet.dart';

/// El mapa a pantalla completa: el recorrido de un circuito (o el viaje en
/// curso por él) o un lugar suelto. Al tocar una parada se acerca y abre su
/// hoja, desde donde se escanea el QR, se salta o se abre Google Maps o Waze
/// para llegar, sin salir del mapa.
class RouteMapView extends StatefulWidget {
  const RouteMapView({super.key});

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  late final AnimationController _flight;
  VoidCallback? _flightStep;

  /// Se pidió "mi ubicación" y el GPS todavía no respondía.
  bool _centerOnUserWhenLocated = false;

  /// Qué fracción de la pantalla ocupa la hoja abierta.
  double _sheetExtent = StopSheet.initialSize;

  /// Al tocar una parada, el mapa se acerca por lo menos hasta aquí.
  static const double _focusZoom = 16.5;

  /// Alto de la barra de arriba, sin el área segura.
  static const double _topBarHeight = 64;

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _flight.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final viewModel = context.read<RouteMapViewModel>();
    await viewModel.load();
    // Siguiendo un viaje, la ubicación se pide de una vez (si nunca se
    // preguntó); en el resto de mapas, sólo al tocar "mi ubicación".
    if (mounted &&
        viewModel.isTrip &&
        viewModel.locationAccess == LocationAccess.unknown) {
      await viewModel.requestLocation();
    }
  }

  void _notify(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  /// Mueve la cámara con una animación corta.
  void _flyTo(LatLng center, double zoom) {
    final camera = _mapController.camera;
    final from = camera.center;
    final fromZoom = camera.zoom;
    double lerp(double a, double b, double t) => a + (b - a) * t;

    if (_flightStep case final previous?) _flight.removeListener(previous);
    void step() {
      final t = Curves.easeInOutCubic.transform(_flight.value);
      _mapController.move(
        LatLng(
          lerp(from.latitude, center.latitude, t),
          lerp(from.longitude, center.longitude, t),
        ),
        lerp(fromZoom, zoom, t),
      );
    }

    _flightStep = step;
    _flight
      ..addListener(step)
      ..forward(from: 0);
  }

  /// Deja libres los controles de arriba, la hoja si está abierta y, a los
  /// lados, media píldora con el nombre de la parada.
  EdgeInsets _mapPadding({required bool withSheet}) {
    final insets = MediaQuery.paddingOf(context);
    final bottom = withSheet
        ? MediaQuery.sizeOf(context).height * _sheetExtent + 24
        : insets.bottom + 90;
    return EdgeInsets.fromLTRB(72, insets.top + 90, 72, bottom);
  }

  void _showWholeRoute(RouteMap map, {required bool withSheet}) {
    final target = KPlanMap.fitFor(
      map,
      user: context.read<RouteMapViewModel>().user?.point,
      padding: _mapPadding(withSheet: withSheet),
    ).fit(_mapController.camera);
    _flyTo(target.center, target.zoom);
  }

  /// Abre la hoja de [point] y acerca el mapa: el pin queda en el medio de
  /// lo que la hoja deja libre arriba.
  void _selectPoint(RouteMapPoint point) {
    context.read<RouteMapViewModel>().select(point.id);
    setState(() => _sheetExtent = StopSheet.initialSize);

    final camera = _mapController.camera;
    final zoom = math.max(camera.zoom, _focusZoom);
    final height = MediaQuery.sizeOf(context).height;
    final topBar = MediaQuery.paddingOf(context).top + _topBarHeight;
    final shift = Offset(0, (height * StopSheet.initialSize - topBar) / 2);
    _flyTo(
      camera.unprojectAtZoom(
        camera.projectAtZoom(point.point, zoom) + shift,
        zoom,
      ),
      zoom,
    );
  }

  void _closeSheet() => context.read<RouteMapViewModel>().select(null);

  /// Mientras se arrastra la hoja, la atribución sube con ella.
  void _onSheetExtentChanged(double extent) {
    if (extent == _sheetExtent) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _sheetExtent = extent);
    });
  }

  Future<void> _centerOnUser() async {
    final viewModel = context.read<RouteMapViewModel>();
    final user = viewModel.user;
    if (user != null) {
      _flyTo(user.point, math.max(_mapController.camera.zoom, 16));
      return;
    }

    final access = await viewModel.requestLocation();
    if (!mounted) return;
    switch (access) {
      case LocationAccess.granted:
        _centerOnUserWhenLocated = true;
        _notify('Buscando tu ubicación…');
      case LocationAccess.deniedForever || LocationAccess.serviceDisabled:
        _notify(
          access == LocationAccess.serviceDisabled
              ? 'Enciende la ubicación del teléfono para verte en el mapa'
              : 'Permite la ubicación en los ajustes para verte en el mapa',
          action: SnackBarAction(
            label: 'Ajustes',
            textColor: AppColors.primary10,
            onPressed: viewModel.openLocationSettings,
          ),
        );
      case LocationAccess.denied || LocationAccess.unknown:
        _notify('Sin tu ubicación, el mapa no puede mostrarte');
    }
  }

  /// Escanea el QR de la parada; si coincide, confirma la visita y muestra
  /// la insignia ganada.
  Future<void> _scanQr(Stop stop) async {
    final matched = await showQrScanner(context, stopId: stop.id);
    if (matched != true || !mounted) return;

    final earnedBadge = context.read<RouteMapViewModel>().confirmVisit(stop);
    if (earnedBadge) {
      await showBadgeEarnedAnimation(context, category: stop.category);
    } else {
      _notify('¡Visita a ${stop.name} confirmada!');
    }
  }

  /// Pantalla de demo con el QR de la parada, para escanearlo desde otro
  /// teléfono (no hay carteles reales en el catálogo).
  void _showDemoQr(Stop stop) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) =>
          QrGeneratorView(stopId: stop.id, stopName: stop.name),
    ),
  );

  Future<void> _skip(RouteMapPoint point) async {
    final reason = await showDropReasonSheet(
      context,
      title: '¿Por qué saltas ${point.name}?',
    );
    if (reason == null || !mounted) return;
    context.read<RouteMapViewModel>().skipStop(point.id, reason);
  }

  Future<void> _directions(RouteMapPoint point) => openInNavigationApp(
    context,
    latitude: point.point.latitude,
    longitude: point.point.longitude,
  );

  void _endTrip() {
    context.read<RouteMapViewModel>().endTrip();
    _notify('Viaje finalizado');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RouteMapViewModel>();
    final map = viewModel.map;
    final user = viewModel.user;
    final selected = map?.pointById(viewModel.selectedId ?? '');
    final insets = MediaQuery.paddingOf(context);
    final height = MediaQuery.sizeOf(context).height;

    if (_centerOnUserWhenLocated && user != null) {
      _centerOnUserWhenLocated = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _flyTo(user.point, math.max(_mapController.camera.zoom, 16));
        }
      });
    }

    final access = viewModel.locationAccess;
    final showLocationHint =
        map != null &&
        map.isTrip &&
        (access == LocationAccess.denied ||
            access == LocationAccess.deniedForever ||
            access == LocationAccess.serviceDisabled);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.mapLand,
        body: Stack(
          children: [
            Positioned.fill(
              child: map == null
                  ? _Backdrop(
                      isBusy: viewModel.isBusy,
                      message:
                          viewModel.errorMessage ??
                          'Este circuito todavía no tiene paradas',
                    )
                  : KPlanMap(
                      map: map,
                      user: user,
                      controller: _mapController,
                      padding: _mapPadding(withSheet: false),
                      selectedId: viewModel.selectedId,
                      onPointTap: _selectPoint,
                      onMapTap: _closeSheet,
                      showAttribution: false,
                    ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _TopBar(
                  title: viewModel.title,
                  subtitle: map == null ? null : _subtitleOf(map),
                  isPlace: map?.kind == RouteMapKind.place,
                  onFit: map == null
                      ? null
                      : () => _showWholeRoute(map, withSheet: selected != null),
                  onMyLocation: map == null ? null : _centerOnUser,
                  showLocationHint: showLocationHint,
                ),
              ),
            ),
            if (map != null && selected == null)
              Positioned(
                left: 16,
                right: 16,
                bottom: insets.bottom + 44,
                child: Center(
                  child: map.isTrip && map.next == null
                      ? _TripCompletePill(onEndTrip: _endTrip)
                      : const _HintChip(),
                ),
              ),
            if (map != null)
              Positioned(
                left: 16,
                bottom: selected == null
                    ? insets.bottom + 12
                    : height * _sheetExtent + 8,
                child: const MapAttribution(),
              ),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: child,
                ),
                child: map == null || selected == null
                    ? const SizedBox.shrink()
                    : _sheetFor(viewModel, map, selected),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetFor(
    RouteMapViewModel viewModel,
    RouteMap map,
    RouteMapPoint point,
  ) {
    final stop = point.stop;
    final next = map.next;
    final isTrip = map.isTrip;
    final isAhead =
        point.status == TripStopStatus.next ||
        point.status == TripStopStatus.pending;
    // En un viaje se escanea para confirmar la visita; fuera de él, sólo
    // para ganar la insignia si todavía no se tiene.
    final canScan =
        stop != null &&
        (isTrip
            ? point.status != TripStopStatus.done
            : stop.hasBadge && !viewModel.hasClaimedBadge(stop.id));

    return StopSheet(
      key: ValueKey(point.id),
      point: point,
      total: map.points.length,
      isTrip: isTrip,
      progress: viewModel.progressOf(point.id),
      delay: viewModel.delay,
      leg: viewModel.legFromUser(point),
      event: point.isStop ? null : viewModel.event,
      hasClaimedBadge: stop != null && viewModel.hasClaimedBadge(stop.id),
      next: next != null && next.id != point.id ? next : null,
      onClose: _closeSheet,
      onDirections: () => _directions(point),
      onScanQr: canScan ? () => _scanQr(stop) : null,
      onShowDemoQr: canScan ? () => _showDemoQr(stop) : null,
      onSkip: isTrip && isAhead ? () => _skip(point) : null,
      onGoToNext: next == null ? null : () => _selectPoint(next),
      onExtentChanged: _onSheetExtentChanged,
    );
  }

  static String? _subtitleOf(RouteMap map) {
    final total = map.points.length;
    switch (map.kind) {
      case RouteMapKind.trip:
        final next = map.next;
        if (next == null) return '¡Recorrido completo!';
        final arrival = next.arrival;
        return arrival == null
            ? 'Siguiente: ${next.name}'
            : 'Siguiente: ${next.name} · ${Formatters.clock(arrival)}';
      case RouteMapKind.preview:
        return '$total ${total == 1 ? 'parada' : 'paradas'}';
      case RouteMapKind.place:
        return null;
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.isPlace,
    required this.onFit,
    required this.onMyLocation,
    required this.showLocationHint,
  });

  final String title;
  final String? subtitle;

  /// Un lugar suelto: el botón de encuadre centra ese lugar.
  final bool isPlace;
  final VoidCallback? onFit;
  final VoidCallback? onMyLocation;
  final bool showLocationHint;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              CircleIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Regresar',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go(Routes.home),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: AppColors.white,
                  elevation: 2,
                  shadowColor: AppColors.primary60.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleIconButton(
                icon: isPlace
                    ? Icons.center_focus_strong_outlined
                    : Icons.route_outlined,
                tooltip: isPlace ? 'Centrar el lugar' : 'Ver todo el recorrido',
                onPressed: onFit,
              ),
              const SizedBox(width: 8),
              CircleIconButton(
                icon: Icons.my_location,
                tooltip: 'Mi ubicación',
                color: AppColors.accentSecondaryBlue,
                onPressed: onMyLocation,
              ),
            ],
          ),
          if (showLocationHint) ...[
            const SizedBox(height: 10),
            Material(
              color: AppColors.primary60,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onMyLocation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_off_outlined,
                        size: 16,
                        color: AppColors.primary10,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Activa tu ubicación para verte en el mapa',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mientras no se toca ninguna parada, el mapa queda libre y sólo se sugiere
/// qué hacer.
class _HintChip extends StatelessWidget {
  const _HintChip();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary60.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.touch_app_outlined,
              size: 16,
              color: AppColors.primary10,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Toca una parada para ver su información',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuando ya no quedan paradas por visitar: invita a cerrar el viaje.
class _TripCompletePill extends StatelessWidget {
  const _TripCompletePill({required this.onEndTrip});

  final VoidCallback onEndTrip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary60,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, color: AppColors.star),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '¡Recorrido completo!',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const StadiumBorder(),
              ),
              onPressed: onEndTrip,
              child: const Text('Finalizar viaje'),
            ),
          ],
        ),
      ),
    );
  }
}

/// El papel del mapa mientras carga, o con un aviso si no hay qué mostrar.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.isBusy, required this.message});

  final bool isBusy;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.mapLand),
        const PaperTexture(),
        Center(
          child: isBusy
              ? const CircularProgressIndicator(color: AppColors.primary30)
              : Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 44,
                        color: AppColors.hintText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
