# Plan de Implementación: Reversión de `about_app_sheet.dart` para Paridad Total con la Versión Enviada a Google Play

Revertir el cambio de `lib/widgets/home/about_app_sheet.dart` para mantener el código fuente de Flutter 100% idéntico al paquete ejecutable `.aab` enviado a revisión en Google Play Console.

## Proposed Changes

### Componente: Aplicación Móvil (`lib/widgets/home/about_app_sheet.dart`)

#### [about_app_sheet.dart](file:///C:/Users/aleja/StudioProjects/SegurCel/lib/widgets/home/about_app_sheet.dart)
- Eliminar el botón estático de GitHub en la vista modal `about_app_sheet.dart` para evitar discrepancias con el binario `.aab` subido a Play Console.
- La referencia a GitHub se mantiene activa en la web oficial (`https://segurcel.app`) y en la Ficha de Play Store.

---

## Verification Plan

### Terminal Commands
- Verificar limpieza de estado con `git status` y hacer push a GitHub.
