# Plan de Implementación: Soporte para Teclado Físico (Enter / Números 0-9) en la Bóveda Web (Login & PinScreen)

Añadir soporte de teclado físico en navegadores web de PC/Mac:
1. **`LoginScreen`:** Activar la tecla `Enter` en los campos de texto de email y contraseña para enviar el formulario e iniciar sesión directamente.
2. **`PinScreen`:** Escuchar los eventos de teclado físico (`KeyboardListener` / `HardwareKeyboard`) para ingresar los dígitos del PIN (0-9), borrar dígitos (`Backspace`) y confirmar el desbloqueo (`Enter`).

## Proposed Changes

### Componente: Pantallas de Flutter (`lib/screens/`)

#### [login_screen.dart](file:///C:/Users/aleja/StudioProjects/SegurCel/lib/screens/login_screen.dart)
- Añadir `onFieldSubmitted: (_) => _signIn()` en el `TextFormField` de contraseña.

#### [pin_screen.dart](file:///C:/Users/aleja/StudioProjects/SegurCel/lib/screens/pin_screen.dart)
- Envolver `PinScreen` con `KeyboardListener` enfocado (`FocusNode`) escuchando teclas numéricas (`0`-`9`), `Backspace` (borrar dígito) y `Enter` (desbloquear).

---

## Verification Plan

### Terminal Commands
- Recompilar la Bóveda Web (`flutter build web --release`).
- Sincronizar en `build/web/` y desplegar en Firebase Hosting:
  `firebase deploy --only hosting`
- Push a GitHub.
