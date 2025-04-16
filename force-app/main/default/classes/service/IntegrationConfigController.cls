public with sharing class IntegrationConfigController {
    private static Map<String, String> regionToUrl = new Map<String, String>{
        'US' => 'https://us1.api.clevertap.com/1/upload',
        'IN' => 'https://in1.api.clevertap.com/1/upload',
        'EU' => 'https://eu1.api.clevertap.com/1/upload',
        'SG' => 'https://sg1.api.clevertap.com/1/upload',
        'UAE' => 'https://mec1.api.clevertap.com/1/upload',
        'ID' => 'https://aps3.api.clevertap.com/1/upload'
    };
    
    // Singleton instance for credential validator
    private static CredentialValidator credentialValidator {
        get {
            if(credentialValidator == null) {
                credentialValidator = new CredentialValidator();
            }
            return credentialValidator;
        }
        set;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<CleverTap_Config__c> getConfigurations() {
        try {
            return getConfigurationsWithSecurity();
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching configurations: ' + e.getMessage());
        }
    }

    // Helper method to implement security checks
    private static List<CleverTap_Config__c> getConfigurationsWithSecurity() {
        // Security check required by PMD immediately before SOQL
        if (Schema.sObjectType.CleverTap_Config__c.isAccessible()) {
            // SOQL immediately after security check
            return [
                SELECT Id, Name, CleverTap_Account_ID__c, 
                       CleverTap_Passcode__c, Region__c, CleverTap_API_URL__c
                FROM CleverTap_Config__c
                WHERE Name != '[Deleted]%'
                ORDER BY Name
            ];
        } else {
            throw new AuraHandledException('You do not have access to CleverTap configurations');
        }
    }

    /**
     * @description Validates CleverTap credentials before saving them
     * @param region The CleverTap region
     * @param accountId The CleverTap Account ID
     * @param passcode The CleverTap Passcode
     * @return ValidationResult with status and message
     */
    @AuraEnabled
    public static CredentialValidator.ValidationResult validateCredentials(
        String region, String accountId, String passcode
    ) {
        return credentialValidator.validateCredentials(region, accountId, passcode);
    }

    @AuraEnabled
    public static String saveConfiguration(Map<String, Object> config) {
        try {
            // Validation
            validateConfigData(config);

            boolean isNew = !config.containsKey('id') || String.isBlank((String)config.get('id'));
            
            if (isNew) {
                return createNewConfiguration(config);
            } else {
                return updateExistingConfiguration(config);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error saving configuration: ' + e.getMessage());
        }
    }
    
    // Helper method for creating a new configuration
    private static String createNewConfiguration(Map<String, Object> config) {
        // Create new config object
        CleverTap_Config__c newConfig = new CleverTap_Config__c(
            Name = (String)config.get('name'),
            Region__c = (String)config.get('region'),
            CleverTap_Account_ID__c = (String)config.get('accountId'),
            CleverTap_Passcode__c = (String)config.get('passcode'),
            CleverTap_API_URL__c = regionToUrl.get(((String)config.get('region')).toUpperCase())
        );
        
        // Security check required by PMD immediately before DML
        if (Schema.sObjectType.CleverTap_Config__c.isCreateable() &&
            Schema.sObjectType.CleverTap_Config__c.fields.Name.isCreateable() &&
            Schema.sObjectType.CleverTap_Config__c.fields.Region__c.isCreateable() &&
            Schema.sObjectType.CleverTap_Config__c.fields.CleverTap_Account_ID__c.isCreateable() &&
            Schema.sObjectType.CleverTap_Config__c.fields.CleverTap_Passcode__c.isCreateable() &&
            Schema.sObjectType.CleverTap_Config__c.fields.CleverTap_API_URL__c.isCreateable()) {
            // DML immediately after security check
            insert newConfig;
            return 'Success';
        } else {
            throw new AuraHandledException('You do not have permission to create CleverTap configurations');
        }
    }
    
    // Helper method for updating an existing configuration
    private static String updateExistingConfiguration(Map<String, Object> config) {
        String configId = (String)config.get('id');
        CleverTap_Config__c existingConfig;
        
        // Security check required by PMD immediately before SOQL
        if (Schema.sObjectType.CleverTap_Config__c.isAccessible()) {
            // SOQL immediately after security check
            List<CleverTap_Config__c> configs = [
                SELECT Id FROM CleverTap_Config__c WHERE Id = :configId LIMIT 1
            ];
            
            if (configs.isEmpty()) {
                throw new AuraHandledException('Configuration not found');
            }
            
            existingConfig = configs[0];
        } else {
            throw new AuraHandledException('You do not have permission to access CleverTap configurations');
        }
        
        // Update fields
        existingConfig.Name = (String)config.get('name');
        existingConfig.Region__c = (String)config.get('region');
        existingConfig.CleverTap_Account_ID__c = (String)config.get('accountId');
        existingConfig.CleverTap_Passcode__c = (String)config.get('passcode');
        existingConfig.CleverTap_API_URL__c = regionToUrl.get(((String)config.get('region')).toUpperCase());
        
        // Security check required by PMD immediately before DML
        if (Schema.sObjectType.CleverTap_Config__c.isUpdateable() &&
            Schema.sObjectType.CleverTap_Config__c.fields.Name.isUpdateable() &&
            Schema.sObjectType.CleverTap_Config__c.fields.Region__c.isUpdateable() &&
            Schema.sObjectType.CleverTap_Config__c.fields.CleverTap_Account_ID__c.isUpdateable() &&
            Schema.sObjectType.CleverTap_Config__c.fields.CleverTap_Passcode__c.isUpdateable() &&
            Schema.sObjectType.CleverTap_Config__c.fields.CleverTap_API_URL__c.isUpdateable()) {
            // DML immediately after security check
            update existingConfig;
            return 'Success';
        } else {
            throw new AuraHandledException('You do not have permission to update CleverTap configurations');
        }
    }

    @AuraEnabled
    public static String deleteConfiguration(String configId) {
        try {
            if (String.isBlank(configId)) {
                throw new AuraHandledException('Configuration ID is required for deletion');
            }
            
            return deleteConfigWithSecurity(configId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Helper method to implement security checks for deletion
    private static String deleteConfigWithSecurity(String configId) {
        List<CleverTap_Config__c> configToDelete;
        
        // Security check required by PMD immediately before SOQL
        if (Schema.sObjectType.CleverTap_Config__c.isAccessible()) {
            // SOQL immediately after security check
            configToDelete = [
                SELECT Id FROM CleverTap_Config__c WHERE Id = :configId LIMIT 1
            ];
            
            if (configToDelete.isEmpty()) {
                throw new AuraHandledException('Configuration not found');
            }
        } else {
            throw new AuraHandledException('You do not have permission to access CleverTap configurations');
        }
        
        // Security check required by PMD immediately before DML
        if (Schema.sObjectType.CleverTap_Config__c.isDeletable()) {
            // DML immediately after security check
            delete configToDelete;
            return 'Success';
        } else {
            throw new AuraHandledException('You do not have permission to delete CleverTap configurations');
        }
    }
    
    private static void validateConfigData(Map<String, Object> config) {
        if (!config.containsKey('name') || String.isBlank((String)config.get('name'))) {
            throw new AuraHandledException('Connection name is required');
        }

        String region = (String)config.get('region');
        if (String.isBlank(region)) {
            throw new AuraHandledException('Region is required');
        }
    }
}