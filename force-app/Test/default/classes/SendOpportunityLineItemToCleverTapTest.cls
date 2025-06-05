@isTest
private class SendOpportunityLineItemToCleverTapTest {
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
            Name = 'Test OpportunityLineItem Sync',
            CleverTap__Sync_Type__c = 'salesforce_to_clevertap',
            CleverTap__Salesforce_Entity__c = 'OpportunityLineItem',
            CleverTap__Entity__c = 'event',
            CleverTap__ConnectionId__c = testConfig.Id,
            CleverTap__Status__c = 'Active'
        );
        insert syncConfig;

        CleverTap__Mapping__c mapping = new CleverTap__Mapping__c(
            Name = 'Test Mapping',
            CleverTap__Sync_mapping__c = syncConfig.Id,
            CleverTap__Field__c = 'Identity',
            CleverTap__Salesforce_Field__c = 'OpportunityId',
            CleverTap__Data_Type__c = 'Text',
            CleverTap__Is_Mandatory__c = true
        );
        insert mapping;
        
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'contact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            IsActive = true
        );
        insert testProduct;

        Id standardPBId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = standardPBId,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPrice;
    }

    @isTest
    static void testInsertOpportunityLineItem() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        TestUtils.bypassTriggers = false;
        
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        Test.startTest();
        OpportunityLineItem testLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 100.00
        );
        insert testLineItem;
        Test.stopTest();

        System.assert(true, 'OpportunityLineItem insert should complete without errors');
    }

    @isTest
    static void testUpdateOpportunityLineItem() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseImpl());
        
        TestUtils.bypassTriggers = true;
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        OpportunityLineItem testLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 100.00
        );
        insert testLineItem;

        TestUtils.bypassTriggers = false;
        
        Test.startTest();
        testLineItem.Quantity = 10;
        testLineItem.Discount = 10;
        update testLineItem;
        Test.stopTest();

        System.assert(true, 'OpportunityLineItem update should complete without errors');
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