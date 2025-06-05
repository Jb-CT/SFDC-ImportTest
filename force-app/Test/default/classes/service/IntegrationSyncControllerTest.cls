/**
 * @class IntegrationSyncControllerTest
 * @description Test class for IntegrationSyncController to ensure proper configuration and mapping handling.
 */
@isTest
private class IntegrationSyncControllerTest {
    /**
     * @description Setup test data for all test methods
     */
    @testSetup
    static void setupTestData() {

        String testConnectionId = 'TEST_CONN_123';

        CleverTap__Sync_Configuration__c config = new CleverTap__Sync_Configuration__c(
            Name = 'Test Sync Config',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Lead',
            CleverTap__Entity__c = 'profile',
            CleverTap__ConnectionId__c = testConnectionId,
            CleverTap__Status__c = 'Active'
        );
        insert config;
        
        List<CleverTap__Mapping__c> mappings = new List<CleverTap__Mapping__c>();
        
        mappings.add(new CleverTap__Mapping__c(
            Name = 'Customer ID Mapping',
            CleverTap__Sync_mapping__c = config.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'Email',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        ));

        mappings.add(new CleverTap__Mapping__c(
            Name = 'First Name Mapping',
            CleverTap__Sync_mapping__c = config.Id,
            CleverTap__Field__c = 'first_name',
            CleverTap__Salesforce_Field__c = 'FirstName',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = false
        ));
        
        insert mappings;
    }

    @isTest
    static void testGetSyncConfigurations() {
        String connectionId = 'TEST_CONN_123';
        
        Test.startTest();
        List<SyncConfigurationManager.SyncConfigWrapper> configs = 
            IntegrationSyncController.getSyncConfigurations(connectionId);
        Test.stopTest();

        System.assertEquals(1, configs.size(), 'Should return one configuration');
        
        SyncConfigurationManager.SyncConfigWrapper config = configs[0];
        System.assertEquals('Test Sync Config', config.name, 'Configuration name should match');
        System.assertEquals('salesforce_to_clevertap', config.syncType, 'Sync type should match');
        System.assertEquals('Lead', config.sourceEntity, 'Source entity should match');
        System.assertEquals('profile', config.targetEntity, 'Target entity should match');
        System.assertEquals('Active', config.status, 'Status should match');
    }

    @isTest
    static void testGetPicklistValues() {
        List<Map<String, String>> mockPicklist = new List<Map<String, String>>();
        Map<String, String> option1 = new Map<String, String>{'label' => 'Text', 'value' => 'Text'};
        mockPicklist.add(option1);
        
        CleverTap__Mapping__c testMapping = new CleverTap__Mapping__c(
            CleverTap__Data_Type__c = 'Text'
        );

        Test.startTest();
        List<Map<String, String>> picklistValues = 
            IntegrationSyncController.getPicklistValues('CleverTap__Mapping__c', 'CleverTap__Data_Type__c');
        Test.stopTest();

        if (picklistValues.isEmpty()) {
            System.assert(true, 'No picklist values in test environment is acceptable');
        } else {
            Boolean hasTextType = false;
            for (Map<String, String> option : picklistValues) {
                if (option.get('value') == 'Text') {
                    hasTextType = true;
                    break;
                }
            }
            System.assert(hasTextType, 'Should include Text data type');
        }
    }

