<div align="center">

# `kplan-mobile`

### Aplicación móvil de K'Plan para turistas, guías y traductores

[![Flutter][flutter-badge]][flutter-docs]
[![Dart][dart-badge]][dart-docs]
[![Material 3][material-badge]][material-docs]
<br/>
[![go_router][router-badge]][router-docs]
[![provider][provider-badge]][provider-docs]
[![Dio][dio-badge]][dio-docs]

</div>

## Descripción

Cliente móvil de K'Plan para descubrir y recorrer las Ciudades Creativas de
Nicaragua. La aplicación permite a turistas planificar circuitos, reservar
servicios y obtener recompensas. También incluye una experiencia separada para
guías y traductores, desde su postulación hasta la gestión de viajes y retiros.

El proyecto está desarrollado con Flutter y Material 3 para Android e iOS. Se
puede ejecutar en dos modalidades:

- **Modo demo:** no requiere backend. Usa catálogos incluidos en
  `assets/mock/` y mantiene la sesión en memoria.
- **Modo conectado:** consume el API de K'Plan y persiste la sesión en el
  almacén seguro del dispositivo.

Los negocios, instituciones, alcaldías y el equipo de K'Plan utilizan el portal
web; esta aplicación está limitada a turistas, guías y traductores.

## Alcance funcional

### Turistas

- Registro con código de correo, inicio de sesión, recuperación y cambio de
  contraseña.
- Inicio de sesión con Google y verificación en dos pasos (TOTP y códigos de
  recuperación).
- Catálogo de circuitos, lugares, eventos, guías y traductores.
- Mapas interactivos, ubicación del dispositivo y lectura de códigos QR.
- Creación y edición de circuitos propios, horarios fijos y asistente de
  itinerarios.
- Salidas grupales, convocatorias, reservas, cancelaciones, chat y reseñas.
- Insignias, saldo, campañas de recompensa, canje y billetera de cupones.
- Bandeja de avisos, preferencias y reportes de contenido o personas.
- Interfaz disponible en español e inglés.

### Guías y traductores

- Postulación con identidad, servicios, idiomas, cobertura y documentos.
- Subida directa de archivos mediante URL firmada por el API.
- Consulta del estado de revisión, corrección de documentos y renovación.
- Perfil público editable.
- Gestión de salidas, convocatorias, postulaciones, reservas y chats.
- Consulta de saldo, cuenta de retiro y solicitudes de retiro.

## Tecnologías principales

- **Flutter / Dart:** interfaz multiplataforma.
- **Material 3:** sistema visual y componentes.
- **go_router:** navegación declarativa y protección de rutas por sesión y rol.
- **provider:** inyección de dependencias y estado con MVVM.
- **Dio:** cliente HTTP, interceptores y manejo centralizado de sesión.
- **MapLibre GL + OpenFreeMap:** mapas vectoriales sin clave privada.
- **flutter_secure_storage:** tokens en Android Keystore e iOS Keychain.
- **google_sign_in:** autenticación móvil con Google.
- **mobile_scanner / qr_flutter:** lectura y presentación de códigos QR.
- **geolocator:** ubicación mientras se muestra un recorrido.
- **gen-l10n / intl:** internacionalización en español e inglés.

Las versiones exactas están fijadas en `pubspec.yaml` y `pubspec.lock`.

## Arquitectura

La aplicación usa MVVM con repositorios y una separación por responsabilidades:

```text
Vista
  -> ViewModel (estado y acciones de la pantalla)
    -> Repositorio (reglas y selección demo/API)
      -> Fuente local o cliente HTTP
        -> API de K'Plan
```

- Las vistas no realizan peticiones de red directamente.
- Los ViewModels extienden `BaseViewModel` y exponen carga y errores.
- Los repositorios devuelven `Result<T>` (`Ok` o `Failure`) en los flujos de
  datos.
- `ApiClient` es el cliente HTTP central y añade la sesión a cada petición.
- Cada pantalla crea su ViewModel desde el router; su ciclo de vida termina al
  abandonar la ruta.
- Los repositorios ligados a una cuenta observan `AuthRepository` y limpian su
  estado cuando cambia la sesión.
- Las rutas y sus guards están centralizados en `lib/src/router/`.

### Inicio de la aplicación

`lib/main.dart` prepara la aplicación en este orden:

