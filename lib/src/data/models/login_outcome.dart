import 'user.dart';

/// Qué pasó al mandar las credenciales (con contraseña o con Google).
sealed class LoginOutcome {
  const LoginOutcome();
}

/// La sesión quedó abierta.
final class LoggedIn extends LoginOutcome {
  const LoggedIn(this.user);

  final User user;
}

/// La contraseña era correcta, pero la cuenta tiene verificación en dos pasos: falta el
/// código de la app de autenticación (o uno de recuperación). El [challenge] vence en
/// cinco minutos.
final class NeedsTwoFactor extends LoginOutcome {
  const NeedsTwoFactor(this.challenge);

  final String challenge;
}

/// Google no entrega la fecha de nacimiento ni la nacionalidad, y la cuenta nueva las
/// necesita: se piden y se reintenta con el mismo [idToken].
final class NeedsProfile extends LoginOutcome {
  const NeedsProfile(this.idToken);

  final String idToken;
}

/// La persona cerró el selector de cuentas de Google sin elegir una.
final class Cancelled extends LoginOutcome {
  const Cancelled();
}
