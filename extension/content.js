/**
 * SegurCel Browser Extension - Content Script
 * Inyección en páginas web para autocompletado inteligente de credenciales en 1 clic
 */

(() => {
  // Escuchar mensajes desde Background Service Worker o Popup
  chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === 'AUTOFILL_FORM') {
      autofillCredentials(request.username, request.password);
      sendResponse({ success: true });
    }
  });

  // Función principal de autocompletado
  function autofillCredentials(username, password) {
    const passwordInputs = Array.from(document.querySelectorAll('input[type="password"]'));

    if (passwordInputs.length === 0) {
      console.warn('[SegurCel] No se encontró ningún campo de contraseña en la página.');
      return;
    }

    const passwordInput = passwordInputs[0];
    const form = passwordInput.closest('form') || document;

    // Buscar campo de usuario dentro del mismo formulario o página
    let usernameInput = form.querySelector('input[type="email"], input[type="text"], input[name*="user"], input[name*="email"], input[id*="user"], input[id*="email"]');

    if (usernameInput && username) {
      _setNativeValue(usernameInput, username);
      usernameInput.dispatchEvent(new Event('input', { bubbles: true }));
      usernameInput.dispatchEvent(new Event('change', { bubbles: true }));
    }

    if (passwordInput && password) {
      _setNativeValue(passwordInput, password);
      passwordInput.dispatchEvent(new Event('input', { bubbles: true }));
      passwordInput.dispatchEvent(new Event('change', { bubbles: true }));
    }

    // Efecto de resaltado visual
    passwordInput.style.transition = 'box-shadow 0.3s ease';
    passwordInput.style.boxShadow = '0 0 10px #6C63FF';
    setTimeout(() => {
      passwordInput.style.boxShadow = '';
    }, 1500);
  }

  // Permite sobreescribir valores en marcos React / Angular / Vue que interceptan setters de HTMLInputElement
  function _setNativeValue(element, value) {
    const valueSetter = Object.getOwnPropertyDescriptor(element, 'value')?.set;
    const prototype = Object.getPrototypeOf(element);
    const prototypeValueSetter = Object.getOwnPropertyDescriptor(prototype, 'value')?.set;

    if (prototypeValueSetter && valueSetter !== prototypeValueSetter) {
      prototypeValueSetter.call(element, value);
    } else if (valueSetter) {
      valueSetter.call(element, value);
    } else {
      element.value = value;
    }
  }

  // Detectar y agregar ícono flotante de SegurCel junto a campos de contraseña
  function attachSegurCelIconToPasswordInputs() {
    const passwordInputs = document.querySelectorAll('input[type="password"]:not([data-segurcel-attached])');

    passwordInputs.forEach((input) => {
      input.setAttribute('data-segurcel-attached', 'true');

      // Crear botón Flotante SegurCel
      const badge = document.createElement('div');
      badge.className = 'segurcel-autofill-badge';
      badge.title = 'Autocompletar con SegurCel';
      badge.innerHTML = `
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 2L3 7V11C3 16.55 6.84 21.74 12 23C17.16 21.74 21 16.55 21 11V7L12 2Z" fill="#6C63FF"/>
          <path d="M12 7V17M9 12H15" stroke="white" stroke-width="2" stroke-linecap="round"/>
        </svg>
      `;

      // Estilos CSS del botón flotante
      Object.assign(badge.style, {
        position: 'absolute',
        cursor: 'pointer',
        zIndex: '99999',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '2px',
        borderRadius: '50%',
        backgroundColor: '#1E2538',
        boxShadow: '0 2px 6px rgba(0,0,0,0.4)',
        transition: 'transform 0.2s ease, background-color 0.2s ease'
      });

      badge.addEventListener('mouseenter', () => {
        badge.style.transform = 'scale(1.15)';
        badge.style.backgroundColor = '#6C63FF';
      });

      badge.addEventListener('mouseleave', () => {
        badge.style.transform = 'scale(1)';
        badge.style.backgroundColor = '#1E2538';
      });

      badge.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();

        const domain = window.location.hostname;
        chrome.runtime.sendMessage(
          { action: 'GET_MATCHING_CREDENTIALS', domain: domain },
          (response) => {
            if (!response || !response.success || !response.matches || response.matches.length === 0) {
              alert('Abre la extensión de SegurCel en la barra de herramientas para desbloquear tu bóveda o seleccionar una contraseña.');
              return;
            }

            const match = response.matches[0];
            autofillCredentials(match.username, match.password);
          }
        );
      });

      // Posicionar el badge relativo al input
      const parent = input.parentElement;
      if (parent) {
        const computedStyle = window.getComputedStyle(parent);
        if (computedStyle.position === 'static') {
          parent.style.position = 'relative';
        }
        badge.style.right = '8px';
        badge.style.top = '50%';
        badge.style.transform = 'translateY(-50%)';
        parent.appendChild(badge);
      }
    });
  }

  // Ejecutar al cargar la página y observar cambios dinámicos en el DOM
  attachSegurCelIconToPasswordInputs();

  const observer = new MutationObserver(() => {
    attachSegurCelIconToPasswordInputs();
  });

  observer.observe(document.body, { childList: true, subtree: true });
})();
