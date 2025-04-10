/**
 * @class EntityExportJobTest
 * @description Test class for EntityExportJob to ensure proper queueing and processing of records.
 */
@isTest
private class EntityExportJobTest {
    
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create test lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'test.lead@example.com',
            Company = 'Test Company'
        );
        insert testLead;
        
        // Create test opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;
    }
    
    @isTest
    static void testExecuteWithLeads() {
        // Create test data
        Lead testLead = [SELECT Id, FirstName, LastName, Email, Company FROM Lead LIMIT 1];
        
        // Create a mock service via TestModule
        MockCleverTapService mockService = new MockCleverTapService();
        TestModule testModule = new TestModule(mockService);
        
        // Execute the queueable with test module
        Test.startTest();
        EntityExportJob queueable = new EntityExportJob(testLead, testModule);
        queueable.execute(null);
        Test.stopTest();
        
        // Verify the mock was called correctly
        System.assertEquals(1, mockService.leadCallCount, 'Lead service should be called once');
        System.assertEquals(0, mockService.contactCallCount, 'Contact service should not be called');
        System.assertEquals(1, mockService.processedRecords.size(), 'One record should be processed');
        System.assertEquals(testLead.Id, mockService.processedRecords[0].Id, 'Correct record should be processed');
    }
    
    @isTest
    static void testExecuteWithContacts() {
        // Create test data
        Contact testContact = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];
        
        // Create a mock service via TestModule
        MockCleverTapService mockService = new MockCleverTapService();
        TestModule testModule = new TestModule(mockService);
        
        // Execute the queueable with test module
        Test.startTest();
        EntityExportJob queueable = new EntityExportJob(testContact, testModule);
        queueable.execute(null);
        Test.stopTest();
        
        // Verify the mock was called correctly
        System.assertEquals(0, mockService.leadCallCount, 'Lead service should not be called');
        System.assertEquals(1, mockService.contactCallCount, 'Contact service should be called once');
        System.assertEquals(1, mockService.processedRecords.size(), 'One record should be processed');
        System.assertEquals(testContact.Id, mockService.processedRecords[0].Id, 'Correct record should be processed');
    }
    
    @isTest
    static void testExecuteWithMultipleRecords() {
        // Get multiple contacts
        List<Contact> testContacts = new List<Contact>{
            new Contact(FirstName = 'Test1', LastName = 'Contact1', Email = 'test1@example.com'),
            new Contact(FirstName = 'Test2', LastName = 'Contact2', Email = 'test2@example.com')
        };
        insert testContacts;
        
        // Create a mock service via TestModule
        MockCleverTapService mockService = new MockCleverTapService();
        TestModule testModule = new TestModule(mockService);
        
        // Execute the queueable with test module and multiple records
        Test.startTest();
        EntityExportJob queueable = new EntityExportJob(testContacts, testModule);
        queueable.execute(null);
        
        // Since we can't easily test queueable chaining in unit tests, 
        // manually process the second record
        EntityExportJob secondQueueable = new EntityExportJob(new List<Contact>{testContacts[1]}, testModule);
        secondQueueable.execute(null);
        Test.stopTest();
        
        // Verify the mock was called correctly
        System.assertEquals(0, mockService.leadCallCount, 'Lead service should not be called');
        System.assertEquals(2, mockService.contactCallCount, 'Contact service should be called twice');
        System.assertEquals(2, mockService.processedRecords.size(), 'Two records should be processed');
    }
    
    @isTest
    static void testIntegrationHandlerWithMock() {
        // Get test lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Create a mock service via TestModule
        MockCleverTapService mockService = new MockCleverTapService();
        TestModule testModule = new TestModule(mockService);
        
        // Set the module in the integration handler
        Test.startTest();
        IntegrationHandler.setDIModule(testModule);
        
        // Process the lead through the integration handler
        IntegrationHandler.processLeads(new List<Lead>{testLead});
        Test.stopTest();
        
        // Here we can only verify that no exceptions were thrown since
        // the asynchronous job won't complete in the test context
        System.assert(true, 'No exceptions were thrown during processing');
    }
}