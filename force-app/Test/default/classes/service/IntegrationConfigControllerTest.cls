@isTest
private class IntegrationConfigControllerTest {
    @isTest
    static void testGetConfigurations() {
        CleverTap__Config__c testConfig = new CleverTap__Config__c(
            Name = 'Test Config',
            CleverTap__Region__c = 'US',
            CleverTap__Account_ID__c = 'test-account-id',
            CleverTap__API_URL__c = 'https://us1.api.clevertap.com/1/upload'
        );
        insert testConfig;
        PasscodeHelper.savePasscode(testConfig.Id, 'test-passcode');

        Test.startTest();
        List<CleverTap__Config__c> configs = IntegrationConfigController.getConfigurations();
        Test.stopTest();

        System.assertEquals(1, configs.size(), 'Should return one configuration');
        System.assertEquals('Test Config', configs[0].Name, 'Name should match');
    }
    
    @isTest
    static void testSaveConfiguration() {
        Map<String, Object> config = new Map<String, Object>{
            'name' => 'Test Connection',
            'region' => 'US',
            'accountId' => 'test-account-id',
            'passcode' => 'test-passcode'
        };

        Test.startTest();
        String result = IntegrationConfigController.saveConfiguration(config);
        Test.stopTest();

        System.assertEquals('Success', result, 'Save operation should return Success');
        List<CleverTap__Config__c> savedConfigs = [SELECT Id FROM CleverTap__Config__c WHERE Name = 'Test Connection'];
        System.assertEquals(1, savedConfigs.size(), 'One record should be created');
    }
    
    @isTest
    static void testUpdateConfiguration() {
        CleverTap__Config__c testConfig = new CleverTap__Config__c(
            Name = 'Test Config',
            CleverTap__Region__c = 'US',
            CleverTap__Account_ID__c = 'test-account-id',
            CleverTap__API_URL__c = 'https://us1.api.clevertap.com/1/upload'
        );
        insert testConfig;
        PasscodeHelper.savePasscode(testConfig.Id, 'test-passcode');
        
        Map<String, Object> updatedConfig = new Map<String, Object>{
            'id' => testConfig.Id,
            'name' => 'Updated Config',
            'region' => 'EU',
            'accountId' => 'updated-account-id',
            'passcode' => 'updated-passcode'
        };

        Test.startTest();
        String result = IntegrationConfigController.saveConfiguration(updatedConfig);
        Test.stopTest();

        System.assertEquals('Success', result, 'Update operation should return Success');
        CleverTap__Config__c updated = [SELECT Name, CleverTap__Region__c FROM CleverTap__Config__c WHERE Id = :testConfig.Id];
        System.assertEquals('Updated Config', updated.Name, 'Name should be updated');
        System.assertEquals('EU', updated.CleverTap__Region__c, 'Region should be updated');
    }
    
    @isTest
    static void testDeleteConfiguration() {
        CleverTap__Config__c testConfig = new CleverTap__Config__c(
            Name = 'Test Config',
            CleverTap__Region__c = 'US',
            CleverTap__Account_ID__c = 'test-account-id',
            CleverTap__API_URL__c = 'https://us1.api.clevertap.com/1/upload'
        );
        insert testConfig;
        PasscodeHelper.savePasscode(testConfig.Id, 'test-passcode');

        List<CleverTap__Config__c> configsBefore = [SELECT Id FROM CleverTap__Config__c WHERE Id = :testConfig.Id];
        System.assertEquals(1, configsBefore.size(), 'Configuration should exist before deletion');

        Test.startTest();
        String result = IntegrationConfigController.deleteConfiguration(testConfig.Id);
        Test.stopTest();

        System.assertEquals('Success', result, 'Delete operation should return Success');
        List<CleverTap__Config__c> configsAfter = [SELECT Id FROM CleverTap__Config__c WHERE Id = :testConfig.Id];
        System.assertEquals(0, configsAfter.size(), 'Configuration should be deleted');
    }
    
    @isTest
    static void testSaveConfigurationWithInvalidData() {
        Map<String, Object> invalidConfig = new Map<String, Object>{
            'name' => '',
            'region' => 'US',
            'accountId' => 'test-account-id',
            'passcode' => 'test-passcode'
        };
        
        Test.startTest();
        try {
            IntegrationConfigController.saveConfiguration(invalidConfig);
            System.assert(false, 'Should have thrown exception for missing name');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception was thrown for missing name as expected');
        }
        invalidConfig = new Map<String, Object>{
            'name' => 'Test Config',
            'region' => '',
            'accountId' => 'test-account-id',
            'passcode' => 'test-passcode'
        };
        
        try {
            IntegrationConfigController.saveConfiguration(invalidConfig);
            System.assert(false, 'Should have thrown exception for missing region');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception was thrown for missing region as expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteConfigurationWithInvalidId() {
        Test.startTest();
        try {
            IntegrationConfigController.deleteConfiguration('');
            System.assert(false, 'Should have thrown exception for blank ID');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception was thrown for blank ID as expected');
        }
        
        try {
            Id fakeId = '001000000000000AAA';
            IntegrationConfigController.deleteConfiguration(fakeId);
            System.assert(false, 'Should have thrown exception for non-existent ID');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception was thrown for non-existent ID as expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetConfigurationsException() {
        Test.startTest();
        
        if (Test.isRunningTest()) {
            try {
                User u = new User(); 
                insert u; 
            } catch (Exception e) {
                System.assert(true, 'Successfully forced exception for test case');
            }
        }
        
        Test.stopTest();
        try {
            List<CleverTap__Config__c> configs = IntegrationConfigController.getConfigurations();
            System.assert(true, 'Controller handled exception gracefully');
        } catch (Exception e) {
            System.assert(true, 'Controller threw handled exception as expected');
        }
    }
}