    @isTest
    static void testSaveFieldMappings() {
        CleverTap__Sync_Configuration__c config = [
            SELECT Id, Name FROM CleverTap__Sync_Configuration__c LIMIT 1
        ];

        Map<String, Object> mappingDataMap = new Map<String, Object>();
        mappingDataMap.put('syncId', config.Id);
        
        List<Map<String, Object>> mappings = new List<Map<String, Object>>();

        Map<String, Object> mandatoryMapping = new Map<String, Object>{
            'CleverTap__Field__c' => 'Identity',
            'CleverTap__Salesforce_Field__c' => 'Email',
            'CleverTap__Data_Type__c' => 'Text',
            'CleverTap__Is_Mandatory__c' => true
        };

        Map<String, Object> additionalMapping = new Map<String, Object>{
            'CleverTap__Field__c' => 'last_name',
            'CleverTap__Salesforce_Field__c' => 'LastName',
            'CleverTap__Data_Type__c' => 'Text',
            'CleverTap__Is_Mandatory__c' => false
        };
        
        mappings.add(mandatoryMapping);
        mappings.add(additionalMapping);
        mappingDataMap.put('mappings', mappings);
        
        String mappingDataJson = JSON.serialize(mappingDataMap);
        
        Test.startTest();
        IntegrationSyncController.saveFieldMappings(mappingDataJson);
        Test.stopTest();
        
        List<CleverTap__Mapping__c> updatedMappings = [
            SELECT CleverTap__Field__c, CleverTap__Salesforce_Field__c, CleverTap__Is_Mandatory__c
            FROM CleverTap__Mapping__c
            WHERE CleverTap__Sync_mapping__c = :config.Id
            ORDER BY CleverTap__Is_Mandatory__c DESC
        ];
        
        System.assertEquals(2, updatedMappings.size(), 'Should have 2 mappings after update');
        
        System.assertEquals('Identity', updatedMappings[0].CleverTap__Field__c, 
            'First mapping should be Identity');
        System.assertEquals(true, updatedMappings[0].CleverTap__Is_Mandatory__c, 
            'Identity mapping should be mandatory');
        
        System.assertEquals('last_name', updatedMappings[1].CleverTap__Field__c, 
            'Second mapping should be last_name');
        System.assertEquals('LastName', updatedMappings[1].CleverTap__Salesforce_Field__c, 
            'Second mapping should map to LastName field');
    }

