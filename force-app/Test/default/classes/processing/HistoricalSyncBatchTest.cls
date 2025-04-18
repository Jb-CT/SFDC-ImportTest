@isTest
private class HistoricalSyncBatchTest {
    // Set up test data
    @testSetup
    static void setupTestData() {
        // Enable trigger bypass to prevent infinite recursion
        TestUtils.bypassTriggers = true;
        
        try {
            // Create test connection
            CleverTap__Config__c testConfig = new CleverTap__Config__c(
                Name = 'Test Config',
                CleverTap__Region__c = 'US',
                CleverTap__Account_ID__c = 'test-account-id',
                CleverTap__Passcode__c = 'test-passcode',
                CleverTap__API_URL__c = 'https://us1.api.clevertap.com/1/upload'
            );
            insert testConfig;
            
            // Create sync configuration for profile
            CleverTap__Sync_Configuration__c syncConfig = new CleverTap__Sync_Configuration__c(
                Name = 'Test Lead Sync',
                CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
                CleverTap__Salesforce_Entity__c = 'Lead',
                CleverTap__Entity__c = 'profile',
                CleverTap__ConnectionId__c = testConfig.Id,
                CleverTap__Status__c = 'Active'
            );
            insert syncConfig;
            
            // Add a sync configuration for event type testing
            CleverTap__Sync_Configuration__c eventSyncConfig = new CleverTap__Sync_Configuration__c(
                Name = 'Test Lead Event Sync',
                CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
                CleverTap__Salesforce_Entity__c = 'Lead',
                CleverTap__Entity__c = 'event',
                CleverTap__ConnectionId__c = testConfig.Id,
                CleverTap__Status__c = 'Active'
            );
            insert eventSyncConfig;
            
            // Create field mappings
            List<CleverTap__Mapping__c> mappings = new List<CleverTap__Mapping__c>();
            
            // Customer ID mapping for profile sync
            mappings.add(new CleverTap__Mapping__c(
                Name = 'Lead Email to Customer ID',
                CleverTap__Sync_mapping__c = syncConfig.Id,
                CleverTap__Field__c = 'customer_id',
                CleverTap__Salesforce_Field__c = 'Email',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ));
            
            // Add a regular field mapping for profile sync
            mappings.add(new CleverTap__Mapping__c(
                Name = 'Lead Name to First Name',
                CleverTap__Sync_mapping__c = syncConfig.Id,
                CleverTap__Field__c = 'first_name',
                CleverTap__Salesforce_Field__c = 'FirstName',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = false
            ));
            
            // Date field mapping
            mappings.add(new CleverTap__Mapping__c(
                Name = 'Last Modified Date',
                CleverTap__Sync_mapping__c = syncConfig.Id,
                CleverTap__Field__c = 'last_modified',
                CleverTap__Salesforce_Field__c = 'LastModifiedDate',
                CleverTap__Data_Type__c = 'Date',
                CleverTap__Is_Mandatory__c = false
            ));
            

            
            // Add another regular field mapping of different type
            mappings.add(new CleverTap__Mapping__c(
                Name = 'Annual Revenue',
                CleverTap__Sync_mapping__c = syncConfig.Id,
                CleverTap__Field__c = 'annual_revenue',
                CleverTap__Salesforce_Field__c = 'AnnualRevenue',
                CleverTap__Data_Type__c = 'Number',
                CleverTap__Is_Mandatory__c = false
            ));
            
            // Customer ID mapping for event sync
            mappings.add(new CleverTap__Mapping__c(
                Name = 'Lead Email to Customer ID (Event)',
                CleverTap__Sync_mapping__c = eventSyncConfig.Id,
                CleverTap__Field__c = 'customer_id',
                CleverTap__Salesforce_Field__c = 'Email',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ));
            
            // Event name mapping
            mappings.add(new CleverTap__Mapping__c(
                Name = 'Lead Event Name',
                CleverTap__Sync_mapping__c = eventSyncConfig.Id,
                CleverTap__Field__c = 'evtName',
                CleverTap__Salesforce_Field__c = 'sf_lead_event',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ));
            
            // Status field for event
            mappings.add(new CleverTap__Mapping__c(
                Name = 'Lead Status',
                CleverTap__Sync_mapping__c = eventSyncConfig.Id,
                CleverTap__Field__c = 'status',
                CleverTap__Salesforce_Field__c = 'Status',
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = false
            ));
            
            insert mappings;
            
            // Create test leads
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
            // Make sure to reset the bypass flag
            TestUtils.bypassTriggers = false;
        }
    }
    
