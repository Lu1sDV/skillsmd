Cipher rsaCipher = Cipher.getInstance("RSA"); // DEFAULTS to PKCS#1 v1.5!
rsaCipher.init(Cipher.DECRYPT_MODE, rsaPrivateKey);
try {
    byte[] decrypted = rsaCipher.doFinal(ciphertext);
} catch (BadPaddingException e) {
    // Timing difference from exception handling is measurable over network
}
