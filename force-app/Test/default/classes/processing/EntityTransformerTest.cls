@isTest
private class EntityTransformerTest {
    static EntityTransformer entityTransformer = new EntityTransformer();

    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'test.lead@example.com',
            Company = 'Test Company'
        );
        insert testLead;

        CleverTap__Sync_Configuration__c leadConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test Lead Config',
            CleverTap__Salesforce_Entity__c = 'Lead',
            CleverTap__Entity__c = 'profile',
            CleverTap__Status__c = 'Active',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__ConnectionId__c = 'TEST_CONN_ID_1'
        );
        insert leadConfig;

        List<CleverTap__Mapping__c> leadMappings = new List<CleverTap__Mapping__c>{
            new CleverTap__Mapping__c(
                CleverTap__Sync_mapping__c = leadConfig.Id,
                CleverTap__Field__c = 'Identity',
                CleverTap__Salesforce_Field__c = 'Email',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ),
            new CleverTap__Mapping__c(
                CleverTap__Sync_mapping__c = leadConfig.Id,
                CleverTap__Field__c = 'first_name',
                CleverTap__Salesforce_Field__c = 'FirstName',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = false
            ),
            new CleverTap__Mapping__c(
                CleverTap__Sync_mapping__c = leadConfig.Id,
                CleverTap__Field__c = 'last_name',
                CleverTap__Salesforce_Field__c = 'LastName',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = false
            )
        };
        insert leadMappings;

        CleverTap__Sync_Configuration__c leadEventConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test Lead Event Config',
            CleverTap__Salesforce_Entity__c = 'Lead',
            CleverTap__Entity__c = 'event',
            CleverTap__Status__c = 'Active',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__ConnectionId__c = 'TEST_CONN_ID_2'
        );
        insert leadEventConfig;

        List<CleverTap__Mapping__c> leadEventMappings = new List<CleverTap__Mapping__c>{
            new CleverTap__Mapping__c(
                CleverTap__Sync_mapping__c = leadEventConfig.Id,
                CleverTap__Field__c = 'Identity',
                CleverTap__Salesforce_Field__c = 'Email',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ),
            new CleverTap__Mapping__c(
                CleverTap__Sync_mapping__c = leadEventConfig.Id,
                CleverTap__Field__c = 'evtName',
                CleverTap__Salesforce_Field__c = 'sf_lead_created',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ),
            new CleverTap__Mapping__c(
                CleverTap__Sync_mapping__c = leadEventConfig.Id,
                CleverTap__Field__c = 'company',
                CleverTap__Salesforce_Field__c = 'Company',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = false
            )
        };
        insert leadEventMappings;

        CleverTap__Sync_Configuration__c contactConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test Contact Config',
            CleverTap__Salesforce_Entity__c = 'Contact',
            CleverTap__Entity__c = 'profile',
            CleverTap__Status__c = 'Active',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__ConnectionId__c = 'TEST_CONN_ID_3'
        );
        insert contactConfig;

        List<CleverTap__Mapping__c> contactMappings = new List<CleverTap__Mapping__c>{
            new CleverTap__Mapping__c(
                CleverTap__Sync_mapping__c = contactConfig.Id,
                CleverTap__Field__c = 'Identity',
                CleverTap__Salesforce_Field__c = 'Email',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ),
            new CleverTap__Mapping__c(
                CleverTap__Sync_mapping__c = contactConfig.Id,
                CleverTap__Field__c = 'name',
                CleverTap__Salesforce_Field__c = 'LastName',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = false
            )
        };
        insert contactMappings;
    }
    
    @isTest
    static void testMapToCleverTapWithLead() {
        Lead testLead = [SELECT Id, FirstName, LastName, Email, Company FROM Lead LIMIT 1];

        Test.startTest();
        Map<String, Object> result = entityTransformer.mapToCleverTap(testLead, 'Lead');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Mapping result should not be null');
        System.assertEquals('profile', result.get('type'), 'Type should be profile');
        System.assertEquals(testLead.Email, result.get('identity'), 'Identity should be email');

        Map<String, Object> profileData = (Map<String, Object>)result.get('profileData');
        System.assertNotEquals(null, profileData, 'Profile data should not be null');
        System.assertEquals(testLead.FirstName, profileData.get('first_name'), 'First name should be mapped');
        System.assertEquals(testLead.LastName, profileData.get('last_name'), 'Last name should be mapped');
    }
    
    @isTest
    static void testMapToCleverTapWithContact() {
        Contact testContact = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Test.startTest();
        Map<String, Object> result = entityTransformer.mapToCleverTap(testContact, 'Contact');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Mapping result should not be null');
        System.assertEquals('profile', result.get('type'), 'Type should be profile');
        System.assertEquals(testContact.Email, result.get('identity'), 'Identity should be email');

        Map<String, Object> profileData = (Map<String, Object>)result.get('profileData');
        System.assertNotEquals(null, profileData, 'Profile data should not be null');
        System.assertEquals(testContact.LastName, profileData.get('name'), 'Name should be mapped');
    }
    
    @isTest
    static void testMapToMultipleConnections() {
        Lead testLead = [SELECT Id, FirstName, LastName, Email, Company FROM Lead LIMIT 1];
        
        Test.startTest();
        List<entityTransformer.ConnectionMapping> results = entityTransformer.mapToMultipleConnections(testLead, 'Lead');
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should have mappings for 2 connections');

        entityTransformer.ConnectionMapping profileMapping = null;
        entityTransformer.ConnectionMapping eventMapping = null;
        
        for (entityTransformer.ConnectionMapping mapping : results) {
            Map<String, Object> payload = mapping.payload;
            if (payload.get('type') == 'profile') {
                profileMapping = mapping;
            } else if (payload.get('type') == 'event') {
                eventMapping = mapping;
            }
        }

        System.assertNotEquals(null, profileMapping, 'Should have a profile mapping');
        System.assertEquals('TEST_CONN_ID_1', profileMapping.connectionId, 'Connection ID should match');
        System.assertEquals('profile', profileMapping.payload.get('type'), 'Type should be profile');

        System.assertNotEquals(null, eventMapping, 'Should have an event mapping');
        System.assertEquals('TEST_CONN_ID_2', eventMapping.connectionId, 'Connection ID should match');
        System.assertEquals('event', eventMapping.payload.get('type'), 'Type should be event');
        System.assertEquals('sf_lead_created', eventMapping.payload.get('evtName'), 'Event name should be set');
    }
    
    @isTest
    static void testMapToCleverTapWithNull() {
        Test.startTest();
        Map<String, Object> result = entityTransformer.mapToCleverTap(null, 'Lead');
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null for null record');
    }
    
    @isTest
    static void testMapToCleverTapWithNoConfig() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Map<String, Object> result = entityTransformer.mapToCleverTap(testAccount, 'Account');
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when no config exists');
    }
    
    @isTest
    static void testMapToCleverTapWithNoMappings() {
        CleverTap__Sync_Configuration__c accountConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test Account Config',
            CleverTap__Salesforce_Entity__c = 'Account',
            CleverTap__Entity__c = 'profile',
            CleverTap__Status__c = 'Active',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap'
        );
        insert accountConfig;

        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Map<String, Object> result = entityTransformer.mapToCleverTap(testAccount, 'Account');
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when no Identity mapping exists');
    }
    
    @isTest
    static void testMapToCleverTapWithMissingIdentityValue() {
        Lead leadWithoutEmail = new Lead(
            FirstName = 'No',
            LastName = 'Email',
            Company = 'Test Company'
        );
        insert leadWithoutEmail;

        Test.startTest();
        Map<String, Object> result = entityTransformer.mapToCleverTap(leadWithoutEmail, 'Lead');
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when identity value is missing');
    }
}