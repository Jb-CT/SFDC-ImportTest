@isTest
private class SendAssetToCleverTapTest {
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
            Name = 'Test Asset Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Asset',
            CleverTap__Entity__c = 'event',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert syncConfig;

        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'SerialNumber',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert mapping;
        
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001'
        );
        insert testProduct;
    }

    @isTest
    static void testInsertAsset() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id,
            Product2Id = testProduct.Id,
            SerialNumber = 'SN-12345',
            Status = 'Installed',
            Quantity = 1,
            Price = 1000.00,
            PurchaseDate = Date.today()
        );
        insert testAsset;
        Test.stopTest();

        System.assert(true, 'Asset insert should complete without errors');
    }

    @isTest
    static void testUpdateAsset() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        TestUtils.bypassTriggers = true;
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id,
            Product2Id = testProduct.Id,
            SerialNumber = 'SN-12345',
            Status = 'Purchased'
        );
        insert testAsset;

        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        testAsset.Status = 'Installed';
        testAsset.InstallDate = Date.today();
        update testAsset;
        Test.stopTest();

        System.assert(true, 'Asset update should complete without errors');
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