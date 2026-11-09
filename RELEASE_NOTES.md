# SegurCel - Historial Oficial de Notas de Versión (Release Notes)

Este documento registra el historial público y técnico de las notas de lanzamiento de **SegurCel - Bóveda & 2FA** para Google Play Console, Apple App Store / TestFlight y Bóveda Web.

---

## 🚀 Versión 1.1.0 (Build 9) - Actualización Mayor Actual
* **Parche de Seguridad de Google Firebase:** Implementación del parche de seguridad TLS oficial de Google Firebase para cifrado y conexiones de datos.
* **Traducción Completa en 14 Idiomas:** Internacionalización total de todos los botones de diálogo, pantallas de inicio de sesión, registro, gestión de suscripciones y confirmación de eliminación de cuenta.
* **Mejoras de Rendimiento:** Optimizaciones en la sincronización en la nube y estabilidad de la bóveda.

---

## 📦 Versión 1.0.6 (Build 8)
* **Traducción de Cuadros de Diálogo:** Internacionalización de botones de diálogo en los 14 idiomas.
* **Privacidad de Desarrollador:** Créditos de desarrollador actualizados a A.M.B.

---

## 📦 Versión 1.0.5 (Build 7)
* **Respaldo cifrado (.segurcel):** Crea y restaura respaldos con cifrado PBKDF2 y AES-256.
* **Restauración inteligente:** Evita registros duplicados al restaurar.
* **Selección de archivos mejorada:** Soporte total para archivos `*.segurcel` sin bloqueos por inactividad.
* **14 Idiomas globales:** Chino Tradicional, Árabe (con maquetación RTL) e Indonesio.

---

## 🎨 Versión 1.0.4 (Build 5)
* **Guía de bienvenida interactiva:** Guía paso a paso para nuevos usuarios al iniciar la app.
* **Selector de temas:** Personaliza la app entre Modo Oscuro, Modo Claro o Tema del Sistema.
* **Temporizador de auto-bloqueo:** Configuración de bloqueo automático por inactividad (1 min, 5 min, 15 min o Nunca).
* **Nuevo idioma global:** Incorporación oficial de Italiano (🇮🇹).

---

## 🔐 Versión 1.0.3 (Build 4)
* **Soporte de teclado físico en PC/Mac:** Atajos de teclado para inicio de sesión (Enter) y digitación de PIN numérico.
* **Selector inteligente de categorías:** Categorización dinámica con creación automática de nuevas categorías.
* **Rutas limpias y sincronización URL:** Navegación web sin extensiones `.html` y sincronización limpia de idiomas.

---

## 🛡️ Versión 1.0.2 (Build 3)
* **Cifrado Zero-Knowledge End-to-End:** Cifrado local AES-256-GCM y PBKDF2 (65,536 iteraciones).
* **Autenticador 2FA TOTP:** Generador de códigos dinámicos de 6 dígitos con temporizador de 30 segundos.
* **Protocolo de autodestrucción:** Protección anti-fuerza bruta tras 3 intentos fallidos de PIN.
* **Código de recuperación de emergencia:** Clave de rescate única para recuperar la bóveda en caso de olvido del PIN.
