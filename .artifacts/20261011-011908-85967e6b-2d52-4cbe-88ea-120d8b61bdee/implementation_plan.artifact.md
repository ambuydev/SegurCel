# Plan de Implementación: Modal de Confirmación con Temporizador de 10s para Código de Recuperación

Implementar un diálogo modal de confirmación secundaria con un **temporizador obligatorio de 10 segundos** al presionar *"Entrar a SegurCel"* en la pantalla de creación de bóveda (`setup_screen.dart`), garantizando que el usuario tome conciencia sobre guardar su Código de Recuperación.

## Proposed Changes

### Componente: Aplicación Flutter (`lib/`)

#### [localization_service.dart](file:///C:/Users/aleja/StudioProjects/SegurCel/lib/services/localization_service.dart)
- Añadir las siguientes claves traducidas en los 10 idiomas (`es`, `en`, `pt`, `zh`, `fr`, `hi`, `de`, `ja`, `ko`, `ru`):
  - `confirm_recovery_title`: *"¿Confirmas que has guardado tu código?"*
  - `confirm_recovery_desc`: *"Este código NO volverá a mostrarse jamás. El equipo de SegurCel no tiene acceso a tus claves ni forma de recuperarlas. Si olvidas tu PIN y no conservas este código, el acceso a tu bóveda se perderá para siempre."*
  - `confirm_recovery_yes`: *"¡Sí, lo he guardado!"*
  - `confirm_recovery_back`: *"Volver al código"*
  - `understood_timer`: *"Entendido ({seconds}s)"*

#### [setup_screen.dart](file:///C:/Users/aleja/StudioProjects/SegurCel/lib/screens/setup_screen.dart)
- Modificar `_finishSetup()` para que despliegue un `showDialog` con un Widget con estado (`StatefulWidget` / `StatefulBuilder`) y un `Timer.periodic` de 1 segundo:
  - Inicializa un contador en 10 segundos.
  - Muestra el botón de confirmación en gris con el texto `Entendido (10s)`, `Entendido (9s)`, ...
  - Al llegar a 0s, cancela el Timer, habilita el botón y cambia el texto a `¡Sí, lo he guardado!`.
  - El botón secundario `Volver al código` cancela el Timer y cierra el modal permitiendo al usuario volver a revisar o copiar su código.

---

## Verification Plan

### Automated Tests
- Ejecutar `flutter analyze` para asegurar 0 advertencias o errores en la sintaxis Dart.

### Manual Verification
- Probar el flujo de creación de bóveda en Flutter para verificar que el temporizador de 10 segundos descienda correctamente y que el botón se habilite al finalizar los 10 segundos.
