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
