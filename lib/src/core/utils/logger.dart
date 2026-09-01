import 'package:logger/logger.dart';

/// Instancia global para loguear en toda la app
final log = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // Muestra 2 niveles de la pila de llamadas
    errorMethodCount: 8, // Si es error, muestra más detalle
    lineLength: 80, // Ancho de línea para que no se corte en consola
    colors: true, // Colores para diferenciar niveles
    printEmojis: true, // Emojis para ver el tipo de un vistazo
  ),
);
