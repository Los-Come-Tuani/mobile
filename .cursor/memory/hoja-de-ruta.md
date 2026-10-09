# Memoria de trabajo: app y la hoja de ruta del API

Actualizada el 2026-10-08 (Google y el identificador definitivo). Traspaso para el
siguiente agente. La memoria general (estado de
todas las tareas, API, F2 a F8, avisos y cómo correr el API en esta máquina) está en
`C:\development\kplan\api\.cursor\memory\hoja-de-ruta.md`: léela primero.

Rama de trabajo: `feat/hoja-de-ruta-api` (sale de `main`). No tocar `main`; no empujar sin que
el usuario lo pida. Commits convencionales en español, sin emojis.

## Estado

- **Hecho: F0** (`.gitignore`, gitleaks, URL por entorno con `--dart-define-from-file`, https
  obligatorio en release, logs redactados).
- **Ramas y API (2026-10-08, decisión del usuario).** `main` es producción y `staging` sale
  de `feat/hoja-de-ruta-api`. Un build release sin `API_BASE_URL` usa
  `ApiClient.releaseBaseUrl` = `https://develop-api.kplan.dev` (nunca queda en demo);
  `env/staging.example.json` apunta al mismo API y `env/prod.example.json` a
  `https://api.kplan.dev` para cuando haya producción. En debug, sin URL, sigue el demo
  (las pruebas dependen de eso: no cambiar el valor por defecto de `ApiClient`). Pero el
  triángulo del editor de Cursor (y el CodeLens de `main()`) usa la entrada
  "K'Plan — develop-api" de `.vscode/launch.json`, con `templateFor: "lib"` y los
  `--dart-define` de develop-api: corre contra el API de desarrollo. Solo `lib/`, para que el
  panel de pruebas no la herede.
  Igual con Google: sin `GOOGLE_SERVER_CLIENT_ID`, un release usa
  `GoogleSignInService.releaseServerClientId` (el Client ID Web de desarrollo, también en
  `staging.example.json`), así que el botón aparece en el APK. "Continuar con Google" está
  en el login y en el primer paso de "Crear cuenta" (la ruta del registro también da un
  `LoginViewModel`).
- **`develop-api` (comprobado el 2026-10-08 desde el APK en un SM A235M):** no tiene
  `EMAIL_HOST`, y con `DEPLOY=True` el API **descarta** los correos: el código del registro,
  el de recuperar contraseña y el de la postulación nunca llegan. Tampoco tiene
  `GOOGLE_OAUTH_CLIENT_IDS`: `POST /auth/mobile/google/` da `404` "no está habilitado".
  Las dos son variables del servicio `develop-a` en Railway (las define el usuario). Para
  poder crear cuentas sin correo, el API `497cfa9` agregó
  `VERIFICATION_ACCEPT_ANY_SIGNUP_CODE=True`: cualquier código de seis dígitos sirve para el
  alta (no para recuperar la contraseña); ver la memoria del API, aviso 20. Un
  `flutter run --release` sin `android/key.properties` firma con la llave de debug de la
  máquina; la de esta (Lenovo) tiene SHA-1
  `62:65:94:64:A9:06:A4:82:84:DD:80:E7:6C:6A:C5:23:F3:93:40:05` y debe estar en el Client
  ID Android de Google.
