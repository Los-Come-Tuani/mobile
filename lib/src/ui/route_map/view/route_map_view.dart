import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/datasources/repository/location_repository.dart';
import '../../../data/models/route_map.dart';
import '../../../data/models/trip_progress.dart';
import '../../../router/routes.dart';
import '../../widgets/circle_icon_button.dart';
import '../../widgets/map/kplan_map.dart';
import '../../widgets/map/paper_texture.dart';
import '../../widgets/open_with_sheet.dart';
import '../viewmodels/route_map_viewmodel.dart';
import '../widgets/map_cards.dart';

/// El mapa a pantalla completa: el recorrido de un circuito (o el viaje en
/// curso por él) o un lugar suelto. Google Maps y Waze quedan en "Cómo
/// llegar", para la navegación paso a paso.
class RouteMapView extends StatefulWidget {
  const RouteMapView({super.key});

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  final _pageController = PageController(viewportFraction: 0.88);
  late final AnimationController _flight;
  VoidCallback? _flightStep;

  /// Se pidió "mi ubicación" y el GPS todavía no respondía.
  bool _centerOnUserWhenLocated = false;

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
    _pageController.dispose();
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

  /// Deja libres los controles de arriba, la tarjeta de abajo y, a los
  /// lados, media píldora con el nombre de la parada.
  EdgeInsets _mapPadding(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return EdgeInsets.fromLTRB(72, insets.top + 90, 72, insets.bottom + 250);
  }

  void _showWholeRoute(RouteMap map) {
    final target = KPlanMap.fitFor(
      map,
      user: context.read<RouteMapViewModel>().user?.point,
      padding: _mapPadding(context),
    ).fit(_mapController.camera);
    _flyTo(target.center, target.zoom);
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

  void _onPointTap(RouteMap map, RouteMapPoint point) {
    context.read<RouteMapViewModel>().select(point.id);
    if (map.kind != RouteMapKind.preview || !_pageController.hasClients) {
      return;
    }
    final index = map.points.indexWhere((p) => p.id == point.id);
    if (index >= 0) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _onPageChanged(RouteMap map, int index) {
    final point = map.points[index];
    context.read<RouteMapViewModel>().select(point.id);
    _flyTo(point.point, math.max(_mapController.camera.zoom, 15));
  }

  Future<void> _directions(RouteMapPoint point) => openInNavigationApp(
    context,
    latitude: point.point.latitude,
    longitude: point.point.longitude,
  );

  void _openStop(RouteMapPoint point) =>
      context.push(Routes.stopDetailPath(point.id));

  void _endTrip() {
    context.read<RouteMapViewModel>().endTrip();
    _notify('Viaje finalizado');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RouteMapViewModel>();
    final map = viewModel.map;
    final user = viewModel.user;

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
                      padding: _mapPadding(context),
                      selectedId: viewModel.selectedId,
                      onPointTap: (point) => _onPointTap(map, point),
                      onMapTap: map.isTrip
                          ? () => viewModel.select(null)
                          : null,
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
                  onFit: map == null ? null : () => _showWholeRoute(map),
                  onMyLocation: map == null ? null : _centerOnUser,
                  showLocationHint: showLocationHint,
                ),
              ),
            ),
            if (map != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
                          child: MapAttribution(),
                        ),
                        if (map.kind == RouteMapKind.preview)
                          _card(viewModel, map)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _card(viewModel, map),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(RouteMapViewModel viewModel, RouteMap map) {
    switch (map.kind) {
      case RouteMapKind.trip:
        final focused = map.pointById(viewModel.selectedId ?? '') ?? map.next;
        if (focused == null) return TripCompleteCard(onEndTrip: _endTrip);
        return TripStopCard(
          point: focused,
          delay: viewModel.delay,
          leg: viewModel.legFromUser(focused),
          onDirections: () => _directions(focused),
          onOpenStop: () => _openStop(focused),
        );
      case RouteMapKind.preview:
        return StopsCarousel(
          points: map.points,
          controller: _pageController,
          onPageChanged: (index) => _onPageChanged(map, index),
          onDirections: _directions,
          onOpenStop: _openStop,
        );
      case RouteMapKind.place:
        final point = map.points.single;
        return PlaceCard(
          point: point,
          leg: viewModel.legFromUser(point),
          onDirections: () => _directions(point),
        );
    }
  }

  static String? _subtitleOf(RouteMap map) {
    final total = map.points.length;
    return switch (map.kind) {
      RouteMapKind.trip =>
        'Viaje en curso · '
            '${map.points.where((p) => p.status == TripStopStatus.done).length}'
            '/$total paradas',
      RouteMapKind.preview => '$total ${total == 1 ? 'parada' : 'paradas'}',
      RouteMapKind.place => null,
    };
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
