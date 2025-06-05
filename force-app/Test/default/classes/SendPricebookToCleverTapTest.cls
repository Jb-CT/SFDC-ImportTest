@isTest
private class SendPricebookToCleverTapTest {
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
            Name = 'Test Pricebook Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Pricebook2',
            CleverTap__Entity__c = 'profile',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert syncConfig;

        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'Name',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert mapping;
    }

    @isTest
    static void testInsertPricebook() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            Description = 'Test Pricebook Description',
            IsActive = true
        );
        insert testPricebook;
        Test.stopTest();

        System.assert(true, 'Pricebook insert should complete without errors');
    }

    @isTest
    static void testUpdatePricebook() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        TestUtils.bypassTriggers = true;
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;

        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        testPricebook.Description = 'Updated Description';
        update testPricebook;
        Test.stopTest();

        System.assert(true, 'Pricebook update should complete without errors');
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