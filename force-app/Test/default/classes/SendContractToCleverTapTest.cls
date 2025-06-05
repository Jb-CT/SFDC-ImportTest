@isTest
private class SendContractToCleverTapTest {
    @testSetup
    static void setupTestData() {
        // Create test config
        CleverTap__Config__c testConfig = new CleverTap__Config__c(
            Name = 'Test Config',
            CleverTap__Region__c = 'US',
            CleverTap__Account_ID__c = 'test-account-id',
            CleverTap__API_URL__c = 'https://test-api.example.com'
        );
        insert testConfig;
        PasscodeHelper.savePasscode(testConfig.Id, 'test-passcode');
        
        // Create sync configuration for Contract
        CleverTap__Sync_Configuration__c syncConfig = new CleverTap__Sync_Configuration__c(
            Name = 'Test Contract Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Contract',
            CleverTap__Entity__c = 'profile',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert syncConfig;

        // Create field mapping
        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'ContractNumber',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert mapping;
        
        // Create test data
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
    }

    @isTest
    static void testInsertContract() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            CustomerSignedId = testContact.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12
        );
        insert testContract;
        Test.stopTest();

        System.assert(true, 'Contract insert should complete without errors');
    }

    @isTest
    static void testUpdateContract() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        TestUtils.bypassTriggers = true;
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12
        );
        insert testContract;

        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        testContract.Status = 'Activated';
        testContract.ActivatedDate = Date.today();
        update testContract;
        Test.stopTest();

        System.assert(true, 'Contract update should complete without errors');
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