- **Datos de `develop-api` (2026-10-08, desplegado: `develop-a` en `4c883ff`).**
  `develop-api` estaba vacío; ya tiene 16 circuitos, 111 lugares, 18 eventos, 13 guías, 64
  salidas y 6 recompensas. En el API (rama `feat/datos-develop`, worktree
  `C:\coding\kplan2\api-datos`): `seedcontent` hace superusuario a `kplan.nic@gmail.com`
  (`fixtures/team.json`; sin contraseña, entra al portal con Google; si la cuenta ya
  existía pierde contraseña, 2FA y sesiones, porque en `develop-api` el alta acepta
  cualquier código) y carga 14 circuitos creativos reales (Managua Xolotlán
  con sus 5 rutas, Granada con 2, Masaya, San Juan de Oriente, León Dariano, Estelí,
  Bluefields, Juigalpa y Nagarote; listas oficiales y coordenadas de OpenStreetMap), 18
  eventos reales, 13 guías y traductores ficticios aprobados (sin contraseña) con salidas y 4
  comercios ficticios con 6 campañas. Railway ignora el `preDeployCommand` de `railway.json`
  (usa el de su panel: solo `migrate`), así que la carga va enganchada al final de `migrate`
  (`api_territory/apps.py`, con `DEPLOY=True`) y solo actúa en develop-api (rama
  `develop-a` o `develop-api.kplan.dev` en `ALLOWED_HOSTS`). Es idempotente: cada
  despliegue solo agrega las salidas que falten. El usuario no quiere tocar Railway.
  Google ya funciona en `develop-api` (el usuario puso `GOOGLE_OAUTH_CLIENT_IDS`).
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
- **Hecho: F4 en la app** (catálogo y "Mi circuito", 2026-10-07; contrato en
  `api/docs/territorio.md`). Con `API_BASE_URL` vacío todo sigue con `assets/mock`, como antes.
  - Catálogo: `remote/tour_api.dart` (`TourApi`) y `TourRepository` con
    `if (ApiClient.isConfigured)`. `getCircuits` (`GET /circuit/` más los lugares de todas las
    paradas en un solo `GET /stop/?ids=`), `getCircuitById` (`/circuit/{id}/`, con las paradas),
    `getStops` (todas las páginas, `page_size=100`), `getStopsByIds` (respeta el orden pedido) y
    `getStopById` (`/stop/{id}/`). Los lugares se reusan dos minutos (las URL firmadas de las fotos
    vencen a los cinco).
  - Mapeo (`Circuit.fromApi`, `Stop.fromApi`): categoría del circuito y pilar del lugar como clave
    en español (`city` -> Ciudad, `historia` -> Historia; `ContentLabels` las traduce al mostrar),
    dificultad, `durationShort` y `badgesNote` en el idioma de la app (claves `repoTour*`), horas
    `"08:30"` -> `"8:30 a.m."` (`Formatters.dataTime`, igual en los dos idiomas), `badges` sin las
    extra del creativo, `organizer` = alcaldía, `legMinutes` de `stops[].leg_minutes`, comentarios
    vacíos (F7). La **duración** la calcula la app con `ItineraryPlanner` (visitas más traslados,
    ritmo equilibrado), como en el detalle; sin los lugares queda `duration_minutes`.
  - Mi circuito: `CircuitCollectionsRepository(tour, auth:)`. Con API **y sesión** guarda en la
    cuenta: `createCollection` -> `POST /itinerary/` con `stop_ids`; `toggleStop`, `updatePlan` y
    `setFixedArrival` -> `PATCH` con el estado completo; `deleteCollection` -> `DELETE`. Uno del
    catálogo solo se guarda cuando le cambian las paradas (`circuit_id` + `stop_ids`, copia propia)
    y queda ligado (`CircuitCollection.itineraryId`). Optimista, con una cola por colección (lo que
    se junta mientras otro viaja se sube una vez; un borrado espera al alta en camino); si falla,
    el aviso sale por `syncErrors` y `CollectionSyncNotices` (en `main.dart`, con el
    `scaffoldMessengerKey`) lo muestra en un SnackBar; el siguiente cambio reintenta.
    `ensureLoaded` trae `GET /itinerary/` (también al iniciar sesión): lo que sale de un circuito
    del catálogo (`followed_circuit` u `origin_circuit_ids`) queda en ese circuito, el más nuevo;
    lo demás son circuitos del turista con el id del itinerario. Al salir o cambiar de cuenta se
    vacía y se vuelve a sembrar. El nombre de un circuito nuevo pide 3 caracteres (el API, 3 a 80).
  - Pruebas: `tour_repository_api_test.dart`, `circuit_collections_sync_test.dart` (con `FakeApi`,
    que ahora anota `query`; muestras del API en `test/support/tour_samples.dart`;
    `repository.settle()` espera lo que se sube) y `test/integration/tour_contract_test.dart`
    (catálogo y ciclo completo de un itinerario con el turista local; pide `KPLAN_API_URL` y
    `KPLAN_TOURIST_PASSWORD`, la contraseña local está en la memoria del API, sección 10; pasó
    contra el API local y borra lo que crea). `flutter analyze` sin avisos; `flutter test` 370 pasan, 6 saltadas.
  - Lo que F4 dejó en demo (eventos, cupones, horarios de grupo, reseñas, reservas, guías,
    insignias) pasó al API con F6 a F8: ver el bloque siguiente.
