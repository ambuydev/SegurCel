# CONTEXT_LOG.md - RESUMEN DE PROYECTO Y ESTADO PARA AGENTE IA

Este archivo contiene el contexto completo de **SegurCel** para que cualquier nuevo agente IA comprenda la arquitectura, el estado de producción y los pasos inmediatos al iniciar una nueva sesión de chat.

---

## 1. 📌 INFORMACIÓN GENERAL DEL PROYECTO
- **Nombre de la App**: SegurCel (com.segurcel.segurcel)
- **Versión**: 1.0.0 (Build 1)
- **Framework**: Flutter 3.41.8 / Dart 3.11.5 (Android & Web)
- **Dominio Oficial & Hosting**: `https://segurcel.app` (Proyecto Firebase: `segurcel-45c92`)
- **Rama Principal de Git**: `master` (Código limpio, verificado y libre de errores).

---

## 2. 🛡️ ARQUITECTURA Y SEGURIDAD ZERO-KNOWLEDGE
- **Cifrado E2EE**: Cifrado local en dispositivo usando **AES-256-GCM** y derivación de clave clave maestra con **PBKDF2WithHmacSHA256** (65,536 iteraciones).
- **Protección Anti-Fuerza Bruta**: Autodestrucción de datos locales tras 3 intentos fallidos de PIN de 4 dígitos.
- **Autenticador 2FA TOTP**: Generador integrado de códigos de 6 dígitos que cambian cada 30 segundos, con temporizador circular y copia en 1 toque.
- **Salud de la Bóveda**: Escáner inteligente que analiza la seguridad de las contraseñas (0 al 100%) y alerta sobre claves débiles, repetidas o antiguas.

---

## 3. 🌐 ACCESO A LA BÓVEDA WEB & GATEKEEPER FREEMIUM
- **App Móvil Android**: Modelo Freemium (gratuito hasta 20 contraseñas y 2 cuentas TOTP; ilimitado en suscripciones PRO/Familiar).
- **Bóveda Web (`https://segurcel.app/vault.html`)**: Gatekeeper Premium forzado en el navegador de la raíz de Flutter (`main.dart`). Los usuarios con `isPremium == false` son redirigidos a la pantalla de suscripción (`PaywallScreen`).

---

## 4. 👨‍👩‍👧‍👦 SISTEMA DE PASES DE INVITACIÓN VIP (PLAN FAMILIAR)
- Los dueños de Plan Familiar (`isFamilyOwner`) pueden generar hasta 4 códigos VIP únicos (`SEG-XXXXXX-V`) guardados en la colección Firestore `promo_codes/{code}`.
- Un familiar canjea el código en `PaywallScreen`, vinculando `familyOwnerUid: ownerUid` en su documento `users/{uid}`.
- **Cascada de Expiración**: `VaultService.fetchUserProfile()` verifica la suscripción del dueño. Si vence o se cancela, los miembros revierten a cuenta gratuita y los códigos antiguos pasan a `disabled: true`. Al renovar, el dueño recibe 4 nuevos cupos limpios (0/4).
- Se eliminó la colección redundante `family_invites`. Reglas desplegadas en `firestore.rules`.

---

## 5. 🌍 INTERNACIONALIZACIÓN (10 IDIOMAS GLOBALES)
- Soporte completo en la app y web para:
  `es` (Español), `en` (English), `pt` (Português), `zh` (中文), `fr` (Français),
  `hi` (हिन्दी), `de` (Deutsch), `ja` (日本語), `ko` (한국어), `ru` (Русский).
- **Persistencia de Idioma**: Navegación Web propaga el idioma usando `?lang=code` (`https://segurcel.app/?lang=de`, `https://segurcel.app/vault.html?lang=ja`, `https://segurcel.app/guide.html?lang=ru`).
- `LocalizationService.initLanguage()` lee `Uri.base.queryParameters['lang']` al arrancar.

---

## 6. 📱 SITIO WEB Y GUÍA DE USO
- **Página Principal**: `https://segurcel.app/` (`web/landing.html`) con menú de idiomas y banderas HD universales PNG (`https://flagcdn.com`).
- **Manual de Botones y Secciones**: `https://segurcel.app/guide.html` (`web/guide.html`) adaptado 100% a celulares móviles (`@media (max-width: 600px)`).
- **Bóveda Web**: `https://segurcel.app/vault.html` (Con botón traducido `← Volver al Sitio Oficial` que preserva el idioma).

---

## 7. 🚀 ESTADO DE PREPARACIÓN PARA GOOGLE PLAY STORE
- **Cuenta de Desarrollador**: Creada y membresía de $35 pagada por el usuario. **Actualmente en espera de la confirmación de verificación de identidad por correo electrónico de Google.**
- **Paquete Ejecutable Firmado**: `build/app/outputs/bundle/release/app-release.aab` (55.1 MB).
- **Textos de la Tienda**: Guardados en `DESCRIPCION_PLAY_STORE.md` y disponibles en `https://segurcel.app/play_store.txt`.
- **Ícono de Alta Resolución (1024x1024 px)**: Guardado en `PLAY_STORE_ICON_1024x1024.png` y en `https://segurcel.app/play_store_icon_1024.png`.
- **IDs de Producto IAP (Google Play Billing SDK)**:
  1. `segurcel_pro_monthly` ($1.99 USD / mes)
  2. `segurcel_pro_yearly` ($10.99 USD / año)
  3. `segurcel_family_monthly` ($3.99 USD / mes)
  4. `segurcel_family_yearly` ($24.99 USD / año)
  5. `segurcel_pro_rescue_6m` ($8.99 USD / 6 meses)
- **URLs de Cumplimiento**:
  - Política de Privacidad: `https://segurcel.app/privacy.html`
  - Eliminación de Cuenta: `https://segurcel.app/privacy.html#delete-account`
  - Guía Rápida: `https://segurcel.app/guide.html`

---

## 8. 🎯 INSTRUCCIÓN PARA LA NUEVA SESIÓN DE CHAT
En cuanto el usuario reciba la verificación de identidad de Google, abrirá un nuevo chat e indicará:
*"Google Play ya me verificó la identidad, lee CONTEXT_LOG.md y continuemos con la subida del AAB y la configuración de suscripciones."*

El nuevo agente IA leerá este archivo `CONTEXT_LOG.md` o `log.md` y podrá continuar inmediatamente el lanzamiento sin perder ningún detalle.
