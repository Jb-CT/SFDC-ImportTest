/**
 * @class ValueExtractor
 * @description Helper class for converting Salesforce data to CleverTap format.
 */
public with sharing class ValueExtractor {
    private final String datePrefix = '$D_';
    /**
     * @description Converts a field value to the appropriate data type for CleverTap
     * @param value The value to convert
     * @param dataType The target data type
     * @return The converted value
     */
    public Object convertFieldValue(Object value, String dataType) {
        if (value == null) {
            return null;
        }
        
        String dataTypeLower = String.isBlank(dataType) ? 'text' : dataType.toLowerCase();
        
        switch on dataTypeLower {
            when 'number' {
                return convertToNumber(value);
            }
            when 'boolean' {
                return convertToBoolean(value);
            }
            when 'date' {
                return convertToDate(value);
            }
            when else {
                return String.valueOf(value);
            }
        }
    }

    private Decimal convertToNumber(Object value) {
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return 0;
        }
    }

    private Boolean convertToBoolean(Object value) {
        return Boolean.valueOf(value);
    }

    private String convertToDate(Object value) {
        if (value instanceof DateTime) {
            DateTime dt = (DateTime)value;
            // Convert to epoch seconds for CleverTap
            Long v = dt.getTime() / 1000;
            return datePrefix + v;
        } else if (value instanceof Date) {
            Date dateValue = (Date)value;
            // Convert Date to DateTime at midnight, then to epoch seconds
            DateTime dt = DateTime.newInstance(
                dateValue.year(), 
                dateValue.month(), 
                dateValue.day()
            );
            Long v = dt.getTime() / 1000;
            return datePrefix + v;
        }
        return String.valueOf(value);
    }
}