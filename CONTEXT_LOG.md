# CONTEXT_LOG.md - RESUMEN COMPLETO DE PROYECTO, ARQUITECTURA Y ESTADO PARA AGENTE IA

Este archivo contiene el contexto técnico y funcional completo de **SegurCel** para que cualquier nuevo agente IA comprenda la arquitectura del sistema, el estado de producción en Google Play Console, la configuración de la Bóveda Web, la extensión de navegador, la localización en 10 idiomas y los pasos inmediatos al iniciar una nueva sesión de chat.

---

## 1. 📌 INFORMACIÓN GENERAL Y RECURSOS DEL PROYECTO
- **Nombre Oficial de la App**: SegurCel - Bóveda & 2FA (`com.segurcel.segurcel`)
- **Versión Actual**: 1.0.0 (Build 1)
- **Framework**: Flutter 3.41.8 / Dart 3.11.5 (Android & Web)
- **Dominio Oficial & Hosting**: `https://segurcel.app` (Proyecto Firebase: `segurcel-45c92`)
- **Dominio de Respaldo Directo**: `https://segurcel-45c92.web.app`
- **Usuario GitHub**: `ambuydev`
- **Repositorio Público GitHub**: `https://github.com/ambuydev/SegurCel.git`
- **Ramas Sincronizadas**: `master` y `feature/browser-extension`

---

## 2. 🛡️ ARQUITECTURA DE SEGURIDAD ZERO-KNOWLEDGE
- **Cifrado End-to-End (E2EE)**: Cifrado local en dispositivo usando **AES-256-GCM** y derivación de clave maestra con **PBKDF2WithHmacSHA256** (65.536 iteraciones).
- **Protección Anti-Fuerza Bruta**: Autodestrucción de datos locales tras 3 intentos fallidos de PIN de 4 dígitos.
- **Confirmación Obligatoria de Código de Recuperación**: Modal interactivo con temporizador de 10 segundos antes de finalizar la instalación inicial para evitar pérdida accidental del código.
- **Autenticador 2FA TOTP**: Generador integrado de códigos de 6 dígitos con temporizador circular de 30 segundos y copia en 1 toque.
- **Salud de la Bóveda**: Escáner inteligente de fortaleza global (0 al 100%) que detecta contraseñas débiles, repetidas o antiguas.
- **Límite Freemium Transparente**: 20 contraseñas y 2 cuentas 2FA TOTP en el plan gratuito. Ilimitado en planes PRO/Familiar.

---

## 3. 🌐 BÓVEDA WEB, NAVEGACIÓN Y TECLADO FÍSICO
- **Soporte de Teclado Físico en PC/Mac**:
  - **`LoginScreen`**: Tecla `Enter` en campos de texto de correo y contraseña envía el formulario e inicia sesión automáticamente.
  - **`PinScreen`**: `KeyboardListener` con `FocusNode` que permite la digitación de PIN numérico (`0`-`9` / Numpad), borrado de dígitos (`Backspace`) y confirmación de desbloqueo (`Enter`).
- **Traducción Integral de `MyDevicesScreen`**: Título (`my_devices_title`) y elementos de rastreo de emergencia de Google y Apple 100% localizados en los 10 idiomas oficiales (`lib/services/localization_service.dart`).
- **Extensión para Navegadores (PC/Mac)**: Ubicada en `extension/` (Manifest V3, Web Crypto API y Firebase REST API). Empaquetada en `web/segurcel-extension.zip`.
- **Módulo JavaScript Reutilizable (`web/navbar.js`)**: Encabezado compartido, banderas HD (`https://flagcdn.com`), selector desplegable de 10 idiomas, traducción de `btnBack` y footer multilingüe.
- **Rutas Limpias Nativas (*Clean URLs*)**: Todos los enlaces utilizan rutas sin `.html` (`/`, `/guide`, `/privacy`, `/vault`) compatibles con `"cleanUrls": true` de Firebase Hosting para prevenir errores `ERR_TOO_MANY_REDIRECTS`.
- **Sincronización de Parámetros URL**: `SegurCelNav.selectLanguage()` actualiza la barra de direcciones con `window.history.replaceState(null, '', '?lang=' + lang)`.

---

## 4. 🖼️ DISEÑO Y ESTÉTICA DE LA LANDING PAGE (`https://segurcel.app`)
- **Infografía Nativa Cibersegura CSS3/HTML**:
  - **Escudo Central Imponente (`250px x 250px`)**: Muestra la imagen oficial `assets/html/logo_circuitos.jpeg` con esquinas de `46px`, superpuesta en la capa superior (`z-index: 10; position: relative;`) con animación de pulso y doble resplandor neón cian/púrpura.
  - **8 Conectores Convergentes**: Conectores cian y púrpura pulsantes inclinados a 35° (200px de longitud) que convergen desde las 4 tarjetas de la izquierda y las 4 tarjetas de la derecha directamente hacia los bordes del escudo central.
  - **8 Tarjetas Vivas de Características**: Fondo glassmorphism con resplandor suave y traducción automática en los 10 idiomas oficiales.
