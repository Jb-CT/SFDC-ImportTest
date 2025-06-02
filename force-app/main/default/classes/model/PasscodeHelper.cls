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
        
        if (setting == null) {
            return;
        }
        
        // Use the exact same pattern with getDescribe() 
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