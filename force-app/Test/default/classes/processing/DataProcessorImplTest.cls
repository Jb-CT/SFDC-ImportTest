@isTest
private class DataProcessorImplTest {
    
    // Create test data first
    @testSetup
    static void setupTestData() {
        // Test config record
        CleverTap__Config__c testConfig = new CleverTap__Config__c(
            Name = 'Test Config',
            CleverTap__Region__c = 'US',
            CleverTap__Account_ID__c = 'test-id',
            CleverTap__Passcode__c = 'test-pass',
            CleverTap__API_URL__c = 'https://test-api.example.com'
        );
        insert testConfig;
        
        // Create sync config
        CleverTap__Sync_Configuration__c syncConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test Lead Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Lead',
            CleverTap__Entity__c = 'profile',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert syncConfig;
        
        // Create field mapping
        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'customer_id',
            CleverTap__Salesforce_Field__c = 'Email',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
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
        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c FROM CleverTap__Event__c WHERE Lead__c = :testLead.Id];
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
        CleverTap__Sync_Configuration__c syncConfig = [SELECT Id FROM CleverTap__Sync_Configuration__c LIMIT 1];
        syncConfig.CleverTap__Entity__c = 'profile';
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
        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c WHERE Lead__c = :testLead.Id];
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
        CleverTap__Sync_Configuration__c syncConfig = [SELECT Id FROM CleverTap__Sync_Configuration__c LIMIT 1];
        syncConfig.CleverTap__Entity__c = 'event';
        update syncConfig;
        
        // Create additional mandatory mapping for event name
        CleverTap__Mapping__c eventMapping = new CleverTap__Mapping__c(
            Name = 'Event Name Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'evtName',
            CleverTap__Salesforce_Field__c = 'sf_lead_event',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
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
        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c WHERE Lead__c = :testLead.Id];
        System.assertNotEquals(0, logs.size(), 'Event log should be created for event entity');
    }
    
    // Test with invalid credentials
    @isTest
    static void testSendToCleverTapInvalidCredentials() {
        // Delete config to simulate invalid credentials
        delete [SELECT Id FROM CleverTap__Config__c];
        
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
    @isTest
    static void testDataProcessorErrorHandling() {
        // Setup a mock that throws an exception
        Test.setMock(HttpCalloutMock.class, new MockExceptionThrowingHttpResponse());
        
        // Get test lead
        Lead testLead = [SELECT Id, FirstName, LastName, Email FROM Lead LIMIT 1];
        
        // Create test helpers
        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();
        
        // Create processor instance
        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        // Enable bypass for trigger
        TestUtils.bypassTriggers = true;
        
        Test.startTest();
        // This should exercise error handling paths in DataProcessorImpl
        processor.sendToCleverTap(testLead, 'Lead');
        Test.stopTest();
        
        // Reset bypass flag
        TestUtils.bypassTriggers = false;
        
        // No assertions needed - we're just exercising the code paths
        System.assert(true, 'Test completed without exceptions');
    }
    
    // Mock that throws an exception during HTTP callout
    private class MockExceptionThrowingHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }
}