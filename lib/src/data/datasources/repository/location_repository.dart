import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/logger.dart';
import '../../models/user_location.dart';

/// Si la app puede usar la ubicación del turista.
enum LocationAccess {
  /// Todavía no se le preguntó.
  unknown,
  granted,

  /// Dijo que no en esta sesión.
  denied,

  /// Negado para siempre: sólo se cambia desde los ajustes del teléfono.
  deniedForever,

  /// El GPS del teléfono está apagado.
  serviceDisabled,
}

/// Dónde está el turista, para dibujarlo en el mapa.
///
/// Sólo escucha el GPS mientras algún mapa lo pida ([startTracking] y
/// [stopTracking] llevan la cuenta), así no gasta batería de más. Nunca
/// pregunta por el permiso por su cuenta: eso lo hace [requestAccess].
class LocationRepository extends ChangeNotifier {
  /// Más despacio que esto (m/s) cuenta como quieto: el rumbo del GPS ya no
  /// es confiable.
  static const double _movingSpeed = 0.7;

  LocationAccess _access = LocationAccess.unknown;
  UserLocation? _location;
  StreamSubscription<Position>? _subscription;
  int _trackers = 0;
  bool _hasAsked = false;

  LocationAccess get access => _access;
  bool get isGranted => _access == LocationAccess.granted;

  /// La última posición conocida; `null` sin permiso o mientras llega.
  UserLocation? get location => isGranted ? _location : null;

  /// Un mapa que quiere mostrar al turista. Si ya dio permiso, empieza a
  /// seguirlo; si no, espera a [requestAccess].
  void startTracking() {
    _trackers++;
    if (_trackers == 1) unawaited(_resume());
  }

  void stopTracking() {
    if (_trackers == 0) return;
    _trackers--;
    if (_trackers == 0) {
      _subscription?.cancel();
      _subscription = null;
    }
  }

  /// Pregunta por el permiso si hace falta y, con él, sigue al turista.
  Future<LocationAccess> requestAccess() async {
    await _updateAccess(request: true);
    _listen();
    return _access;
  }

  /// Abre los ajustes del teléfono: la única salida si el permiso se negó
  /// para siempre o el GPS está apagado.
  Future<void> openSettings() async {
    try {
      if (_access == LocationAccess.serviceDisabled) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (e) {
      log.w('LocationRepository.openSettings: $e');
    }
  }

  Future<void> _resume() async {
    await _updateAccess(request: false);
    _listen();
  }

  Future<void> _updateAccess({required bool request}) async {
    var access = LocationAccess.unknown;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        access = LocationAccess.serviceDisabled;
      } else {
        var permission = await Geolocator.checkPermission();
        if (request && permission == LocationPermission.denied) {
          _hasAsked = true;
          permission = await Geolocator.requestPermission();
        }
        access = switch (permission) {
          LocationPermission.always ||
          LocationPermission.whileInUse => LocationAccess.granted,
          LocationPermission.deniedForever => LocationAccess.deniedForever,
          LocationPermission.denied =>
            _hasAsked ? LocationAccess.denied : LocationAccess.unknown,
          LocationPermission.unableToDetermine => LocationAccess.unknown,
        };
      }
    } catch (e) {
      // Sin el plugin (pruebas, escritorio) el mapa sigue, sin ubicación.
      log.w('LocationRepository: $e');
    }
    if (access == _access) return;
    _access = access;
    notifyListeners();
  }

  void _listen() {
    if (!isGranted || _trackers == 0 || _subscription != null) return;
    unawaited(_seedWithLastKnown());
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen(
          _onPosition,
          onError: (Object e) => log.w('LocationRepository.stream: $e'),
        );
  }

  /// La última posición del teléfono, para no esperar al primer dato del GPS.
  Future<void> _seedWithLastKnown() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && _location == null) _onPosition(last);
    } catch (e) {
      log.w('LocationRepository.lastKnown: $e');
    }
  }

  void _onPosition(Position position) {
    final isMoving = position.speed >= _movingSpeed && position.heading >= 0;
    _location = UserLocation(
      point: LatLng(position.latitude, position.longitude),
      heading: isMoving ? position.heading : null,
      accuracy: position.accuracy,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
