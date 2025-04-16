@isTest
private class CredentialValidatorTest {
    // Mock HTTP callout class for successful validation
    private class MockValidationSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success","message":"Connected successfully"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Mock HTTP callout class for failed validation
    private class MockValidationFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"error","error":"Invalid credentials","code":401}');
            res.setStatusCode(401);
            return res;
        }
    }
    
    // Test successful validation
    @isTest
    static void testValidateCredentialsSuccess() {
        // Set up mock response
        Test.setMock(HttpCalloutMock.class, new MockValidationSuccess());
        
        // Create validator instance
        CredentialValidator validator = new CredentialValidator();
        
        // Test the method
        Test.startTest();
        CredentialValidator.ValidationResult result = validator.validateCredentials('US', 'test-account', 'test-passcode');
        Test.stopTest();
        
        // Verify results
        System.assertEquals(true, result.isValid, 'Validation should succeed');
        System.assertEquals('Credentials validated successfully', result.message, 'Success message should match');
    }
    
    // Test failed validation
    @isTest
    static void testValidateCredentialsFailure() {
        // Set up mock response
        Test.setMock(HttpCalloutMock.class, new MockValidationFailure());
        
        // Create validator instance
        CredentialValidator validator = new CredentialValidator();
        
        // Test the method
        Test.startTest();
        CredentialValidator.ValidationResult result = validator.validateCredentials('US', 'test-account', 'test-passcode');
        Test.stopTest();
        
        // Verify results
        System.assertEquals(false, result.isValid, 'Validation should fail');
        System.assert(result.message.contains('Invalid credentials'), 'Failure message should contain error details');
    }
    
    // Test validation with missing credentials
    @isTest
    static void testValidateCredentialsMissing() {
        CredentialValidator validator = new CredentialValidator();
        
        // Test with empty account ID
        Test.startTest();
        CredentialValidator.ValidationResult result1 = validator.validateCredentials('US', '', 'test-passcode');
        System.assertEquals(false, result1.isValid, 'Validation should fail with empty account ID');
        
        // Test with empty passcode
        CredentialValidator.ValidationResult result2 = validator.validateCredentials('US', 'test-account', '');
        System.assertEquals(false, result2.isValid, 'Validation should fail with empty passcode');
        
        // Test with empty region
        CredentialValidator.ValidationResult result3 = validator.validateCredentials('', 'test-account', 'test-passcode');
        System.assertEquals(false, result3.isValid, 'Validation should fail with empty region');
        Test.stopTest();
    }
    
    // Test invalid region
    @isTest
    static void testInvalidRegion() {
        CredentialValidator validator = new CredentialValidator();
        
        Test.startTest();
        CredentialValidator.ValidationResult result = validator.validateCredentials('INVALID', 'test-account', 'test-passcode');
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail with invalid region');
        System.assertEquals('Invalid region selected', result.message, 'Error message should indicate invalid region');
    }
    
    // Test HTTP exception handling
    @isTest
    static void testHttpException() {
        // Set mock to throw exception
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutExceptionImpl());
        
        CredentialValidator validator = new CredentialValidator();
        
        Test.startTest();
        CredentialValidator.ValidationResult result = validator.validateCredentials('US', 'test-account', 'test-passcode');
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail on exception');
        System.assert(result.message.contains('Validation error'), 'Error message should indicate validation error');
    }
    
    // Mock HTTP class that throws an exception
    private class MockHttpCalloutExceptionImpl implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated callout exception');
        }
    }
}