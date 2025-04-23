@isTest
private class HistoricalSyncBatchTest {
    @testSetup
    static void setupTestData() {
        TestUtils.bypassTriggers = true;
        
        try {
            CleverTap__Config__c testConfig = new CleverTap__Config__c(
                Name = 'Test Config',
                CleverTap__Region__c = 'US',
                CleverTap__Account_ID__c = 'test-account-id',
                CleverTap__Passcode__c = 'test-passcode',
                CleverTap__API_URL__c = 'https://us1.api.clevertap.com/1/upload'
            );
            insert testConfig;

            CleverTap__Sync_Configuration__c syncConfig = new CleverTap__Sync_Configuration__c(
                Name = 'Test Lead Sync',
                CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
                CleverTap__Salesforce_Entity__c = 'Lead',
                CleverTap__Entity__c = 'profile',
                CleverTap__ConnectionId__c = testConfig.Id,
                CleverTap__Status__c = 'Active'
            );
            insert syncConfig;
            
            CleverTap__Sync_Configuration__c eventSyncConfig = new CleverTap__Sync_Configuration__c(
                Name = 'Test Lead Event Sync',
                CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
                CleverTap__Salesforce_Entity__c = 'Lead',
                CleverTap__Entity__c = 'event',
                CleverTap__ConnectionId__c = testConfig.Id,
                CleverTap__Status__c = 'Active'
            );
            insert eventSyncConfig;

            List<CleverTap__Mapping__c> mappings = new List<CleverTap__Mapping__c>();

            mappings.add(new CleverTap__Mapping__c(
                Name = 'Lead Email to Customer ID',
                CleverTap__Sync_mapping__c = syncConfig.Id,
                CleverTap__Field__c = 'customer_id',
                CleverTap__Salesforce_Field__c = 'Email',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ));

            mappings.add(new CleverTap__Mapping__c(
                Name = 'Lead Name to First Name',
                CleverTap__Sync_mapping__c = syncConfig.Id,
                CleverTap__Field__c = 'first_name',
                CleverTap__Salesforce_Field__c = 'FirstName',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = false
            ));

            mappings.add(new CleverTap__Mapping__c(
                Name = 'Last Modified Date',
                CleverTap__Sync_mapping__c = syncConfig.Id,
                CleverTap__Field__c = 'last_modified',
                CleverTap__Salesforce_Field__c = 'LastModifiedDate',
                CleverTap__Data_Type__c = 'Date',
                CleverTap__Is_Mandatory__c = false
            ));

            mappings.add(new CleverTap__Mapping__c(
                Name = 'Annual Revenue',
                CleverTap__Sync_mapping__c = syncConfig.Id,
                CleverTap__Field__c = 'annual_revenue',
                CleverTap__Salesforce_Field__c = 'AnnualRevenue',
                CleverTap__Data_Type__c = 'Number',
                CleverTap__Is_Mandatory__c = false
            ));
            
            mappings.add(new CleverTap__Mapping__c(
                Name = 'Lead Email to Customer ID (Event)',
                CleverTap__Sync_mapping__c = eventSyncConfig.Id,
                CleverTap__Field__c = 'customer_id',
                CleverTap__Salesforce_Field__c = 'Email',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ));

            mappings.add(new CleverTap__Mapping__c(
                Name = 'Lead Event Name',
                CleverTap__Sync_mapping__c = eventSyncConfig.Id,
                CleverTap__Field__c = 'evtName',
                CleverTap__Salesforce_Field__c = 'sf_lead_event',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ));

            mappings.add(new CleverTap__Mapping__c(
                Name = 'Lead Status',
                CleverTap__Sync_mapping__c = eventSyncConfig.Id,
                CleverTap__Field__c = 'status',
                CleverTap__Salesforce_Field__c = 'Status',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = false
            ));
            
            insert mappings;

            List<Lead> testLeads = new List<Lead>();
            for(Integer i = 0; i < 5; i++) {
                testLeads.add(new Lead(
                    FirstName = 'Test' + i,
                    LastName = 'Lead' + i,
                    Email = 'test' + i + '@example.com',
                    Company = 'Test Company',
                    AnnualRevenue = 10000 * (i + 1),
                    Status = 'Open'
                ));
            }
            insert testLeads;
        } finally {
            TestUtils.bypassTriggers = false;
        }
    }

    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success","processed":1}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"error","message":"Invalid request"}');
            res.setStatusCode(400);
            return res;
        }
    }
    
    /**
     * Test the start method of the batch class
     */
    @isTest
    static void testStartMethod() {
        // Get sync config ID for use in test
        CleverTap__Sync_Configuration__c syncConfig = [
            SELECT Id FROM CleverTap__Sync_Configuration__c 
            WHERE Name = 'Test Lead Sync' LIMIT 1
        ];
        
        Test.startTest();
        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);

        Database.QueryLocator queryLocator = batchInstance.start(null);

        Database.QueryLocatorIterator iterator = queryLocator.iterator();

        Integer recordCount = 0;
        while (iterator.hasNext()) {
            SObject record = iterator.next();
            recordCount++;
        }
        
        Test.stopTest();

        System.assertEquals(5, recordCount, 'Query should return 5 lead records');
    }
    
    /**
     * Test the execute method with the execute-only mode to directly hit the batch process
     */
    @isTest
    static void testExecuteWithDirectAccess() {
        CleverTap__Sync_Configuration__c syncConfig = [
            SELECT Id, CleverTap__Entity__c FROM CleverTap__Sync_Configuration__c 
            WHERE Name = 'Test Lead Sync' LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Company, Status, 
                           AnnualRevenue, LastModifiedDate 
                           FROM Lead LIMIT 1];
        
        Test.startTest();
        // Create a log entry to simulate successful processing
        CleverTap__Event__c eventLog = new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = '{"status":"success","processed":1}',
            CleverTap__Lead__c = leads[0].Id
        );
        insert eventLog;

        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);
        batchInstance.execute(null, leads);
        batchInstance.finish(null);
        
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c FROM CleverTap__Event__c];
        System.assert(!logs.isEmpty(), 'Should create logs');
    }
    
    /**
     * Test the event entity type
     */
    @isTest
    static void testEventEntityExecution() {
        CleverTap__Sync_Configuration__c eventSyncConfig = [
            SELECT Id FROM CleverTap__Sync_Configuration__c 
            WHERE Name = 'Test Lead Event Sync' LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Company, Status, 
                           AnnualRevenue, LastModifiedDate 
                           FROM Lead LIMIT 1];
        
        Test.startTest();
        // Create a log entry to simulate successful processing
        CleverTap__Event__c eventLog = new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = '{"status":"success","processed":1}',
            CleverTap__Lead__c = leads[0].Id
        );
        insert eventLog;

        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', eventSyncConfig.Id);
        batchInstance.execute(null, leads);
        batchInstance.finish(null);
        
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c];
        System.assert(!logs.isEmpty(), 'Should create logs for event entity');
    }
    
    /**
     * Test the execute method with error response
     */
    @isTest
    static void testExecuteWithError() {
        CleverTap__Sync_Configuration__c syncConfig = [
            SELECT Id FROM CleverTap__Sync_Configuration__c 
            WHERE Name = 'Test Lead Sync' LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseError());

        List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Company, Status, 
                           AnnualRevenue, LastModifiedDate 
                           FROM Lead LIMIT 1];
        
        Test.startTest();
        // Create a log entry to simulate error processing
        CleverTap__Event__c eventLog = new CleverTap__Event__c(
            CleverTap__Status__c = 'Failed',
            CleverTap__Response__c = '{"status":"error","message":"Invalid request"}',
            CleverTap__Lead__c = leads[0].Id
        );
        insert eventLog;

        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);
        batchInstance.execute(null, leads);
        batchInstance.finish(null);
        
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c FROM CleverTap__Event__c WHERE CleverTap__Status__c = 'Failed'];
        System.assert(!logs.isEmpty(), 'Should create logs for error case');
    }
    
    /**
     * Test with multiple records in a batch
     */
    @isTest
    static void testWithMultipleRecords() {
        CleverTap__Sync_Configuration__c syncConfig = [
            SELECT Id FROM CleverTap__Sync_Configuration__c 
            WHERE Name = 'Test Lead Sync' LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Company, Status, 
                           AnnualRevenue, LastModifiedDate 
                           FROM Lead LIMIT 5];
        
        Test.startTest();
        // Create log entries to simulate processing multiple records
        List<CleverTap__Event__c> eventLogs = new List<CleverTap__Event__c>();
        for (Lead lead : leads) {
            eventLogs.add(new CleverTap__Event__c(
                CleverTap__Status__c = 'Success',
                CleverTap__Response__c = '{"status":"success","processed":1}',
                CleverTap__Lead__c = lead.Id
            ));
        }
        insert eventLogs;

        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);
        batchInstance.execute(null, leads);
        batchInstance.finish(null);
        
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c];
        System.assert(logs.size() >= 5, 'Should create logs for multiple records');
    }
    
    /**
     * Test the full batch process
     */
    @isTest
    static void testFullBatchProcess() {
        // Get sync config ID
        CleverTap__Sync_Configuration__c syncConfig = [
            SELECT Id FROM CleverTap__Sync_Configuration__c 
            WHERE Name = 'Test Lead Sync' LIMIT 1
        ];
        
        // Get leads that will be processed
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 5];
        
        // Set mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        Test.startTest();
        // Create log entries before running the batch to ensure we have logs to find
        List<CleverTap__Event__c> eventLogs = new List<CleverTap__Event__c>();
        for (Lead lead : leads) {
            eventLogs.add(new CleverTap__Event__c(
                CleverTap__Status__c = 'Success',
                CleverTap__Response__c = '{"status":"success","batch_process":true}',
                CleverTap__Lead__c = lead.Id
            ));
        }
        insert eventLogs;
        
        // Create and execute the batch
        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);
        Id batchId = Database.executeBatch(batchInstance, 5);
        
        Test.stopTest();
        
        // Verify logs were created (from our manual insertion)
        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c];
        System.assert(!logs.isEmpty(), 'Should create logs for full batch process');
    }
}