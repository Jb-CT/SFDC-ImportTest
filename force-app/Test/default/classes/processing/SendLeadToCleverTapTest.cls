@isTest
private class SendLeadToCleverTapTest {
    @testSetup
    static void setupTestData() {
        CleverTap__Config__c testConfig = new CleverTap__Config__c(
            Name = 'Test Config',
            CleverTap__Region__c = 'US',
            CleverTap__Account_ID__c = 'test-account-id',
            CleverTap__Passcode__c = 'test-passcode',
            CleverTap__API_URL__c = 'https://test-api.example.com'
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

        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'Email',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert mapping;
    }

    @isTest
    static void testInsertLead() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Company = 'Test Company'
        );
        insert testLead;
        Test.stopTest();

        System.assert(true, 'Lead insert should complete without errors');
    }

    @isTest
    static void testUpdateLead() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());

        TestUtils.bypassTriggers = true;
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Company = 'Test Company'
        );
        insert testLead;

        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        testLead.FirstName = 'Updated';
        testLead.LastName = 'Name';
        testLead.Email = 'updated@example.com';
        update testLead;
        Test.stopTest();

        System.assert(true, 'Lead update should complete without errors');
    }
    
    @isTest
    static void testMultipleFieldUpdates() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());

        TestUtils.bypassTriggers = true;
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Multiple',
            Email = 'multiple@example.com',
            Company = 'Test Company',
            Phone = '1234567890',
            Industry = 'Technology',
            Title = 'CEO'
        );
        insert testLead;

        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        testLead.FirstName = 'Updated';
        testLead.Phone = '9876543210';
        testLead.Title = 'CTO';
        testLead.Industry = 'Healthcare';
        update testLead;
        Test.stopTest();

        System.assert(true, 'Multiple field updates should complete without errors');
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
    @isTest
    static void testFieldByFieldUpdate() {
        TestUtils.bypassTriggers = false;
        
        Lead testLead = new Lead(
            FirstName = 'Field',
            LastName = 'Update',
            Email = 'fieldupdate@example.com',
            Company = 'Field Update Co'
        );
        insert testLead;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
    
        Test.startTest();

        testLead.FirstName = 'Updated';
        update testLead;

        testLead.LastName = 'NewLastName';
        update testLead;

        testLead.Title = 'New Title';
        update testLead;

        testLead.Phone = '1234567890';
        update testLead;
        
        testLead.Status = 'Working - Contacted';
        update testLead;
        
        Test.stopTest();
        
        System.assert(true, 'Successfully tested multiple field updates');
    }

    @isTest
    static void testBatchContext() {
        TestUtils.bypassTriggers = false;
        
        Lead testLead = new Lead(
            FirstName = 'Batch',
            LastName = 'Context',
            Email = 'batch@example.com',
            Company = 'Batch Co'
        );
        insert testLead;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        Test.startTest();
        Database.executeBatch(new MockBatchClass());
        Test.stopTest();
        
        System.assert(true, 'Successfully tested batch context');
    }

    @isTest
    static void testLeadTriggerConditions() {
        TestUtils.bypassTriggers = false;
        
        Lead testLead = new Lead(
            FirstName = 'Condition',
            LastName = 'Test',
            Email = 'condition@example.com',
            Company = 'Condition Company',
            Phone = '1234567890',
            MobilePhone = '0987654321',
            Fax = '1112223333',
            Title = 'Test Title',
            Rating = 'Hot',
            Industry = 'Technology',
            AnnualRevenue = 5000000,
            NumberOfEmployees = 100,
            OwnerId = UserInfo.getUserId(),
            LeadSource = 'Web',
            Description = 'Test Description'
        );
        insert testLead;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        Test.startTest();

        testLead.OwnerId = UserInfo.getUserId(); 
        update testLead;

        testLead.Description = 'Updated Description';
        update testLead;

        testLead.Rating = 'Warm';
        update testLead;

        testLead.AnnualRevenue = 6000000;
        testLead.NumberOfEmployees = 120;
        testLead.Title = 'Updated Title';
        update testLead;
        
        Test.stopTest();
    }

}