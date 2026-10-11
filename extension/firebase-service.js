/**
 * SegurCel Browser Extension - Firebase REST API Service
 * Conexión nativa e ultrarrápida con Firebase Auth y Firestore sin dependencias externas
 */

const FIREBASE_API_KEY = "AIzaSyB21H7Nvb67yddWT1dzFV68pVDOxI15qfg";
const PROJECT_ID = "segurcel-45c92";

export class SegurCelFirebase {
  /**
   * Inicia sesión con correo y contraseña en Firebase Auth.
   * Retorna { uid, email, idToken, refreshToken }
   */
  static async loginWithEmailPassword(email, password) {
    const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`;

    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: email.trim(),
        password: password.trim(),
        returnSecureToken: true
      })
    });

    const data = await response.json();
    if (!response.ok) {
      const errorMsg = data.error?.message || "ERROR_AUTH";
      throw new Error(SegurCelFirebase._parseAuthError(errorMsg));
    }

    return {
      uid: data.localId,
      email: data.email,
      idToken: data.idToken,
      refreshToken: data.refreshToken
    };
  }

  /**
   * Obtiene el perfil de usuario desde Firestore (`users/{uid}`).
   */
  static async fetchUserProfile(uid, idToken) {
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`;

    const response = await fetch(url, {
      method: "GET",
      headers: { "Authorization": `Bearer ${idToken}` }
    });

    if (!response.ok) return null;

    const data = await response.json();
    if (!data.fields) return null;

    return {
      uid: uid,
      email: data.fields.email?.stringValue || "",
      isPremium: data.fields.isPremium?.booleanValue || false,
      subscriptionType: data.fields.subscriptionType?.stringValue || "free"
    };
  }

  /**
   * Obtiene la bóveda cifrada desde Firestore (`users/{uid}/vault/main`).
   */
  static async fetchEncryptedVault(uid, idToken) {
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}/vault/main`;

    const response = await fetch(url, {
      method: "GET",
      headers: { "Authorization": `Bearer ${idToken}` }
    });

    if (!response.ok) {
      if (response.status === 404) {
        throw new Error("VAULT_NOT_FOUND");
      }
      throw new Error(`Error en Firestore (${response.status})`);
    }

    const data = await response.json();
    if (!data.fields) throw new Error("Bóveda vacía o corrupta.");

    const fields = data.fields;
    return {
      pinSalt: fields.pinSalt?.stringValue || "",
      wrappedMasterKeyByPin: fields.wrappedMasterKeyByPin?.stringValue || "",
      recoverySalt: fields.recoverySalt?.stringValue || "",
      wrappedMasterKeyByRecovery: fields.wrappedMasterKeyByRecovery?.stringValue || "",
      encryptedPasswordsData: fields.encryptedPasswordsData?.stringValue || "",
      failedAttempts: parseInt(fields.failedAttempts?.integerValue || "0", 10),
      updatedAt: parseInt(fields.updatedAt?.integerValue || "0", 10)
    };
  }

  /**
   * Actualiza la bóveda cifrada en Firestore (`users/{uid}/vault/main`).
   */
  static async saveEncryptedVault(uid, idToken, vaultData) {
    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}/vault/main`;

    const body = {
      fields: {
        pinSalt: { stringValue: vaultData.pinSalt },
        wrappedMasterKeyByPin: { stringValue: vaultData.wrappedMasterKeyByPin },
        recoverySalt: { stringValue: vaultData.recoverySalt },
        wrappedMasterKeyByRecovery: { stringValue: vaultData.wrappedMasterKeyByRecovery },
        encryptedPasswordsData: { stringValue: vaultData.encryptedPasswordsData },
        failedAttempts: { integerValue: vaultData.failedAttempts.toString() },
        updatedAt: { integerValue: (vaultData.updatedAt || Date.now()).toString() }
      }
    };

    const response = await fetch(url, {
      method: "PATCH",
      headers: {
        "Authorization": `Bearer ${idToken}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    });

    if (!response.ok) {
      throw new Error("No se pudo sincronizar la bóveda con la nube.");
    }

    return true;
  }

  static _parseAuthError(code) {
    switch (code) {
      case "EMAIL_NOT_FOUND":
      case "INVALID_EMAIL":
        return "No existe ninguna cuenta registrada con este correo.";
      case "INVALID_PASSWORD":
      case "INVALID_LOGIN_CREDENTIALS":
        return "La contraseña ingresada es incorrecta.";
      case "USER_DISABLED":
        return "Esta cuenta de usuario ha sido deshabilitada.";
      default:
        return `Error de autenticación (${code}).`;
    }
  }
}
