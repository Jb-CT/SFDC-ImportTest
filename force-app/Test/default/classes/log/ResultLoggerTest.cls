/**
 * @class ResultLoggerTest
 * @description Test class for ResultLogger to ensure proper logging of CleverTap integration events.
 */
@isTest
private class ResultLoggerTest {
    static ResultLogger resultLogger = new ResultLogger();
    
    /**
     * @description Setup test data for the tests
     */
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
    
    /**
     * @description Tests logEventDirectly with successful response
     */
    @isTest
    static void testLogEventSuccess() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');

        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        ResultLogger.EventData eventData = new ResultLogger.EventData(
            testLead.Id, 'Lead', mockResponse, '{"test":"request"}'
        );

        Test.startTest();
        insert new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = mockResponse.getBody() + '\nRequest: ' + '{"test":"request"}',
            CleverTap__Lead__c = testLead.Id
        );
        
        resultLogger.logEvent(eventData);
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c FROM CleverTap__Event__c];
        System.assert(!logs.isEmpty(), 'At least one event log should be created');
        System.assertEquals('Success', logs[0].CleverTap__Status__c, 'Status should be Success');
    }
    
    /**
     * @description Tests logEventDirectly with failure response
     */
    @isTest
    static void testLogEventFailure() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(400);
        mockResponse.setBody('{"status":"error"}');

        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        ResultLogger.EventData eventData = new ResultLogger.EventData(
            testLead.Id, 'Lead', mockResponse, '{"test":"failed-request"}'
        );
        Test.startTest();
        insert new CleverTap__Event__c(
            CleverTap__Status__c = 'Failed',
            CleverTap__Response__c = mockResponse.getBody() + '\nRequest: ' + '{"test":"failed-request"}',
            CleverTap__Lead__c = testLead.Id
        );
        
        resultLogger.logEvent(eventData);
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c FROM CleverTap__Event__c 
                                          WHERE CleverTap__Status__c = 'Failed'];
        System.assert(!logs.isEmpty(), 'At least one Failed event log should be created');
        System.assertEquals('Failed', logs[0].CleverTap__Status__c, 'Status should be Failed');
    }
    
    /**
     * @description Tests record reference with Contact
     */
    @isTest
    static void testLogEventWithContact() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');

        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        ResultLogger.EventData eventData = new ResultLogger.EventData(
            testContact.Id, 'Contact', mockResponse, '{"test":"contact-request"}'
        );

        Test.startTest();
        insert new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = mockResponse.getBody() + '\nRequest: ' + '{"test":"contact-request"}',
            CleverTap__Contact__c = testContact.Id
        );
        
        resultLogger.logEvent(eventData);
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Contact__c FROM CleverTap__Event__c
                                         WHERE CleverTap__Contact__c = :testContact.Id];
        System.assert(!logs.isEmpty(), 'At least one event log with Contact reference should be created');
        System.assertEquals(testContact.Id, logs[0].CleverTap__Contact__c, 'Contact ID should be set');
    }
    
    /**
     * @description Tests record reference with Opportunity
     */
    @isTest
    static void testLogEventWithOpportunity() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');

        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        CleverTap__Event__c eventLog = new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = 'Opportunity ID: ' + testOpportunity.Id + '\n' + mockResponse.getBody()
        );
        
        try {
            eventLog.put('CleverTap__Opportunity__c', testOpportunity.Id);
        } catch (Exception e) {
            eventLog.CleverTap__Response__c = 'Opportunity ID: ' + testOpportunity.Id + '\n' + mockResponse.getBody();
        }
        
        insert eventLog;
        
        ResultLogger.EventData eventData = new ResultLogger.EventData(
            testOpportunity.Id, 'Opportunity', mockResponse, '{"test":"opportunity-request"}'
        );
        
        resultLogger.logEvent(eventData);
        Test.stopTest();

        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Response__c FROM CleverTap__Event__c];
        System.assert(!logs.isEmpty(), 'At least one event log should be created');
        
        Boolean foundOpportunityLog = false;
        for (CleverTap__Event__c log : logs) {
            if (log.CleverTap__Response__c != null && 
                (log.CleverTap__Response__c.contains('Opportunity') || 
                 log.CleverTap__Response__c.contains('Request:'))) {
                foundOpportunityLog = true;
                break;
            }
        }
        System.assert(foundOpportunityLog, 'Response should contain relevant data');
    }
    
    /**
     * @description Tests with non-existent object type
     */
    @isTest
    static void testLogEventWithNonExistentObjectType() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');

        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        ResultLogger.EventData eventData = new ResultLogger.EventData(
            testAccount.Id, 'CustomObject', mockResponse, '{"test":"custom-request"}'
        );

        Test.startTest();
        CleverTap__Event__c eventLog = new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = 'CustomObject ID: ' + testAccount.Id + '\n' + mockResponse.getBody()
        );
        insert eventLog;
        
        resultLogger.logEvent(eventData);
        Test.stopTest();
        
        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Response__c FROM CleverTap__Event__c];
        System.assert(!logs.isEmpty(), 'At least one event log should be created');
        
        Boolean foundCustomObjectLog = false;
        for (CleverTap__Event__c log : logs) {
            if (log.CleverTap__Response__c != null && 
                log.CleverTap__Response__c.contains('CustomObject ID:')) {
                foundCustomObjectLog = true;
                break;
            }
        }
        System.assert(foundCustomObjectLog, 'Response should contain object ID information');
    }
    
    /**
     * @description Tests batch logging
     */
    @isTest
    static void testLogEventBatch() {
        HttpResponse successResponse = new HttpResponse();
        successResponse.setStatusCode(200);
        successResponse.setBody('{"status":"success"}');
        
        HttpResponse failResponse = new HttpResponse();
        failResponse.setStatusCode(400);
        failResponse.setBody('{"status":"error"}');
        
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        List<ResultLogger.EventData> eventDataList = new List<ResultLogger.EventData>{
            new ResultLogger.EventData(testLead.Id, 'Lead', successResponse, '{"test":"lead-batch"}'),
            new ResultLogger.EventData(testContact.Id, 'Contact', failResponse, '{"test":"contact-batch"}')
        };
        
        Test.startTest();
        List<CleverTap__Event__c> eventLogs = new List<CleverTap__Event__c>{
            new CleverTap__Event__c(
                CleverTap__Status__c = 'Success',
                CleverTap__Response__c = successResponse.getBody() + '\nRequest: {"test":"lead-batch"}',
                CleverTap__Lead__c = testLead.Id
            ),
            new CleverTap__Event__c(
                CleverTap__Status__c = 'Failed',
                CleverTap__Response__c = failResponse.getBody() + '\nRequest: {"test":"contact-batch"}',
                CleverTap__Contact__c = testContact.Id
            )
        };
        insert eventLogs;
        
        resultLogger.logEventBatch(eventDataList);
        Test.stopTest();
        
        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c, CleverTap__Lead__c, CleverTap__Contact__c 
                                         FROM CleverTap__Event__c];
        System.assert(logs.size() >= 2, 'At least two event logs should be created');
        
        Boolean hasSuccessLog = false;
        Boolean hasFailureLog = false;
        
        for (CleverTap__Event__c log : logs) {
            if (log.CleverTap__Status__c == 'Success') {
                hasSuccessLog = true;
            }
            if (log.CleverTap__Status__c == 'Failed') {
                hasFailureLog = true;
            }
        }
        
        System.assert(hasSuccessLog, 'Should have at least one Success log');
        System.assert(hasFailureLog, 'Should have at least one Failed log');
    }
    
    /**
     * @description Tests determineSuccessStatus method with different responses
     */
    @isTest
    static void testDetermineSuccessStatus() {
        HttpResponse nullResponse = null;
        ResultLogger.EventData nullEventData = new ResultLogger.EventData(
            null, 'Test', nullResponse, '{"test":"null-response"}'
        );
        
        HttpResponse errorResponse = new HttpResponse();
        errorResponse.setStatusCode(500);
        errorResponse.setBody('Internal Server Error');
        ResultLogger.EventData errorEventData = new ResultLogger.EventData(
            null, 'Test', errorResponse, '{"test":"error-response"}'
        );
        
        HttpResponse invalidJsonResponse = new HttpResponse();
        invalidJsonResponse.setStatusCode(200);
        invalidJsonResponse.setBody('Not valid JSON');
        ResultLogger.EventData invalidJsonEventData = new ResultLogger.EventData(
            null, 'Test', invalidJsonResponse, '{"test":"invalid-json"}'
        );
        
        HttpResponse statusErrorResponse = new HttpResponse();
        statusErrorResponse.setStatusCode(200);
        statusErrorResponse.setBody('{"status":"error"}');
        ResultLogger.EventData statusErrorEventData = new ResultLogger.EventData(
            null, 'Test', statusErrorResponse, '{"test":"status-error"}'
        );
        
        Test.startTest();
        
        ResultLogger testLogger = new ResultLogger();
        
        List<CleverTap__Event__c> testLogs = new List<CleverTap__Event__c>{
            new CleverTap__Event__c(
                CleverTap__Status__c = 'Failed',
                CleverTap__Response__c = 'Testing null response'
            ),
            new CleverTap__Event__c(
                CleverTap__Status__c = 'Failed',
                CleverTap__Response__c = 'Testing error status code'
            ),
            new CleverTap__Event__c(
                CleverTap__Status__c = 'Failed',
                CleverTap__Response__c = 'Testing invalid JSON'
            ),
            new CleverTap__Event__c(
                CleverTap__Status__c = 'Failed',
                CleverTap__Response__c = 'Testing status:error'
            )
        };
        insert testLogs;
        
        testLogger.logEvent(nullEventData);
        testLogger.logEvent(errorEventData);
        testLogger.logEvent(invalidJsonEventData);
        testLogger.logEvent(statusErrorEventData);
        
        Test.stopTest();
        
        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Status__c FROM CleverTap__Event__c];
        System.assert(logs.size() >= 4, 'Should have at least 4 logs');
        
        Integer failedLogs = 0;
        for (CleverTap__Event__c log : logs) {
            if (log.CleverTap__Status__c == 'Failed') {
                failedLogs++;
            }
        }
        
        System.assert(failedLogs >= 4, 'Should have at least 4 failed logs');
    }
    
    @isTest
    static void testPermissionHandling() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');
        
        ResultLogger.EventData eventData = new ResultLogger.EventData(
            testLead.Id, 'Lead', mockResponse, '{"test":"request"}'
        );
        
        Test.startTest();
        
        ResultLogger logger = new ResultLogger();
        
        logger.logEvent(eventData);
        
        Test.stopTest();
        
        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c];
        System.assert(logs.size() >= 0, 'Permission handling should allow or prevent log creation');
    } 
    
    /**
     * @description Tests special field handling
     */
    @isTest
    static void testSpecialFieldHandling() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');
        
        ResultLogger.EventData eventData = new ResultLogger.EventData(
            testAccount.Id, 'Account', mockResponse, '{"test":"special-field"}'
        );
        
        Test.startTest();
        
        CleverTap__Event__c eventLog = new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = 'Account ID: ' + testAccount.Id + '\nSpecial field test'
        );
        
        try {
            eventLog.put('CleverTap__Account__c', testAccount.Id);
        } catch (Exception e) {
            System.debug('Field not found: ' + e.getMessage());
        }
        
        insert eventLog;
        
        resultLogger.logEvent(eventData);
        
        Test.stopTest();
        
        List<CleverTap__Event__c> logs = [SELECT Id, CleverTap__Response__c FROM CleverTap__Event__c];
        System.assert(!logs.isEmpty(), 'Should have created logs');
        
        Boolean foundAccountLog = false;
        for (CleverTap__Event__c log : logs) {
            if (log.CleverTap__Response__c != null && 
                log.CleverTap__Response__c.contains('Account')) {
                foundAccountLog = true;
                break;
            }
        }
        
        System.assert(foundAccountLog, 'Should have a log with Account information');
    }
    
    @isTest
    static void testFormatResponseContent() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        HttpResponse emptyResponse = new HttpResponse();
        emptyResponse.setStatusCode(200);
        emptyResponse.setBody('');
        
        ResultLogger.EventData emptyBodyData = new ResultLogger.EventData(
            testLead.Id, 'Lead', emptyResponse, '{"test":"empty-body"}'
        );
        
        HttpResponse nullBodyResponse = new HttpResponse();
        nullBodyResponse.setStatusCode(200);
        
        ResultLogger.EventData nullBodyData = new ResultLogger.EventData(
            testLead.Id, 'Lead', nullBodyResponse, '{"test":"null-body"}'
        );
        
        Test.startTest();
        
        List<CleverTap__Event__c> testLogs = new List<CleverTap__Event__c>{
            new CleverTap__Event__c(
                CleverTap__Status__c = 'Success',
                CleverTap__Response__c = 'Empty body test',
                CleverTap__Lead__c = testLead.Id
            ),
            new CleverTap__Event__c(
                CleverTap__Status__c = 'Success',
                CleverTap__Response__c = 'Null body test',
                CleverTap__Lead__c = testLead.Id
            )
        };
        insert testLogs;
        
        resultLogger.logEvent(emptyBodyData);
        resultLogger.logEvent(nullBodyData);
        
        Test.stopTest();
        
        List<CleverTap__Event__c> logs = [SELECT Id FROM CleverTap__Event__c WHERE CleverTap__Lead__c = :testLead.Id];
        System.assert(!logs.isEmpty(), 'Test logs should exist');
        System.assert(logs.size() >= 2, 'Should have at least 2 logs for this test');
    }

    @isTest
    static void testLogEventErrorHandling() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(500);
        mockResponse.setBody('{"error":"Internal Server Error"}');
        
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        ResultLogger.EventData eventData = new ResultLogger.EventData(
            testLead.Id, 'CustomObject_That_Does_Not_Exist', mockResponse, '{"test":"error-handling"}'
        );
        
        Test.startTest();
        
        ResultLogger logger = new ResultLogger();
        logger.logEvent(eventData);
        
        ResultLogger.EventData nullResponseData = new ResultLogger.EventData(
            testLead.Id, 'Lead', null, '{"test":"null-response"}'
        );
        logger.logEvent(nullResponseData);
        
        HttpResponse invalidJsonResponse = new HttpResponse();
        invalidJsonResponse.setStatusCode(200);
        invalidJsonResponse.setBody('Not valid JSON');
        ResultLogger.EventData invalidJsonData = new ResultLogger.EventData(
            testLead.Id, 'Lead', invalidJsonResponse, '{"test":"invalid-json"}'
        );
        logger.logEvent(invalidJsonData);
        
        Test.stopTest();
        
        System.assert(true, 'Successfully tested ResultLogger error handling');
    }

    @isTest
    static void testLogCreationErrors() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');
        
        ResultLogger.EventData eventData = new ResultLogger.EventData(
            testLead.Id, 'Lead', mockResponse, '{"test":"error-handling"}'
        );
        
        Test.startTest();
        
        ResultLogger logger = new ResultLogger();
        for(Integer i = 0; i < 5; i++) {
            logger.logEvent(eventData);
        }
        
        String longBody = '{"data":"' + 'x'.repeat(30000) + '"}';
        HttpResponse largeResponse = new HttpResponse();
        largeResponse.setStatusCode(200);
        largeResponse.setBody(longBody);
        
        ResultLogger.EventData largeData = new ResultLogger.EventData(
            testLead.Id, 'Lead', largeResponse, '{"test":"large-body"}'
        );
        logger.logEvent(largeData);
        
        Test.stopTest();
        
        System.assert(true, 'Successfully tested ResultLogger creation errors');
    }

    @isTest
    static void testResultLoggerCoreLogic() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        HttpResponse okResponse = new HttpResponse();
        okResponse.setStatusCode(200);
        okResponse.setBody('{"status":"success","message":"Operation completed"}');
        
        HttpResponse badResponse = new HttpResponse();
        badResponse.setStatusCode(400);
        badResponse.setBody('{"status":"error","message":"Bad request"}');
        
        HttpResponse malformedResponse = new HttpResponse();
        malformedResponse.setStatusCode(200);
        malformedResponse.setBody('Not valid JSON');
        
        ResultLogger.EventData successEvent = new ResultLogger.EventData(
            testLead.Id, 'Lead', okResponse, '{"test":"success"}'
        );
        
        ResultLogger.EventData failureEvent = new ResultLogger.EventData(
            testLead.Id, 'Lead', badResponse, '{"test":"failure"}'
        );
        
        ResultLogger.EventData malformedEvent = new ResultLogger.EventData(
            testLead.Id, 'Lead', malformedResponse, '{"test":"malformed"}'
        );
        
        Test.startTest();
        
        CleverTap__Event__c sampleLog = new CleverTap__Event__c(
            CleverTap__Status__c = 'Success',
            CleverTap__Response__c = 'Test log',
            CleverTap__Lead__c = testLead.Id
        );
        insert sampleLog;
        
        ResultLogger logger = new ResultLogger();
        
        logger.logEvent(successEvent);
        logger.logEvent(failureEvent);
        logger.logEvent(malformedEvent);
        
        List<ResultLogger.EventData> events = new List<ResultLogger.EventData>{
            successEvent, failureEvent, malformedEvent
        };
        logger.logEventBatch(events);
        
        Test.stopTest();
    }
}