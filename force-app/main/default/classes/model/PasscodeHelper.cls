public with sharing class PasscodeHelper {
    
    public static String getPasscode(String configId) {
        CleverTap_Passcode__c setting = CleverTap_Passcode__c.getInstance(configId);
        return setting != null ? setting.Passcode__c : null;
    }
    
    public static void savePasscode(String configId, String passcode) {
        if (String.isBlank(passcode)) {
            return;
        }
        
        CleverTap_Passcode__c setting = CleverTap_Passcode__c.getInstance(configId);
        if (setting == null) {
            setting = new CleverTap_Passcode__c(Name = configId);
        }
        setting.Passcode__c = passcode;

        if (setting.Id == null && Schema.sObjectType.CleverTap_Passcode__c.isCreateable()) {
            insert setting;
        } else if (setting.Id != null && Schema.sObjectType.CleverTap_Passcode__c.isUpdateable()) {
            update setting;
        }
    }
    
    public static void deletePasscode(String configId) {
        CleverTap_Passcode__c setting = CleverTap_Passcode__c.getInstance(configId);
        if (setting != null && Schema.sObjectType.CleverTap_Passcode__c.isDeletable()) {
            delete setting;
        }
    }
}