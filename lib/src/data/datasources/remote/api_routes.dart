/// API - End Points
abstract final class ApiRoutes {
  // Estado del servicio
  static const statusApi = '/api/status';
  static const testdBConnection = '/api/test-db-connection';

  // Autenticación
  static const login = '/api/auth/login';
  static const register = '/api/auth/register';
  static const forgotPassword = '/api/auth/forgot-password';
  static const profile = '/api/auth/me';
}
