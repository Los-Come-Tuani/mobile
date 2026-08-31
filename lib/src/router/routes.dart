/// Rutas de la app. Nunca escribas un path a mano en una vista.
abstract final class Routes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';

  /// Detalle de un circuito: `/circuit/:id`
  static const circuitDetail = '/circuit/:$circuitId';

  /// Sub-ruta de agendar, relativa al detalle: `/circuit/:id/booking`
  static const bookingSegment = 'booking';

  /// Detalle de una parada: `/stop/:id`
  static const stopDetail = '/stop/:$stopId';

  /// Circuito creado por el usuario: `/my-circuit/:id`
  static const myCircuit = '/my-circuit/:$collectionId';

  /// Nombres de los parámetros de ruta.
  static const circuitId = 'circuitId';
  static const stopId = 'stopId';
  static const collectionId = 'collectionId';

  static String circuitDetailPath(String id) => '/circuit/$id';
  static String bookingPath(String id) => '/circuit/$id/booking';
  static String stopDetailPath(String id) => '/stop/$id';
  static String myCircuitPath(String id) => '/my-circuit/$id';

  /// Rutas accesibles sin sesión iniciada.
  static const Set<String> public = {
    welcome,
    login,
    register,
    forgotPassword,
  };
}
