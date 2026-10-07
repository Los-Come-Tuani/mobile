# Memoria de trabajo: app y la hoja de ruta del API

Actualizada el 2026-10-07. Traspaso para el siguiente agente. La memoria general (estado de
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
  - `flutter analyze` y `flutter test` pasan limpios (estado actual al final de esta sección).
- **Hecho: F5 en la app** (guías y traductores, 2026-10-07; contrato en `api/docs/prestadores.md`):
  - **Una cuenta, un papel.** La de un guía o traductor se crea al postularse desde la app; un
    turista que quiere ser guía usa otro correo ("Salir para postularme" en la pantalla de
    inicio). Mientras la revisan, el router solo la deja en `/guide-access/status`; ya aprobada
    (`active` o `suspended`) cualquier login y el `/home` del turista la mandan a `/guide-app`.
    En el perfil del guía ya no hay "Entrar como turista".
  - `models/provider.dart`: lo que manda y recibe el API (`ProviderRef` de la sesión, que
    `User.provider` lee; `ProviderApplication`, `ProviderSelf`, `ProviderDocument` con su
    revisión, `CredentialType.requiredFor`, los borradores `ProviderApplicationDraft` y
    `DocumentDraft`). `remote/provider_api.dart`: catálogos, `upload` (pide la URL a
    `POST /upload/` y sube con un PUT y los encabezados firmados, con un `Dio` aparte sin
    `Bearer`), postularse, `mine`, reenvío, renovación y perfil. En pruebas se cambian
    `ProviderApi.storage` y `ProviderApi.readFile`, y `ProviderApi.reset()` en `tearDown`.
  - `GuideAccessRepository`: el estado sale de `User.provider` (o del rol, para una cuenta que el
    equipo habilitó antes de F5); `apply` crea la cuenta y abre la sesión con
    `AuthRepository.openSessionFrom`; `refresh` (la pantalla de estado lo llama al abrir y cada
    30 s) vuelve a pedir la sesión si el equipo resolvió. En modo demo todo se simula: dos guías
    aprobados (`guia@kplan.com`, `guia.granada@kplan.com`) y una postulación nueva se aprueba
    sola a los 60 s.
  - Postulación (`GuideApplicationViewModel`): identidad, servicios (guía, traductor o ambos;
    idiomas; zona; si lleva turistas en su vehículo), documentos con número y fechas (los que
    pide el catálogo según lo elegido), revisión, código del correo y contraseña. Con
    `correcting:` (desde el estado de una solicitud rechazada) arranca en servicios con lo que ya
    mandó y solo pide subir otra vez lo rechazado. El nivel de idioma se simplificó: español
    nativo, los demás avanzado.
  - App del guía: "Editar mi perfil" (`/guide-app/profile/edit`: foto, presentación, teléfono,
    idiomas) y "Mis documentos" con renovación por documento (`/guide-app/renewal`, `extra` es
    el código del tipo); un guía suspendido ve el aviso y sigue entrando para renovar.
  - Pruebas: `guide_access_test.dart`, `guide_access_roles_test.dart` (con `FakeApi`) y
    `test/integration/provider_contract_test.dart` contra el API real (postulación con subida
    firmada; pasó con el S3 local de pruebas, ver la memoria del API, sección 10).
- No se probó en un dispositivo o emulador: la pantalla se verificó con pruebas y analizador.
- **Hecho: idiomas español e inglés** (merge de `respaldo/idiomas-local`, 2026-10-07): gen-l10n,
  catálogo de ejemplo en inglés (`assets/mock/en/`), selector de idioma la primera vez en el login
  y en Configuraciones (y en el perfil del guía). Se quedó el mapa de esta rama (OpenFreeMap con
  `maplibre_gl`); el motor viejo de `a85d7c2` (paquete `maplibre`, `map_engine`,
  `maplibre_engine`, `map_marker_layer`, `route_geojson`, `core/utils/map_camera`) se descartó.
  Los textos que la rama agregó (2FA, Google, registro con nacionalidad, recuperar y cambiar
  contraseña, postulación F5, estados vacíos, documentos del guía) tienen sus claves en los dos
  ARB. `flutter analyze` queda sin avisos y `flutter test` pasa completo (347, 4 saltadas).

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
   `User` lee `role` de la sesión (`isGuide`, `isTranslator`, `providesServices`) y, desde F5,
   `provider` (estado y servicios del perfil de prestador): de ahí sale el acceso a la app del
   guía (ver F5 arriba). El API manda un solo rol, el de más rango: una cuenta que es guía y
   traductora llega como `guia`; los servicios completos vienen en `provider.services`.
   Falta: el turista no ve todavía a los guías aprobados (el perfil público del guía y la
   contratación siguen simulados; llegan con la fase que los conecte).
4. **Datos del dominio** (circuitos, lugares, reservas, guías...): siguen simulados. Cada fase
   (F3 en adelante) reemplaza su repositorio por llamadas al API; la app no consume nada de eso
   todavía. El mejor checklist es `portal/src/data/api/endpoints.ts`.
5. **Eliminar la cuenta** (`POST /auth/account-close/`, baja a 30 días) no tiene pantalla todavía.
6. Opcional: borrar la sesión del Keychain en una reinstalación de iOS (el Keychain sobrevive a
   desinstalar la app); con un `refresh` de un día el riesgo es bajo.
7. **Textos sin traducir** (siguen en español en los dos idiomas):
   - Configuraciones -> Cuenta -> "Verificación en dos pasos" (`settings/view/two_factor_view.dart`
     y su viewmodel).
   - App del guía: "Editar mi perfil" y "Mis documentos"/renovación
     (`guide_app/profile/view/guide_profile_edit_view.dart`, `guide_renewal_view.dart` y sus
     viewmodels).
   - Nombres de países (`models/nationality.dart`) y las etiquetas de `models/provider.dart`
     (`ProviderServices.label`, nombres de respaldo de los documentos).
   - Lo que manda el API llega en español: el `detail` de los errores (`describeError` lo muestra
     tal cual) y los catálogos de prestadores (ciudades, idiomas, tipos de documento). Si se
     quiere en inglés, el API tendría que leer `Accept-Language`.

## Cómo está armada la app

- Flutter con `go_router`, `provider` (MVVM), `dio`, `logger`, `flutter_secure_storage`,
  `google_sign_in`, `qr_flutter`, `maplibre_gl`, `mobile_scanner`, `shared_preferences` (solo
  el idioma) e `intl`.
- Mapa (`lib/src/ui/widgets/map/`): `KPlanMap` usa MapLibre nativo en Android e iOS
  (`native_map.dart`); las calles, los tramos, los pines y el turista son capas del mapa. Los pines
  son los widgets de `map_pins.dart` pintados a PNG (`map_icon_renderer.dart`), y `map_scene.dart`
  decide qué se destaca y arma el GeoJSON. En pruebas y escritorio no hay MapLibre: queda
  `paper_map.dart` con los mismos pines, y por eso las pruebas pueden tocarlos. El estilo
  (`core/theme/map_style.dart`) usa tiles y glifos de OpenFreeMap (Noto Sans: MapLibre no puede
  usar Poppins). Los zoom son los de MapLibre: uno menos que los de `flutter_map` para la misma
  vista.
- `lib/src/ui/<pantalla>/{view,viewmodels,widgets}`; las rutas están en `router/routes.dart` (nunca
  escribas un path a mano) y los guards en `router/router.dart` (`refreshListenable` con el
  `AuthRepository`).
- Los viewmodels extienden `BaseViewModel` (`isBusy`, `errorMessage`) y los repositorios devuelven
  `Result<T>` (`Ok`/`Failure`); las vistas no lanzan excepciones de red.
- Para probar un repositorio sin red: `FakeApi` (`test/support/fake_api.dart`) se conecta con
  `api.connect(store: ...)` y se limpia con `ApiClient.configureForTest()` en `tearDown`.
- Idiomas (gen-l10n, `l10n.yaml`): los textos viven en `lib/l10n/arb/app_es.arb` (plantilla) y
  `app_en.arb`; `flutter gen-l10n` genera `lib/l10n/app_localizations*.dart`, que se versionan
  (córrelo después de tocar un ARB). En las vistas se usa `context.l10n.clave`
  (`core/l10n/l10n.dart`); sin `BuildContext` (viewmodels, repositorios, validadores, el pintado
  de los pines del mapa) se usa `AppStrings.current.clave`, que sigue el idioma elegido.
  `ContentLabels` traduce valores de datos que siguen en español (`l10n.categoryName`,
  `l10n.languageName`). `LanguageRepository` guarda el idioma en `shared_preferences`
  (`LanguageRepository.memory()` en pruebas) y `LanguageContentSync` recarga el contenido de
  ejemplo al cambiarlo. Los íconos del mapa se cachean por nombre: si un pin lleva texto, el
  nombre lleva el código del idioma (`pin/start/es`).
- Para agregar un texto: la clave va en los dos ARB con el prefijo de su pantalla (`common*`,
  `login*`, `register*`, `settings*`, `guideAccess*`, `guideApp*`, `repo*`, `validator*`...),
  en orden alfabético sin distinguir mayúsculas; el bloque `@clave` con `placeholders` solo en
  `app_es.arb` y solo si lleva parámetros. Las pruebas corren en español salvo que usen
  `AppStrings.use(AppLanguage.en)` (y lo devuelvan en `tearDown`); un widget suelto necesita
  `localizationsDelegates` y `supportedLocales` de `AppLocalizations` para traducirse.
