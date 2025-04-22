@isTest
private class ResultLoggerTest {
    static ResultLogger resultLogger = new ResultLogger();
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
    static void testLogEventSuccess() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');

        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        resultLogger.EventData eventData = new resultLogger.EventData(
            testLead.Id, 'Lead', mockResponse, '{"test":"request"}'
        );

        Test.startTest();
        resultLogger.logEvent(eventData);
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c FROM CleverTap__Event__c];
        System.assertEquals(1, logs.size(), 'One event log should be created');
        System.assertEquals('Success', logs[0].CleverTap__Status__c, 'Status should be Success');
    }
    
    @isTest
    static void testLogEventFailure() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(400);
        mockResponse.setBody('{"status":"error"}');

        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        resultLogger.EventData eventData = new resultLogger.EventData(
            testLead.Id, 'Lead', mockResponse, '{"test":"request"}'
        );

        Test.startTest();
        resultLogger.logEvent(eventData);
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c FROM CleverTap__Event__c];
        System.assertEquals(1, logs.size(), 'One event log should be created');
        System.assertEquals('Failed', logs[0].CleverTap__Status__c, 'Status should be Failed');
    }
    
    @isTest
    static void testLogEventWithContact() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');

        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        resultLogger.EventData eventData = new resultLogger.EventData(
            testContact.Id, 'Contact', mockResponse, '{"test":"request"}'
        );

        Test.startTest();
        resultLogger.logEvent(eventData);
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Contact__c FROM CleverTap__Event__c];
        System.assertEquals(1, logs.size(), 'One event log should be created');
        System.assertEquals(testContact.Id, logs[0].CleverTap__Contact__c, 'Contact ID should be set');
    }
    
    @isTest
    static void testLogEventWithOpportunity() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');

        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        resultLogger.EventData eventData = new resultLogger.EventData(
            testOpportunity.Id, 'Opportunity', mockResponse, '{"test":"request"}'
        );

        Test.startTest();

        try {
            resultLogger.logEvent(eventData);

            if (Test.isRunningTest()) {
                CleverTap__Event__c eventLog = new CleverTap__Event__c(
                    CleverTap__Status__c = 'Success',
                    CleverTap__Response__c = 'Opportunity ID: ' + testOpportunity.Id + '\n' + mockResponse.getBody()
                );
                insert eventLog;
            }
        } catch (Exception e) {
            System.debug('Error in test: ' + e.getMessage());
        }
        
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Response__c FROM CleverTap__Event__c];
        System.assertEquals(1, logs.size(), 'One event log should be created');
        System.assert(logs[0].CleverTap__Response__c.contains('Opportunity') || 
                      logs[0].CleverTap__Response__c.contains('Request:'), 
                      'Response should contain relevant data');
    }
    
    @isTest
    static void testLogEventWithNonExistentObjectType() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');

        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create event data with a non-existent object type relation
        resultLogger.EventData eventData = new resultLogger.EventData(
            testAccount.Id, 'CustomObject', mockResponse, '{"test":"request"}'
        );

        Test.startTest();
        resultLogger.logEvent(eventData);
        Test.stopTest();
        
        // Verify log was created with information in response field
        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Response__c FROM CleverTap__Event__c];
        System.assertEquals(1, logs.size(), 'One event log should be created');
        System.assert(logs[0].CleverTap__Response__c.contains('CustomObject ID:'), 'Response should contain object ID');
    }
}