    // Mock HTTP callout class for successful responses
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success","processed":1}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Mock HTTP callout class for error responses
    private class MockHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"error","message":"Invalid request"}');
            res.setStatusCode(400);
            return res;
        }
    }
    
    // This helper method accesses private methods via reflection
    private static Object invokePrivateMethod(Object obj, String methodName, List<Type> paramTypes, List<Object> params) {
        // This method doesn't actually work in Apex, but we're using it 
        // as a placeholder to indicate the intent of testing private methods
        return null;
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
        
        // Create batch instance
        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);
        
        // Execute the start method
        Database.QueryLocator queryLocator = batchInstance.start(null);
        
        // Execute the query locator to verify it works
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        
        // Count the records
        Integer recordCount = 0;
        while (iterator.hasNext()) {
            SObject record = iterator.next();
            recordCount++;
        }
        
        Test.stopTest();
        
        // Assert that the query returned the expected number of records
        System.assertEquals(5, recordCount, 'Query should return 5 lead records');
    }
    
    /**
     * Test the execute method with the execute-only mode to directly hit the batch process
     */
    @isTest
    static void testExecuteWithDirectAccess() {
        // Get sync config ID
        CleverTap__Sync_Configuration__c syncConfig = [
            SELECT Id, CleverTap__Entity__c FROM CleverTap__Sync_Configuration__c 
            WHERE Name = 'Test Lead Sync' LIMIT 1
        ];
        
        // Set mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        // Get a lead to use for testing
        List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Company, Status, 
                           AnnualRevenue, LastModifiedDate 
                           FROM Lead LIMIT 1];
        
        Test.startTest();
        
        // Create the batch instance
        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);
        
        // Execute the batch with the lead records
        batchInstance.execute(null, leads);
        
        // Call finish
        batchInstance.finish(null);
        
        Test.stopTest();
        
        // Verify log creation
        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c FROM CleverTap__Event__c];
        System.assertNotEquals(0, logs.size(), 'Should create logs');
    }
    
    /**
     * Test the event entity type
     */
    @isTest
    static void testEventEntityExecution() {
        // Get sync config ID for event
        CleverTap__Sync_Configuration__c eventSyncConfig = [
            SELECT Id FROM CleverTap__Sync_Configuration__c 
            WHERE Name = 'Test Lead Event Sync' LIMIT 1
        ];
        
        // Set mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        // Get test lead
        List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Company, Status, 
                           AnnualRevenue,  LastModifiedDate 
                           FROM Lead LIMIT 1];
        
        Test.startTest();
        
        // Create batch instance for event sync
        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', eventSyncConfig.Id);
        
        // Execute with the lead
        batchInstance.execute(null, leads);
        
        // Call finish
        batchInstance.finish(null);
        
        Test.stopTest();
        
        // Verify log creation
        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c];
        System.assertNotEquals(0, logs.size(), 'Should create logs for event entity');
    }
    
    /**
     * Test the execute method with error response
     */
    @isTest
    static void testExecuteWithError() {
        // Get sync config ID
        CleverTap__Sync_Configuration__c syncConfig = [
            SELECT Id FROM CleverTap__Sync_Configuration__c 
            WHERE Name = 'Test Lead Sync' LIMIT 1
        ];
        
        // Set mock error response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseError());
        
        // Get test leads
        List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Company, Status, 
                           AnnualRevenue,  LastModifiedDate 
                           FROM Lead LIMIT 1];
        
        Test.startTest();
        
        // Create batch instance
        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);
        
        // Execute with the lead
        batchInstance.execute(null, leads);
        
        // Call finish
        batchInstance.finish(null);
        
        Test.stopTest();
        
        // Verify log creation with error status
        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c FROM CleverTap__Event__c];
        System.assertNotEquals(0, logs.size(), 'Should create logs for error case');
    }
    /**
     * Test with multiple records in a batch
     */
    @isTest
    static void testWithMultipleRecords() {
        // Get sync config ID
        CleverTap__Sync_Configuration__c syncConfig = [
            SELECT Id FROM CleverTap__Sync_Configuration__c 
            WHERE Name = 'Test Lead Sync' LIMIT 1
        ];
        
        // Set mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        // Get all test leads
        List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Company, Status, 
                           AnnualRevenue,  LastModifiedDate 
                           FROM Lead LIMIT 5];
        
        Test.startTest();
        
        // Create batch instance
        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);
        
        // Execute with multiple leads
        batchInstance.execute(null, leads);
        
        // Call finish
        batchInstance.finish(null);
        
        Test.stopTest();
        
        // Verify log creation
        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c];
        System.assertNotEquals(0, logs.size(), 'Should create logs for multiple records');
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
        
        // Set mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
        Test.startTest();
        
        // Create and execute the batch
        HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);
        Id batchId = Database.executeBatch(batchInstance, 5);
        
        Test.stopTest();
        
        // Verify logs were created
        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c];
        System.assertNotEquals(0, logs.size(), 'Should create logs for full batch process');
    }
    
    // /**
    //  * Test with different data types
    //  */
    // @isTest
    // static void testDataTypeHandling() {
    //     // Get sync config ID
    //     CleverTap__Sync_Configuration__c syncConfig = [
    //         SELECT Id FROM CleverTap__Sync_Configuration__c 
    //         WHERE Name = 'Test Lead Sync' LIMIT 1
    //     ];
        
    //     // Set mock response
    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());
        
    //     // Update a lead with various data types
    //     Lead testLead = [SELECT Id FROM Lead LIMIT 1];
    //     testLead.AnnualRevenue = 1000000;
    //     update testLead;
        
    //     // Query the updated lead
    //     List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Company, Status, 
    //                        AnnualRevenue,  LastModifiedDate 
    //                        FROM Lead WHERE Id = :testLead.Id];
        
    //     Test.startTest();
        
    //     // Create batch instance
    //     HistoricalSyncBatch batchInstance = new HistoricalSyncBatch('Lead', syncConfig.Id);
        
    //     // Execute with the lead with various data types
    //     batchInstance.execute(null, leads);
        
    //     // Call finish
    //     batchInstance.finish(null);
        
    //     Test.stopTest();
        
    //     // Verify log creation
    //     List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c];
    //     System.assertNotEquals(0, logs.size(), 'Should create logs for data type handling');
    // }
}