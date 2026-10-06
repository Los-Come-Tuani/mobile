# Memoria de trabajo: app y la hoja de ruta del API

Actualizada el 2026-10-06. Traspaso para el siguiente agente. La memoria general (estado de
todas las tareas, API, F2 a F8, avisos y cómo correr el API en esta máquina) está en
`C:\development\kplan\api\.cursor\memory\hoja-de-ruta.md`: léela primero.

Rama de trabajo: `feat/hoja-de-ruta-api` (sale de `main`). No tocar `main`; no empujar sin que
el usuario lo pida. Commits convencionales en español, sin emojis.

## Estado

- **Hecho: F0** (`.gitignore`, gitleaks, URL por entorno con `--dart-define-from-file`, https
  obligatorio en release, logs redactados).
- **Hecho: `f1-app-link`** (identidad contra el API real; con `API_BASE_URL` vacío la app sigue
  en modo demo, como antes):
  - `lib/src/data/datasources/local/session_store.dart`: `SessionStore` con `SecureSessionStore`
    (`flutter_secure_storage`: Keychain/Keystore) y `MemorySessionStore` (demo y pruebas).
  - `remote/api_client.dart`: pone `Bearer`, y ante un 401 renueva con el `refresh` **una sola
    vez** aunque fallen varias peticiones (el refresh es de un solo uso) y reintenta; si el API
    rechaza la renovación, borra los tokens y llama a `ApiClient.onSessionExpired` (el
    `AuthRepository` sale de la cuenta); un corte de red no cierra la sesión. Helpers
    `describeError` (usa el `detail` del API), `fieldErrors` (sin `body.`), `retryAfter`.
    `ApiClient.configureForTest(...)` cambia la URL, el transporte y el almacén en pruebas.
  - `repository/auth_repository.dart`: `login` (devuelve `LoginOutcome`: `LoggedIn`,
    `NeedsTwoFactor`, `NeedsProfile` de Google o `Cancelled`), `verifyTwoFactor`,
    `loginWithGoogle`, registro con código (`sendVerificationCode`, `verifyCode`, `register` con
    código, fecha de nacimiento y nacionalidad; luego entra), `requestPasswordReset`,
    `resetPassword`, `changePassword` (el API cierra todas las sesiones: sale), `updateName`
    (PATCH del perfil), `restoreSession` (al abrir), `refreshUser`, `logout`. Sin API configurada
    sigue la simulación de cuentas de ejemplo.
  - `repository/security_repository.dart`: estado, activar (QR y clave), confirmar (diez códigos
    de recuperación, una sola vez), regenerar y desactivar el 2FA.
  - `remote/google_sign_in_service.dart`: `google_sign_in` 7.x con `GOOGLE_SERVER_CLIENT_ID`
    (Client ID **Web**) y `GOOGLE_IOS_CLIENT_ID`; el botón solo aparece si el primero existe.
  - Pantallas: login con paso de 2FA (`/login/two-factor`), "Completa tu perfil" de Google
    (`/login/google-profile`), registro con paso de **nacionalidad** y mayoría de edad, recuperar
    contraseña en dos pasos (código + contraseña nueva), cambiar contraseña con la actual, y
    Configuraciones -> Cuenta -> "Verificación en dos pasos" (QR con `qr_flutter`, códigos).
    La postulación de guía pide fecha de nacimiento y nacionalidad en su primer paso si todavía
    no hay cuenta.
  - Android: `allowBackup="false"` (requisito de `flutter_secure_storage`) y firma del release con
    `android/key.properties` (ignorado por git; sin él cae a la llave de debug y avisa).
  - Contraseña: ocho caracteres, una mayúscula y un número (igual que el API).
  - Pruebas: 56 nuevas (`api_client_test`, `auth_repository_test`, `security_repository_test`,
    `auth_viewmodels_test`, con un API falso en `test/support/fake_api.dart`) y
    `test/integration/api_contract_test.dart` contra un API local (se salta sin
    `KPLAN_API_URL` y `KPLAN_MAIL_LOG`; ver README). Esa prueba pasó contra el API real:
    registro con código del correo, renovación de tokens, 2FA completo con TOTP, cambio de
    contraseña.
  - `flutter analyze` solo reporta dos avisos de `onReorder` que ya estaban; `flutter test` pasa
    completo.