1. Valida que un build release no use un API por HTTP.
2. Recupera el idioma antes del primer cuadro.
3. Configura el almacenamiento seguro cuando existe un API.
4. Intenta restaurar la sesión guardada.
5. Registra repositorios globales con `MultiProvider`.
6. Inicia `MaterialApp.router` con localización y guards de navegación.

### Origen de los datos

Los repositorios conservan la misma interfaz en ambos modos y eligen su fuente
mediante `ApiClient.isConfigured`:

| Área | Con `API_BASE_URL` | Sin `API_BASE_URL` |
| --- | --- | --- |
| Cuenta, sesión, 2FA y Google | API real | Simulación en memoria |
| Circuitos, lugares, eventos e itinerarios | API real | JSON de `assets/mock/` |
| Guías, salidas, convocatorias, reservas, chat y reseñas | API real | JSON y estado en memoria |
| Insignias, cupones, avisos, reportes y retiros | API real | JSON y estado en memoria |

Incluso en modo conectado permanecen locales los lugares destacados, los
guardados, el viaje en curso, la bitácora de visitas, las medallas por ciudad,
el chat de la propuesta demo y soporte. Las notificaciones push tampoco están
activas todavía; la bandeja de avisos sí consume el API.

## Ejecución local

### Requisitos

1. [Git][git].
2. [Flutter][flutter-install] `3.41.0` o superior.
   - El proyecto requiere Dart `>=3.11.1 <4.0.0`.
3. Android Studio con Android SDK y un emulador, o un dispositivo Android.
4. Para iOS: macOS, Xcode, CocoaPods y un simulador o dispositivo.
5. Java 17 para la compilación de Android.

Compruebe la instalación:

```bash
flutter doctor -v
flutter devices
```

### Clonar e instalar

```bash
git clone https://github.com/Los-Come-Tuani/mobile.git kplan-mobile
cd kplan-mobile
flutter pub get
```

### Ejecutar en modo demo

```bash
flutter run
```

No se necesita API ni archivo de entorno. La identidad y parte del dominio se
simulan localmente.

### Ejecutar con el API

Copie la plantilla de desarrollo:

```bash
cp env/dev.example.json env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

En PowerShell:

```powershell
Copy-Item env/dev.example.json env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

Los archivos `env/dev.json`, `env/staging.json` y `env/prod.json` están
ignorados por Git. Solo se versionan sus plantillas `*.example.json`.

## Configuración por entorno

Los valores se incorporan al compilar mediante
`--dart-define-from-file`. No son variables de entorno leídas en tiempo de
ejecución.

| Variable | Uso |
| --- | --- |
| `API_BASE_URL` | URL base sin `/` final. En debug, vacía o ausente activa el modo demo; en release, ausente usa `https://develop-api.kplan.dev`. |
| `GOOGLE_SERVER_CLIENT_ID` | Client ID público de tipo Web que también valida el API. Vacío oculta el botón de Google. |
| `GOOGLE_IOS_CLIENT_ID` | Client ID público de tipo iOS. En Android puede quedar vacío. |

Todo valor compilado en un APK o IPA puede extraerse. Estos archivos solo deben
contener datos públicos: nunca secretos del servidor, tokens, contraseñas,
cuentas de servicio o llaves de firma.

### Dirección del API local

El API de desarrollo utiliza el puerto `8080`:

| Destino de la app | `API_BASE_URL` |
| --- | --- |
| Emulador Android | `http://10.0.2.2:8080` |
| Simulador iOS | `http://localhost:8080` |
| Android conectado por USB | Ejecutar `adb reverse tcp:8080 tcp:8080` y usar `http://localhost:8080` |
| Dispositivo por Wi-Fi | `http://<IP_DEL_EQUIPO>:8080` y exponer el API en la red local |

HTTP se admite únicamente para desarrollo. Si `API_BASE_URL` no usa `https`,
un build release se detiene al iniciar. La explicación completa está en
[`env/README.md`](env/README.md).

## Sesión y comunicación con el API

- Los tokens de acceso y renovación se guardan con
  `flutter_secure_storage`, nunca en `shared_preferences`.
- Cada petición autenticada incluye `Authorization: Bearer`.
- Ante un `401`, el cliente renueva la sesión una sola vez aunque varias
  peticiones fallen al mismo tiempo, y después reintenta la petición original.
- Si el API rechaza la renovación, los tokens se eliminan y el router vuelve al
  acceso. Un fallo de conectividad no elimina una sesión válida.
