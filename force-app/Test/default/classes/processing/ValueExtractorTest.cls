@isTest
private class ValueExtractorTest {
    static ValueExtractor valueExtractor = new ValueExtractor();
    
    @isTest
    static void testConvertFieldValueText() {
        Object result = valueExtractor.convertFieldValue('Test String', 'Text');
        System.assertEquals('Test String', result, 'Text value should remain unchanged');
        
        result = valueExtractor.convertFieldValue(null, 'Text');
        System.assertEquals(null, result, 'Null value should remain null');
    }
    
    @isTest
    static void testConvertFieldValueNumber() {
        Object result = valueExtractor.convertFieldValue(123.45, 'Number');
        System.assertEquals(123.45, result, 'Number value should remain as a number');
        
        result = valueExtractor.convertFieldValue('678.90', 'Number');
        System.assertEquals(678.90, (Decimal)result, 'String number should be converted to number');
        
        result = valueExtractor.convertFieldValue('not-a-number', 'Number');
        System.assertEquals(0, result, 'Invalid number should convert to 0');
        
        result = valueExtractor.convertFieldValue(null, 'Number');
        System.assertEquals(null, result, 'Null value should remain null');
    }
    
    @isTest
    static void testConvertFieldValueBoolean() {
        Object result = valueExtractor.convertFieldValue(true, 'Boolean');
        System.assertEquals(true, result, 'Boolean true should remain true');
        
        result = valueExtractor.convertFieldValue(false, 'Boolean');
        System.assertEquals(false, result, 'Boolean false should remain false');
        
        result = valueExtractor.convertFieldValue('true', 'Boolean');
        System.assertEquals(true, result, 'String "true" should convert to boolean true');
        
        result = valueExtractor.convertFieldValue('false', 'Boolean');
        System.assertEquals(false, result, 'String "false" should convert to boolean false');
        
        result = valueExtractor.convertFieldValue('TrUe', 'Boolean');
        System.assertEquals(true, result, 'String "TrUe" should convert to boolean true');

        result = valueExtractor.convertFieldValue('random string', 'Boolean');
        System.assertEquals(false, result, 'Random string should convert to boolean false');

        result = valueExtractor.convertFieldValue(null, 'Boolean');
        System.assertEquals(null, result, 'Null value should remain null');
    }
    
    @isTest
    static void testConvertFieldValueDate() {
        Date testDate = Date.newInstance(2023, 1, 1);
        Object result = valueExtractor.convertFieldValue(testDate, 'Date');
        String resultStr = (String)result;
        System.assert(resultStr.startsWith('$D_'), 'Date should be converted to $D_ format');

        DateTime testDateTime = DateTime.newInstance(2023, 1, 1, 12, 30, 45);
        result = valueExtractor.convertFieldValue(testDateTime, 'Date');
        resultStr = (String)result;
        System.assert(resultStr.startsWith('$D_'), 'DateTime should be converted to $D_ format');

        result = valueExtractor.convertFieldValue('2023-01-01', 'Date');
        System.assertEquals('2023-01-01', result, 'String date should remain as string');

        result = valueExtractor.convertFieldValue(null, 'Date');
        System.assertEquals(null, result, 'Null value should remain null');

        DateTime now = DateTime.now();
        result = valueExtractor.convertFieldValue(now, 'Date');
        resultStr = (String)result;

        System.assert(resultStr.startsWith('$D_'), 'DateTime should convert to $D_ format');

        String timestampStr = resultStr.substring(3); 
        Long timestamp = Long.valueOf(timestampStr);

        System.assert(timestamp > 0, 'Timestamp should be a positive value');
    }
    
    @isTest
    static void testConvertFieldValueDefaultType() {
        Object result = valueExtractor.convertFieldValue('Test String', '');
        System.assertEquals('Test String', result, 'Empty data type should default to text');
        
        result = valueExtractor.convertFieldValue('Test String', null);
        System.assertEquals('Test String', result, 'Null data type should default to text');
        
        result = valueExtractor.convertFieldValue('Test String', 'InvalidType');
        System.assertEquals('Test String', result, 'Invalid data type should default to text');
        
        result = valueExtractor.convertFieldValue(123.45, 'NumBer');
        System.assertEquals(123.45, result, 'Mixed case data type should work');
    }
    
    @isTest
    static void testConvertFieldValueEdgeCases() {
        Object result = valueExtractor.convertFieldValue('', 'Text');
        System.assertEquals('', result, 'Empty string should remain empty');
        
        Decimal largeNumber = 9223372036854775807.0; // max safe integer
        result = valueExtractor.convertFieldValue(largeNumber, 'Number');
        System.assertEquals(largeNumber, result, 'Large number should be preserved');
        
        Decimal smallNumber = 0.0000000000000001;
        result = valueExtractor.convertFieldValue(smallNumber, 'Number');
        System.assertEquals(smallNumber, result, 'Small number should be preserved');
        
        Date futureDate = Date.newInstance(2100, 12, 31);
        result = valueExtractor.convertFieldValue(futureDate, 'Date');
        String resultStr = (String)result;
        System.assert(resultStr.startsWith('$D_'), 'Future date should be converted to $D_ format');
    }
    
