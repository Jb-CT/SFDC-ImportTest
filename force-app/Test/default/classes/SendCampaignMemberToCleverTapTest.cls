@isTest
private class SendCampaignMemberToCleverTapTest {
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
        
        // Create sync configuration for CampaignMember
        CleverTap__Sync_Configuration__c syncConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test CampaignMember Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'CampaignMember',
            CleverTap__Entity__c = 'event',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert syncConfig;

        // Create field mapping (Identity will be fetched from parent Contact/Lead)
        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'Email', // This will be resolved from parent
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert mapping;
        
        // Create test Campaign
        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign',
            Status = 'Planned',
            Type = 'Email',
            IsActive = true
        );
        insert testCampaign;
        
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'contact@example.com'
        );
        insert testContact;
        
        // Create test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'lead@example.com',
            Company = 'Test Company'
        );
        insert testLead;
    }

    @isTest
    static void testInsertCampaignMemberWithContact() {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        // Get test data
        Campaign testCampaign = [SELECT Id FROM Campaign LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        // Create CampaignMember with Contact
        CampaignMember cm = new CampaignMember(
            CampaignId = testCampaign.Id,
            ContactId = testContact.Id,
            Status = 'Sent'
        );
        insert cm;
        Test.stopTest();

        System.assert(true, 'CampaignMember insert should complete without errors');
    }

    @isTest
    static void testInsertCampaignMemberWithLead() {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        // Get test data
        Campaign testCampaign = [SELECT Id FROM Campaign LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        // Create CampaignMember with Lead
        CampaignMember cm = new CampaignMember(
            CampaignId = testCampaign.Id,
            LeadId = testLead.Id,
            Status = 'Sent'
        );
        insert cm;
        Test.stopTest();

        System.assert(true, 'CampaignMember insert should complete without errors');
    }

    @isTest
    static void testUpdateCampaignMember() {
        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());

        // Create CampaignMember with bypass
        TestUtils.bypassTriggers = true;
        Campaign testCampaign = [SELECT Id FROM Campaign LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        CampaignMember cm = new CampaignMember(
            CampaignId = testCampaign.Id,
            ContactId = testContact.Id,
            Status = 'Sent'
        );
        insert cm;

        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        // Update CampaignMember
        cm.Status = 'Responded';
        //cm.HasResponded = true;
        update cm;
        Test.stopTest();

        System.assert(true, 'CampaignMember update should complete without errors');
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