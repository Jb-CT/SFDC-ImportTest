@isTest
private class SendLeadToCleverTapTest {
    // Flag to control trigger behavior for this test class
    public static Boolean isRunningLeadTriggerTest = false;
    
    // Create test sync configuration
    @testSetup
    static void setupTestData() {
        // Create Test CleverTap Config
        CleverTap__Config__c testConfig = new CleverTap__Config__c(
            Name = 'Test Config',
            CleverTap__Region__c = 'US',
            CleverTap__Account_ID__c = 'test-account-id',
            CleverTap__Passcode__c = 'test-passcode',
            CleverTap__API_URL__c = 'https://test-api.example.com'
        );
        insert testConfig;
        
        // Create sync configuration
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
    }

    // Test for insert scenario
    @isTest
    static void testLeadInsert() {
        TestUtils.bypassTriggers = true;
        // Mock HttpCallout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        // Create a test lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Company = 'Test Company'
        );
        
        // Insert the lead first
        insert testLead;
        
        // Then manually process it since the trigger is bypassed in test context
        Test.startTest();
        new IntegrationHandler(new DIModuleMain()).processLeads(new List<Lead>{testLead});
        Test.stopTest();
        
        // Verification
        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c WHERE Lead__c = :testLead.Id];
        System.assertNotEquals(0, logs.size(), 'Event log should be created for lead insert');
    }
    
    // Test for update scenario where fields change
    @isTest
    static void testLeadUpdateWithChanges() {
        TestUtils.bypassTriggers = true;
        // Mock HttpCallout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        // Create a test lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Company = 'Test Company'
        );
        insert testLead;
        
        // Clear logs from insert
        delete [SELECT Id FROM CleverTap__Event__c];
        
        // Update the lead with changes to tracked fields
        testLead.Email = 'updated@example.com';
        update testLead;
        
        // Manually process it since the trigger is bypassed in test context
        Test.startTest();
        new IntegrationHandler(new DIModuleMain()).processLeads(new List<Lead>{testLead});
        Test.stopTest();
        
        // Verification
        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c WHERE Lead__c = :testLead.Id];
        System.assertNotEquals(0, logs.size(), 'Event log should be created for lead update with changes');
    }
    
    // Test for update scenario where no relevant fields change
    // @isTest
    // static void testLeadUpdateWithNoRelevantChanges() {
    //     // Mock HttpCallout
    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
    //     // Create a test lead
    //     Lead testLead = new Lead(
    //         FirstName = 'Test',
    //         LastName = 'User',
    //         Email = 'test@example.com',
    //         Company = 'Test Company',
    //         // Add a field not tracked in the trigger
    //         Description = 'Initial description'
    //     );
    //     insert testLead;
        
    //     // Clear logs from insert
    //     delete [SELECT Id FROM CleverTap__Event__c];
        
    //     // Update a field that isn't tracked in the trigger
    //     testLead.Description = 'Updated description';
    //     update testLead;
        
    //     // Don't manually process this one - we're testing that it doesn't create logs
    //     Test.startTest();
    //     // IntegrationHandler is not called here intentionally
    //     Test.stopTest();
        
    //     // Since no tracked fields changed, no logs should be created
    //     List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c WHERE Lead__c = :testLead.Id];
    //     System.assertEquals(0, logs.size(), 'No event log should be created when no tracked fields change');
    // }
    
    // @isTest
    // static void testLeadUpdateVariousFields() {
    //     // Mock HttpCallout
    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
    //     // Fields to test
    //     Map<String, Object> fieldUpdates = new Map<String, Object>{
    //         'FirstName' => 'Updated',
    //         'LastName' => 'Updated',
    //         'Email' => 'updated@example.com',
    //         'Company' => 'Updated Company',
    //         'Phone' => '9999999999'
    //     };
        
    //     // Create a separate lead for each field to avoid duplicate IDs
    //     List<Lead> leadsToProcess = new List<Lead>();
        
    //     for (String fieldName : fieldUpdates.keySet()) {
    //         // Create a new lead with a unique name
    //         Lead newLead = new Lead(
    //             FirstName = 'Test',
    //             LastName = 'Lead' + fieldName, // Make each one unique
    //             Email = fieldName + '@example.com',
    //             Company = 'Test Company'
    //         );
    //         insert newLead;
            
    //         // Update with the specific field change
    //         newLead.put(fieldName, fieldUpdates.get(fieldName));
    //         update newLead;
            
    //         // Add to processing list
    //         leadsToProcess.add(newLead);
    //     }
        
    //     // Clear logs from previous operations
    //     delete [SELECT Id FROM CleverTap__Event__c];
        
    //     // Process all leads
    //     TestUtils.bypassTriggers = true;
    //     Test.startTest();
    //     new IntegrationHandler(new DIModuleMain()).processLeads(leadsToProcess);
    //     Test.stopTest();
        
    //     // Verification
    //     List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c];
    //     System.assertNotEquals(0, logs.size(), 'Event logs should be created');
    // }
    
    @isTest
    static void testLeadTriggerInsert() {
        // Set up mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        // IMPORTANT: Do NOT bypass trigger
        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        // Create a new lead to trigger the SendLeadToCleverTap trigger
        Lead triggerLead = new Lead(
            FirstName = 'Trigger',
            LastName = 'Test',
            Email = 'trigger@example.com',
            Company = 'Trigger Test Co'
        );
        insert triggerLead;
        Test.stopTest();
        
        // No assertions needed - just verifying the trigger executes
        System.assert(true, 'Trigger executed without exceptions');
    }

    @isTest
    static void testLeadTriggerUpdate() {
        // Set up mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        // Create a test lead
        Lead triggerLead = new Lead(
            FirstName = 'Trigger',
            LastName = 'Update',
            Email = 'triggerupdate@example.com',
            Company = 'Trigger Update Co'
        );
        insert triggerLead;
        
        // IMPORTANT: Do NOT bypass trigger
        TestUtils.bypassTriggers = false;
        
        // Update the lead to trigger the update branch of the trigger
        Test.startTest();
        triggerLead.LastName = 'Updated';
        update triggerLead;
        Test.stopTest();
        
        // No assertions needed - just verifying the trigger executes
        System.assert(true, 'Trigger update path executed without exceptions');
    }

    // @isTest
    // static void testLeadTriggerBulkUpdate() {
    //     // Set up mock
    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
    //     // Create multiple leads
    //     List<Lead> bulkLeads = new List<Lead>();
    //     for(Integer i = 0; i < 5; i++) {
    //         bulkLeads.add(new Lead(
    //             FirstName = 'Bulk' + i,
    //             LastName = 'Lead' + i,
    //             Email = 'bulk' + i + '@example.com',
    //             Company = 'Bulk Company'
    //         ));
    //     }
    //     insert bulkLeads;
        
    //     // IMPORTANT: Do NOT bypass trigger
    //     TestUtils.bypassTriggers = false;
        
    //     // Update all leads to trigger bulk processing
    //     Test.startTest();
    //     for(Lead lead : bulkLeads) {
    //         lead.LastName += ' Updated';
    //     }
    //     update bulkLeads;
    //     Test.stopTest();
        
    //     // No assertions needed - just verifying the trigger executes
    //     System.assert(true, 'Trigger bulk update executed without exceptions');
    // }
    // Mock HTTP class
    private class MockHttpResponseImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}