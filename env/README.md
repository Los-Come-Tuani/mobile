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
| `GOOGLE_SERVER_CLIENT_ID` | Client ID de tipo **Web** de Google Cloud (el que valida el API). Vacío = sin botón de Google.   |
| `GOOGLE_IOS_CLIENT_ID`    | Client ID de tipo **iOS**. Solo iOS lo usa; en Android se deja vacío.                            |

Los dos Client ID de Google son públicos (no son secretos), pero se crean con el
identificador definitivo de la app: ver `docs/google.md` en el repo del API.

> Todo lo que se compila dentro de la app se puede extraer del APK/IPA. Aquí solo van valores
> públicos (la URL del API, un Client ID de Google), **nunca** claves de servidor ni tokens.

## A dónde apuntar en desarrollo

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

Las URLs todavía no existen. Cuando haya, copia `staging.example.json` / `prod.example.json`,
completa la URL y compila con ese archivo:

```bash
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
