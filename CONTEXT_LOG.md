# CONTEXT_LOG.md - RESUMEN COMPLETO DE PROYECTO Y ESTADO PARA AGENTE IA

Este archivo contiene el contexto completo de **SegurCel** para que cualquier nuevo agente IA comprenda la arquitectura, el estado de producción en Google Play Console, la configuración de GitHub, la extensión de navegador y los pasos inmediatos al iniciar una nueva sesión de chat.

---

## 1. 📌 INFORMACIÓN GENERAL Y RESORTES DEL PROYECTO
- **Nombre de la App**: SegurCel - Bóveda & 2FA (`com.segurcel.segurcel`)
- **Versión Actual**: 1.0.0 (Build 1)
- **Framework**: Flutter 3.41.8 / Dart 3.11.5 (Android & Web)
- **Dominio Oficial & Hosting**: `https://segurcel.app` (Proyecto Firebase: `segurcel-45c92`)
- **Usuario GitHub**: `ambuydev`
- **Repositorio Público GitHub**: `https://github.com/ambuydev/SegurCel.git`
- **Ramas Sincronizadas**: `master` y `feature/browser-extension`

---

## 2. 🛡️ ARQUITECTURA DE SEGURIDAD ZERO-KNOWLEDGE
- **Cifrado E2EE**: Cifrado local en dispositivo usando **AES-256-GCM** y derivación de clave maestra con **PBKDF2WithHmacSHA256** (65,536 iteraciones).
- **Protección Anti-Fuerza Bruta**: Autodestrucción de datos locales tras 3 intentos fallidos de PIN de 4 dígitos.
- **Confirmación Obligatoria de Código de Recuperación**: Modal con temporizador de 10 segundos antes de finalizar la instalación inicial para evitar pérdida accidental del código.
- **Autenticador 2FA TOTP**: Generador integrado de códigos de 6 dígitos con temporizador circular de 30 segundos y copia en 1 toque.
- **Salud de la Bóveda**: Escáner inteligente de fortaleza global (0 al 100%) que detecta contraseñas débiles, repetidas o antiguas.
- **Límite Freemium**: 20 contraseñas y 2 cuentas 2FA TOTP en el plan gratuito. Ilimitado en planes PRO/Familiar.

---

## 3. 🌐 EXTENSIÓN DE NAVEGADOR MANIFEST V3 Y SITIO WEB
- **Extensión para Navegadores (PC/Mac)**: Ubicada en `extension/` (Manifest V3, Web Crypto API y Firebase REST API). Empaquetada en `web/segurcel-extension.zip`.
- **Módulo JavaScript Reutilizable (`web/navbar.js`)**: Encabezado compartido, banderas HD (`https://flagcdn.com`), selector desplegable de 10 idiomas, traducción de `btnBack` y footer multilingüe.
- **Rutas Limpias Nativas (*Clean URLs*)**: Todos los enlaces utilizan rutas sin `.html` (`/`, `/guide`, `/privacy`, `/vault`) compatibles con `"cleanUrls": true` de Firebase Hosting para prevenir errores `ERR_TOO_MANY_REDIRECTS`.
- **Sincronización de Parámetros URL**: `SegurCelNav.selectLanguage()` actualiza la barra de direcciones con `window.history.replaceState(null, '', '?lang=' + lang)`.

---

## 4. 📜 POLÍTICA DE PURGA POR INACTIVIDAD (180 DÍAS) & GOOGLE PLAY
- **Seguimiento de Actividad**: `VaultService.fetchUserProfile()` registra automáticamente `last_login_at: FieldValue.serverTimestamp()` en Firestore en cada uso de la app o Bóveda Web.
- **Sección 4 de la Política de Privacidad (`https://segurcel.app/privacy`)**:
  - *Eliminación Autónoma:* Exclusiva dentro de la sesión autenticada en la App o Bóveda Web (`https://segurcel.app/vault`).
  - *Purga Automática por Inactividad (180 Días):* Notificación de advertencia previa al correo registrado tras 180 días sin logins y eliminación definitiva automática si no se reconfirma el uso activo.
  - *Cláusula Google Play Billing:* Procesa suscripciones únicamente por el sistema de Google sin almacenar datos bancarios.
- **Traducida en 10 Idiomas**: `es`, `en`, `pt`, `zh`, `fr`, `hi`, `de`, `ja`, `ko`, `ru`.

---

## 5. 🚀 ESTADO EN GOOGLE PLAY CONSOLE (EN REVISIÓN)
- **Cuenta de Desarrollador**: Verificación de identidad **APROBADA** en Google Play Console (`ID: 7478631796851696861`).
- **Lanzamiento de Pruebas Cerradas (14 Cambios Enviados a Revisión)**:
  - **Paquete Firmado Oficial de Producción**: `build/app/outputs/bundle/release/app-release.aab` (55.1 MB) firmado con `upload-keystore.jks` (configurado en `android/key.properties` y `android/app/build.gradle.kts`).
  - **Credenciales de Revisor de Google**:  
    - Email: `google.reviewer@segurcel.app`  
    - Contraseña: `ReviewerPass2026!`  
    - PIN Maestro de Prueba: `1234`
  - **Formularios de Contenido**: Política de Privacidad (`https://segurcel.app/privacy`), Acceso a la App (Instrucciones con credenciales), Anuncios (No), Clasificación (PEGI 3 / All ages), Público (18+), Funciones Financieras (No), ID de Publicidad (No), Datos Recopilados (Email, ID de Usuario y ID de Dispositivo obligatorios para gestión de cuenta cifrada en tránsito TLS 1.3).
  - **Imágenes de la Tienda**: Ícono 512x512 PNG (`build/app/icon_512.png`) y Banner 1024x500 PNG (`build/app/feature_graphic_1024x500.png`).

---

## 6. 🛠️ ESTRUCTURA Y CÓDIGO REFACTORIZADO
- `lib/screens/setup_screen.dart` refactorizado en componentes modulares (`lib/widgets/pin_creation_form.dart`, `recovery_code_card.dart`, `recovery_confirmation_dialog.dart`).
- `lib/screens/home_screen.dart` refactorizado de 2087 a 360 líneas en componentes modulares en `lib/widgets/home/`.

---

## 7. 🎯 INSTRUCCIONES PARA EL PRÓXIMO CHAT / AGENTE IA
Cuando se abra una nueva sesión de chat:
1. El agente debe leer este `CONTEXT_LOG.md`.
2. Si Google aprueba la revisión de Pruebas Cerradas, el próximo paso será revisar los comentarios de los 20 testers durante los 14 días y preparar la promoción final a **Producción**.
