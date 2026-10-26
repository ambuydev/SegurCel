# Plan de Implementación: Aplicación de Correcciones Automáticas de Salud de Código (`dart fix --apply`)

Aplicar las correcciones automáticas recomendadas por la herramienta oficial `dart fix` de Dart SDK:

1. **`lib/widgets/home/add_edit_entry_sheet.dart` (`deprecated_member_use`):**
   - Actualiza el uso de APIs de opacidad/color en Flutter a sus formas modernas no obsoletas.

2. **`tool/check_translations.dart` (`avoid_relative_lib_imports`):**
   - Reemplaza la importación relativa por la importación oficial de paquete (`package:segurcel/services/localization_service.dart`).

---

## Verification Plan

### Terminal Commands
- Ejecutar corrección automática:
  `dart fix --apply`
- Verificar con el analizador estático:
  `flutter analyze`
- Push a GitHub.
