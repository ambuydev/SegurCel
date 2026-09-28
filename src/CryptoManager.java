import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import java.security.SecureRandom;
import java.security.spec.KeySpec;
import java.util.Base64;

/**
 * Gestor Criptográfico para SegurCel.
 *
 * Utiliza Cifrado de Envoltorio (Key Wrapping Architecture):
 * 1. Los datos del usuario (contraseñas) se cifran con una Clave Maestra (Master Key) usando AES-256-GCM.
 * 2. La Clave Maestra se cifra/envuelve a su vez con:
 *    - El PIN del usuario (vía PBKDF2 + AES-GCM).
 *    - La Clave de Recuperación ("Olvidé mi PIN").
 *    - (Futuro en Android) La clave protegida por Biometría (Android Keystore).
 */
public class CryptoManager {

    private static final String KEY_DERIVATION_ALGORITHM = "PBKDF2WithHmacSHA256";
    private static final String CIPHER_ALGORITHM = "AES/GCM/NoPadding";
    private static final int AES_KEY_SIZE = 256; // bits
    private static final int PBKDF2_ITERATIONS = 65536;
    private static final int SALT_SIZE = 16; // bytes
    private static final int IV_SIZE = 12; // bytes para GCM
    private static final int GCM_TAG_LENGTH = 128; // bits

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    /**
     * Genera un Salt aleatorio de 16 bytes.
     */
    public static byte[] generateSalt() {
        byte[] salt = new byte[SALT_SIZE];
        SECURE_RANDOM.nextBytes(salt);
        return salt;
    }

    /**
     * Genera un IV (Vector de Inicialización) aleatorio de 12 bytes para AES-GCM.
     */
    public static byte[] generateIv() {
        byte[] iv = new byte[IV_SIZE];
        SECURE_RANDOM.nextBytes(iv);
        return iv;
    }

    /**
     * Genera una Clave Maestra aleatoria de 256 bits para cifrar el archivo de datos.
     */
    public static SecretKey generateMasterKey() throws Exception {
        KeyGenerator keyGen = KeyGenerator.getInstance("AES");
        keyGen.init(AES_KEY_SIZE, SECURE_RANDOM);
        return keyGen.generateKey();
    }

    /**
     * Deriva una clave AES-256 a partir del PIN o Clave de Recuperación usando PBKDF2.
     */
    public static SecretKey deriveKeyFromPassword(char[] password, byte[] salt) throws Exception {
        SecretKeyFactory factory = SecretKeyFactory.getInstance(KEY_DERIVATION_ALGORITHM);
        KeySpec spec = new PBEKeySpec(password, salt, PBKDF2_ITERATIONS, AES_KEY_SIZE);
        SecretKey tmp = factory.generateSecret(spec);
        return new SecretKeySpec(tmp.getEncoded(), "AES");
    }

    /**
     * Cifra datos en bruto utilizando AES-256-GCM.
     * Retorna un arreglo de bytes que contiene [IV (12 bytes) + Cifrado].
     */
    public static byte[] encrypt(byte[] plainText, SecretKey key) throws Exception {
        byte[] iv = generateIv();
        Cipher cipher = Cipher.getInstance(CIPHER_ALGORITHM);
        GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
        cipher.init(Cipher.ENCRYPT_MODE, key, spec);

        byte[] cipherText = cipher.doFinal(plainText);

        // Concatenar IV + Cifrado
        byte[] encryptedWithIv = new byte[iv.length + cipherText.length];
        System.arraycopy(iv, 0, encryptedWithIv, 0, iv.length);
        System.arraycopy(cipherText, 0, encryptedWithIv, iv.length, cipherText.length);

        return encryptedWithIv;
    }

    /**
     * Descifra datos cifrados con AES-256-GCM.
     * Lanza una excepción (ej. BadPaddingException / AEADBadTagException) si la clave es incorrecta o los datos fueron alterados.
     */
    public static byte[] decrypt(byte[] encryptedWithIv, SecretKey key) throws Exception {
        if (encryptedWithIv.length < IV_SIZE) {
            throw new IllegalArgumentException("Datos cifrados inválidos o corruptos.");
        }

        // Extraer IV
        byte[] iv = new byte[IV_SIZE];
        System.arraycopy(encryptedWithIv, 0, iv, 0, IV_SIZE);

        // Extraer texto cifrado
        int cipherTextSize = encryptedWithIv.length - IV_SIZE;
        byte[] cipherText = new byte[cipherTextSize];
        System.arraycopy(encryptedWithIv, IV_SIZE, cipherText, 0, cipherTextSize);

        Cipher cipher = Cipher.getInstance(CIPHER_ALGORITHM);
        GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
        cipher.init(Cipher.DECRYPT_MODE, key, spec);

        return cipher.doFinal(cipherText);
    }

    /**
     * Genera un código de recuperación aleatorio de 24 caracteres legibles.
     * Ejemplo: "A1B2-C3D4-E5F6-G7H8-I9J0-K1L2"
     */
    public static String generateRecoveryCode() {
        byte[] randomBytes = new byte[18];
        SECURE_RANDOM.nextBytes(randomBytes);
        String base64 = Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes).toUpperCase();
        // Formatear en bloques de 4 caracteres
        StringBuilder code = new StringBuilder();
        for (int i = 0; i < base64.length(); i++) {
            if (i > 0 && i % 4 == 0) {
                code.append("-");
            }
            code.append(base64.charAt(i));
        }
        return code.toString();
    }
}
