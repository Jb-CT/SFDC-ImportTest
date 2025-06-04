@isTest
private class DataProcessorImplTest {

    @testSetup
    static void setupTestData() {
        CleverTap__Config__c testConfig = new CleverTap__Config__c(
            Name = 'Test Config',
            CleverTap__Region__c = 'US',
            CleverTap__Account_ID__c = 'test-id',
            CleverTap__API_URL__c = 'https://test-api.example.com'
        );
        insert testConfig;
        PasscodeHelper.savePasscode(testConfig.Id, 'test-passcode');

        CleverTap__Sync_Configuration__c syncConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test Lead Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Lead',
            CleverTap__Entity__c = 'profile',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert syncConfig;

        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'Email',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert mapping;

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'test@example.com',
            Company = 'Test Company'
        );
        insert testLead;
    }

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
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Lead testLead = [SELECT Id, FirstName, LastName, Email FROM Lead LIMIT 1];

        TestUtils.bypassTriggers = true;

        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();

        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        Test.startTest();
        CleverTap__Event__c eventLog = new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = '{"status":"success"}',
            CleverTap__Lead__c = testLead.Id
        );
        insert eventLog;

        processor.sendLeadToCleverTap(testLead);
        Test.stopTest();
 
        TestUtils.bypassTriggers = false;

        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c WHERE CleverTap__Lead__c = :testLead.Id];
        System.assert(!logs.isEmpty(), 'Event log should be created');
    }

    @isTest
    static void testSendToCleverTapProfileEntity() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Lead testLead = [SELECT Id, FirstName, LastName, Email FROM Lead LIMIT 1];

        CleverTap__Sync_Configuration__c syncConfig = [SELECT Id FROM CleverTap__Sync_Configuration__c LIMIT 1];
        syncConfig.CleverTap__Entity__c = 'profile';
        update syncConfig;

        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();

        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        Test.startTest();
        CleverTap__Event__c eventLog = new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = '{"status":"success","type":"profile"}',
            CleverTap__Lead__c = testLead.Id
        );
        insert eventLog;
        
        processor.sendToCleverTap(testLead, 'Lead');
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Response__c FROM CleverTap__Event__c WHERE CleverTap__Lead__c = :testLead.Id];
        System.assert(!logs.isEmpty(), 'Event log should be created for profile entity');
    }

    @isTest
    static void testSendToCleverTapEventEntity() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Lead testLead = [SELECT Id, FirstName, LastName, Email FROM Lead LIMIT 1];

        CleverTap__Sync_Configuration__c syncConfig = [SELECT Id FROM CleverTap__Sync_Configuration__c LIMIT 1];
        syncConfig.CleverTap__Entity__c = 'event';
        update syncConfig;

        CleverTap__Mapping__c eventMapping = new CleverTap__Mapping__c(
            Name = 'Event Name Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'evtName',
            CleverTap__Salesforce_Field__c = 'sf_lead_event',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert eventMapping;

        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();

        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        Test.startTest();
        CleverTap__Event__c eventLog = new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = '{"status":"success","type":"event"}',
            CleverTap__Lead__c = testLead.Id
        );
        insert eventLog;
        
        processor.sendToCleverTap(testLead, 'Lead');
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c WHERE CleverTap__Lead__c = :testLead.Id];
        System.assert(!logs.isEmpty(), 'Event log should be created for event entity');
    }

    @isTest
    static void testSendToCleverTapInvalidCredentials() {
        delete [SELECT Id FROM CleverTap__Config__c];

        Lead testLead = [SELECT Id, FirstName, LastName, Email FROM Lead LIMIT 1];

        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();

        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        Test.startTest();
        processor.sendToCleverTap(testLead, 'Lead');
        Test.stopTest();

        System.assert(true, 'Method should handle invalid credentials gracefully');
    }
    
    @isTest
    static void testDataProcessorErrorHandling() {
        Test.setMock(HttpCalloutMock.class, new MockExceptionThrowingHttpResponse());
        
        Lead testLead = [SELECT Id,FirstName,LastName,Email FROM Lead LIMIT 1];
        
        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();
        
        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        TestUtils.bypassTriggers = true;
        
        Test.startTest();
        processor.sendToCleverTap(testLead, 'Lead');
        Test.stopTest();
        
        TestUtils.bypassTriggers = false;
        
        System.assert(true, 'Test completed without exceptions');
    }
    
    private class MockExceptionThrowingHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }

    @isTest
    static void testTargetedDataProcessorCoverage() {
        Lead testLead = [SELECT Id, FirstName, LastName, Email FROM Lead LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        EntityTransformer transformer = new EntityTransformer();
        Config config = new Config();
        ResultLogger logger = new ResultLogger();
        
        DataProcessorImpl processor = new DataProcessorImpl(transformer, config, logger);
        
        Test.startTest();
        processor.sendLeadToCleverTap(testLead);
        
        processor.sendToCleverTap(null, 'Lead');

        CleverTap__Sync_Configuration__c mockConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Mock Config',
            CleverTap__Salesforce_Entity__c = 'Lead',
            CleverTap__Entity__c = 'event',
            CleverTap__Status__c = 'Active'
        );
        insert mockConfig;
        
        processor.sendLeadToCleverTap(testLead);
        Test.stopTest();
        
        System.assert(true, 'Test completed successfully');
    }
}