- **Hecho: F6, F7 y F8 en la app** (2026-10-08; contratos en `api/docs/servicios.md`,
  `agenda-y-recompensas.md`, `finanzas.md` y `avisos.md`). Con `API_BASE_URL` vacío todo sigue en
  demo como antes. Un commit por área en `feat/hoja-de-ruta-api`.
  - **Piezas comunes**: `remote/api_call.dart` (`apiCall` devuelve `Result` con el `detail` del API;
    `failureStatus` da el código; `ApiRows.list/one/pages/post/patch/put`) y
    `core/utils/api_json.dart` (`ApiJson`: lectura tolerante de campos, fechas, imágenes). Las rutas
    de F6 a F8 están en `api_routes.dart`. Capas finas: `services_api.dart` (F7),
    `guide_desk_api.dart` (lo del guía y su dinero), `rewards_api.dart` (visitas, insignias,
    cupones), `notifications_api.dart`, `reports_api.dart`.
  - **Guías** (`GuideRepository`): `GET /guide/` con filtros y `GET /guide/{id}/` (reseñas y
    próximas salidas). Pantalla nueva "Guías y traductores" (`/guides`, menú del inicio). El API no
    tiene años de experiencia ni especialidades: el perfil los oculta.
  - **Salidas y reservas**: con el API todo circuito oficial se reserva en una salida (la pantalla
    de horarios de grupo lista `GET /circuit/{id}/departure/` y reserva con `POST /booking/`); si el
    turista le cambió las paradas, ya es suyo y va por la agenda con convocatoria
    (`CircuitDetailViewModel.booksDeparture`). `BookingsRepository(auth:)` trae `GET /booking/` (al
    abrir el inicio y "Mis viajes") y reserva, cancela, inicia, termina y reseña; `Booking.fromApi`
    con estado, monto, `payment_status`, `payment_instructions`, plazo y `can_cancel`. Detalle
    nuevo `/booking/:id` (turista y guía): estado, cobro con las instrucciones mientras está
    pendiente (sin cobro con tarjeta), cancelar, chat, reseña, iniciar/terminar (guía) y reportar
    al turista (guía). Tras reservar sale la hoja "Reserva confirmada" con cómo pagar.
  - **Convocatorias** (`GuideRequestRepository`, `publishRemote`/`refreshActive`/`hireRemote`/
    `cancelRemote`/`loadMine`): agendar un itinerario propio publica `POST /service-request/` con
    el itinerario de la cuenta (`CircuitCollectionsRepository.savedItineraryId` espera a que esté
    guardado), el presupuesto como `max_fee` y lo pedido como nota (`GuideRequestTerms.apiNote`).
    El API pide **una** persona por convocatoria (guía o traductor). La pantalla de propuesta
    refresca cada 10 s; elegir crea la reserva y abre su detalle. Al abrir el inicio se trae la
    abierta más nueva; sin las condiciones del teléfono que la publicó, se muestra la nota.
  - **Chat** (`BookingChatRepository`, `/booking/:id/chat`): `?after=` con el `sent_at` crudo del
    último mensaje cada 7 s, `POST` y `.../read/`; solo lectura en una reserva cancelada.
  - **Reseñas**: hoja de calificación compartida (`showRateGuideSheet` para el turista);
    `disputeReview` (motivo de 10 caracteres o más) se ofrece al tocar un aviso de reseña.
  - **App del guía con el API** (`GuideDeskRepository(auth:)`, `ui/guide_desk/`): las pestañas
    Inicio (convocatorias abiertas y postularse sin pasar del tope; mis postulaciones, con la
    convocatoria en corto que trae cada una en `request` (`BidRequest`), y retirar),
    Viajes (mis salidas: publicar, editar cupo/transporte/nota, cancelar con motivo; mis reservas),
    Chats (una conversación por reserva, no leídos en la barra) y "Mi dinero" (saldo y
    movimientos, cuenta activa y la pendiente de 24 h, retiros). El router elige estas pantallas
    con `ApiClient.isConfigured`; la demo sigue con `GuideWorkRepository`.
  - **Avisos** (`NotificationsRepository(auth:)`, `/notifications`): bandeja paginada, contador
    con `GET /notification/unread/` (`{ count }`) cada minuto (campana del inicio y del guía), marcar uno y todos; tocar abre
    la reserva, la convocatoria o los retiros según `data`. Configuraciones -> Notificaciones usa
    `GET|PUT /notification-preference/` con el API. **Push**: interfaz `PushService` con
    `NoPushService` (sin `firebase_messaging` ni `google-services.json`); el cliente de
    `POST /device-token/` y `/device-token/remove/` está listo en `registerDevice` y
    `unregisterDevice`. Cuando exista el proyecto de Firebase: implementar `PushService` con
    `firebase_messaging`, pasarlo a `NotificationsRepository(push:)` en `main.dart`, agregar
    `google-services.json`/`GoogleService-Info.plist` y llamar a `unregisterDevice()` **antes** de
    `AuthRepository.logout()` (no se tocó `auth_repository.dart` por el trabajo de Google).
  - **Agenda**: `TourRepository.getUpcomingEvents/getEventById` con `GET /event/`;
    `EventItem.fromApi` (organizador, cancelado con motivo). Los lugares destacados siguen en
    `places.json`.
  - **Insignias** (`BadgesRepository(auth:)`): escanear un QR (detalle del lugar y mapa del viaje)
    manda `POST /visit/` con la ubicación (`LocationRepository.currentPosition`, geolocator ya
    estaba con sus permisos) y muestra el error del API; saldo y logros de `GET /badge/mine/`
    (`by_pillar` con la clave de categoría de la app). El escáner acepta cualquier QR con el API.
  - **Cupones**: tienda `GET /reward/`, canje `POST /coupon/` con el código para el mostrador y
    billetera `GET /coupon/mine/` en la misma pantalla (`BadgesRepository.rewards`,
    `redeemCampaign`, `loadWallet`).
  - **Reportar** (`ReportsRepository`, `showReportSheet`): motivos de `GET /report/reason/` y
    `POST /report/`. Botón en lugar, evento y turista de una reserva (guía), en el perfil del guía
    (`target_kind: "user"` con su `user_id`, no el id del perfil) y en cada reseña (`"review"`
    con su `id`); los dos últimos los cubre `guide_profile_report_test`.
  - Pruebas con `FakeApi` (muestras en `test/support/services_samples.dart`):
    `guide_repository_api_test`, `bookings_repository_api_test`, `guide_request_api_test`,
    `booking_chat_test`, `reviews_api_test`, `guide_desk_repository_test`,
    `notifications_repository_test`, `badges_api_test`, `coupons_api_test`,
    `reports_repository_test`, `guide_profile_report_test` y la agenda en
    `tour_repository_api_test`. Contrato: `test/integration/services_contract_test.dart`, que
    pasó entero contra el API local (2026-10-08, API `fd2bb7b`) con el turista y con el guía
    local `guia.leon@example.com` (`KPLAN_GUIDE_EMAIL`/`KPLAN_GUIDE_PASSWORD`, la misma clave
    local; otra ciudad con `KPLAN_GUIDE_CITY`): publica una salida en un circuito de León, la ve
    en su lista y en las públicas del circuito y la cancela al final. El API local tiene 12
    eventos y ninguna campaña de cupones. `flutter analyze` sin avisos; `flutter test` 411
    pasan, 9 saltadas. No se probó en un dispositivo.
  - **Sigue en demo con el API**: lugares destacados, viaje en curso y bitácora de visitas (solo en
    el teléfono), medallas por ciudad creativa, el chat simulado de la propuesta de la demo.

