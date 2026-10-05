# Memoria de trabajo: app y la hoja de ruta del API

Actualizada el 2026-10-05. Traspaso para el siguiente agente. La memoria general (estado de
todas las tareas, API, F2 a F8, avisos y cómo correr el API en esta máquina) está en
`C:\development\kplan\api\.cursor\memory\hoja-de-ruta.md`: léela primero.

Rama de trabajo: `feat/hoja-de-ruta-api` (sale de `main`). No tocar `main`; no empujar sin que
el usuario lo pida. Commits convencionales en español, sin emojis.

## Estado

- **Hecho (F0, `f0-secrets-gitignore` y `f0-env-config`)**:
  - `.gitignore` ignora `.env.*`, `env/*.json` (salvo `env/*.example.json`),
    `google-services.json`, `GoogleService-Info.plist`, llaves `*.p8`, perfiles de
    aprovisionamiento, keystores y `key.properties`.
  - `.github/workflows/secrets.yml`: escaneo de secretos en CI.
  - `lib/src/data/datasources/remote/api_client.dart` reescrito: la URL ya no está en el
    código, viene de `API_BASE_URL` (`--dart-define-from-file=env/<entorno>.json`); vacía =
    modo demo (los repositorios devuelven datos simulados, `ApiClient.isConfigured`).
    `ApiClient.ensureSafeConfiguration()` (se llama en `main.dart`) impide abrir un build
    release que no use `https`. Los logs de red solo van en debug y pasan por
    `lib/src/core/utils/redact.dart` (`redactSensitive`), con prueba en
    `test/redact_test.dart`.
  - `env/dev.example.json`, `staging.example.json`, `prod.example.json` y `env/README.md`
    (cómo apuntar al API local: emulador `http://10.0.2.2:8080`, simulador iOS
    `http://localhost:8080`, teléfono físico `adb reverse tcp:8080 tcp:8080`).
  - HTTP en claro solo en debug: `android/app/src/debug/AndroidManifest.xml`
    (`usesCleartextTraffic`) y `NSAllowsLocalNetworking` en `ios/Runner/Info.plist`.
- **Pendiente: `f1-app-link`**. No hay código de autenticación real todavía.
- Al cerrar F0 `flutter pub get` cambió `pubspec.lock` por diferencias de SDK; se revirtió.
  Si lo vuelves a ver cambiar sin que agregues paquetes, revierte con
  `git checkout -- pubspec.lock`.

## Cómo está armada la app

- Flutter con `go_router`, `provider` (MVVM), `dio`, `logger`, `flutter_map`,
  `mobile_scanner`, `qr_flutter`. **No** están `flutter_secure_storage` ni `google_sign_in`.
- `lib/src/ui/<pantalla>/{view,viewmodels,widgets}`. Pantallas relacionadas:
  `ui/login`, `ui/register`, `ui/forgot_password`, `ui/welcome`, `ui/settings`
  (`account_view.dart`, `logout_sheet.dart`), `ui/profile`, `ui/guide_access`.
- `lib/src/data/datasources/repository/*` (repositorios con datos simulados),
  `lib/src/data/models/user.dart`, `lib/src/router/{router,routes}.dart`,
  `lib/src/core/utils/{result,validators,logger}.dart`.
- `ApiClient` guarda el token en una variable estática (`setToken`/`clearToken`) y lo manda
  como `Authorization: Bearer`. No lo persiste ni lo refresca.

## Qué trae el API para la app (detalle en `api/docs/autenticacion.md` y `docs/google.md`)

- Sesión: `POST /auth/mobile/login/` (`{email, password}` -> 200 `{access, refresh, user}`
  o 202 `{challenge, expires_in}`), `POST /auth/mobile/two-factor/` (`{challenge, code}` ->
  200 igual que el login), `POST /auth/mobile/refresh/` (`{refresh}` -> 200 `{access,
  refresh}`; el `refresh` es de un solo uso y rota), `POST /auth/mobile/logout/`.
- Registro: `POST /auth/register-code/` (`{email}` -> 204, manda un código de seis dígitos),
  `POST /auth/register-verify/` (`{email, code}` -> 204, no gasta el código),
  `POST /auth/register/` (`{email, code, password, first_name, last_name?, birth_date,
  nationality, username?}` -> 201; la cuenta nace activa y verificada con rol turista;
  luego se llama a `login`). `birth_date` en `YYYY-MM-DD` y mayor de 18; `nationality` es el
  código de dos letras (`NI`, `US`); contraseña de 8+ con una mayúscula y un número.
