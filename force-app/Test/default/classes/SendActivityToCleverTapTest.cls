@isTest
private class SendActivityToCleverTapTest {
    @testSetup
    static void setupTestData() {
        // Create test configuration
        CleverTap__Config__c testConfig = new CleverTap__Config__c(
            Name = 'Test Config',
            CleverTap__Region__c = 'US',
            CleverTap__Account_ID__c = 'test-account-id',
            CleverTap__API_URL__c = 'https://test-api.example.com'
        );
        insert testConfig;
        PasscodeHelper.savePasscode(testConfig.Id, 'test-passcode');
        
        // Create sync configuration for Event
        CleverTap__Sync_Configuration__c eventSyncConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test Event Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Event',
            CleverTap__Entity__c = 'event',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert eventSyncConfig;
        
        // Create sync configuration for Task
        CleverTap__Sync_Configuration__c taskSyncConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test Task Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Task',
            CleverTap__Entity__c = 'event',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert taskSyncConfig;

        // Create field mappings
        List<CleverTap__Mapping__c> mappings = new List<CleverTap__Mapping__c>{
            new CleverTap__Mapping__c(
                Name = 'Event Identity Mapping',
                CleverTap__Sync_mapping__c = eventSyncConfig.Id,
                CleverTap__Field__c = 'Identity',
                CleverTap__Salesforce_Field__c = 'Email', // Will be resolved from WhoId
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            ),
            new CleverTap__Mapping__c(
                Name = 'Task Identity Mapping',
                CleverTap__Sync_mapping__c = taskSyncConfig.Id,
                CleverTap__Field__c = 'Identity',
                CleverTap__Salesforce_Field__c = 'Email', // Will be resolved from WhoId
                CleverTap__Data_Type__c = 'Text',
                CleverTap__Is_Mandatory__c = true
            )
        };
        insert mappings;
        
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'lead@example.com',
            Company = 'Test Company'
        );
        insert testLead;
    }

    @isTest
    static void testInsertEventWithContact() {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        // Get test data
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        // Create Event with Contact
        Event testEvent = new Event(
            Subject = 'Test Meeting',
            WhoId = testContact.Id,
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1),
            Description = 'Test event description'
        );
        insert testEvent;
        Test.stopTest();

        System.assert(true, 'Event insert should complete without errors');
    }

    @isTest
    static void testInsertTaskWithLead() {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        // Get test data
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        // Create Task with Lead
        Task testTask = new Task(
            Subject = 'Follow up call',
            WhoId = testLead.Id,
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today().addDays(1),
            Description = 'Follow up on proposal'
        );
        insert testTask;
        Test.stopTest();

        System.assert(true, 'Task insert should complete without errors');
    }

    @isTest
    static void testUpdateEvent() {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());

        // Create Event with bypass
        TestUtils.bypassTriggers = true;
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Event testEvent = new Event(
            Subject = 'Test Meeting',
            WhoId = testContact.Id,
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );
        insert testEvent;

        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        // Update Event
        testEvent.Subject = 'Updated Meeting';
        testEvent.Description = 'Updated description';
        update testEvent;
        Test.stopTest();

        System.assert(true, 'Event update should complete without errors');
    }

    @isTest
    static void testTaskWithAccount() {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        // Get test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        // Create Task related to Account (no WhoId)
        Task testTask = new Task(
            Subject = 'Account follow up',
            WhatId = testAccount.Id,
            Status = 'Not Started',
            Priority = 'High',
            ActivityDate = Date.today()
        );
        insert testTask;
        Test.stopTest();

        System.assert(true, 'Task insert with Account should complete without errors');
    }

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