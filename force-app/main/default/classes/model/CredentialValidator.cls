/**
 * @class CredentialValidator
 * @description Validates CleverTap credentials by making an API call before saving them
 */
public with sharing class CredentialValidator {
    /**
     * @description Validates CleverTap credentials by making a connection test API call
     * @param region The CleverTap region (US, EU, IN, etc.)
     * @param accountId The CleverTap Account ID
     * @param passcode The CleverTap Passcode
     * @return ValidationResult Object containing validation status and message
     */
    public ValidationResult validateCredentials(String region, String accountId, String passcode) {
        if (String.isBlank(accountId) || String.isBlank(passcode) || String.isBlank(region)) {
            return new ValidationResult(false, 'All credential fields are required');
        }
        
        try {
            String apiBaseUrl = getRegionBaseUrl(region);
            if (String.isBlank(apiBaseUrl)) {
                return new ValidationResult(false, 'Invalid region selected');
            }

            String connectUrl = apiBaseUrl + '/v1/connect?partner=Salesforce';

            HttpRequest req = new HttpRequest();
            req.setEndpoint(connectUrl);
            req.setMethod('GET');
            req.setTimeout(20000); 

            req.setHeader('X-CleverTap-Account-Id', accountId);
            req.setHeader('X-CleverTap-Passcode', passcode);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            return processValidationResponse(res);   
        } catch (Exception e) {
            return new ValidationResult(false, 'Validation error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Processes the HTTP response from the validation request
     * @param res The HTTP response
     * @return ValidationResult Object containing validation status and message
     */
    private ValidationResult processValidationResponse(HttpResponse res) {
        Integer statusCode = res.getStatusCode();
        String responseBody = res.getBody();

        Map<String, Object> responseMap;
        try {
            responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        } catch (Exception e) {
            return new ValidationResult(false, 'Error parsing response: ' + e.getMessage());
        }
        
        String status = (String)responseMap.get('status');
        
        if (statusCode == 200 && status == 'success') {
            return new ValidationResult(true, 'Credentials validated successfully');
        } else {
            String errorMessage = '';
            if (responseMap.containsKey('error')) {
                errorMessage = (String)responseMap.get('error');
            } else if (responseMap.containsKey('message')) {
                errorMessage = (String)responseMap.get('message');
            } else {
                errorMessage = 'Unknown error occurred';
            }
            
            Integer errorCode = 0;
            if (responseMap.containsKey('code')) {
                Object codeObj = responseMap.get('code');
                if (codeObj instanceof Integer) {
                    errorCode = (Integer)codeObj;
                } else if (codeObj instanceof String) {
                    errorCode = Integer.valueOf((String)codeObj);
                }
            }
            
            return new ValidationResult(false, 'Validation failed: ' + errorMessage + ' (Code: ' + errorCode + ')');
        }
    }

    private String getRegionBaseUrl(String region) {
        Map<String, String> regionUrls = new Map<String, String>{
            'US' => 'https://us1.api.clevertap.com',
            'EU' => 'https://eu1.api.clevertap.com',
            'IN' => 'https://in1.api.clevertap.com',
            'SG' => 'https://sg1.api.clevertap.com',
            'UAE' => 'https://mec1.api.clevertap.com',
            'ID' => 'https://aps3.api.clevertap.com'
        };
        
        return regionUrls.get(region.toUpperCase());
    }
    
    /**
     * @class ValidationResult
     * @description Wrapper class to represent the result of the CleverTap credentials validation process.
     */
    public class ValidationResult {
        @AuraEnabled 
        public Boolean isValid { get; set; }
        @AuraEnabled 
        public String message { get; set; }

        public ValidationResult(Boolean isValid, String message) {
            this.isValid = isValid;
            this.message = message;
        }
    }
}