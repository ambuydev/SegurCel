/**
 * SegurCel Browser Extension - Service Worker (Background Script)
 * Gestiona la sesión en memoria, temporizador de bloqueo y mensajes con Popup y Content Scripts.
 */

import { SegurCelCrypto } from './crypto.js';
import { SegurCelFirebase } from './firebase-service.js';

// Estado en memoria del Service Worker (Se borra al cerrar el navegador o bloquear)
let sessionState = {
  isLoggedIn: false,
  isUnlocked: false,
  user: null, // { uid, email, idToken }
  encryptedVault: null,
  decryptedEntries: [],
  masterKey: null,
  failedAttempts: 0,
  lockTimer: null
};

// Cargar sesión previa guardada en chrome.storage.local (sin datos en claro)
chrome.runtime.onInstalled.addListener(() => {
  console.log('[SegurCel Extension] Instalada correctamente.');
});

// Oyente de Mensajes desde Popup y Content Scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  handleMessage(request, sender)
    .then(sendResponse)
    .catch((err) => sendResponse({ success: false, error: err.message }));
  return true; // Asíncrono
});

async function handleMessage(request, sender) {
  switch (request.action) {
    case 'GET_STATUS': {
      // Si la sesión no tiene idToken, intentar leer de storage.local
      if (!sessionState.isLoggedIn) {
        const stored = await chrome.storage.local.get(['user', 'encryptedVault']);
        if (stored.user && stored.encryptedVault) {
          sessionState.user = stored.user;
          sessionState.encryptedVault = stored.encryptedVault;
          sessionState.isLoggedIn = true;
        }
      }

      return {
        success: true,
        isLoggedIn: sessionState.isLoggedIn,
        isUnlocked: sessionState.isUnlocked,
        userEmail: sessionState.user?.email || null,
        failedAttempts: sessionState.failedAttempts,
        entriesCount: sessionState.decryptedEntries.length
      };
    }

    case 'LOGIN': {
      const { email, password } = request;
      const user = await SegurCelFirebase.loginWithEmailPassword(email, password);
      const encryptedVault = await SegurCelFirebase.fetchEncryptedVault(user.uid, user.idToken);

      sessionState.user = user;
      sessionState.encryptedVault = encryptedVault;
      sessionState.isLoggedIn = true;
      sessionState.isUnlocked = false;

      // Guardar en storage local para acelerar inicios posteriores
      await chrome.storage.local.set({ user, encryptedVault });

      return { success: true };
    }

    case 'UNLOCK_PIN': {
      if (!sessionState.encryptedVault) {
        throw new Error('No se encontró la bóveda en la nube.');
      }

      const pin = request.pin;
      const vault = sessionState.encryptedVault;

      try {
        const pinSalt = SegurCelCrypto.base64ToUint8Array(vault.pinSalt);
        const wrappedKeyBytes = SegurCelCrypto.base64ToUint8Array(vault.wrappedMasterKeyByPin);
        const encryptedDataBytes = SegurCelCrypto.base64ToUint8Array(vault.encryptedPasswordsData);

        // 1. Derivar clave del PIN
        const pinDerivedKey = await SegurCelCrypto.deriveKeyFromPassword(pin, pinSalt);

        // 2. Descifrar Clave Maestra
        const masterKeyBytes = await SegurCelCrypto.decrypt(wrappedKeyBytes, pinDerivedKey);
        const masterKey = await SegurCelCrypto.importRawMasterKey(masterKeyBytes);

        // 3. Descifrar Contraseñas
        const plainBytes = await SegurCelCrypto.decrypt(encryptedDataBytes, masterKey);
        const jsonStr = new TextDecoder().decode(plainBytes);
        const entries = JSON.parse(jsonStr);

        sessionState.masterKey = masterKey;
        sessionState.decryptedEntries = entries;
        sessionState.isUnlocked = true;
        sessionState.failedAttempts = 0;

        _startAutoLockTimer();

        return { success: true, entriesCount: entries.length };
      } catch (e) {
        sessionState.failedAttempts++;
        if (sessionState.failedAttempts >= 3) {
          lockVault();
          throw new Error('PIN incorrecto. Se alcanzó el límite de 3 intentos.');
        }
        throw new Error(`PIN incorrecto. Te quedan ${3 - sessionState.failedAttempts} intento(s).`);
      }
    }

    case 'LOCK_VAULT': {
      lockVault();
      return { success: true };
    }

    case 'LOGOUT': {
      lockVault();
      sessionState.isLoggedIn = false;
      sessionState.user = null;
      sessionState.encryptedVault = null;
      await chrome.storage.local.remove(['user', 'encryptedVault']);
      return { success: true };
    }

    case 'GET_ENTRIES': {
      if (!sessionState.isUnlocked) {
        throw new Error('La bóveda está bloqueada.');
      }
      return { success: true, entries: sessionState.decryptedEntries };
    }

    case 'GET_MATCHING_CREDENTIALS': {
      if (!sessionState.isUnlocked) {
        return { success: false, isUnlocked: false };
      }

      const domain = (request.domain || '').toLowerCase().replace('www.', '');
      const matches = sessionState.decryptedEntries.filter((entry) => {
        const title = (entry.title || '').toLowerCase();
        const url = (entry.url || '').toLowerCase();
        return title.includes(domain) || url.includes(domain) || domain.includes(title);
      });

      return { success: true, matches: matches, totalCount: sessionState.decryptedEntries.length };
    }

    case 'GENERATE_TOTP': {
      const { secret } = request;
      const otp = await SegurCelCrypto.generateTOTP(secret);
      return { success: true, otp };
    }

    case 'GENERATE_PASSWORD': {
      const password = SegurCelCrypto.generateSecurePassword(request.length || 16);
      return { success: true, password };
    }

    case 'TRIGGER_AUTOFILL': {
      const { username, password } = request;
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      if (tab?.id) {
        chrome.tabs.sendMessage(tab.id, {
          action: 'AUTOFILL_FORM',
          username,
          password
        });
      }
      return { success: true };
    }

    default:
      throw new Error(`Acción desconocida: ${request.action}`);
  }
}

function lockVault() {
  sessionState.isUnlocked = false;
  sessionState.masterKey = null;
  sessionState.decryptedEntries = [];
  if (sessionState.lockTimer) {
    clearTimeout(sessionState.lockTimer);
    sessionState.lockTimer = null;
  }
}

function _startAutoLockTimer() {
  if (sessionState.lockTimer) clearTimeout(sessionState.lockTimer);
  // Bloquear automáticamente tras 10 minutos de inactividad
  sessionState.lockTimer = setTimeout(() => {
    lockVault();
    console.log('[SegurCel Extension] Bóveda auto-bloqueada por inactividad.');
  }, 10 * 60 * 1000);
}
