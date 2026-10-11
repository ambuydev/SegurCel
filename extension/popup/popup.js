/**
 * SegurCel Browser Extension - Popup Controller UI
 */

document.addEventListener('DOMContentLoaded', async () => {
  // Elementos UI
  const headerActions = document.getElementById('header-actions');
  const btnLock = document.getElementById('btn-lock');
  const btnLogout = document.getElementById('btn-logout');

  const viewLogin = document.getElementById('view-login');
  const viewPin = document.getElementById('view-pin');
  const viewVault = document.getElementById('view-vault');

  // Login Inputs
  const loginEmail = document.getElementById('login-email');
  const loginPassword = document.getElementById('login-password');
  const btnLogin = document.getElementById('btn-login');
  const loginError = document.getElementById('login-error');

  // PIN Inputs
  const userEmailDisplay = document.getElementById('user-email-display');
  const pinInput = document.getElementById('pin-input');
  const btnUnlock = document.getElementById('btn-unlock');
  const pinError = document.getElementById('pin-error');

  // Vault Controls
  const searchInput = document.getElementById('search-input');
  const tabMatches = document.getElementById('tab-matches');
  const tabAll = document.getElementById('tab-all');
  const tabGenerator = document.getElementById('tab-generator');
  const entriesContainer = document.getElementById('entries-container');
  const generatorPanel = document.getElementById('generator-panel');

  // Generator Elements
  const genPasswordDisplay = document.getElementById('gen-password-display');
  const btnCopyGen = document.getElementById('btn-copy-gen');
  const genLength = document.getElementById('gen-length');
  const genLengthVal = document.getElementById('gen-length-val');
  const btnGenerateNew = document.getElementById('btn-generate-new');

  let activeTabName = 'matches';
  let cachedEntries = [];
  let currentDomain = '';

  // 1. Obtener dominio de la pestaña activa
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tab?.url) {
      const urlObj = new URL(tab.url);
      currentDomain = urlObj.hostname.toLowerCase().replace('www.', '');
    }
  } catch (_) {}

  // 2. Consultar Estado Actual
  await checkStatus();

  async function checkStatus() {
    const response = await chrome.runtime.sendMessage({ action: 'GET_STATUS' });
    if (!response || !response.success) return;

    if (!response.isLoggedIn) {
      showView(viewLogin);
      headerActions.classList.add('hidden');
    } else if (!response.isUnlocked) {
      showView(viewPin);
      headerActions.classList.remove('hidden');
      if (response.userEmail) userEmailDisplay.textContent = response.userEmail;
      pinInput.value = '';
      pinInput.focus();
    } else {
      showView(viewVault);
      headerActions.classList.remove('hidden');
      await loadVaultEntries();
    }
  }

  // Evento: Iniciar Sesión
  btnLogin.addEventListener('click', async () => {
    const email = loginEmail.value.trim();
    const password = loginPassword.value.trim();

    if (!email || !password) {
      showError(loginError, 'Por favor ingresa tu correo y contraseña.');
      return;
    }

    loginError.classList.add('hidden');
    btnLogin.disabled = true;

    try {
      const res = await chrome.runtime.sendMessage({
        action: 'LOGIN',
        email,
        password
      });

      btnLogin.disabled = false;
      if (res.success) {
        await checkStatus();
      } else {
        showError(loginError, res.error || 'Error al iniciar sesión.');
      }
    } catch (e) {
      btnLogin.disabled = false;
      showError(loginError, e.message);
    }
  });

  // Evento: Desbloquear por PIN
  btnUnlock.addEventListener('click', async () => {
    await submitPinUnlock();
  });

  pinInput.addEventListener('keyup', async (e) => {
    if (e.key === 'Enter' || pinInput.value.length === 4) {
      await submitPinUnlock();
    }
  });

  async function submitPinUnlock() {
    const pin = pinInput.value.trim();
    if (pin.length < 4) {
      showError(pinError, 'Ingresa tu PIN de 4 dígitos.');
      return;
    }

    pinError.classList.add('hidden');
    btnUnlock.disabled = true;

    try {
      const res = await chrome.runtime.sendMessage({
        action: 'UNLOCK_PIN',
        pin
      });

      btnUnlock.disabled = false;
      if (res.success) {
        await checkStatus();
      } else {
        showError(pinError, res.error || 'PIN incorrecto.');
        pinInput.value = '';
      }
    } catch (e) {
      btnUnlock.disabled = false;
      showError(pinError, e.message);
      pinInput.value = '';
    }
  }

  // Evento: Bloquear Bóveda
  btnLock.addEventListener('click', async () => {
    await chrome.runtime.sendMessage({ action: 'LOCK_VAULT' });
    await checkStatus();
  });

  // Evento: Cerrar Sesión
  btnLogout.addEventListener('click', async () => {
    await chrome.runtime.sendMessage({ action: 'LOGOUT' });
    await checkStatus();
  });

  // Carga de Entradas de la Bóveda
  async function loadVaultEntries() {
    const res = await chrome.runtime.sendMessage({ action: 'GET_ENTRIES' });
    if (res.success) {
      cachedEntries = res.entries || [];
      renderEntries();
    }
  }

  // Renderizado de Lista de Contraseñas
  function renderEntries() {
    if (activeTabName === 'generator') {
      entriesContainer.classList.add('hidden');
      generatorPanel.classList.remove('hidden');
      generatePassword();
      return;
    }

    entriesContainer.classList.remove('hidden');
    generatorPanel.classList.add('hidden');
    entriesContainer.innerHTML = '';

    const searchTerm = searchInput.value.toLowerCase().trim();

    let filtered = cachedEntries.filter((entry) => {
      const title = (entry.title || '').toLowerCase();
      const url = (entry.url || '').toLowerCase();
      const user = (entry.username || '').toLowerCase();

      if (searchTerm) {
        return title.includes(searchTerm) || url.includes(searchTerm) || user.includes(searchTerm);
      }

      if (activeTabName === 'matches' && currentDomain) {
        return title.includes(currentDomain) || url.includes(currentDomain) || currentDomain.includes(title);
      }

      return true;
    });

    if (filtered.length === 0) {
      entriesContainer.innerHTML = `
        <div class="empty-state">
          ${activeTabName === 'matches' ? `No hay credenciales guardadas para "${currentDomain}".` : 'No se encontraron contraseñas.'}
        </div>
      `;
      return;
    }

    filtered.forEach((entry) => {
      const card = document.createElement('div');
      card.className = 'entry-card';

      const hasTotp = !!entry.totpSecret;

      card.innerHTML = `
        <div class="entry-header">
          <div>
            <div class="entry-title">${_escapeHtml(entry.title || 'Sin Título')}</div>
            <div class="entry-user">${_escapeHtml(entry.username || '')}</div>
          </div>
          <button class="btn-sm btn-autofill">⚡ Llenar</button>
        </div>
        <div class="entry-actions">
          <button class="btn-secondary btn-copy-user">👤 Usuario</button>
          <button class="btn-secondary btn-copy-pass">🔑 Clave</button>
          ${hasTotp ? `<button class="totp-badge btn-copy-totp">🔢 2FA</button>` : ''}
        </div>
      `;

      // Evento: Autocompletar
      card.querySelector('.btn-autofill').addEventListener('click', async () => {
        await chrome.runtime.sendMessage({
          action: 'TRIGGER_AUTOFILL',
          username: entry.username,
          password: entry.password
        });
        window.close(); // Cerrar popup tras llenar
      });

      // Eventos de Copia
      card.querySelector('.btn-copy-user').addEventListener('click', () => {
        navigator.clipboard.writeText(entry.username || '');
        _flashBtn(card.querySelector('.btn-copy-user'), '¡Copiado!');
      });

      card.querySelector('.btn-copy-pass').addEventListener('click', () => {
        navigator.clipboard.writeText(entry.password || '');
        _flashBtn(card.querySelector('.btn-copy-pass'), '¡Copiada!');
      });

      if (hasTotp) {
        const totpBtn = card.querySelector('.btn-copy-totp');
        totpBtn.addEventListener('click', async () => {
          const res = await chrome.runtime.sendMessage({
            action: 'GENERATE_TOTP',
            secret: entry.totpSecret
          });
          if (res.success) {
            navigator.clipboard.writeText(res.otp);
            _flashBtn(totpBtn, `¡${res.otp}!`);
          }
        });
      }

      entriesContainer.appendChild(card);
    });
  }

  // Pestañas
  tabMatches.addEventListener('click', () => {
    setActiveTab('matches', tabMatches);
  });

  tabAll.addEventListener('click', () => {
    setActiveTab('all', tabAll);
  });

  tabGenerator.addEventListener('click', () => {
    setActiveTab('generator', tabGenerator);
  });

  function setActiveTab(name, element) {
    activeTabName = name;
    [tabMatches, tabAll, tabGenerator].forEach((t) => t.classList.remove('active'));
    element.classList.add('active');
    renderEntries();
  }

  // Búsqueda
  searchInput.addEventListener('input', () => {
    renderEntries();
  });

  // Generador de Contraseñas
  genLength.addEventListener('input', () => {
    genLengthVal.textContent = genLength.value;
    generatePassword();
  });

  btnGenerateNew.addEventListener('click', () => {
    generatePassword();
  });

  btnCopyGen.addEventListener('click', () => {
    navigator.clipboard.writeText(genPasswordDisplay.textContent);
    _flashBtn(btnCopyGen, '¡Copiado!');
  });

  async function generatePassword() {
    const res = await chrome.runtime.sendMessage({
      action: 'GENERATE_PASSWORD',
      length: parseInt(genLength.value, 10)
    });
    if (res.success) {
      genPasswordDisplay.textContent = res.password;
    }
  }

  function showView(viewElement) {
    [viewLogin, viewPin, viewVault].forEach((v) => v.classList.add('hidden'));
    viewElement.classList.remove('hidden');
  }

  function showError(element, msg) {
    element.textContent = msg;
    element.classList.remove('hidden');
  }

  function _flashBtn(btn, text) {
    const originalText = btn.textContent;
    btn.textContent = text;
    setTimeout(() => {
      btn.textContent = originalText;
    }, 1200);
  }

  function _escapeHtml(str) {
    return str.replace(/[&<>"']/g, (m) => {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' }[m];
    });
  }
});
