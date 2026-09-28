public class Main {

    public static void main(String[] args) {
        System.out.println("==========================================");
        System.out.println("     DEMOSTRACIÓN DE SEGURCEL - CRYPTO     ");
        System.out.println("==========================================\n");

        VaultManager vault = new VaultManager();

        try {
            // 1. Configuración Inicial de la Bóveda con PIN original "1234"
            char[] initialPin = "1234".toCharArray();
            String samplePasswords = "Email: miemail@gmail.com | Pass: 123456Secret\n" +
                                     "Banco: usuario_banco   | Pass: SuperBanquero$2025\n" +
                                     "WiFi:  MiRedHogar       | Pass: ClaveWiFiSegura";

            System.out.println("[1] Inicializando bóveda cifrada con PIN '1234'...");
            String recoveryCode = vault.setupVault(initialPin, samplePasswords);

            System.out.println("-> Bóveda cifrada con éxito usando AES-256-GCM + PBKDF2.");
            System.out.println("-> ¡ATENCIÓN! Guarda tu CÓDIGO DE RECUPERACIÓN en lugar seguro:");
            System.out.println("   >>> " + recoveryCode + " <<<\n");

            // 2. Probar desbloqueo con el PIN correcto "1234"
            System.out.println("[2] Probando desbloqueo con el PIN correcto ('1234')...");
            String decryptedData = vault.unlockWithPin("1234".toCharArray());
            System.out.println("-> Bóveda desbloqueada correctamente!");
            System.out.println("-> Contenido descifrado:\n" + decryptedData + "\n");

            // 3. Probar desbloqueo con PIN incorrecto ("0000")
            System.out.println("[3] Simulando intento con PIN incorrecto ('0000')...");
            try {
                vault.unlockWithPin("0000".toCharArray());
            } catch (SecurityException e) {
                System.out.println("-> " + e.getMessage() + "\n");
            }

            // 4. Probar función "Olvidé mi PIN" usando el Código de Recuperación
            System.out.println("[4] Probando recuperación ('Olvidé mi PIN') con el Código de Recuperación y cambiando PIN a '5678'...");
            char[] newPin = "5678".toCharArray();
            String recoveredData = vault.unlockWithRecoveryCode(recoveryCode, newPin);
            System.out.println("-> ¡Recuperación exitosa!");
            System.out.println("-> Datos recuperados:\n" + recoveredData);
            System.out.println("-> El PIN ha sido actualizado a '5678'.\n");

            // 5. Probar desbloqueo con el NUEVO PIN ("5678")
            System.out.println("[5] Probando desbloqueo con el nuevo PIN ('5678')...");
            vault.unlockWithPin("5678".toCharArray());
            System.out.println("-> ¡Nuevo PIN validado correctamente!\n");

            // 6. Demostración del límite de 3 intentos fallidos y AUTODESTRUCCIÓN
            System.out.println("[6] Simulando 3 intentos fallidos consecutivos para activar AUTODESTRUCCIÓN...");

            for (int i = 1; i <= VaultManager.MAX_ATTEMPTS; i++) {
                try {
                    System.out.println("--- Intento Fallido #" + i + " ---");
                    vault.unlockWithPin("9999".toCharArray());
                } catch (SecurityException e) {
                    System.out.println("-> Capa de Seguridad: " + e.getMessage());
                }
            }

            // 7. Intentar acceder a la bóveda post-autodestrucción
            System.out.println("\n[7] Intentando acceder a la bóveda tras la autodestrucción...");
            try {
                vault.unlockWithPin("5678".toCharArray());
            } catch (Exception e) {
                System.out.println("-> Resultado esperado: " + e.getMessage());
            }

        } catch (Exception e) {
            System.err.println("Error no esperado durante la prueba: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
