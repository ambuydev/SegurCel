import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

/**
 * Gestor del Bóveda / Archivo Cifrado.
 * Administra el desbloqueo por PIN, Código de Recuperación, contador de fallos y autodestrucción.
 */
public class VaultManager {

    public static final int MAX_ATTEMPTS = 3;

    private int failedAttempts = 0;
    private boolean isVaultInitialized = false;

    // Metadatos de la bóveda
    private byte[] pinSalt;
    private byte[] wrappedMasterKeyByPin;

    private byte[] recoverySalt;
    private byte[] wrappedMasterKeyByRecovery;

    private String currentRecoveryCode; // Código generado para el usuario al configurar

    // Archivo donde se guardan las contraseñas cifradas
    private byte[] encryptedPasswordsData;

    /**
     * Inicializa la bóveda por primera vez definiendo un PIN.
     * Retorna el Código de Recuperación generado que el usuario debe guardar.
     */
    public String setupVault(char[] pin, String initialData) throws Exception {
        // 1. Generar la Clave Maestra aleatoria
        SecretKey masterKey = CryptoManager.generateMasterKey();

        // 2. Envolver (cifrar) la Clave Maestra con el PIN del usuario
        this.pinSalt = CryptoManager.generateSalt();
        SecretKey pinDerivedKey = CryptoManager.deriveKeyFromPassword(pin, pinSalt);
        this.wrappedMasterKeyByPin = CryptoManager.encrypt(masterKey.getEncoded(), pinDerivedKey);

        // 3. Envolver (cifrar) la Clave Maestra con un Código de Recuperación aleatorio
        this.currentRecoveryCode = CryptoManager.generateRecoveryCode();
        this.recoverySalt = CryptoManager.generateSalt();
        SecretKey recoveryDerivedKey = CryptoManager.deriveKeyFromPassword(currentRecoveryCode.toCharArray(), recoverySalt);
        this.wrappedMasterKeyByRecovery = CryptoManager.encrypt(masterKey.getEncoded(), recoveryDerivedKey);

        // 4. Cifrar los datos iniciales con la Clave Maestra
        if (initialData != null) {
            this.encryptedPasswordsData = CryptoManager.encrypt(initialData.getBytes(StandardCharsets.UTF_8), masterKey);
        }

        this.failedAttempts = 0;
        this.isVaultInitialized = true;

        return currentRecoveryCode;
    }

    /**
     * Intenta desbloquear la bóveda utilizando el PIN del usuario.
     * Si falla 3 veces consecutivas, elimina los datos (Autodestrucción).
     */
    public String unlockWithPin(char[] pin) {
        checkVaultInitialized();

        if (failedAttempts >= MAX_ATTEMPTS) {
            selfDestruct();
            throw new IllegalStateException("La bóveda ha sido autodestruida por superar el límite de intentos.");
        }

        try {
            // 1. Derivar la clave del PIN ingresado
            SecretKey pinDerivedKey = CryptoManager.deriveKeyFromPassword(pin, pinSalt);

            // 2. Intentar descifrar la Clave Maestra
            byte[] masterKeyBytes = CryptoManager.decrypt(wrappedMasterKeyByPin, pinDerivedKey);
            SecretKey masterKey = new SecretKeySpec(masterKeyBytes, "AES");

            // 3. Descifrar el contenido
            byte[] plainDataBytes = CryptoManager.decrypt(encryptedPasswordsData, masterKey);

            // ¡Éxito! Reiniciar el contador de fallos
            this.failedAttempts = 0;

            return new String(plainDataBytes, StandardCharsets.UTF_8);

        } catch (Exception e) {
            this.failedAttempts++;
            int remaining = MAX_ATTEMPTS - failedAttempts;

            if (failedAttempts >= MAX_ATTEMPTS) {
                selfDestruct();
                throw new SecurityException("PIN incorrecto. Límite de " + MAX_ATTEMPTS + " intentos alcanzado. ¡BÓVEDA ELIMINADA!");
            } else {
                throw new SecurityException("PIN incorrecto. Te quedan " + remaining + " intento(s).");
            }
        }
    }

    /**
     * Recupera la bóveda usando el Código de Recuperación ("Olvidé mi PIN").
     * Si es correcto, permite definir un nuevo PIN sin perder los datos.
     */
    public String unlockWithRecoveryCode(String recoveryCode, char[] newPin) throws Exception {
        checkVaultInitialized();

        // Limpiar el código ingresado de espacios extra
        char[] cleanCode = recoveryCode.trim().toCharArray();

        try {
            // 1. Derivar clave del código de recuperación
            SecretKey recoveryDerivedKey = CryptoManager.deriveKeyFromPassword(cleanCode, recoverySalt);

            // 2. Descifrar la Clave Maestra
            byte[] masterKeyBytes = CryptoManager.decrypt(wrappedMasterKeyByRecovery, recoveryDerivedKey);
            SecretKey masterKey = new SecretKeySpec(masterKeyBytes, "AES");

            // 3. Re-envolver la Clave Maestra con el nuevo PIN
            this.pinSalt = CryptoManager.generateSalt();
            SecretKey newPinDerivedKey = CryptoManager.deriveKeyFromPassword(newPin, pinSalt);
            this.wrappedMasterKeyByPin = CryptoManager.encrypt(masterKeyBytes, newPinDerivedKey);

            // 4. Resetear intentos fallidos
            this.failedAttempts = 0;

            // 5. Descifrar y retornar los datos
            byte[] plainDataBytes = CryptoManager.decrypt(encryptedPasswordsData, masterKey);
            return new String(plainDataBytes, StandardCharsets.UTF_8);

        } catch (Exception e) {
            throw new SecurityException("El Código de Recuperación ingresado es incorrecto.");
        }
    }

    /**
     * Elimina completamente todos los datos cifrados y claves en caso de emergencia/autodestrucción.
     */
    public void selfDestruct() {
        if (wrappedMasterKeyByPin != null) Arrays.fill(wrappedMasterKeyByPin, (byte) 0);
        if (wrappedMasterKeyByRecovery != null) Arrays.fill(wrappedMasterKeyByRecovery, (byte) 0);
        if (encryptedPasswordsData != null) Arrays.fill(encryptedPasswordsData, (byte) 0);

        this.wrappedMasterKeyByPin = null;
        this.wrappedMasterKeyByRecovery = null;
        this.encryptedPasswordsData = null;
        this.pinSalt = null;
        this.recoverySalt = null;
        this.currentRecoveryCode = null;
        this.failedAttempts = 0;
        this.isVaultInitialized = false;

        System.out.println("\n[ALERTA DE SEGURIDAD] ¡Archivos y claves borradas permanentemente de la memoria y almacenamiento!");
    }

    private void checkVaultInitialized() {
        if (!isVaultInitialized) {
            throw new IllegalStateException("La bóveda no está inicializada o ha sido eliminada.");
        }
    }

    public int getFailedAttempts() {
        return failedAttempts;
    }

    public boolean isVaultInitialized() {
        return isVaultInitialized;
    }
}
