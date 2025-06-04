@isTest
private class SchemaUtilityTest {
    static SchemaUtility schemaUtility = new SchemaUtility();
    @isTest
    static void testGetFieldsMap() {
        Test.startTest();
        Map<String, Schema.SObjectField> leadFields = schemaUtility.getFieldsMap('Lead');
        Test.stopTest();

        System.assert(leadFields.containsKey('lastname'), 'Fields map should contain LastName field');
        System.assert(leadFields.containsKey('email'), 'Fields map should contain Email field');
        System.assert(leadFields.containsKey('company'), 'Fields map should contain Company field');
    }
    
    @isTest
    static void testGetFieldsMapInvalidObject() {
        Test.startTest();
        Map<String, Schema.SObjectField> invalidFields = schemaUtility.getFieldsMap('InvalidObject');
        Test.stopTest();

        System.assertEquals(0, invalidFields.size(), 'Should return empty map for invalid object');
    }
    
    @isTest
    static void testGetFieldDescribe() {
        Test.startTest();
        Schema.DescribeFieldResult emailField = schemaUtility.getFieldDescribe('Lead', 'Email');
        Test.stopTest();

        System.assertNotEquals(null, emailField, 'Field describe should not be null');
        System.assertEquals('Email', emailField.getName(), 'Field name should match');
        System.assertEquals(Schema.DisplayType.EMAIL, emailField.getType(), 'Field type should be EMAIL');
    }
    
    @isTest
    static void testGetFieldDescribeInvalidField() {
        Test.startTest();
        Schema.DescribeFieldResult invalidField = schemaUtility.getFieldDescribe('Lead', 'InvalidField');
        Test.stopTest();

        System.assertEquals(null, invalidField, 'Should return null for invalid field');
    }
    
    @isTest
    static void testGetObjectDescribe() {
        Test.startTest();
        Schema.DescribeSObjectResult leadDescribe = schemaUtility.getObjectDescribe('Lead');
        Test.stopTest();
        System.assertNotEquals(null, leadDescribe, 'Object describe should not be null');
        System.assertEquals('Lead', leadDescribe.getName(), 'Object name should match');
        System.assertEquals('Lead', leadDescribe.getLabel(), 'Object label should match');
    }
    
    @isTest
    static void testGetObjectDescribeInvalidObject() {
        Test.startTest();
        Schema.DescribeSObjectResult invalidDescribe = schemaUtility.getObjectDescribe('InvalidObject');
        Test.stopTest();
        System.assertEquals(null, invalidDescribe, 'Should return null for invalid object');
    }
    
    @isTest
    static void testIsFieldAccessible() {
        Test.startTest();
        Boolean isAccessible = schemaUtility.isFieldAccessible('Lead', 'Email');
        Test.stopTest();
        System.assertEquals(true, isAccessible, 'Email field should be accessible');
    }
    
    @isTest
    static void testIsFieldAccessibleInvalidField() {
        Test.startTest();
        Boolean isAccessible = schemaUtility.isFieldAccessible('Lead', 'InvalidField');
        Test.stopTest();
        System.assertEquals(false, isAccessible, 'Invalid field should not be accessible');
    }
    
    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<Map<String, String>> leadStatusOptions = schemaUtility.getPicklistValues('Lead', 'Status');
        Test.stopTest();
        
        System.assert(!leadStatusOptions.isEmpty(), 'Should return picklist values for Status field');
        
        for (Map<String, String> option : leadStatusOptions) {
            System.assert(option.containsKey('label'), 'Picklist option should have label');
            System.assert(option.containsKey('value'), 'Picklist option should have value');
        }
    }
    
    @isTest
    static void testGetPicklistValuesNonPicklistField() {
        Test.startTest();
        List<Map<String, String>> emailOptions = schemaUtility.getPicklistValues('Lead', 'Email');
        Test.stopTest();
        
        System.assertEquals(0, emailOptions.size(), 'Should return empty list for non-picklist field');
    }
    
    @isTest
    static void testGetPicklistValuesInvalidField() {
        Test.startTest();
        List<Map<String, String>> invalidOptions = schemaUtility.getPicklistValues('Lead', 'InvalidField');
        Test.stopTest();
        
        System.assertEquals(0, invalidOptions.size(), 'Should return empty list for invalid field');
    }
    
    @isTest
    static void testGetAccessibleFields() {
        Test.startTest();
        List<Map<String, String>> leadFields = schemaUtility.getAccessibleFields('Lead');
        Test.stopTest();
        
        System.assert(!leadFields.isEmpty(), 'Should return accessible fields for Lead');
        
        for (Map<String, String> field : leadFields) {
            System.assert(field.containsKey('label'), 'Field info should have label');
            System.assert(field.containsKey('value'), 'Field info should have value');
        }
    }
    
    @isTest
    static void testGetAccessibleFieldsInvalidObject() {
        Test.startTest();
        List<Map<String, String>> invalidFields = schemaUtility.getAccessibleFields('InvalidObject');
        Test.stopTest();

        System.assertEquals(0, invalidFields.size(), 'Should return empty list for invalid object');
    }
    
    @isTest
    static void testFieldsMapCache() {
        Test.startTest();
        Map<String, Schema.SObjectField> firstCall = schemaUtility.getFieldsMap('Lead');
        Map<String, Schema.SObjectField> secondCall = schemaUtility.getFieldsMap('Lead');
        Test.stopTest();
        
        System.assertEquals(firstCall.size(), secondCall.size(), 'Both calls should return same number of fields');
    }
    
    @isTest
    static void testObjectDescribeCache() {
        Test.startTest();
        Schema.DescribeSObjectResult firstCall = schemaUtility.getObjectDescribe('Lead');
        Schema.DescribeSObjectResult secondCall = schemaUtility.getObjectDescribe('Lead');
        Test.stopTest();
        
        System.assertEquals(firstCall.getName(), secondCall.getName(), 'Both calls should return same object name');
    }
}