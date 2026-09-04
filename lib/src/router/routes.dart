/// Rutas de la app. Nunca escribas un path a mano en una vista.
abstract final class Routes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const myTrips = '/my-trips';
  static const saved = '/saved';
  static const coupons = '/coupons';
  static const medals = '/medals';
  static const profile = '/profile';

  /// Detalle de un circuito: `/circuit/:id`
  static const circuitDetail = '/circuit/:$circuitId';

  /// Sub-ruta de agendar, relativa al detalle: `/circuit/:id/booking`
  static const bookingSegment = 'booking';

  /// Sub-ruta de solicitar guía en vivo, relativa al detalle:
  /// `/circuit/:id/guide-request`
  static const guideRequestSegment = 'guide-request';

  /// Detalle de una parada: `/stop/:id`
  static const stopDetail = '/stop/:$stopId';

  /// Detalle de un evento: `/event/:id`
  static const eventDetail = '/event/:$eventId';

  /// Circuito creado por el usuario: `/my-circuit/:id`
  static const myCircuit = '/my-circuit/:$collectionId';

  /// Perfil del guía encontrado: `/guide/:id`
  static const guideProfile = '/guide/:$guideId';

  /// Chat con el guía de la solicitud activa: `/guide-chat`.
  ///
  /// No lleva id: siempre opera sobre la única solicitud activa de
  /// `GuideRequestRepository`.
  static const guideChat = '/guide-chat';

  /// Nombres de los parámetros de ruta.
  static const circuitId = 'circuitId';
  static const stopId = 'stopId';
  static const eventId = 'eventId';
  static const collectionId = 'collectionId';
  static const guideId = 'guideId';

  static String circuitDetailPath(String id) => '/circuit/$id';
  static String bookingPath(String id) => '/circuit/$id/booking';
  static String guideRequestPath(String circuitId) =>
      '/circuit/$circuitId/guide-request';
  static String stopDetailPath(String id) => '/stop/$id';
  static String eventDetailPath(String id) => '/event/$id';
  static String myCircuitPath(String id) => '/my-circuit/$id';
  static String guideProfilePath(String id) => '/guide/$id';

  /// Rutas accesibles sin sesión iniciada.
  static const Set<String> public = {welcome, login, register, forgotPassword};
}