    @isTest
    static void testConvertToNumberExceptions() {
        Account acc = new Account(Name = 'Test Account');
        Object result = valueExtractor.convertFieldValue(acc, 'Number');
        
        System.assertEquals(0, result, 'Failed number conversion should return 0');
    }

    @isTest
    static void testAdvancedBooleanConversions() {
        Object result = valueExtractor.convertFieldValue('1', 'Boolean');
        System.assertEquals(false, result, 'String "1" should convert to a boolean value');
        
        result = valueExtractor.convertFieldValue('0', 'Boolean');
        System.assertEquals(false, result, 'String "0" should convert to a boolean value');

        result = valueExtractor.convertFieldValue('yes', 'Boolean');
        System.assertEquals(false, result, 'String "yes" should convert to a boolean value');
        
        result = valueExtractor.convertFieldValue('no', 'Boolean');
        System.assertEquals(false, result, 'String "no" should convert to a boolean value');

        result = valueExtractor.convertFieldValue('TRUE', 'Boolean');
        System.assertEquals(true, result, 'String "TRUE" should convert to boolean true');
        
        result = valueExtractor.convertFieldValue('False', 'Boolean');
        System.assertEquals(false, result, 'String "False" should convert to boolean false');
    }
    
    @isTest
    static void testComplexObjectConversions() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );

        Object result = valueExtractor.convertFieldValue(opp, 'Text');
        System.assert(result instanceof String, 'Complex object should convert to string with Text type');

        result = valueExtractor.convertFieldValue(opp, 'Number');
        System.assertEquals(0, result, 'Complex object should convert to 0 with Number type due to exception');

        result = valueExtractor.convertFieldValue(opp, 'Date');
        System.assert(result instanceof String, 'Complex object should convert to string with Date type');

        List<String> stringList = new List<String>{'a', 'b', 'c'};
        result = valueExtractor.convertFieldValue(stringList, 'Text');
        System.assert(result instanceof String, 'List should convert to string with Text type');
        
        Map<String, Object> testMap = new Map<String, Object>{'key' => 'value'};
        result = valueExtractor.convertFieldValue(testMap, 'Number');
        System.assertEquals(0, result, 'Map should convert to 0 with Number type');
    }
    
    @isTest
    static void testDateConversionEdgeCases() {
        Date pastDate = Date.newInstance(1900, 1, 1);
        Object result = valueExtractor.convertFieldValue(pastDate, 'Date');
        String resultStr = (String)result;
        System.assert(resultStr.startsWith('$D_'), 'Past date should be converted to $D_ format');

        DateTime midnightTime = DateTime.newInstance(2023, 6, 15, 0, 0, 0);
        result = valueExtractor.convertFieldValue(midnightTime, 'Date');
        resultStr = (String)result;
        System.assert(resultStr.startsWith('$D_'), 'Midnight time should be converted to $D_ format');

        result = valueExtractor.convertFieldValue('Jan 1, 2023', 'Date');
        System.assertEquals('Jan 1, 2023', result, 'Non-ISO date string should remain unchanged');

        result = valueExtractor.convertFieldValue('', 'Date');
        System.assertEquals('', result, 'Empty string should remain unchanged in date conversion');
    }
    
    @isTest
    static void testMixedInputTypes() {
        Object result = valueExtractor.convertFieldValue(42.5, 'Text');
        System.assertEquals('42.5', result, 'Number should convert to string with Text type');

        Date testDate = Date.today();
        result = valueExtractor.convertFieldValue(testDate, 'Text');
        System.assert(result instanceof String, 'Date should convert to string with Text type');

        Blob blobData = Blob.valueOf('Test Blob');
        result = valueExtractor.convertFieldValue(blobData, 'Number');
        System.assertEquals(0, result, 'Blob should convert to 0 with Number type due to exception');

        result = valueExtractor.convertFieldValue(blobData, 'Date');
        System.assert(result instanceof String, 'Blob should convert to string with Date type');
    }
    
    @isTest
    static void testNegativeNumbers() {
        Object result = valueExtractor.convertFieldValue('-42.5', 'Number');
        System.assertEquals(-42.5, (Decimal)result, 'String with negative number should convert to negative decimal');

        result = valueExtractor.convertFieldValue(-5, 'Number');
        System.assertEquals(-5, result, 'Negative integer should remain as negative');

        result = valueExtractor.convertFieldValue(-123.45, 'Number');
        System.assertEquals(-123.45, result, 'Negative decimal should remain as negative');
    }

    @isTest
    static void testTextConversionWithVariousTypes() {
        Object result = valueExtractor.convertFieldValue(123, 'Text');
        System.assertEquals('123', result, 'Number should convert to string');

        result = valueExtractor.convertFieldValue(true, 'Text');
        System.assertEquals('true', result, 'Boolean should convert to string');

        Account acc = new Account(Name = 'Test Account');
        result = valueExtractor.convertFieldValue(acc, 'Text');
        System.assert(result instanceof String, 'Account should convert to string');

        List<String> strList = new List<String>{'a', 'b', 'c'};
        result = valueExtractor.convertFieldValue(strList, 'Text');
        System.assert(result instanceof String, 'List should convert to string');

        Blob blobData = Blob.valueOf('Test Blob');
        result = valueExtractor.convertFieldValue(blobData, 'Text');
        System.assert(result instanceof String, 'Blob should convert to string');
    }
}