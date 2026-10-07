# K'Plan · App móvil

App Flutter de K'Plan para **turistas**, **guías** y **traductores** (ver `PRODUCT.md`). Los negocios,
alcaldías y el equipo de K'Plan usan el portal web.

## Requisitos

- Flutter estable (Dart `^3.11.1`). Verifica con `flutter doctor`.

## Ejecutar

```bash
flutter pub get
flutter run                                              # modo demo: datos simulados, sin API
flutter run --dart-define-from-file=env/dev.json         # contra el API local
```

Sin `API_BASE_URL` la app corre en **modo demo**: los repositorios devuelven datos de
`assets/mock/` y la sesión vive en memoria. Con la URL del API configurada, el inicio de sesión
y el registro hablan con el API real.

### Entornos

La URL del API se fija al compilar con `--dart-define-from-file`; no está en el código. Las
plantillas viven en `env/*.example.json` y los archivos reales (`env/dev.json`, `env/staging.json`,
`env/prod.json`) no se versionan. Ver [`env/README.md`](env/README.md) para saber a qué dirección
apuntar según corras en el emulador de Android, el simulador de iOS o un teléfono físico.

- **Desarrollo**: HTTP en claro permitido solo en builds debug.
- **Staging y producción**: URLs pendientes. Un build release **rechaza** una URL que no sea `https`.
- Lo que se compila dentro de la app se puede extraer del APK/IPA: solo valores públicos, nunca
  claves de servidor.

## Cuenta y sesión

Con el API configurado, la identidad va contra el API real (`/auth/mobile/*`, ver
`docs/autenticacion.md` del repo del API):

- **Tokens**: `access` (3 horas) y `refresh` (1 día, de un solo uso) se guardan en el almacén
  seguro del dispositivo (Keychain en iOS, Keystore en Android) con `flutter_secure_storage`,
  nunca en `shared_preferences`. Los pone el `ApiClient` en cada petición; ante un `401` renueva la
  sesión **una sola vez** aunque fallen varias peticiones a la vez y reintenta. Si el API rechaza la
  renovación, la sesión termina y el router vuelve a la bienvenida. Al abrir la app se recupera la
  sesión guardada.
- **Entrar**: correo y contraseña. Si la cuenta tiene verificación en dos pasos, llega el reto y la
  pantalla "Verifica que eres tú" pide el código de la app de autenticación o uno de recuperación.
  Cinco intentos fallidos bloquean el acceso quince minutos (la app dice cuánto esperar).
- **Crear cuenta**: correo -> código de 6 dígitos que llega al correo -> contraseña (8+, una
  mayúscula y un número) -> fecha de nacimiento (mayor de 18) -> nacionalidad -> nombre -> usuario.
- **Guías y traductores**: una cuenta ejerce un solo papel. La de un guía o traductor se crea al
  postularse ("Comparte tu territorio"): datos, servicios, idiomas y zona, documentos (se suben
  directo al almacenamiento con una URL firmada) y, al final, el código del correo y la
  contraseña. Mientras el equipo la revisa, la cuenta solo ve el estado de su solicitud; si le
  piden correcciones, reenvía solo lo rechazado. Ya aprobada entra a la app del guía, edita su
  perfil público y renueva un documento por vencer sin dejar de trabajar. Contrato:
  `docs/prestadores.md` del repo del API.
- **Recuperar la contraseña**: código al correo y contraseña nueva. **Cambiarla** desde la cuenta
  cierra todas las sesiones.
- **Verificación en dos pasos**: en Configuraciones -> Cuenta (QR, clave, códigos de recuperación
  que se muestran una sola vez, regenerarlos y desactivar).
- **Google**: el botón "Continuar con Google" solo aparece con `GOOGLE_SERVER_CLIENT_ID`. La primera
  vez pide fecha de nacimiento y nacionalidad. Configuración paso a paso en `docs/google.md` del
  repo del API.
- Los registros de red redactan contraseñas, tokens y códigos (`lib/src/core/utils/redact.dart`).

Sin API (modo demo) todo esto se simula con cuentas de ejemplo y no se guarda nada en disco.

### Probar contra el API de verdad

Con el API local corriendo y el correo en consola (`DEBUG=True`):

```bash
KPLAN_API_URL=http://localhost:8080 KPLAN_MAIL_LOG=<archivo con la salida del API> flutter test test/integration
```

Crea una cuenta de turista nueva y recorre el registro con código, la renovación de la sesión y el
2FA completo con códigos reales. `provider_contract_test.dart` crea además una cuenta de guía con
sus documentos: necesita el almacenamiento configurado en el API (`STORAGE_*`). Sin esas variables,
las pruebas se saltan.

## Calidad

```bash
flutter analyze
flutter test
```

## Estructura

```text
lib/src/
  core/      tema, constantes y utilidades (logger, resultados, validadores, itinerarios, mapas)
  data/      modelos y repositorios; datasources/remote es el cliente HTTP único (ApiClient)
  router/    rutas y guards (go_router)
  ui/        una carpeta por función: view, viewmodels y widgets
```
