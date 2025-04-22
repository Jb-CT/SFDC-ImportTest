/**
 * @class SchemaUtility
 * @description Utility class for handling Schema-related operations.
 * Provides cached access to schema information to improve performance.
 */
public with sharing class SchemaUtility {
    private final Map<String, Map<String, Schema.SObjectField>> objectFieldsCache;

    private final Map<String, Schema.DescribeSObjectResult> objectDescribeCache;

    public SchemaUtility() {
        this.objectFieldsCache = new Map<String, Map<String, Schema.SObjectField>>();
        this.objectDescribeCache = new Map<String, Schema.DescribeSObjectResult>();
    }

    public Map<String, Schema.SObjectField> getFieldsMap(String objectName) {
        if (objectFieldsCache.containsKey(objectName)) {
            return objectFieldsCache.get(objectName);
        }

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            return new Map<String, Schema.SObjectField>();
        }

        Map<String, Schema.SObjectField> fieldsMap = objectType.getDescribe().fields.getMap();
        objectFieldsCache.put(objectName, fieldsMap);
        
        return fieldsMap;
    }

    public Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
        Map<String, Schema.SObjectField> fieldsMap = getFieldsMap(objectName);
        Schema.SObjectField field = fieldsMap.get(fieldName);
        
        if (field == null) {
            return null;
        }
        
        return field.getDescribe();
    }

    public Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
        if (objectDescribeCache.containsKey(objectName)) {
            return objectDescribeCache.get(objectName);
        }

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            return null;
        }

        Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
        objectDescribeCache.put(objectName, describeResult);
        
        return describeResult;
    }

    public Boolean isFieldAccessible(String objectName, String fieldName) {
        Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(objectName, fieldName);
        return (fieldDescribe != null && fieldDescribe.isAccessible());
    }

    public List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(objectName, fieldName);
        if (fieldDescribe == null || !fieldDescribe.isAccessible()) {
            return new List<Map<String, String>>();
        }
        
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', entry.getLabel());
            option.put('value', entry.getValue());
            options.add(option);
        }
        
        return options;
    }

    public List<Map<String, String>> getAccessibleFields(String objectName) {
        List<Map<String, String>> fields = new List<Map<String, String>>();
        Map<String, Schema.SObjectField> fieldsMap = getFieldsMap(objectName);
        
        for (String fieldName : fieldsMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
            if (fieldDescribe.isAccessible()) {
                Map<String, String> fieldInfo = new Map<String, String>();
                fieldInfo.put('label', fieldDescribe.getLabel());
                fieldInfo.put('value', fieldDescribe.getName());
                fields.add(fieldInfo);
            }
        }
        
        return fields;
    }
}