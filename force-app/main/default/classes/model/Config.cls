/**
 * @class Config
 * @description This class is responsible for retrieving CleverTap credentials from the CleverTap_Config__c custom setting.
 * It ensures proper field-level access and returns a map containing configuration key-value pairs used for integration with CleverTap.
 */
public with sharing class Config {
    /**
     * @description Get CleverTap credentials from the custom setting
     * @return Map of credential key-value pairs
     */
    public Map<String, String> getCredentials() {
        // Ensure the user has read access to CleverTap_Config__c
        if (!Schema.sObjectType.CleverTap_Config__c.isAccessible()) {
            return null;
        }

        List<CleverTap_Config__c> configList = [
            SELECT Name, CleverTap_API_URL__c, 
                   CleverTap_Account_ID__c, CleverTap_Passcode__c,
                   Region__c
            FROM CleverTap_Config__c 
            WHERE Name != '[Deleted]'
            LIMIT 1
        ];

        if (configList.isEmpty()) {
            return null;
        }

        CleverTap_Config__c config = configList[0];

        Map<String, String> credentials = new Map<String, String>{
            'NAME'       => config.Name,
            'DEV_NAME'   => config.Name, 
            'API_URL'    => config.CleverTap_API_URL__c,
            'ACCOUNT_ID' => config.CleverTap_Account_ID__c,
            'PASSCODE'   => config.CleverTap_Passcode__c,
            'REGION'     => config.Region__c
        };
        
        return credentials;
    }
}