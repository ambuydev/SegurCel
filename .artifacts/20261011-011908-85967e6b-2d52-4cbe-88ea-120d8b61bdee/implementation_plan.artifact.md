# Plan de Implementación: Menú Desplegable de Categorías y Elevación de Versión a 1.0.1 (Build 2)

Implementar el selector desplegable de categorías existentes con la opción de crear nueva categoría en el modal `AddEditEntrySheet`, y elevar el número de versión oficial de la aplicación de `1.0.0+1` a `1.0.1+2` en todos los archivos correspondientes:

1. **Traducciones en `lib/services/localization_service.dart` (10 Idiomas):**
   - `select_category`: "Seleccionar categoría" / "Select category" / "Selecionar categoria"
   - `new_category_option`: "+ Nueva categoría..." / "+ New category..." / "+ Nova categoria..."
   - `new_category_label`: "Nombre de la nueva categoría" / "New category name" / "Nome da nova categoria"

2. **Lógica de Categorías en `lib/widgets/home/add_edit_entry_sheet.dart`:**
   - Extraer todas las categorías únicas creadas en la bóveda (`widget.vaultService.entries`).
   - Agregar opciones predeterminadas ("General", "Tarjetas", "Notas").
   - Construir `DropdownButtonFormField<String>` con opciones existentes + `'__NEW_CATEGORY__'`.
   - Si el usuario selecciona `'__NEW_CATEGORY__'`, mostrar el `TextField` para ingresar el nuevo nombre.

3. **Incremento de Versión:**
   - `pubspec.yaml`: `version: 1.0.1+2`
   - `lib/widgets/home/about_app_sheet.dart`: `1.0.1 (Build 2)`
   - `CONTEXT_LOG.md`: `Versión Actual: 1.0.1 (Build 2)`

4. **Compilación y Despliegue:**
   - Recompilar Web (`flutter build web --release`), copiar a `build/web/` y desplegar en Firebase Hosting.
   - Recompilar paquete firmado oficial `.aab` (`flutter build appbundle --release`).
   - Push a GitHub en las ramas `master` y `feature/browser-extension`.

---

## Verification Plan

### Terminal Commands
- Verificar análisis estático en Flutter:
  `flutter analyze`
- Recompilar Bóveda Web y desplegar:
  `flutter build web --release`
  `powershell -Command "Copy-Item -Path build/web/* -Destination web/ -Recurse -Force"`
  `firebase deploy --only hosting`
- Recompilar Bundle Firmado para Android:
  `flutter build appbundle --release`
- Push a GitHub.
