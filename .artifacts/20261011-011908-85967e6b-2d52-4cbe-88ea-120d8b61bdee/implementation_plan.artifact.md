# Plan de Implementación: Estandarización de Lista de Planes PRO (pi5) en los 10 Idiomas

Eliminar cualquier mención de precios fijos en dólares ($1.99, $10.99, $24.99) y referencias obsoletas a "Licencia Vitalicia" / "Lifetime License" en la clave `pi5` del diccionario multilingüe `dict` en `web/landing.html` e `index.html`:

1. **Traducciones Estandarizadas de `pi5`:**
   - **`es`:** `"Planes Flexibles: Mensual, Anual, Plan Familiar y Rescate de Emergencia (6 Meses)."`
   - **`en`:** `"Flexible Plans: Monthly, Yearly, Family Plan, and Emergency Rescue (6 Months)."`
   - **`pt`:** `"Planos Flexíveis: Mensal, Anual, Plano Familiar e Resgate de Emergência (6 Meses)."`
   - **`zh`:** `"灵活订阅方案：按月、按年、家庭方案与紧急救援方案 (6 个月)。"`
   - **`fr`:** `"Offres Flexibles : Mensuel, Annuel, Offre Familiale et Sauvetage d'Urgence (6 Mois)."`
   - **`hi`:** `"लचीले प्लान: मासिक, वार्षिक, फैमिली प्लान और आपातकालीन बचाव (6 महीने)।"`
   - **`de`:** `"Flexible Pläne: Monatlich, Jährlich, Familien-Tarif und Notfall-Rettung (6 Monate)."`
   - **`ja`:** `"柔軟なプラン：月額、年額、ファミリープラン、6ヶ月緊急レスキュー。"`
   - **`ko`:** `"유연한 요금제: 월간, 연간, 패밀리 요금제, 6개월 긴급 구조."`
   - **`ru`:** `"Гибкие тарифы: Ежемесячный, Годовой, Семейный и Аварийный (6 месяцев)."`

---

## Verification Plan

### Terminal Commands
- Sincronizar en `build/web/` y desplegar en Firebase Hosting:
  `firebase deploy --only hosting`
- Push a GitHub.
