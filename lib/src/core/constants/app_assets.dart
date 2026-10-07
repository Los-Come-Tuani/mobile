abstract final class AppAssets {
  static const String _images = 'assets/images';
  static const String _animations = 'assets/animation';

  // ── La vaca de K'Plan, la mascota ─────────────────────────────────────────
  static const String mascot = '$_images/kplanMascota.svg';

  /// Saltando: mientras algo carga.
  static const String mascotJumping = '$_animations/kPlanSaltando.json';

  /// Con estrellitas alrededor de la cabeza: al ganar una insignia.
  static const String mascotStars =
      '$_animations/vacaKPlanCabezaEstrellita.json';

  /// Ilustración vertical de la pantalla de bienvenida.
  static const String welcomeIllustration = authIllustration;

  /// Variante corta (banda superior) usada en el login.
  static const String authIllustration =
      '$_images/background/loginIllustration.svg';

  // ── Registro (un arte decorativo al pie de cada paso) ─────────────────────
  static const String registerEmail = '$_images/register/registerEmail.svg';
  static const String registerCodeLines =
      '$_images/register/registerCodeLines.svg';

  /// El sobre con el código, sobre el campo de verificación.
  static const String registerCodeSent =
      '$_images/register/registerCodeSent.svg';
  static const String registerBirthDate =
      '$_images/register/registerBirthDate.svg';
  static const String registerName = '$_images/register/registerName.svg';
  static const String registerUsername =
      '$_images/register/registerUsername.svg';

  /// Logotipo (versión clara) usado en la barra superior del home.
  static const String logoTipoClaro = '$_images/logo/LogoTipoClaro.svg';
}
