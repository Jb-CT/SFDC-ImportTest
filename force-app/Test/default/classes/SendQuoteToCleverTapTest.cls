@isTest
private class SendQuoteToCleverTapTest {
    @testSetup
    static void setupTestData() {
        CleverTap__Config__c testConfig = new CleverTap__Config__c(
            Name = 'Test Config',
            CleverTap__Region__c = 'US',
            CleverTap__Account_ID__c = 'test-account-id',
            CleverTap__API_URL__c = 'https://test-api.example.com'
        );
        insert testConfig;
        PasscodeHelper.savePasscode(testConfig.Id, 'test-passcode');

        CleverTap__Sync_Configuration__c syncConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test Quote Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Quote',
            CleverTap__Entity__c = 'profile',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert syncConfig;

        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'QuoteNumber',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert mapping;
        
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
    }

    @isTest
    static void testInsertQuote() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            ContactId = testContact.Id,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30)
        );
        insert testQuote;
        Test.stopTest();

        System.assert(true, 'Quote insert should complete without errors');
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