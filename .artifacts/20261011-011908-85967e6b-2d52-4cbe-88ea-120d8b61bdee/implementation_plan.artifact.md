# Plan de Implementación: Integración de Insignias y Enlaces de Código Abierto (GitHub)

Integrar insignias y enlaces directos hacia el repositorio público de GitHub (`https://github.com/ambuydev/SegurCel`) en el sitio web (`landing.html`, `guide.html`, `navbar.js`) y en el menú *"Acerca de SegurCel"* de la aplicación móvil para comunicar la auditabilidad del código.

## Proposed Changes

### Componente: Sitio Web (`web/`) y Módulo Reutilizable (`web/navbar.js`)

#### [navbar.js](file:///C:/Users/aleja/StudioProjects/SegurCel/web/navbar.js)
- Añadir en el footer dinámico el enlace directo:
  `<a href="https://github.com/ambuydev/SegurCel" target="_blank">⭐ GitHub (Código Auditable)</a>`

#### [landing.html](file:///C:/Users/aleja/StudioProjects/SegurCel/web/landing.html) & [guide.html](file:///C:/Users/aleja/StudioProjects/SegurCel/web/guide.html)
- Añadir insignia promocional en la sección Hero / Seguridad:
  `"🛡️ Código Fuente 100% Auditable y Transparente en GitHub"`

### Componente: Aplicación Móvil (`lib/widgets/home/about_app_sheet.dart`)

#### [about_app_sheet.dart](file:///C:/Users/aleja/StudioProjects/SegurCel/lib/widgets/home/about_app_sheet.dart)
- Añadir un botón con el ícono de código hacia `https://github.com/ambuydev/SegurCel`.

---

## Verification Plan

### Terminal / Deployment Commands
- Sincronizar en `build/web/` y desplegar en Firebase Hosting:
  `firebase deploy --only hosting`
- Push a GitHub.