- Los errores del API con `detail`, `field_errors` y `Retry-After` se convierten
  en mensajes y errores de campo para la interfaz.
- Los logs de red solo existen en debug, nunca incluyen cabeceras y pasan los
  cuerpos por `redactSensitive`.

Los contratos completos se mantienen en el repositorio del API, especialmente
en `docs/autenticacion.md`, `docs/prestadores.md`, `docs/territorio.md`,
`docs/agenda-y-recompensas.md`, `docs/servicios.md`, `docs/finanzas.md` y
`docs/avisos.md`.

## Internacionalización

Los textos fuente están en:

```text
lib/l10n/arb/app_es.arb
lib/l10n/arb/app_en.arb
```

Después de modificar un ARB:

```bash
flutter gen-l10n
```

Los archivos generados en `lib/l10n/app_localizations*.dart` forman parte del
repositorio. El idioma seleccionado se guarda en `shared_preferences`; no se
almacena ahí ningún dato sensible.

## Mapas, cámara y ubicación

- En Android e iOS, `KPlanMap` utiliza MapLibre nativo con tiles y glifos de
  OpenFreeMap.
- En pruebas y plataformas de escritorio se utiliza un mapa de respaldo
  dibujado con widgets, lo que permite probar los marcadores sin un motor
  nativo.
- La cámara se solicita al escanear el QR de una visita.
- La ubicación se solicita mientras una pantalla de mapa necesita mostrar al
  turista o acreditar una visita.

Los permisos se declaran en `android/app/src/main/AndroidManifest.xml` y
`ios/Runner/Info.plist`.

## Pruebas y calidad

### Análisis y pruebas automatizadas

Antes de entregar cambios:

```bash
flutter analyze
flutter test
```

La suite incluye pruebas unitarias, de repositorios, ViewModels y widgets. Las
pruebas de contrato ubicadas en `test/integration/` se saltan automáticamente
si no reciben la configuración de un API real.

Última verificación del entregable: `flutter analyze` sin incidencias y
`flutter test` con 411 pruebas aprobadas y 9 pruebas de integración omitidas por
no haberse proporcionado sus variables.

### Pruebas de contrato con el API

Para identidad, 2FA y postulación de prestadores, ejecute el API con correo de
desarrollo visible en un archivo de log. La postulación también necesita el
almacenamiento S3 compatible configurado en el API:

```bash
KPLAN_API_URL=http://localhost:8080 \
KPLAN_MAIL_LOG=/ruta/api.out.log \
flutter test test/integration
```

En PowerShell:

```powershell
$env:KPLAN_API_URL = 'http://localhost:8080'
$env:KPLAN_MAIL_LOG = 'C:\ruta\api.out.log'
flutter test test/integration
```

El catálogo, los itinerarios y los servicios usan una cuenta turista local:

```powershell
$env:KPLAN_API_URL = 'http://localhost:8080'
$env:KPLAN_TOURIST_EMAIL = 'turista@example.com' # opcional
$env:KPLAN_TOURIST_PASSWORD = '<contraseña-local>'
flutter test test/integration/tour_contract_test.dart
flutter test test/integration/services_contract_test.dart
```

Para cubrir también las operaciones del prestador en
`services_contract_test.dart`, defina `KPLAN_GUIDE_EMAIL` y
`KPLAN_GUIDE_PASSWORD` con una cuenta aprobada. Las pruebas eliminan los
itinerarios que crean.

## Compilación

### Android

Un release sin archivo de entorno habla con `https://develop-api.kplan.dev`, el
API de desarrollo publicado:

```bash
flutter build apk --release
```

Con los Client ID de Google, compile con `env/staging.json` (copia de
`staging.example.json`, que apunta al mismo API). `env/prod.json` queda para
cuando exista producción (`https://api.kplan.dev`):

```bash
flutter build apk --release --dart-define-from-file=env/staging.json
flutter build appbundle --release --dart-define-from-file=env/prod.json
```

La firma de publicación se configura en `android/key.properties`, un archivo
ignorado por Git. Sin él, Gradle firma el release con la llave de debug y emite
una advertencia; ese artefacto no debe publicarse. Consulte
[`env/README.md`](env/README.md) para el formato.

### iOS

En macOS:

```bash
flutter build ipa --release --dart-define-from-file=env/prod.json
```

