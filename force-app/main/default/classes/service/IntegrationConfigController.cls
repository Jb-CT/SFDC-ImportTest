public with sharing class IntegrationConfigController {
    private static final Map<String, String> regionToUrl = new Map<String, String>{
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
    public static List<CleverTap__Config__c> getConfigurations() {
        try {
            return getConfigurationsWithSecurity();
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching configurations: ' + e.getMessage());
        }
    }

    private static List<CleverTap__Config__c> getConfigurationsWithSecurity() {
        // Security check for object-level accessibility
        if (!Schema.sObjectType.CleverTap__Config__c.isAccessible()) {
            throw new AuraHandledException('You do not have access to CleverTap configurations');
        }
        
        // Check field-level security for each field we're querying
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.CleverTap__Config__c.fields.getMap();
        List<String> fieldsToCheck = new List<String>{
            'Id', 'Name', 'CleverTap__Account_ID__c', 
            'CleverTap__Region__c', 'CleverTap__API_URL__c'
        };
        
        // Validate each field's accessibility
        for (String field : fieldsToCheck) {
            if (!fieldMap.get(field.toLowerCase()).getDescribe().isAccessible()) {
                throw new AuraHandledException('You do not have access to the ' + field + ' field');
            }
        }
        
        // Only after both object and field level security checks pass, we perform the SOQL query
        return [
            SELECT Id, Name, CleverTap__Account_ID__c, 
                   CleverTap__Region__c, CleverTap__API_URL__c
            FROM CleverTap__Config__c
            WHERE Name != '[Deleted]%'
            ORDER BY Name
        ];
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

    private static String createNewConfiguration(Map<String, Object> config) {
        CleverTap__Config__c newConfig = new CleverTap__Config__c(
            Name = (String)config.get('name'),
            CleverTap__Region__c = (String)config.get('region'),
            CleverTap__Account_ID__c = (String)config.get('accountId'),
            CleverTap__API_URL__c = regionToUrl.get(((String)config.get('region')).toUpperCase())
        );

        if (Schema.sObjectType.CleverTap__Config__c.isCreateable() &&
            Schema.sObjectType.CleverTap__Config__c.fields.Name.isCreateable() &&
            Schema.sObjectType.CleverTap__Config__c.fields.CleverTap__Region__c.isCreateable() &&
            Schema.sObjectType.CleverTap__Config__c.fields.CleverTap__Account_ID__c.isCreateable() &&
            Schema.sObjectType.CleverTap__Config__c.fields.CleverTap__API_URL__c.isCreateable()) {

            insert newConfig;
            PasscodeHelper.savePasscode(newConfig.Id, (String)config.get('passcode'));
            return 'Success';
        } else {
            throw new AuraHandledException('You do not have permission to create CleverTap configurations');
        }
    }

    private static String updateExistingConfiguration(Map<String, Object> config) {
        String configId = (String)config.get('id');
        CleverTap__Config__c existingConfig;

        if (Schema.sObjectType.CleverTap__Config__c.isAccessible()) {
            List<CleverTap__Config__c> configs = [
                SELECT Id FROM CleverTap__Config__c WHERE Id = :configId LIMIT 1
            ];
            
            if (configs.isEmpty()) {
                throw new AuraHandledException('Configuration not found');
            }
            
            existingConfig = configs[0];
        } else {
            throw new AuraHandledException('You do not have permission to access CleverTap configurations');
        }

        existingConfig.Name = (String)config.get('name');
        existingConfig.CleverTap__Region__c = (String)config.get('region');
        existingConfig.CleverTap__Account_ID__c = (String)config.get('accountId');
        existingConfig.CleverTap__API_URL__c = regionToUrl.get(((String)config.get('region')).toUpperCase());

        if (Schema.sObjectType.CleverTap__Config__c.isUpdateable() &&
            Schema.sObjectType.CleverTap__Config__c.fields.Name.isUpdateable() &&
            Schema.sObjectType.CleverTap__Config__c.fields.CleverTap__Region__c.isUpdateable() &&
            Schema.sObjectType.CleverTap__Config__c.fields.CleverTap__Account_ID__c.isUpdateable() &&
            Schema.sObjectType.CleverTap__Config__c.fields.CleverTap__API_URL__c.isUpdateable()) {

            update existingConfig;
            PasscodeHelper.savePasscode(existingConfig.Id, (String)config.get('passcode'));
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
    
    private static String deleteConfigWithSecurity(String configId) {
        try {
            // Check permission with the exact same pattern
            if (!CleverTap__Config__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isDeletable()) {
                throw new AuraHandledException('You do not have permission to delete CleverTap configurations');
            }
            
            // Query the record - same structure
            List<CleverTap__Config__c> configToDelete = [
                SELECT Id FROM CleverTap__Config__c WHERE Id = :configId LIMIT 1
            ];
            
            if (configToDelete.isEmpty()) {
                throw new AuraHandledException('Configuration not found');
            }

            PasscodeHelper.deletePasscode(configId);
            delete configToDelete;
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error during deletion: ' + e.getMessage());
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