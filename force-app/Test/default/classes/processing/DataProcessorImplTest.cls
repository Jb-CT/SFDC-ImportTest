@isTest
private class DataProcessorImplTest {
    
    // Create test data first
    @testSetup
    static void setupTestData() {
        // Test config record
        CleverTap_Config__c testConfig = new CleverTap_Config__c(
            Name = 'Test Config',
            Region__c = 'US',
            CleverTap_Account_ID__c = 'test-id',
            CleverTap_Passcode__c = 'test-pass',
            CleverTap_API_URL__c = 'https://test-api.example.com'
        );
        insert testConfig;
        
        // Create sync config
        CleverTap_Sync_Configuration__c syncConfig = new CleverTap_Sync_Configuration__c(
            Name = 'Test Lead Sync',
            Sync_Type__c = 'salesforce_to_clevertap',
            Salesforce_Entity__c = 'Lead',
            CleverTap_Entity__c = 'profile',
            ConnectionId__c = testConfig.Id,
            Status__c = 'Active'
        );
        insert syncConfig;
        
        // Create field mapping
        CleverTap_Mapping__c mapping = new CleverTap_Mapping__c(
            Name = 'Test Mapping',
            Sync_Configuration__c = syncConfig.Id,
            CleverTap_Field__c = 'customer_id',
            Salesforce_Field__c = 'Email',
            Data_Type__c = 'Text',
            Is_Mandatory__c = true
        );
        insert mapping;
        
        // Create test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'test@example.com',
            Company = 'Test Company'
        );
        insert testLead;
    }
    
    // Mock HTTP class
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testSendLeadToCleverTap() {
        // Set up mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        // Get test lead
        Lead testLead = [SELECT Id, FirstName, LastName, Email FROM Lead LIMIT 1];
        
        // Enable bypass to prevent trigger recursion
        TestUtils.bypassTriggers = true;
        
        // Create test helpers
        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();
        
        // Create processor instance
        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        Test.startTest();
        processor.sendLeadToCleverTap(testLead);
        Test.stopTest();
        
        // Restore bypass flag
        TestUtils.bypassTriggers = false;
        
        // Verify log created
        List<CleverTap_Event__c> logs = [SELECT Id, Status__c FROM CleverTap_Event__c WHERE Lead__c = :testLead.Id];
        System.assertNotEquals(0, logs.size(), 'Event log should be created');
    }
    
    // Test sendToCleverTap method with profile entity
    @isTest
    static void testSendToCleverTapProfileEntity() {
        // Set up mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        // Get test lead
        Lead testLead = [SELECT Id, FirstName, LastName, Email FROM Lead LIMIT 1];
        
        // Update sync config to profile
        CleverTap_Sync_Configuration__c syncConfig = [SELECT Id FROM CleverTap_Sync_Configuration__c LIMIT 1];
        syncConfig.CleverTap_Entity__c = 'profile';
        update syncConfig;
        
        // Create test helpers
        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();
        
        // Create processor instance
        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        Test.startTest();
        processor.sendToCleverTap(testLead, 'Lead');
        Test.stopTest();
        
        // Verify log created
        List<CleverTap_Event__c> logs = [SELECT Id FROM CleverTap_Event__c WHERE Lead__c = :testLead.Id];
        System.assertNotEquals(0, logs.size(), 'Event log should be created for profile entity');
    }
    
    // Test sendToCleverTap method with event entity
    @isTest
    static void testSendToCleverTapEventEntity() {
        // Set up mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        // Get test lead
        Lead testLead = [SELECT Id, FirstName, LastName, Email FROM Lead LIMIT 1];
        
        // Update sync config to event
        CleverTap_Sync_Configuration__c syncConfig = [SELECT Id FROM CleverTap_Sync_Configuration__c LIMIT 1];
        syncConfig.CleverTap_Entity__c = 'event';
        update syncConfig;
        
        // Create additional mandatory mapping for event name
        CleverTap_Mapping__c eventMapping = new CleverTap_Mapping__c(
            Name = 'Event Name Mapping',
            Sync_Configuration__c = syncConfig.Id,
            CleverTap_Field__c = 'evtName',
            Salesforce_Field__c = 'sf_lead_event',
            Data_Type__c = 'Text',
            Is_Mandatory__c = true
        );
        insert eventMapping;
        
        // Create test helpers
        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();
        
        // Create processor instance
        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        Test.startTest();
        processor.sendToCleverTap(testLead, 'Lead');
        Test.stopTest();
        
        // Verify log created
        List<CleverTap_Event__c> logs = [SELECT Id FROM CleverTap_Event__c WHERE Lead__c = :testLead.Id];
        System.assertNotEquals(0, logs.size(), 'Event log should be created for event entity');
    }
    
    // Test with invalid credentials
    @isTest
    static void testSendToCleverTapInvalidCredentials() {
        // Delete config to simulate invalid credentials
        delete [SELECT Id FROM CleverTap_Config__c];
        
        // Get test lead
        Lead testLead = [SELECT Id, FirstName, LastName, Email FROM Lead LIMIT 1];
        
        // Create test helpers
        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();
        
        // Create processor instance
        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        Test.startTest();
        processor.sendToCleverTap(testLead, 'Lead');
        Test.stopTest();
        
        // No exception should be thrown
        System.assert(true, 'Method should handle invalid credentials gracefully');
    }

}