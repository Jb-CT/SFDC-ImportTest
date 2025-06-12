/**
 * COMPLETELY REWRITTEN - Clean EncryptionUtil.cls
 * File: force-app/main/default/classes/EncryptionUtil.cls
 */
public with sharing class EncryptionUtil {
    
    private static final String ALGORITHM = 'AES256';
    
    /**
     * @description Generate encryption key based on org ID
     */
    private static Blob getEncryptionKey() {
        String keySource = UserInfo.getOrganizationId() + 'CleverTapSecret2024';
        return Crypto.generateDigest('SHA256', Blob.valueOf(keySource));
    }
    
    /**
     * @description Encrypt sensitive data
     * @param plainText Text to encrypt
     * @return Encrypted string with IV prepended
     */
    public static String encryptData(String plainText) {
        if (String.isBlank(plainText)) {
            return null;
        }
        
        try {
            // Get encryption key
            Blob encryptionKey = getEncryptionKey();
            
            // Generate random IV
            Blob iv = Crypto.generateAesKey(128);
            
            // Convert plaintext to blob
            Blob dataToEncrypt = Blob.valueOf(plainText);
            
            // Encrypt data using correct Salesforce API
            Blob encryptedData = Crypto.encrypt(ALGORITHM, encryptionKey, iv, dataToEncrypt);
            
            // Combine IV and encrypted data
            String ivString = EncodingUtil.base64Encode(iv);
            String encryptedString = EncodingUtil.base64Encode(encryptedData);
            
            return ivString + '::' + encryptedString;
            
        } catch (Exception ex) {
            throw new AuraHandledException('Encryption failed: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Decrypt sensitive data
     * @param encryptedText Encrypted string with IV prepended
     * @return Decrypted plaintext
     */
    public static String decryptData(String encryptedText) {
        if (String.isBlank(encryptedText)) {
            return null;
        }
        
        try {
            // Split IV and encrypted data
            String[] parts = encryptedText.split('::');
            if (parts.size() != 2) {
                throw new AuraHandledException('Invalid encrypted format');
            }
            
            // Decode IV and encrypted data
            Blob iv = EncodingUtil.base64Decode(parts[0]);
            Blob encryptedData = EncodingUtil.base64Decode(parts[1]);
            
            // Get encryption key
            Blob encryptionKey = getEncryptionKey();
            
            // Decrypt data using correct Salesforce API
            Blob decryptedData = Crypto.decrypt(ALGORITHM, encryptionKey, iv, encryptedData);
            
            return decryptedData.toString();
            
        } catch (Exception ex) {
            throw new AuraHandledException('Decryption failed: ' + ex.getMessage());
        }
    }
}