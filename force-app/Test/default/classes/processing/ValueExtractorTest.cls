@isTest
private class ValueExtractorTest {
    
    @isTest
    static void testConvertFieldValueText() {
        // Test converting a string value with text data type
        Object result = ValueExtractor.convertFieldValue('Test String', 'Text');
        System.assertEquals('Test String', result, 'Text value should remain unchanged');
        
        // Test with null value
        result = ValueExtractor.convertFieldValue(null, 'Text');
        System.assertEquals(null, result, 'Null value should remain null');
    }
    
    @isTest
    static void testConvertFieldValueNumber() {
        // Test converting a number value with number data type
        Object result = ValueExtractor.convertFieldValue(123.45, 'Number');
        System.assertEquals(123.45, result, 'Number value should remain as a number');
        
        // Test converting a string to number
        result = ValueExtractor.convertFieldValue('678.90', 'Number');
        System.assertEquals(678.90, (Decimal)result, 'String number should be converted to number');
        
        // Test invalid number
        result = ValueExtractor.convertFieldValue('not-a-number', 'Number');
        System.assertEquals(0, result, 'Invalid number should convert to 0');
        
        // Test with null value
        result = ValueExtractor.convertFieldValue(null, 'Number');
        System.assertEquals(null, result, 'Null value should remain null');
    }
    
    @isTest
    static void testConvertFieldValueBoolean() {
        // Test boolean true value
        Object result = ValueExtractor.convertFieldValue(true, 'Boolean');
        System.assertEquals(true, result, 'Boolean true should remain true');
        
        // Test boolean false value
        result = ValueExtractor.convertFieldValue(false, 'Boolean');
        System.assertEquals(false, result, 'Boolean false should remain false');
        
        // Test string 'true'
        result = ValueExtractor.convertFieldValue('true', 'Boolean');
        System.assertEquals(true, result, 'String "true" should convert to boolean true');
        
        // Test string 'false'
        result = ValueExtractor.convertFieldValue('false', 'Boolean');
        System.assertEquals(false, result, 'String "false" should convert to boolean false');
        
        // Test with mixed case
        result = ValueExtractor.convertFieldValue('TrUe', 'Boolean');
        System.assertEquals(true, result, 'String "TrUe" should convert to boolean true');
        
        // Test with other strings that should become false
        result = ValueExtractor.convertFieldValue('random string', 'Boolean');
        System.assertEquals(false, result, 'Random string should convert to boolean false');
        
        // Test with null value
        result = ValueExtractor.convertFieldValue(null, 'Boolean');
        System.assertEquals(null, result, 'Null value should remain null');
    }
    
    @isTest
    static void testConvertFieldValueDate() {
        // Test with Date
        Date testDate = Date.newInstance(2023, 1, 1);
        Object result = ValueExtractor.convertFieldValue(testDate, 'Date');
        String resultStr = (String)result;
        System.assert(resultStr.startsWith('$D_'), 'Date should be converted to $D_ format');
        
        // Test with DateTime
        DateTime testDateTime = DateTime.newInstance(2023, 1, 1, 12, 30, 45);
        result = ValueExtractor.convertFieldValue(testDateTime, 'Date');
        resultStr = (String)result;
        System.assert(resultStr.startsWith('$D_'), 'DateTime should be converted to $D_ format');
        
        // Test with String that isn't a date - should just return the string
        result = ValueExtractor.convertFieldValue('2023-01-01', 'Date');
        System.assertEquals('2023-01-01', result, 'String date should remain as string');
        
        // Test with null value
        result = ValueExtractor.convertFieldValue(null, 'Date');
        System.assertEquals(null, result, 'Null value should remain null');
        
        // Additional test for numeric string date conversion path
        DateTime now = DateTime.now();
        result = ValueExtractor.convertFieldValue(now, 'Date');
        resultStr = (String)result;
        
        // Verify the resulting string is in the expected format (prefix + timestamp)
        System.assert(resultStr.startsWith('$D_'), 'DateTime should convert to $D_ format');
        
        // Extract the timestamp part and check if it's a valid number
        String timestampStr = resultStr.substring(3); // strip $D_
        Long timestamp = Long.valueOf(timestampStr);
        
        // The timestamp should be a reasonable epoch value (not 0 or negative)
        System.assert(timestamp > 0, 'Timestamp should be a positive value');
    }
    
    @isTest
    static void testConvertFieldValueDefaultType() {
        // Test with empty data type - should default to text
        Object result = ValueExtractor.convertFieldValue('Test String', '');
        System.assertEquals('Test String', result, 'Empty data type should default to text');
        
        result = ValueExtractor.convertFieldValue('Test String', null);
        System.assertEquals('Test String', result, 'Null data type should default to text');
        
        // Test with invalid data type
        result = ValueExtractor.convertFieldValue('Test String', 'InvalidType');
        System.assertEquals('Test String', result, 'Invalid data type should default to text');
        
        // Test with mixed case data type
        result = ValueExtractor.convertFieldValue(123.45, 'NumBer');
        System.assertEquals(123.45, result, 'Mixed case data type should work');
    }
    
    @isTest
    static void testConvertFieldValueEdgeCases() {
        // Test with empty string
        Object result = ValueExtractor.convertFieldValue('', 'Text');
        System.assertEquals('', result, 'Empty string should remain empty');
        
        // Test with very large number
        Decimal largeNumber = 9223372036854775807.0; // max safe integer
        result = ValueExtractor.convertFieldValue(largeNumber, 'Number');
        System.assertEquals(largeNumber, result, 'Large number should be preserved');
        
        // Test with very small number
        Decimal smallNumber = 0.0000000000000001;
        result = ValueExtractor.convertFieldValue(smallNumber, 'Number');
        System.assertEquals(smallNumber, result, 'Small number should be preserved');
        
        // Test with date far in the future
        Date futureDate = Date.newInstance(2100, 12, 31);
        result = ValueExtractor.convertFieldValue(futureDate, 'Date');
        String resultStr = (String)result;
        System.assert(resultStr.startsWith('$D_'), 'Future date should be converted to $D_ format');
    }
    
    @isTest
    static void testConvertToNumberExceptions() {
        // Test with a complex object that would cause exception in number conversion
        Account acc = new Account(Name = 'Test Account');
        Object result = ValueExtractor.convertFieldValue(acc, 'Number');
        
        // Should fall back to 0 as per the catch block
        System.assertEquals(0, result, 'Failed number conversion should return 0');
    }
}