- Contraseña: `password-forgot` (`{email}`), `password-reset` (`{email, code, password}`),
  `password-change` (con sesión). `GET/PATCH /auth/profile/`, `POST /auth/account-close/`.
- 2FA con `Bearer`: `GET /auth/two-factor/`, `POST /auth/two-factor-setup/` (201 `{secret,
  uri}`), `two-factor-confirm` (201 `{codes}`), `two-factor-recovery`, `two-factor-disable`.
- Google: `POST /auth/mobile/google/` `{id_token, birth_date?, nationality?}`. La primera vez
  sin fecha y nacionalidad responde 400 con esos campos en `field_errors`: la app muestra
  "completa tu perfil" y reintenta **con el mismo token**.
- Errores: `{ "detail": "...", "field_errors": { "body.campo": "..." } }`. 401 genérico, 403
  con el motivo, 429 con `Retry-After`.
- El `access` vive 3 horas y el `refresh` 1 día. La app debe refrescar con una sola petición
  en vuelo ante un 401 y reintentar una vez; si falla, cerrar sesión.

## Diseño decidido para `f1-app-link`

1. **Almacenamiento**: agregar `flutter_secure_storage` (última versión en pub.dev al
   escribir esto: 11.2.0; revisar su requisito de SDK mínimo en Android) y guardar ahí
   `access` y `refresh`. Nunca en `shared_preferences`.
2. **`ApiClient`**: interceptor que (a) pone el `Bearer`, (b) ante 401 refresca con una sola
   petición compartida y reintenta una vez, (c) si el refresco falla borra la sesión y avisa
   al router. Mantener los logs redactados. Mapear `detail`/`field_errors` a errores de
   formulario.
3. **Repositorio de autenticación** nuevo (`AuthRepository`) detrás de la misma interfaz que
   hoy usa la demo: con `ApiClient.isConfigured == false` sigue en modo demo; configurado,
   habla con el API. Restaurar la sesión al arrancar (leer el almacén seguro y llamar a
   `GET /auth/profile/`).
4. **Pantallas**: login (con el paso de código cuando responde 202), registro (agregar
   **nacionalidad** y **fecha de nacimiento**; flujo: correo -> código -> datos), recuperar
   contraseña con código, y las pantallas de 2FA (activar con `qr_flutter`, confirmar,
   mostrar los códigos de recuperación una sola vez, desactivar) en Ajustes/Cuenta.
5. **Google**: paquete `google_sign_in` (7.x; `GoogleSignIn.instance.initialize(clientId:,
   serverClientId:)`, `authenticate()` y `account.authentication.idToken`). Variables nuevas
   en `env/*.json`: `GOOGLE_SERVER_CLIENT_ID` (Client ID **Web**) y `GOOGLE_IOS_CLIENT_ID`.
   Ocultar el botón si no hay `GOOGLE_SERVER_CLIENT_ID`. iOS necesita en `Info.plist` el
   esquema de URL con el Client ID de iOS invertido (`CFBundleURLTypes`). Guía completa:
   `api/docs/google.md`. Apple exige ofrecer también "Iniciar sesión con Apple" si se
   publica en iOS con Google.
6. **Identificadores y firma (bloquea Google y la publicación)**: hoy el `applicationId` es
   `com.example.k_plan_mobile` (`android/app/build.gradle.kts`) y el bundle id
   `com.example.kPlanMobile` (`ios/Runner.xcodeproj/project.pbxproj`), y el release se firma
   con la llave de debug. **Preguntar al usuario el identificador definitivo antes de crear
   los Client ID de Google**; cambiarlo después los invalida. Luego, firma release con
   `key.properties` (ya ignorado) y un keystore fuera del repo.
7. **Pruebas**: `flutter test` para el interceptor de refresco, el mapeo de errores y los
   viewmodels. Antes de cerrar: `flutter analyze` y `flutter test`.

## Límite conocido

El resto de la app (circuitos, lugares, reservas...) sigue con datos simulados: el API no
publica esos recursos hasta F3 en adelante. Solo la identidad va contra el API en F1.
