/**
 * @class EntityExportJobTest
 * @description Test class for EntityExportJob to ensure proper queueing and processing of records.
 */
@isTest
private class EntityExportJobTest {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Email = 'test.lead@example.com',
            Company = 'Test Company'
        );
        insert testLead;

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
        Lead testLead = [SELECT Id, FirstName, LastName, Email, Company FROM Lead LIMIT 1];

        MockCleverTapService mockService = new MockCleverTapService();
        TestModule testModule = new TestModule(mockService);

        Test.startTest();
        EntityExportJob queueable = new EntityExportJob(testLead, testModule);
        queueable.execute(null);
        Test.stopTest();

        System.assertEquals(1, mockService.leadCallCount, 'Lead service should be called once');
        System.assertEquals(0, mockService.contactCallCount, 'Contact service should not be called');
        System.assertEquals(1, mockService.processedRecords.size(), 'One record should be processed');
        System.assertEquals(testLead.Id, mockService.processedRecords[0].Id, 'Correct record should be processed');
    }
    
    @isTest
    static void testExecuteWithContacts() {
        Contact testContact = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];
        
        MockCleverTapService mockService = new MockCleverTapService();
        TestModule testModule = new TestModule(mockService);

        Test.startTest();
        EntityExportJob queueable = new EntityExportJob(testContact, testModule);
        queueable.execute(null);
        Test.stopTest();

        System.assertEquals(0, mockService.leadCallCount, 'Lead service should not be called');
        System.assertEquals(1, mockService.contactCallCount, 'Contact service should be called once');
        System.assertEquals(1, mockService.processedRecords.size(), 'One record should be processed');
        System.assertEquals(testContact.Id, mockService.processedRecords[0].Id, 'Correct record should be processed');
    }
    
    @isTest
    static void testExecuteWithMultipleRecords() {
        List<Contact> testContacts = new List<Contact>{
            new Contact(FirstName = 'Test1', LastName = 'Contact1', Email = 'test1@example.com'),
            new Contact(FirstName = 'Test2', LastName = 'Contact2', Email = 'test2@example.com')
        };
        insert testContacts;

        MockCleverTapService mockService = new MockCleverTapService();
        TestModule testModule = new TestModule(mockService);

        EntityExportJob.disableChaining = true;
        
        Test.startTest();
        EntityExportJob firstQueueable = new EntityExportJob(testContacts[0], testModule);
        firstQueueable.execute(null);

        EntityExportJob secondQueueable = new EntityExportJob(testContacts[1], testModule);
        secondQueueable.execute(null);
        Test.stopTest();

        EntityExportJob.disableChaining = false;

        System.assertEquals(0, mockService.leadCallCount, 'Lead service should not be called');
        System.assertEquals(2, mockService.contactCallCount, 'Contact service should be called twice');
        System.assertEquals(2, mockService.processedRecords.size(), 'Two records should be processed');
    }
    
    @isTest
    static void testIntegrationHandlerWithMock() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        MockCleverTapService mockService = new MockCleverTapService();
        TestModule testModule = new TestModule(mockService);

        Test.startTest();
        IntegrationHandler ihandler = new IntegrationHandler(new DIModuleMain());

        ihandler.processLeads(new List<Lead>{testLead});
        Test.stopTest();

        System.assert(true, 'No exceptions were thrown during processing');
    }
}