- No se probó en un dispositivo o emulador: la pantalla se verificó con pruebas y analizador.

## Qué falta

1. **Decisión del usuario: identificador de la app (bloquea Google y publicar).** Hoy el
   `applicationId` es `com.example.k_plan_mobile` (`android/app/build.gradle.kts`) y el bundle id
   `com.example.kPlanMobile` (`ios/Runner.xcodeproj/project.pbxproj`). Los Client ID de Google
   quedan atados a ellos: **preguntar el definitivo antes de crearlos**. Luego: la llave de
   firma del release (`android/key.properties`), el Client ID Android (paquete + SHA-1 de
   debug, release y Play App Signing), el Client ID iOS (bundle id) y, en iOS, el esquema de URL
   con el Client ID iOS invertido en `ios/Runner/Info.plist` (`CFBundleURLTypes`). Paso a paso:
   `api/docs/google.md`. Probar el botón de Google en un dispositivo real.
2. **"Iniciar sesión con Apple"** si se publica en iOS (Apple lo exige junto a Google).
3. **Roles en la app (hecho, 2026-10-06)**: `mobile` solo admite turista, guía y traductor (y
   cuentas sin rol); una cuenta del equipo o de un negocio recibe `401` como una contraseña mala.
   `User` lee `role` de la sesión (`isGuide`, `isTranslator`, `providesServices`). Con el API real,
   `GuideAccessRepository.status` sale del rol: guía o traductor -> aprobado (entra al "Modo guía",
   que en el menú dice "Modo traductor" a una traductora), cualquier otro -> sin acceso. La
   postulación desde la app **no existe con el API** (`canApplyInApp` falso): la pantalla de
   inicio de la postulación lo explica y no ofrece "Postularme", y `submit` falla en lugar de
   aprobarse sola a los 60 s como en la demo. El rol de guía o traductor hoy solo se da a mano
   (no hay ruta del API para eso); llega con la fase de guías y traductores (F5), que es cuando
   la postulación tendrá su endpoint y la revisión del equipo en el portal. Pruebas:
   `test/guide_access_roles_test.dart`. El API manda un solo rol, el de más rango: una cuenta que
   es guía y traductora llega como `guia`.
4. **Datos del dominio** (circuitos, lugares, reservas, guías...): siguen simulados. Cada fase
   (F3 en adelante) reemplaza su repositorio por llamadas al API; la app no consume nada de eso
   todavía. El mejor checklist es `portal/src/data/api/endpoints.ts`.
5. **Eliminar la cuenta** (`POST /auth/account-close/`, baja a 30 días) no tiene pantalla todavía.
6. Opcional: borrar la sesión del Keychain en una reinstalación de iOS (el Keychain sobrevive a
   desinstalar la app); con un `refresh` de un día el riesgo es bajo.

## Cómo está armada la app

- Flutter con `go_router`, `provider` (MVVM), `dio`, `logger`, `flutter_secure_storage`,
  `google_sign_in`, `qr_flutter`, `flutter_map`, `mobile_scanner`.
- `lib/src/ui/<pantalla>/{view,viewmodels,widgets}`; las rutas están en `router/routes.dart` (nunca
  escribas un path a mano) y los guards en `router/router.dart` (`refreshListenable` con el
  `AuthRepository`).
- Los viewmodels extienden `BaseViewModel` (`isBusy`, `errorMessage`) y los repositorios devuelven
  `Result<T>` (`Ok`/`Failure`); las vistas no lanzan excepciones de red.
- Para probar un repositorio sin red: `FakeApi` (`test/support/fake_api.dart`) se conecta con
  `api.connect(store: ...)` y se limpia con `ApiClient.configureForTest()` en `tearDown`.