- **Carruseles de Demostración Paralelos (Mobile First & PC)**:
  - **Carrusel Móvil**: Primero en secuencia, marcos HD de 220px en rotación circular de plano paralelo (`ingreso_pin.png`, `pantalla_principal.png`, `auditoria_boveda.png`, `agregar_elementos.png`).
  - **Carrusel PC Desktop**: Segundo en secuencia, marcos PC HD de 590px x 395px (`ingreso_pc.png`, `pantalla_principal_pc.png`, `settings_pc.png`, `my_devices_pc.png`).
- **Re-orientación de Botones Android para Pruebas Cerradas**:
  - **Botón Hero Destacado**: Redirige al enlace de invitación web oficial de la prueba cerrada (`https://play.google.com/apps/testing/com.segurcel.segurcel`).
  - **Botón CTA Inferior**: Conserva únicamente el acceso directo a la Bóveda Web (`/vault`).
  - **Sincronización Multilingüe**: Auditada en los 10 idiomas (`es`, `en`, `pt`, `zh`, `fr`, `hi`, `de`, `ja`, `ko`, `ru`).

---

## 5. 📜 POLÍTICA DE PURGA POR INACTIVIDAD (180 DÍAS) & GOOGLE PLAY
- **Seguimiento de Actividad**: `VaultService.fetchUserProfile()` registra automáticamente `last_login_at: FieldValue.serverTimestamp()` en Firestore en cada uso de la app o Bóveda Web.
- **Sección 4 de la Política de Privacidad (`https://segurcel.app/privacy`)**:
  - *Eliminación Autónoma:* Exclusiva dentro de la sesión autenticada en la App o Bóveda Web (`https://segurcel.app/vault`).
  - *Purga Automática por Inactividad (180 Días):* Notificación de advertencia previa al correo registrado tras 180 días sin logins y eliminación definitiva automática si no se reconfirma el uso activo.
  - *Cláusula Google Play Billing:* Procesa suscripciones únicamente por el sistema de Google sin almacenar datos bancarios.
- **Traducida en 10 Idiomas**: `es`, `en`, `pt`, `zh`, `fr`, `hi`, `de`, `ja`, `ko`, `ru`.

---

## 6. 🚀 ESTADO EN GOOGLE PLAY CONSOLE (APROBADO Y EN PRUEBAS CERRADAS)
- **Cuenta de Desarrollador**: Verificación de identidad **APROBADA** en Google Play Console (`ID: 7478631796851696861`).
- **Estado de Publicación**: **APROBADO Y PUBLICADO EN PISTA ALPHA**. "No tienes cambios no publicados".
- **Paquete Firmado Oficial de Producción**: `build/app/outputs/bundle/release/app-release.aab` (55.1 MB) firmado con `upload-keystore.jks` (configurado en `android/key.properties` y `android/app/build.gradle.kts`).
- **Credenciales de Revisor de Google**:  
  - Email: `google.reviewer@segurcel.app`  
  - Contraseña: `ReviewerPass2026!`  
  - PIN Maestro de Prueba: `1234`
- **Mecanismo de Opt-In para Testers (Brasil / LATAM)**:
  - Enlace de invitación oficial: `https://play.google.com/apps/testing/com.segurcel.segurcel`
  - Requisito: Los correos Gmail de los testers deben agregarse previamente en Google Play Console para que puedan presionar **"Convertirse en probador"** e iniciar el contador obligatorio de **14 días**.

---

## 7. 🛠️ CÓDIGO REFACTORIZADO Y COMPONENTES
- `lib/screens/setup_screen.dart` refactorizado en componentes modulares (`lib/widgets/pin_creation_form.dart`, `recovery_code_card.dart`, `recovery_confirmation_dialog.dart`).
- `lib/screens/home_screen.dart` refactorizado de 2087 a 360 líneas en componentes modulares en `lib/widgets/home/`.
- `lib/screens/my_devices_screen.dart` adaptado para traducción dinámica mediante `LocalizationService`.
- `lib/screens/login_screen.dart` & `lib/screens/pin_screen.dart` equipados con manejadores de eventos de teclado físico.

---

## 8. 🗺️ HOJA DE RUTA (ROADMAP) Y PRÓXIMOS PASOS
1. **[EN PROGRESO] Reclutamiento y Ejecución de Pruebas Cerradas (14 Días):**
   - Cargar las direcciones Gmail de los testers (Brasil / LATAM) en la lista de probadores de Google Play Console.
   - Compartir el enlace `https://segurcel.app/` o `https://play.google.com/apps/testing/com.segurcel.segurcel`.
   - Completar el período obligatorio de 14 días consecutivos con al menos 20 testers activos.
2. **[PRÓXIMO PASO] Promoción a Producción:**
   - Promover la versión aprobada `1.0.0 (1)` a la pista de **Producción Pública** en Google Play Console.