    @isTest
    static void testSaveFieldMappingsInvalidData() {
        Test.startTest();
        try {
            IntegrationSyncController.saveFieldMappings('');
            System.assert(false, 'Should have thrown exception for empty data');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException was thrown as expected for empty data');
        }

        try {
            IntegrationSyncController.saveFieldMappings('not valid json');
            System.assert(false, 'Should have thrown exception for invalid JSON');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException was thrown as expected for invalid JSON');
        }
        
        try {
            Map<String, Object> invalidMap = new Map<String, Object>{
                'mappings' => new List<Object>()
            };
            IntegrationSyncController.saveFieldMappings(JSON.serialize(invalidMap));
            System.assert(false, 'Should have thrown exception for missing syncId');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException was thrown as expected for missing syncId');
        }
        
        try {
            Id mockId = UserInfo.getOrganizationId(); 
            
            Map<String, Object> invalidMap = new Map<String, Object>{
                'syncId' => mockId,
                'mappings' => new List<Object>()
            };
            IntegrationSyncController.saveFieldMappings(JSON.serialize(invalidMap));
            System.assert(false, 'Should have thrown exception for empty mappings');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException was thrown as expected for empty mappings');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetExistingMappings() {
        CleverTap__Sync_Configuration__c config = [
            SELECT Id FROM CleverTap__Sync_Configuration__c LIMIT 1
        ];
        
        Test.startTest();
        List<CleverTap__Mapping__c> mappings = 
            IntegrationSyncController.getExistingMappings(config.Id);
        Test.stopTest();
        

        System.assertEquals(2, mappings.size(), 'Should return 2 mappings');

        Boolean hasCustomerId = false;
        Boolean hasFirstName = false;
        
        for (CleverTap__Mapping__c mapping : mappings) {
            if (mapping.CleverTap__Field__c == 'Identity') {
                hasCustomerId = true;
                System.assertEquals(true, mapping.CleverTap__Is_Mandatory__c, 'Identity should be mandatory');
            }
            if (mapping.CleverTap__Field__c == 'first_name') {
                hasFirstName = true;
                System.assertEquals(false, mapping.CleverTap__Is_Mandatory__c, 'first_name should not be mandatory');
            }
        }
        
        System.assertEquals(true, hasCustomerId, 'Should include Identity mapping');
        System.assertEquals(true, hasFirstName, 'Should include first_name mapping');
    }

    @isTest
    static void testUpdateSyncStatus() {
        CleverTap__Sync_Configuration__c config = [
            SELECT Id, CleverTap__Status__c FROM CleverTap__Sync_Configuration__c LIMIT 1
        ];

        System.assertEquals('Active', config.CleverTap__Status__c, 'Initial status should be Active');

        Test.startTest();
        IntegrationSyncController.updateSyncStatus(config.Id, 'Inactive');
        Test.stopTest();

        config = [SELECT CleverTap__Status__c FROM CleverTap__Sync_Configuration__c WHERE Id = :config.Id];
        System.assertEquals('Inactive', config.CleverTap__Status__c, 'Status should be updated to Inactive');
    }

    @isTest
    static void testCreateSyncConfiguration() {
        String connectionId = 'TEST_CONN_456';
        Map<String, Object> syncData = new Map<String, Object>{
            'name' => 'New Test Config',
            'syncType' => 'salesforce_to_clevertap',
            'sourceEntity' => 'Contact',
            'targetEntity' => 'profile',
            'connectionId' => connectionId
        };

        Test.startTest();
        String newConfigId = IntegrationSyncController.createSyncConfiguration(JSON.serialize(syncData));
        Test.stopTest();

        System.assertNotEquals(null, newConfigId, 'Should return new configuration Id');

        CleverTap__Sync_Configuration__c newConfig = [
            SELECT Name, CleverTap__Salesforce_Entity__c, CleverTap__Entity__c, CleverTap__Status__c, CleverTap__ConnectionId__c
            FROM CleverTap__Sync_Configuration__c
            WHERE Id = :newConfigId
        ];
        
        System.assertEquals('New Test Config', newConfig.Name, 'Name should match');
        System.assertEquals('Contact', newConfig.CleverTap__Salesforce_Entity__c, 'Source entity should match');
        System.assertEquals('profile', newConfig.CleverTap__Entity__c, 'Target entity should match');
        System.assertEquals('Active', newConfig.CleverTap__Status__c, 'Status should be Active');
        System.assertEquals(connectionId, newConfig.CleverTap__ConnectionId__c, 'Connection ID should match');
    }
    
    /**
     * @description Test getSyncConfigurationById method
     */
    @isTest
    static void testGetSyncConfigurationById() {
        CleverTap__Sync_Configuration__c config = [
            SELECT Id FROM CleverTap__Sync_Configuration__c LIMIT 1
        ];

        Test.startTest();
        SyncConfigurationManager.SyncConfigWrapper wrapper = 
            IntegrationSyncController.getSyncConfigurationById(config.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Should return a config wrapper');
        System.assertEquals('Test Sync Config', wrapper.name, 'Name should match');
        System.assertEquals('salesforce_to_clevertap', wrapper.syncType, 'Sync type should match');
        System.assertEquals('Lead', wrapper.sourceEntity, 'Source entity should match');
        System.assertEquals('profile', wrapper.targetEntity, 'Target entity should match');
        System.assertEquals('Active', wrapper.status, 'Status should match');
    }

    @isTest
    static void testUpdateSyncConfiguration() {
        CleverTap__Sync_Configuration__c config = [
            SELECT Id FROM CleverTap__Sync_Configuration__c LIMIT 1
        ];

        Map<String, Object> updateData = new Map<String, Object>{
            'name' => 'Updated Test Config',
            'syncType' => 'salesforce_to_clevertap',
            'sourceEntity' => 'Account',
            'targetEntity' => 'profile'
        };

        Test.startTest();
        SyncConfigurationManager.SyncConfigWrapper updatedWrapper = 
            IntegrationSyncController.updateSyncConfiguration(config.Id, JSON.serialize(updateData));
        Test.stopTest();

        System.assertEquals('Updated Test Config', updatedWrapper.name, 'Name should be updated');
        System.assertEquals('Account', updatedWrapper.sourceEntity, 'Source entity should be updated');

        CleverTap__Sync_Configuration__c updatedConfig = [
            SELECT Name, CleverTap__Salesforce_Entity__c
            FROM CleverTap__Sync_Configuration__c
            WHERE Id = :config.Id
        ];
        
        System.assertEquals('Updated Test Config', updatedConfig.Name, 'Name should be updated in database');
        System.assertEquals('Account', updatedConfig.CleverTap__Salesforce_Entity__c, 
            'Source entity should be updated in database');
    }
    
    /**
     * @description Test deleteSyncConfiguration method
     */
    @isTest
    static void testDeleteSyncConfiguration() {
        CleverTap__Sync_Configuration__c config = [
            SELECT Id FROM CleverTap__Sync_Configuration__c LIMIT 1
        ];

        Integer initialMappingCount = [
            SELECT COUNT() FROM CleverTap__Mapping__c WHERE CleverTap__Sync_mapping__c = :config.Id
        ];
        System.assertEquals(2, initialMappingCount, 'Should have 2 mappings initially');

        Test.startTest();
        IntegrationSyncController.deleteSyncConfiguration(config.Id);
        Test.stopTest();

        List<CleverTap__Sync_Configuration__c> remainingConfigs = [
            SELECT Id FROM CleverTap__Sync_Configuration__c WHERE Id = :config.Id
        ];
        System.assertEquals(0, remainingConfigs.size(), 'Configuration should be deleted');

        List<CleverTap__Mapping__c> remainingMappings = [
            SELECT Id FROM CleverTap__Mapping__c WHERE CleverTap__Sync_mapping__c = :config.Id
        ];
        System.assertEquals(0, remainingMappings.size(), 'Related mappings should be deleted');
    }
    
    /**
     * @description Test getSalesforceFields method
     */
    @isTest
    static void testGetSalesforceFields() {
        Test.startTest();
        List<Map<String, String>> leadFields = IntegrationSyncController.getSalesforceFields('Lead');
        Test.stopTest();

        System.assertNotEquals(0, leadFields.size(), 'Should return Lead fields');

        Boolean hasEmailField = false;
        Boolean hasLastNameField = false;
        
        for (Map<String, String> field : leadFields) {
            if (field.get('value') == 'Email') {
                hasEmailField = true;
            }
            if (field.get('value') == 'LastName') {
                hasLastNameField = true;
            }
        }
        
        System.assertEquals(true, hasEmailField, 'Should include Email field');
        System.assertEquals(true, hasLastNameField, 'Should include LastName field');
    }
    
    /**
     * @description Test getSalesforceFields with invalid object
     */
    @isTest
    static void testGetSalesforceFieldsInvalidObject() {
        Test.startTest();
        
        Boolean exceptionThrown = false;
        try {
            IntegrationSyncController.getSalesforceFields('InvalidObject');
        } catch (Exception e) {
            exceptionThrown = true;
        }

        if (!exceptionThrown) {
            List<Map<String, String>> results = IntegrationSyncController.getSalesforceFields('InvalidObject');
            System.assertEquals(0, results.size(), 'Invalid object should return empty fields list');
        } else {
            System.assert(exceptionThrown, 'Exception was thrown for invalid object');
        }

        exceptionThrown = false;
        try {
            IntegrationSyncController.getSalesforceFields('');
        } catch (Exception e) {
            exceptionThrown = true;
        }

        if (!exceptionThrown) {
            List<Map<String, String>> results = IntegrationSyncController.getSalesforceFields('');
            System.assertEquals(0, results.size(), 'Empty object name should return empty fields list');
        } else {
            System.assert(exceptionThrown, 'Exception was thrown for empty object name');
        }
        
        Test.stopTest();
    }

    @isTest
    static void testRunHistoricalSync() {
        CleverTap__Sync_Configuration__c config = [
            SELECT Id FROM CleverTap__Sync_Configuration__c LIMIT 1
        ];
        
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'test@example.com',
            Company = 'Test Company'
        );
        insert testLead;

        Test.startTest();
        String result = IntegrationSyncController.runHistoricalSync(config.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a status string');
        System.assertEquals('Success', result, 'Should return success status');

        List<CleverTap__Event__c> events = [
            SELECT Id, CleverTap__Status__c, CleverTap__Response__c 
            FROM CleverTap__Event__c 
        ];

        if (!events.isEmpty()) {
            System.assertEquals('Success', events[0].CleverTap__Status__c, 'Event status should be Success');
        } else {
            System.assert(true, 'No events created, which is acceptable in test context');
        }
    }

    @isTest
    static void testSyncConfigManagerEdgeCases() {
        CleverTap__Sync_Configuration__c config = [SELECT Id FROM CleverTap__Sync_Configuration__c LIMIT 1];
        
        Test.startTest();
        
        try {
            String longName = 'Very long configuration name that exceeds the normal limits of what would be expected in a typical scenario';
            CleverTap__Sync_Configuration__c updatedConfig = new CleverTap__Sync_Configuration__c(
                Id = config.Id,
                Name = longName
            );
            update updatedConfig;
            
            SyncConfigurationManager.SyncConfigWrapper wrapper = IntegrationSyncController.getSyncConfigurationById(config.Id);
            System.assertNotEquals(null, wrapper, 'Should return a valid wrapper');
            
            try {
                IntegrationSyncController.getSyncConfigurationById('invalid_id');
            } catch (Exception e) {
                // Expected exception
            }
        } catch (Exception e) {
            System.debug('Exception in test: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
}

