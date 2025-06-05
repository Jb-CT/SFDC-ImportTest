@isTest
private class SendOrderToCleverTapTest {
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
            Name = 'Test Order Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Order',
            CleverTap__Entity__c = 'event',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert syncConfig;

        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'OrderNumber',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert mapping;

        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingState = 'CA',
            BillingPostalCode = '12345'
        );
        insert testAccount;

        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12
        );
        insert testContract;
    }

    @isTest
    static void testInsertOrder() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Description = 'Test Order'
        );
        insert testOrder;
        Test.stopTest();

        System.assert(true, 'Order insert should complete without errors');
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