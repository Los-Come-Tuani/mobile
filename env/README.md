# Configuración por entorno

La app no trae ninguna URL en el código: se fija al compilar con
`--dart-define-from-file`. Los archivos reales (`dev.json`, `staging.json`, `prod.json`)
**no se versionan**; en git solo están las plantillas `*.example.json`.

```bash
cp env/dev.example.json env/dev.json
flutter run --dart-define-from-file=env/dev.json
```

| Variable                  | Qué es                                                                                          |
| ------------------------- | ----------------------------------------------------------------------------------------------- |
| `API_BASE_URL`            | URL base del API, sin `/` al final. Vacía o ausente = modo demo (sin backend).                  |
| `GOOGLE_SERVER_CLIENT_ID` | Client ID de tipo **Web** de Google Cloud (el que valida el API). Vacío = sin botón de Google; ausente en release = el de desarrollo. |
| `GOOGLE_IOS_CLIENT_ID`    | Client ID de tipo **iOS**. Solo iOS lo usa; en Android se deja vacío.                            |

Los dos Client ID de Google son públicos (no son secretos). El identificador definitivo
de Android y el bundle ID de iOS son `dev.kplan.app`; ver `docs/google.md` en el repo del
API. `dev.example.json` ya trae el Client ID Web de desarrollo. El Client ID iOS se
agregará cuando se trabaje esa publicación.

> Todo lo que se compila dentro de la app se puede extraer del APK/IPA. Aquí solo van valores
> públicos (la URL del API, un Client ID de Google), **nunca** claves de servidor ni tokens.

## A dónde apuntar en desarrollo

En VS Code / Cursor, el triángulo del editor y el "Run | Debug" sobre `main()` usan la
configuración "K'Plan — develop-api" de `.vscode/launch.json` (`templateFor: "lib"`): la app
habla con `https://develop-api.kplan.dev` sin crear ningún archivo. Para el API local o el
modo demo, elige "K'Plan — API local" o "K'Plan — modo demo" en el panel "Run and Debug".
Las pruebas no heredan esa configuración y siguen en modo demo.

El API local corre en el puerto `8080` de tu máquina (`just run` en el repo del API).

| Dónde corre la app           | `API_BASE_URL`                                                           |
| ---------------------------- | ------------------------------------------------------------------------ |
| Emulador de Android          | `http://10.0.2.2:8080` (así llega al `localhost` de la máquina)          |
| Simulador de iOS             | `http://localhost:8080`                                                  |
| Teléfono Android por USB     | `adb reverse tcp:8080 tcp:8080` y luego `http://localhost:8080`          |
| Teléfono por Wi-Fi           | `http://<IP de tu PC>:8080`; el API debe correr con `GRANIAN_HOST="0.0.0.0"` y esa IP en `ALLOWED_HOSTS` |

El HTTP en claro solo está permitido en builds debug (Android: manifest de `debug`; iOS: solo
hacia `localhost` y la red local). Un build release **rechaza** una URL que no sea `https`.

## Staging y producción

| Archivo                | Rama de la app | `API_BASE_URL`                  |
| ---------------------- | -------------- | ------------------------------- |
| `staging.example.json` | `staging`      | `https://develop-api.kplan.dev` |
| `prod.example.json`    | `main`         | `https://azure-api.kplan.dev`   |

Un build release **sin** archivo (`flutter build apk --release`) usa
`https://azure-api.kplan.dev` (el API en Azure, rama `production`) y el Client ID Web de
desarrollo (`GoogleSignInService.releaseServerClientId`), así que el APK publicado nunca
queda en modo demo ni sin el botón de Google. Para que ese botón funcione, el API de Azure
necesita el mismo Client ID en `GOOGLE_OAUTH_CLIENT_IDS`, y el Client ID Android de Google, la
SHA-1 de la llave con la que se firmó el APK. Para otro entorno, copia el que toque a
`staging.json` o `prod.json` (ignorados), complétalos y compila con ese archivo:

```bash
flutter build apk --release --dart-define-from-file=env/staging.json
flutter build apk --release --dart-define-from-file=env/prod.json
```

### Firma del release (Android)

El release se firma con una llave propia que **no** se versiona. Crea `android/key.properties`
(ignorado por git) con:

```properties
storeFile=../../ruta/fuera/del/repo/kplan-release.jks
storePassword=...
keyAlias=...
keyPassword=...
```

Sin ese archivo, `build.gradle.kts` firma el release con la llave de debug y lo avisa: sirve
para probar con `flutter run --release`, no para publicar. La misma llave (y la de Play App
Signing) hay que registrarla con su huella SHA-1 en el Client ID Android de Google.
