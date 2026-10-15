# Plan de Implementación: Remoción del Botón Secundario del Banner CTA Final

Eliminar el botón secundario `btnCtaPlayStore` ("Ver en Google Play Store") del banner de llamada a la acción final al pie de la página, conservando únicamente el botón principal de acceso a la Bóveda Web (`btnCtaVault`):

1. **Modificación HTML en `web/landing.html` e `index.html`:**
   ```html
   <!-- CTA Banner -->
   <section style="padding: 0 20px;">
       <div class="cta-banner">
           <h2 style="font-size: 28px; font-weight: 800; margin-bottom: 12px;" id="ctaTitle">¿Listo para proteger tu vida digital?</h2>
           <p style="color: var(--text-muted); max-width: 600px; margin: 0 auto 24px;" id="ctaSub">Comienza a usar SegurCel hoy mismo desde cualquier navegador o dispositivo Android.</p>
           <div style="display: flex; justify-content: center; gap: 12px; flex-wrap: wrap;">
               <a href="/vault" class="btn-primary" id="btnCtaVault">🚀 Acceder a SegurCel Web</a>
           </div>
       </div>
   </section>
   ```

---

## Verification Plan

### Terminal Commands
- Sincronizar en `build/web/` y desplegar en Firebase Hosting:
  `firebase deploy --only hosting`
- Push a GitHub.