La firma, los perfiles y las capacidades se administran desde
`ios/Runner.xcworkspace` en Xcode.

La aplicación usa el identificador `dev.kplan.app` en Android e iOS. No debe
cambiarse sin actualizar también la firma, los Client ID de Google y la
configuración de las tiendas.

## Estructura del proyecto

```text
.
├── android/                 proyecto y configuración nativa de Android
├── ios/                     proyecto y configuración nativa de iOS
├── assets/
│   ├── animation/           animaciones Lottie
│   ├── images/              identidad visual e ilustraciones
│   └── mock/                catálogos demo en español e inglés
├── env/                     plantillas públicas de configuración
├── lib/
│   ├── l10n/                ARB y localizaciones generadas
│   ├── main.dart            arranque e inyección global
│   └── src/
│       ├── core/            tema, l10n, validación y utilidades
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── local/   sesión y datos demo
│       │   │   ├── remote/  cliente y adaptadores del API
│       │   │   └── repository/
│       │   └── models/
│       ├── router/          rutas y guards
│       └── ui/              vistas, ViewModels y widgets por función
└── test/
    ├── integration/         contratos contra un API real
    └── support/             API falso, muestras y utilidades
```

## Seguridad

- No se versionan archivos de entorno reales, certificados, keystores,
  configuraciones de Firebase, cuentas de servicio ni secretos.
- Los tokens viven en Android Keystore o iOS Keychain.
- Android desactiva el respaldo de los datos de la aplicación.
- Producción exige HTTPS.
- Los logs redactan tokens, contraseñas, códigos y otros campos sensibles.
- Las subidas de documentos se hacen directamente al almacenamiento con un
  `PUT` firmado; la aplicación no conoce credenciales del bucket.

## Estado de publicación y limitaciones conocidas

- Los flujos principales están conectados al API, pero los lugares destacados,
  el viaje en curso, la bitácora de visitas y las medallas por ciudad todavía
  conservan estado local o datos demo.
- El chat consulta periódicamente al API; todavía no utiliza WebSocket.
- Los avisos se muestran en la bandeja. El push requiere crear el proyecto de
  Firebase e implementar `PushService` con `firebase_messaging`.
- Falta configurar el Client ID de Google para iOS y su esquema de URL.
- Si la app se publica en iOS junto con Google, debe incorporarse «Iniciar
  sesión con Apple».
- Publicar en tiendas necesita la firma de publicación y la configuración de
  cada tienda. Hoy el release habla con `develop-api.kplan.dev`.
- Antes de publicar debe completarse una ronda de validación en dispositivos
  Android e iOS reales.

## Solución de problemas

- **El emulador Android no llega a `localhost`:** utilice `10.0.2.2`.
- **El botón de Google no aparece:** defina `GOOGLE_SERVER_CLIENT_ID` y vuelva a
  compilar; los `dart-define` no cambian en caliente.
- **El release falla al iniciar:** compruebe que `API_BASE_URL` use `https`.
- **Las pruebas de integración aparecen como omitidas:** defina las variables
  `KPLAN_*` requeridas y asegúrese de que el API esté disponible.
- **Una foto deja de cargar durante una sesión larga:** las URLs de archivos
  entregadas por el API son temporales; vuelva a abrir o refrescar la pantalla.

[dart-badge]: https://img.shields.io/badge/Dart-white?style=for-the-badge&color=0175C2&logo=dart&logoColor=white
[dart-docs]: https://dart.dev/
[dio-badge]: https://img.shields.io/badge/Dio-white?style=for-the-badge&color=5A29E4
[dio-docs]: https://pub.dev/packages/dio
[flutter-badge]: https://img.shields.io/badge/Flutter-white?style=for-the-badge&color=02569B&logo=flutter&logoColor=white
[flutter-docs]: https://docs.flutter.dev/
[flutter-install]: https://docs.flutter.dev/get-started/install
[git]: https://git-scm.com/install/
[material-badge]: https://img.shields.io/badge/Material_3-white?style=for-the-badge&color=6750A4&logo=materialdesign&logoColor=white
[material-docs]: https://m3.material.io/
[provider-badge]: https://img.shields.io/badge/provider-white?style=for-the-badge&color=02569B
[provider-docs]: https://pub.dev/packages/provider
[router-badge]: https://img.shields.io/badge/go__router-white?style=for-the-badge&color=02569B
[router-docs]: https://pub.dev/packages/go_router
