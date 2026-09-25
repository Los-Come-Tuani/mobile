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

  /// Sub-ruta de agendar, relativa al detalle de un circuito del catálogo
  /// (`/circuit/:id/booking`) o de uno propio (`/my-circuit/:id/booking`).
  static const bookingSegment = 'booking';

  /// Sub-ruta de los horarios de grupo de un circuito creativo, relativa al
  /// detalle: `/circuit/:id/group-slots`
  static const groupSlotsSegment = 'group-slots';

  /// Detalle de una parada: `/stop/:id`
  static const stopDetail = '/stop/:$stopId';

  /// Detalle de un evento: `/event/:id`
  static const eventDetail = '/event/:$eventId';

  /// Circuito creado por el usuario: `/my-circuit/:id`
  static const myCircuit = '/my-circuit/:$collectionId';

  /// Sub-ruta del asistente que reorganiza un circuito propio:
  /// `/my-circuit/:id/assistant`.
  static const assistantSegment = 'assistant';

  /// Asistente que arma un circuito desde cero: `/assistant`.
  static const assistant = '/assistant';

  /// Perfil de un guía: `/guide/:id`
  static const guideProfile = '/guide/:$guideId';

  /// Propuesta de trabajo para guía/traductor y sus postulaciones:
  /// `/guide-proposal`.
  ///
  /// No lleva id: siempre opera sobre la única propuesta activa de
  /// `GuideRequestRepository`.
  static const guideProposal = '/guide-proposal';

  /// Chat con quienes se contrató en la propuesta activa: `/guide-chat`.
  static const guideChat = '/guide-chat';

  /// Nombres de los parámetros de ruta.
  static const circuitId = 'circuitId';
  static const stopId = 'stopId';
  static const eventId = 'eventId';
  static const collectionId = 'collectionId';
  static const guideId = 'guideId';

  static String circuitDetailPath(String id) => '/circuit/$id';
  static String bookingPath(String id) => '/circuit/$id/booking';
  static String groupSlotsPath(String id) => '/circuit/$id/group-slots';
  static String stopDetailPath(String id) => '/stop/$id';
  static String eventDetailPath(String id) => '/event/$id';
  static String myCircuitPath(String id) => '/my-circuit/$id';
  static String myCircuitBookingPath(String id) => '/my-circuit/$id/booking';
  static String myCircuitAssistantPath(String id) =>
      '/my-circuit/$id/assistant';
  static String guideProfilePath(String id) => '/guide/$id';

  /// Rutas accesibles sin sesión iniciada.
  static const Set<String> public = {welcome, login, register, forgotPassword};
}