## Qué falta

0. **Distribución por la landing (F9, 2026-10-08).** La landing (`..\landing-page`) ofrece el
   instalador vigente de cada plataforma y el equipo lo sube y publica desde el portal ("Sitio web
   → Versiones de la app"; contrato en `api/docs/landing.md`). El APK que se reparte tiene que ir
   firmado siempre con la misma llave de release (`android/key.properties`): con otra, Android no
   deja actualizar sobre la versión instalada. La app no tiene
   destinos `macos/` ni `windows/`: el DMG y el EXE que acepta el panel requieren agregarlos a
   Flutter (el DMG se compila en una Mac). iOS no se reparte como archivo.
1. **Google y publicación.** El `applicationId` de Android y el bundle ID de iOS ya son
   `dev.kplan.app`. Ya existen el Client ID Web y el Android de desarrollo; `env/dev.json`
   local y `dev.example.json` llevan el Web como `GOOGLE_SERVER_CLIENT_ID`. El botón ya se
   probó en un SM A235M contra `develop-api` (2026-10-08): entra y crea la cuenta. A
   `develop-api` le sigue faltando un proveedor de correo (ver "Estado"). Para publicar Android faltan la llave de subida
   (`android/key.properties`) y registrar las SHA-1 de release y Play App Signing. Para iOS
   faltan el Client ID, su esquema invertido en `Info.plist` y la configuración de Apple.
2. **"Iniciar sesión con Apple"** si se publica en iOS (Apple lo exige junto a Google).
3. **Roles en la app (hecho, 2026-10-06)**: `mobile` solo admite turista, guía y traductor (y
   cuentas sin rol); una cuenta del equipo o de un negocio recibe `401` como una contraseña mala.
   `User` lee `role` de la sesión (`isGuide`, `isTranslator`, `providesServices`) y, desde F5,
   `provider` (estado y servicios del perfil de prestador): de ahí sale el acceso a la app del
   guía (ver F5 arriba). El API manda un solo rol, el de más rango: una cuenta que es guía y
   traductora llega como `guia`; los servicios completos vienen en `provider.services`.
   Desde F7 el turista ve a los guías aprobados y los contrata con el API (arriba).
4. **Datos del dominio**: con F4 a F8 casi todo viene del API (arriba). Faltan los lugares
   destacados, el viaje en curso y la bitácora de visitas, que el API todavía no tiene. El
   flujo del guía (salidas) ya pasó contra el API local; falta probar postularse y cobrar con
   una convocatoria y una reserva reales.
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
8. **Lo que el API debería cambiar para la app** (anotado en F4, sin tocar el API):
   - Leer `Accept-Language`: los circuitos y lugares llegan en español; con la app en inglés el
     catálogo del API se ve en español (los JSON de ejemplo sí tenían la traducción).
   - Las fotos del catálogo llegan con URL firmadas de cinco minutos
     (`STORAGE_DOWNLOAD_EXPIRES`): en una sesión larga una foto que no se había pintado puede
     fallar. Para fotos públicas convendría una URL pública o un vencimiento largo.
   - `duration_minutes` no suma los traslados que calcula la app, y la lista de circuitos no
     trae coordenadas ni tiempos de las paradas: la app pide los lugares aparte para calcular la
     duración. Sería más simple que la lista traiga eso (o que el API calcule los traslados).
   - `POST /itinerary/` no acepta `fixed_arrivals`: la app hace `POST` y luego `PATCH`.
   - Un itinerario guarda nombre y coordenadas de un lugar retirado, pero la app solo pinta lugares
     de `/stop/` (activos): esa parada desaparece de su circuito. O el API entrega el lugar
     retirado por id, o la app arma la parada con lo que trae el itinerario.
   - Resuelto en el API `fd2bb7b` y ya usado por la app: `user_id` en cada guía y `id` en cada
     reseña (para reportarlos), `request` resumida en cada postulación y
     `GET /notification/unread/` para la campana.
   - (F7) Una convocatoria pide una sola persona: la app pedía guía y traductor a la vez. Con el
     API se publica una por persona (hoy la app manda lo pedido en la nota y acepta a una).
   - (F7, abierto) La convocatoria no guarda las condiciones (servicio, horas, transporte): la
     app las manda como nota y `max_fee`; otro teléfono solo ve la nota. Campos propios
     ayudarían.
   - (F7) Reservar en una salida no deja elegir idioma ni pedir traductor; y no hay reservas del
     equipo para incidencias (anotado en el API).
   - (F8, abierto) Los avisos (título y cuerpo, también los push) llegan en español: el API
     debería escribirlos en el idioma del teléfono.
   - (F8, abierto) El chat no tiene tiempo real: la app pregunta cada 7 s con la conversación
     abierta.
   - (F6, abierto) `GET /badge/mine/` no dice cuándo vuelve a valer un lugar (24 h); la app solo
     muestra el `409` del API.
   - Los horarios de grupo de los creativos y las reseñas ya están (F7: salidas y reseñas).
   - Los circuitos de Ometepe (Rivas) no se siembran: en la app con API no aparecen.

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
- Patrón para conectar un repositorio al API: una capa fina en `remote/<algo>_api.dart` (rutas en
  `api_routes.dart`, modelos con `fromApi`), y en el repositorio `if (ApiClient.isConfigured)` ->
  API con un `_call` que devuelve `Result<T>` (el `detail` del API como mensaje); si no, la demo.
  Ver `provider_api.dart` (F5) y `tour_api.dart` (F4); desde F6 a F8 el `_call` común es
  `apiCall` (`remote/api_call.dart`) y los modelos leen con `ApiJson`. Un repositorio que guarda
  datos de la cuenta escucha `AuthRepository` y se vacía al cambiar de cuenta (`auth:`). En un
  repositorio que se precarga con
  `tester.runAsync`, no hagas `await` de un `Future` ya terminado en las llamadas siguientes: su
  continuación queda en la otra zona y la pantalla no sigue con el reloj falso (por eso
  `ensureLoaded` vuelve sin esperar cuando ya cargó).
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
