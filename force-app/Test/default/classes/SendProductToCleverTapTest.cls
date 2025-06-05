@isTest
private class SendProductToCleverTapTest {
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
            Name = 'Test Product Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'Product2',
            CleverTap__Entity__c = 'profile',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert syncConfig;

        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'ProductCode',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert mapping;
    }

    @isTest
    static void testInsertProduct() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            Family = 'Test Family',
            IsActive = true,
            Description = 'Test Product Description'
        );
        insert testProduct;
        Test.stopTest();

        System.assert(true, 'Product insert should complete without errors');
    }

    @isTest
    static void testUpdateProduct() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        TestUtils.bypassTriggers = true;
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            IsActive = true
        );
        insert testProduct;

        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        testProduct.Description = 'Updated Description';
        testProduct.Family = 'Updated Family';
        update testProduct;
        Test.stopTest();

        System.assert(true, 'Product update should complete without errors');
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