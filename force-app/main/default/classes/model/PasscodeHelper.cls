public with sharing class PasscodeHelper {
    
    public static String getPasscode(String configId) {
        try {
            CleverTap_Passcode__c setting = CleverTap_Passcode__c.getInstance(configId);
            if (setting != null && String.isNotBlank(setting.Passcode__c)) {
                // Decrypt the stored passcode
                return EncryptionUtil.decryptData(setting.Passcode__c);
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving passcode: ' + e.getMessage());
        }
    }
    
    public static void savePasscode(String configId, String passcode) {
        if (String.isBlank(passcode)) {
            return;
        }
        
        try {
            CleverTap_Passcode__c setting = CleverTap_Passcode__c.getInstance(configId);
            if (setting == null) {
                setting = new CleverTap_Passcode__c(Name = configId);
            }
            
            // Encrypt the passcode before storing
            setting.Passcode__c = EncryptionUtil.encryptData(passcode);

            if (setting.Id == null && Schema.sObjectType.CleverTap_Passcode__c.isCreateable()) {
                insert setting;
            } else if (setting.Id != null && Schema.sObjectType.CleverTap_Passcode__c.isUpdateable()) {
                update setting;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error saving passcode: ' + e.getMessage());
        }
    }
    
    public static void deletePasscode(String configId) {
        CleverTap_Passcode__c setting = CleverTap_Passcode__c.getInstance(configId);
        
        if (setting == null) {
            return;
        }
        
        if (!CleverTap_Passcode__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() ||
            !CleverTap_Passcode__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isDeletable()) {
            throw new AuraHandledException('You do not have permission to delete CleverTap_Passcode__c');
        }
        
        try {
            Database.delete(setting, AccessLevel.USER_MODE);
        } catch (System.NoAccessException e) {
            throw new AuraHandledException('Access denied: ' + e.getMessage());
        } catch (DmlException e) {
            throw new AuraHandledException('Delete failed: ' + e.getMessage());
        }
    }
}