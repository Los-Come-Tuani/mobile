/// Textos de la app en un solo lugar (paso previo a la localización real).
abstract final class AppStrings {
  static const appName = "K'Plan";

  // Welcome
  static const welcomeTitle = 'Bienvenido';
  static const welcomeSubtitle = 'Por favor, inicie sesión para continuar';

  // Auth
  static const login = 'Iniciar sesión';
  static const register = 'Crear cuenta';
  static const email = 'Correo electrónico';
  static const password = 'Contraseña';
  static const forgotPassword = '¿Olvidaste tu contraseña?';

  // Validaciones
  static const emailRequired = 'Ingresa tu correo electrónico';
  static const emailInvalid = 'El correo no es válido';
  static const passwordRequired = 'Ingresa tu contraseña';
  static const passwordTooShort = 'Mínimo 6 caracteres';

  // Errores
  static const genericError = 'Algo salió mal, intenta de nuevo';
  static const invalidCredentials = 'Correo o contraseña incorrectos';

  // Home
  static const searchHint = '¿Qué quieres descubrir?';
  static const tabForYou = 'Para ti';
  static const tabCircuits = 'Circuitos';
  static const tabEvents = 'Eventos';
  static const sectionCircuits = 'Circuitos completos';
  static const sectionPlaces = 'Lugares destacados';
  static const sectionEvents = 'Eventos Próximos';
  static const emptyResults = 'No encontramos resultados para tu búsqueda';

  // Detalle del circuito
  static const scheduleCircuit = 'Agendar circuito';
  static const comments = 'Comentarios';
  static const seeAll = 'Ver todos';
  static const openWith = 'Abrir circuito con...';
  static const alwaysUseThisOption = 'Usar siempre esta opción';
  static const cancel = 'Cancelar';
  static const accept = 'Aceptar';

  // Agendar
  static const schedule = 'Agendar';
  static const bookingDetails = 'Detalles de la reserva';
  static const tourInfo = 'Información del recorrido';
  static const date = 'Fecha';
  static const group = 'Grupo';
  static const startTime = 'Hora inicial';
  static const language = 'Idioma';
  static const recommendations = 'Recomendaciones';
  static const estimatedDuration = 'Duración estimada';
  static const meetingPoint = 'Punto de encuentro';
  static const includes = 'Incluye';
  static const badges = 'Insignias';
  static const tourNotes = 'Notas del recorrido';
  static const subtotal = 'Subtotal';
  static const serviceFee = 'Servicio (20%)';
  static const total = 'Total';
  static const bookingConfirmed = '¡Listo! Tu circuito quedó agendado';

  // Paradas
  static const stops = 'Paradas del recorrido';
  static const addToCircuit = 'Añadir a un circuito';
  static const savedInCircuits = 'Guardado en';
  static const myCircuits = 'Mis circuitos';
  static const emptyCircuit = 'Este circuito todavía no tiene paradas';
}
