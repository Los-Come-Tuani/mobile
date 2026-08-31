/// Rutas de assets. Nunca escribas un string de asset directo en una vista.
abstract final class AppAssets {
  static const String _images = 'assets/images';

  /// Ilustración vertical de la pantalla de bienvenida.
  static const String welcomeIllustration = '$_images/login.png';

  /// Variante corta (banda superior) usada en login / registro.
  static const String authIllustration = '$_images/login.png';
}
