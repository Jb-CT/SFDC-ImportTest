/**
 * @class Config
 * @description This class is responsible for retrieving CleverTap credentials from the CleverTap__Config__c custom setting.
 * It ensures proper field-level access and returns a map containing configuration key-value pairs used for integration with CleverTap.
 */
public with sharing class Config {
    /**
     * @description Get CleverTap credentials from the custom setting
     * @return Map of credential key-value pairs
     */
    public Map<String, String> getCredentials() {
        if (!Schema.sObjectType.CleverTap__Config__c.isAccessible()) {
            return null;
        }

        List<CleverTap__Config__c> configList = [
            SELECT Name, CleverTap__API_URL__c, 
                   CleverTap__Account_ID__c,
                   CleverTap__Region__c
            FROM CleverTap__Config__c 
            WHERE Name != '[Deleted]'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (configList.isEmpty()) {
            return null;
        }

        CleverTap__Config__c config = configList[0];

        Map<String, String> credentials = new Map<String, String>{
            'NAME'       => config.Name,
            'DEV_NAME'   => config.Name, 
            'API_URL'    => config.CleverTap__API_URL__c,
            'ACCOUNT_ID' => config.CleverTap__Account_ID__c,
            'PASSCODE'   => PasscodeHelper.getPasscode(config.Id),
            'REGION'     => config.CleverTap__Region__c
        };
        
        return credentials;
    }
}