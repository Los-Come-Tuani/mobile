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
