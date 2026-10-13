# CONTEXT_LOG.md - RESUMEN COMPLETO DE PROYECTO, ARQUITECTURA Y ESTADO PARA AGENTE IA

Este archivo contiene el contexto técnico y funcional completo de **SegurCel** para que cualquier nuevo agente IA comprenda la arquitectura del sistema, el estado de producción en Google Play Console, la configuración de la Bóveda Web, la extensión de navegador, la localización en 10 idiomas y los pasos inmediatos al iniciar una nueva sesión de chat.

---

## 1. 📌 INFORMACIÓN GENERAL Y RECURSOS DEL PROYECTO
- **Nombre Oficial de la App**: SegurCel - Bóveda & 2FA (`com.segurcel.segurcel`)
- **Versión Actual**: 1.0.0 (Build 1)
- **Framework**: Flutter 3.41.8 / Dart 3.11.5 (Android & Web)
- **Dominio Oficial & Hosting**: `https://segurcel.app` (Proyecto Firebase: `segurcel-45c92`)
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
- **Bordes Iluminados Fijos**: Tarjetas de características (`.feature-card`) y marcos de teléfono (`.phone-frame`) con borde violeta fijo e iluminado (`border: 1.5px solid rgba(108, 99, 255, 0.5);`) constante.
- **Capturas PNG en Alta Definición**: Muestra capturas reales de la aplicación móvil en marcos HD (`pantalla_principal.png`, `auditoria_boveda.png`, `ingreso_pin.png`, `agregar_elementos.png`).
- **Responsividad Móvil**: Reglas CSS `@media (max-width: 768px)` con `flex-wrap: wrap` y paddings flexibles para garantizar que textos extensos en alemán (`Benutzerhandbuch`, `Tresor öffnen`) y ruso no se desborden.

---

## 5. 📜 POLÍTICA DE PURGA POR INACTIVIDAD (180 DÍAS) & GOOGLE PLAY
- **Seguimiento de Actividad**: `VaultService.fetchUserProfile()` registra automáticamente `last_login_at: FieldValue.serverTimestamp()` en Firestore en cada uso de la app o Bóveda Web.
- **Sección 4 de la Política de Privacidad (`https://segurcel.app/privacy`)**:
  - *Eliminación Autónoma:* Exclusiva dentro de la sesión autenticada en la App o Bóveda Web (`https://segurcel.app/vault`).
  - *Purga Automática por Inactividad (180 Días):* Notificación de advertencia previa al correo registrado tras 180 días sin logins y eliminación definitiva automática si no se reconfirma el uso activo.
  - *Cláusula Google Play Billing:* Procesa suscripciones únicamente por el sistema de Google sin almacenar datos bancarios.
- **Traducida en 10 Idiomas**: `es`, `en`, `pt`, `zh`, `fr`, `hi`, `de`, `ja`, `ko`, `ru`.

---

## 6. 🚀 ESTADO EN GOOGLE PLAY CONSOLE (EN REVISIÓN)
- **Cuenta de Desarrollador**: Verificación de identidad **APROBADA** en Google Play Console (`ID: 7478631796851696861`).
- **Lanzamiento de Pruebas Cerradas (14 Cambios Enviados a Revisión)**:
  - **Paquete Firmado Oficial de Producción**: `build/app/outputs/bundle/release/app-release.aab` (55.1 MB) firmado con `upload-keystore.jks` (configurado en `android/key.properties` y `android/app/build.gradle.kts`).
  - **Aislamiento Garantizado**: El archivo `.aab` subido a Google Play Console permanece 100% congelado, sellado e inalterado por las actualizaciones web.
  - **Credenciales de Revisor de Google**:  
    - Email: `google.reviewer@segurcel.app`  
    - Contraseña: `ReviewerPass2026!`  
    - PIN Maestro de Prueba: `1234`
  - **Formularios de Contenido**: Política de Privacidad (`https://segurcel.app/privacy`), Acceso a la App (Instrucciones con credenciales), Anuncios (No), Clasificación (PEGI 3 / All ages), Público (18+), Funciones Financieras (No), ID de Publicidad (No), Datos Recopilados (Email, ID de Usuario y ID de Dispositivo obligatorios para gestión de cuenta cifrada en tránsito TLS 1.3).
  - **Imágenes de la Tienda**: Ícono 512x512 PNG (`build/app/icon_512.png`) y Banner 1024x500 PNG (`build/app/feature_graphic_1024x500.png`).

---

## 7. 🛠️ CÓDIGO REFACTORIZADO Y COMPONENTES
- `lib/screens/setup_screen.dart` refactorizado en componentes modulares (`lib/widgets/pin_creation_form.dart`, `recovery_code_card.dart`, `recovery_confirmation_dialog.dart`).
- `lib/screens/home_screen.dart` refactorizado de 2087 a 360 líneas en componentes modulares en `lib/widgets/home/`.
- `lib/screens/my_devices_screen.dart` adaptado para traducción dinámica mediante `LocalizationService`.
- `lib/screens/login_screen.dart` & `lib/screens/pin_screen.dart` equipados con manejadores de eventos de teclado físico.

---

## 8. 🗺️ HOJA DE RUTA (ROADMAP) Y PRÓXIMOS PASOS
1. **[EN PROGRESO] Pruebas Cerradas de Google Play:**
   - Mantener a los 20 testers probando activamente la app durante los 14 días consecutivos requeridos por Google Play.
2. **[PRÓXIMO PASO] Promoción a Producción:**
   - Tras la aprobación oficial de los 14 cambios y la finalización del período de 14 días de pruebas cerradas, promover el lanzamiento a la pista de **Producción** en Google Play Console.
