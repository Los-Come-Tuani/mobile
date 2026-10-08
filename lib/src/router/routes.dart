/// Rutas de la app. Nunca escribas un path a mano en una vista.
abstract final class Routes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  /// Segundo paso de entrar a una cuenta con verificación en dos pasos. Se llega con el
  /// reto del API en `extra` (`TwoFactorLoginArgs`); sin él vuelve a [login].
  static const loginTwoFactor = '/login/two-factor';

  /// "Completa tu perfil" tras entrar con Google por primera vez (`GoogleProfileArgs`).
  static const googleProfile = '/login/google-profile';

  /// El mismo login, pero al entrar lleva a [guideAccess] y abajo ofrece
  /// postularse en vez de crear cuenta.
  static const guideLogin = '/guide-login';

  /// Entrada de guías con sesión iniciada. No tiene pantalla: redirige a
  /// [guideStart] o a [guideStatus] según en qué va la solicitud.
  static const guideAccess = '/guide-access';

  /// "Comparte tu territorio": qué pide la postulación antes de empezar.
  static const guideStart = '/guide-access/start';

  /// La postulación por pasos. Sin sesión, al final se verifica el correo y
  /// se crea la cuenta.
  static const guideApplication = '/guide-access/application';

  /// Solicitud en revisión o acceso de guía habilitado.
  static const guideStatus = '/guide-access/status';

  /// App del guía (cuenta aprobada). Sus pestañas son rutas hermanas, como
  /// las del turista.
  static const guideHome = '/guide-app';
  static const guideTrips = '/guide-app/trips';
  static const guideChats = '/guide-app/chats';
  static const guideSelfProfile = '/guide-app/profile';

  /// Cambiar la foto, la presentación, el teléfono o los idiomas del perfil.
  static const guideProfileEdit = '/guide-app/profile/edit';

  /// Renovar un documento; `extra` es el código del tipo que se renueva.
  static const guideRenewal = '/guide-app/renewal';
  static const guideBalance = '/guide-app/balance';

  /// El idioma de la app, visto desde el modo guía (que no tiene
  /// Configuraciones).
  static const guideLanguage = '/guide-app/language';

  /// Una propuesta vista por el guía: `/guide-app/proposal/:jobId`
  static const guideJob = '/guide-app/proposal/:$jobId';

  /// Un turista visto por el guía: `/guide-app/tourist/:touristId`
  static const guideTourist = '/guide-app/tourist/:$touristId';

  /// Un viaje del guía: `/guide-app/trip/:tripId`
  static const guideTrip = '/guide-app/trip/:$tripId';

  /// La conversación de un viaje: `/guide-app/chat/:tripId`
  static const guideThread = '/guide-app/chat/:$tripId';

  /// Todo lo de la app del guía exige una cuenta de guía aprobada.
  static bool isGuideApp(String location) =>
      location == guideHome || location.startsWith('$guideHome/');
  static const home = '/home';
  static const myTrips = '/my-trips';
  static const saved = '/saved';
  static const coupons = '/coupons';
  static const medals = '/medals';
  static const profile = '/profile';

  /// Configuraciones y sus pantallas.
  static const settings = '/settings';
  static const settingsAccount = '/settings/account';
  static const settingsPassword = '/settings/account/password';
  static const settingsTwoFactor = '/settings/account/two-factor';
  static const settingsNotifications = '/settings/notifications';
  static const settingsLanguage = '/settings/language';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsDataUsage = '/settings/privacy/data';
  static const settingsHelp = '/settings/help';
  static const settingsBookingHelp = '/settings/help/booking';
  static const settingsSupport = '/settings/help/support';

  /// Detalle de un circuito: `/circuit/:id`
  static const circuitDetail = '/circuit/:$circuitId';

  /// Sub-ruta de agendar, relativa al detalle de un circuito del catálogo
  /// (`/circuit/:id/booking`) o de uno propio (`/my-circuit/:id/booking`).
  static const bookingSegment = 'booking';

  /// Sub-ruta de los horarios de grupo de un circuito creativo, relativa al
  /// detalle: `/circuit/:id/group-slots`
  static const groupSlotsSegment = 'group-slots';

  /// Sub-ruta del mapa, relativa al detalle de un circuito, de uno propio, de
  /// una parada o de un evento: `/circuit/:id/map`, `/my-circuit/:id/map`,
  /// `/stop/:id/map` y `/event/:id/map`.
  static const mapSegment = 'map';

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

  /// Los guías y traductores aprobados para contratar.
  static const guides = '/guides';

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
  static const jobId = 'jobId';
  static const touristId = 'touristId';
  static const tripId = 'tripId';

  static String circuitDetailPath(String id) => '/circuit/$id';
  static String bookingPath(String id) => '/circuit/$id/booking';
  static String groupSlotsPath(String id) => '/circuit/$id/group-slots';
  static String circuitMapPath(String id) => '/circuit/$id/map';
  static String stopDetailPath(String id) => '/stop/$id';
  static String stopMapPath(String id) => '/stop/$id/map';
  static String eventDetailPath(String id) => '/event/$id';
  static String eventMapPath(String id) => '/event/$id/map';
  static String myCircuitPath(String id) => '/my-circuit/$id';
  static String myCircuitBookingPath(String id) => '/my-circuit/$id/booking';
  static String myCircuitMapPath(String id) => '/my-circuit/$id/map';
  static String myCircuitAssistantPath(String id) =>
      '/my-circuit/$id/assistant';
  static String guideProfilePath(String id) => '/guide/$id';
  static String guideJobPath(String id) => '/guide-app/proposal/$id';
  static String guideTouristPath(String id) => '/guide-app/tourist/$id';
  static String guideTripPath(String id) => '/guide-app/trip/$id';
  static String guideThreadPath(String tripId) => '/guide-app/chat/$tripId';

  /// Rutas accesibles sin sesión iniciada.
  static const Set<String> public = {
    welcome,
    login,
    loginTwoFactor,
    googleProfile,
    register,
    forgotPassword,
    guideLogin,
  };

  /// Rutas que se recorren con o sin sesión: quien se postula sin cuenta la
  /// crea al final, sin salir de la postulación.
  static const Set<String> guideOnboarding = {guideStart, guideApplication};
}
