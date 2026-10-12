# Plan de Implementación: Cláusula Estricta de Eliminación Autenticada en `privacy.html`

Actualizar la sección de Eliminación de Datos en `web/privacy.html` para especificar que la eliminación de cuenta se realiza de forma **exclusiva dentro de la sesión autenticada** del usuario en la aplicación móvil o en la Bóveda Web (`https://segurcel.app/vault`), impidiendo eliminaciones vía correo o formularios externos.

## Proposed Changes

### Componente: Sitio Web (`web/privacy.html`)

#### [privacy.html](file:///C:/Users/aleja/StudioProjects/SegurCel/web/privacy.html)
- Actualizar `content_4` en la plantilla HTML y en los objetos `texts` de todos los idiomas:
  `"Por estrictos motivos de seguridad y arquitectura Zero-Knowledge, la eliminación de cuenta y purga de registros cifrados se realiza EXCLUSIVAMENTE mediante autenticación activa de sesión dentro de la aplicación móvil de SegurCel o en nuestra Bóveda Web oficial en https://segurcel.app/vault. No se procesan solicitudes de baja vía correos electrónicos ni formularios de terceros desautenticados para prevenir eliminaciones no autorizadas."`

---

## Verification Plan

### Terminal / Deployment Commands
- Sincronizar en `build/web/` y desplegar en Firebase Hosting:
  `firebase deploy --only hosting`
- Push a GitHub.
