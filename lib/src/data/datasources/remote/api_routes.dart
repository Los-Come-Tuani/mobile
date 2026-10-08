/// API - End Points. Las rutas son las del API (`docs/autenticacion.md` del repo del API):
/// sin prefijo `/api` y con barra final. La sesión de la app va en `/auth/mobile/*`, con
/// los tokens en el cuerpo.
abstract final class ApiRoutes {
  // Estado del servicio
  static const health = '/health/';

  // Sesión
  static const login = '/auth/mobile/login/';
  static const twoFactorLogin = '/auth/mobile/two-factor/';
  static const refresh = '/auth/mobile/refresh/';
  static const logout = '/auth/mobile/logout/';
  static const google = '/auth/mobile/google/';

  // Cuenta
  static const registerCode = '/auth/register-code/';
  static const registerVerify = '/auth/register-verify/';
  static const register = '/auth/register/';
  static const passwordForgot = '/auth/password-forgot/';
  static const passwordReset = '/auth/password-reset/';
  static const passwordChange = '/auth/password-change/';
  static const profile = '/auth/profile/';
  static const sessionRevoke = '/auth/session-revoke/';
  static const accountClose = '/auth/account-close/';

  // Segundo factor (con sesión)
  static const twoFactorStatus = '/auth/two-factor/';
  static const twoFactorSetup = '/auth/two-factor-setup/';
  static const twoFactorConfirm = '/auth/two-factor-confirm/';
  static const twoFactorRecovery = '/auth/two-factor-recovery/';
  static const twoFactorDisable = '/auth/two-factor-disable/';

  // Archivos: una URL firmada para subir directo al almacenamiento
  static const upload = '/upload/';

  // Catálogos (públicos)
  static const cities = '/catalog/city/';
  static const languages = '/catalog/language/';
  static const credentialTypes = '/catalog/credential-type/';

  // Guías y traductores (F5, `docs/prestadores.md` del repo del API)
  static const providerApplication = '/provider-application/';
  static const providerApplicationMine = '/provider-application/mine/';
  static const providerResubmit = '/provider-application/mine/resubmit/';
  static const providerRenewal = '/provider-application/mine/renewal/';
  static const providerProfile = '/provider-profile/mine/';

  // Lugares, circuitos e itinerarios (F4, `docs/territorio.md` del repo del API)
  static const circuits = '/circuit/';
  static String circuit(String id) => '/circuit/$id/';
  static const stops = '/stop/';
  static String stop(String id) => '/stop/$id/';
  static const itineraries = '/itinerary/';
  static String itinerary(String id) => '/itinerary/$id/';

  // Guías, reservas, chat y reseñas (F7, `docs/servicios.md` del repo del API)
  static const guides = '/guide/';
  static String guide(String id) => '/guide/$id/';
  static String circuitDepartures(String id) => '/circuit/$id/departure/';
  static const departures = '/departure/';
  static String departure(String id) => '/departure/$id/';
  static String departureCancel(String id) => '/departure/$id/cancel/';
  static const serviceRequests = '/service-request/';
  static String serviceRequest(String id) => '/service-request/$id/';
  static String serviceRequestAccept(String id) =>
      '/service-request/$id/accept/';
  static String serviceRequestCancel(String id) =>
      '/service-request/$id/cancel/';
  static const openRequests = '/open-request/';
  static String openRequestApply(String id) => '/open-request/$id/apply/';
  static const applicationsMine = '/application/mine/';
  static String applicationWithdraw(String id) => '/application/$id/withdraw/';
  static const bookings = '/booking/';
  static String booking(String id) => '/booking/$id/';
  static String bookingCancel(String id) => '/booking/$id/cancel/';
  static String bookingStart(String id) => '/booking/$id/start/';
  static String bookingFinish(String id) => '/booking/$id/finish/';
  static String bookingMessages(String id) => '/booking/$id/message/';
  static String bookingMessagesRead(String id) => '/booking/$id/message/read/';
  static String bookingReview(String id) => '/booking/$id/review/';
  static String reviewDispute(String id) => '/review/$id/dispute/';

  // Agenda, insignias y cupones (F6, `docs/agenda-y-recompensas.md` del repo del API)
  static const events = '/event/';
  static String event(String id) => '/event/$id/';
  static const visits = '/visit/';
  static const badgesMine = '/badge/mine/';
  static const rewards = '/reward/';
  static const coupons = '/coupon/';
  static const couponsMine = '/coupon/mine/';

  // Saldo y retiros del guía (F8, `docs/finanzas.md` del repo del API)
  static const balanceMine = '/balance/mine/';
  static const bankAccountMine = '/bank-account/mine/';
  static const withdrawals = '/withdrawal/';
  static const withdrawalsMine = '/withdrawal/mine/';

  // Avisos y reportes (F8, `docs/avisos.md` del repo del API)
  static const notifications = '/notification/';
  static String notificationRead(String id) => '/notification/$id/read/';
  static const notificationsReadAll = '/notification/read-all/';
  static const notificationsUnread = '/notification/unread/';
  static const notificationPreferences = '/notification-preference/';
  static const deviceToken = '/device-token/';
  static const deviceTokenRemove = '/device-token/remove/';
  static const reportReasons = '/report/reason/';
  static const reports = '/report/';

  /// En estas rutas un 401 es la respuesta de la acción (credenciales o código malos),
  /// no una sesión vencida: renovar la sesión solo escondería el error.
  static const Set<String> own401 = {
    login,
    twoFactorLogin,
    refresh,
    logout,
    google,
    registerCode,
    registerVerify,
    register,
    passwordForgot,
    passwordReset,
  };
}
