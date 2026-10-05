# Guía para agentes

App móvil de K'Plan (Flutter, `go_router`, `provider` en MVVM, `dio`).

## Léelo primero

Hay una hoja de ruta en curso para conectar la app con el API real. Lee
`.cursor/memory/hoja-de-ruta.md`: tiene el estado, el diseño ya decidido (sesión segura,
refresco de tokens, registro con código, 2FA, Google) y lo que falta. La memoria general está en
`C:\development\kplan\api\.cursor\memory\hoja-de-ruta.md`.

## Reglas del repo

- Español en código, textos, docs y commits (`feat(auth): ...`). Sin emojis.
- No se commitea en `main` ni se empuja sin que el usuario lo pida: se trabaja en
  `feat/hoja-de-ruta-api` o en otra rama `feat/...`.
- Todo lo que se compila con `--dart-define` se puede extraer del APK/IPA: solo valores
  públicos (URL del API, Client ID de Google), nunca claves. Los `env/*.json` reales no se
  versionan; solo las plantillas `*.example.json`.
- Los tokens van en el almacenamiento seguro del dispositivo, no en `shared_preferences`, y los
  logs de red pasan siempre por `redactSensitive`.
- No cambiar el `applicationId` ni el bundle id sin hablarlo con el usuario: invalida los
  Client ID de Google.
- Antes de cerrar: `flutter analyze` y `flutter test`.
