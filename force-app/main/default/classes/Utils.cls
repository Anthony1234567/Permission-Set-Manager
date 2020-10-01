/**
 * General purpose static utility methods
 */
public class Utils {
    /**
	 * @description Mirrors the way SF Process Builder/Workflows do filter logic
	 */
    public enum CONDITION_FILTER_LOGIC {
        ALL_CONDITIONS_MET, // AND
        ANY_CONDITION_MET, // OR
        CUSTOM_LOGIC, // User defined
        ALWAYS // No condition
    } 

    /**
     * @description: Custom getRecord method. Can be invoked outside of @wire 
     *               Finds record by recordId. SObject Type determined based on recordId parameter
     * @param:: recordId - Id of record to match
     * @param:: fields - fields to query
     * @return:: Record matching the given recordId (if one exists)
     * Source: https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.data_wire_example
     */
    @AuraEnabled(cacheable=true)
    public static SObject getRecord(Id recordId, List<String> fields) {
        return Database.query('SELECT ' + String.join(fields, ',') + ' ' + 
                              'FROM ' + recordId.getSobjectType() + ' ' +
                              'WHERE Id = :recordId');
    }

    /**
     * @description: Finds records by recordId. Not auraEnabled for now since it doesn't need to be
     * @param:: recordIdSet - Id of records to match
     * @param:: fields - fields to query
     * @param:: sObjectType - Object to query
     * @return:: Records matching the given recordId (if one exists)
     */
    public static List<SObject> getRecords(Set<Id> recordIdSet, List<String> fields, SObjectType sObjectType) {
        return Database.query('SELECT ' + String.join(fields, ',') + ' ' + 
                              'FROM ' + sObjectType + ' ' +
                              'WHERE Id IN :recordIdSet');
    }
    
    /**
     * @description: Given a set of Ids and a map of Id->SObject, 
     *               returns all corresponding records that are present in the Map
     *               Apex Map class does not have a getAll method and 
     *               multiple inheritance is not allowed so chose not to exted base Map class. 
     * @param: sObjectList - list of records
     * @return: Set of Id corresponding to the records in the list
     */
    public static List<SObject> getAllFromRecordMap(Map<Id, SObject> sObjectMap, Set<Id> recordIdSet) {
        List<SObject> returnList = new List<SObject>();
        
        for (Id recordId : recordIdSet) {
            if (sObjectMap.containsKey(recordId)) {
                returnList.add(sObjectMap.get(recordId));
            }
        }
        
        return returnList;
    }
    
   /**
	* The following are for getting field values (Set - unique) from collections of Salesforce records
	*/
        
   /**
    * @description: Creates a Set of Id from a list of records of any SObject type (includes generic)
    *               FASTEST option if all you want is a set of ids from a collection of records
    * @param: sObjectList - list of records
    * @return: Set of Id corresponding to the records in the list
    */
    public static Set<Id> toIdSet(List<SObject> sObjectList) {
        // Takes advantage of Map constructor that is built into the language 
        return (new Map<Id, SObject>(sObjectList)).keySet();
    }
    
    /**
     * @description: Creates a Set of distinct field values for a particular field among a set of records
     *               Example method call - returns Object collection: Utils.toFieldValueSet(Account.OwnerId, accountList);
     *               Example method call - returns String collection: Utils.castStringSet(Utils.toFieldValueSet(Account.OwnerId, accountList));
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Set of field values corresponding to the records in the list
     */
    public static Set<Object> toFieldValueObjectSet(SObjectField field, List<SObject> sObjectList) {
        Set<Object> fieldValueSet = new Set<Object>();
        
        for (SObject record : sObjectList) {
            fieldValueSet.add(record.get(field));
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return fieldValueSet;
    }

    /**
     * @description: Creates a Set of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Set of field values corresponding to the records in the list
     */
    public static Set<Id> toFieldValueIdSet(SObjectField field, List<SObject> sObjectList) {
        Set<Id> fieldValueIdSet = new Set<Id>();
        
        for (SObject record : sObjectList) {
            fieldValueIdSet.add((Id) record.get(field));
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return fieldValueIdSet;
    }

    /**
     * @description: Creates a Set of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Set of field values corresponding to the records in the list
     */
    public static Set<String> toFieldValueStringSet(SObjectField field, List<SObject> sObjectList) {
        Set<String> fieldValueStringSet = new Set<String>();
        
        for (SObject record : sObjectList) {
            fieldValueStringSet.add((String) record.get(field));
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return fieldValueStringSet;
    }

    /**
     * @description: Creates a Set of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Set of field values corresponding to the records in the list
     */
    public static Set<Boolean> toFieldValueBooleanSet(SObjectField field, List<SObject> sObjectList) {
        Set<Boolean> fieldValueBooleanSet = new Set<Boolean>();
        
        for (SObject record : sObjectList) {
            fieldValueBooleanSet.add((Boolean) record.get(field));
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return fieldValueBooleanSet;
    }

    /**
     * @description: Creates a Set of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Set of field values corresponding to the records in the list
     */
    public static Set<Double> toFieldValueDoubleSet(SObjectField field, List<SObject> sObjectList) {
        Set<Double> fieldValueDoubleSet = new Set<Double>();
        
        for (SObject record : sObjectList) {
            fieldValueDoubleSet.add((Double) record.get(field));
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return fieldValueDoubleSet;
    }

    /**
     * @description: Creates a Set of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Set of field values corresponding to the records in the list
     */
    public static Set<DateTime> toFieldValueDateTimeSet(SObjectField field, List<SObject> sObjectList) {
        Set<DateTime> fieldValueDateTimeSet = new Set<DateTime>();
        
        for (SObject record : sObjectList) {
            fieldValueDateTimeSet.add((DateTime) record.get(field));
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return fieldValueDateTimeSet;
    }

    /**
     * @description: Creates a Set of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Set of field values corresponding to the records in the list
     */
    public static Set<Date> toFieldValueDateSet(SObjectField field, List<SObject> sObjectList) {
        Set<Date> fieldValueDateSet = new Set<Date>();
        
        for (SObject record : sObjectList) {
            fieldValueDateSet.add((Date) record.get(field));
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return fieldValueDateSet;
    }

    /**
     * @description: Creates a Set of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Set of field values corresponding to the records in the list
     */
    public static Set<Time> toFieldValueTimeSet(SObjectField field, List<SObject> sObjectList) {
        Set<Time> fieldValueTimeSet = new Set<Time>();
        
        for (SObject record : sObjectList) {
            fieldValueTimeSet.add((Time) record.get(field));
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return fieldValueTimeSet;
    }

    /**
     * @description: Creates a Map of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Map of field values to record where that value is present
     */
    public static Map<Object, SObject> toFieldValueObjectMapUnique(SObjectField field, List<SObject> sObjectList) {
        Map<Object, SObject> uniqueFieldValueToRecordMap = new Map<Object, SObject>();
        
        for (SObject record : sObjectList) {
            uniqueFieldValueToRecordMap.put(record.get(field), record);
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return uniqueFieldValueToRecordMap;
    }

    /**
     * @description: Creates a Map of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Map of field values to record where that value is present
     */
    public static Map<Id, SObject> toFieldValueIdMapUnique(SObjectField field, List<SObject> sObjectList) {
        Map<Id, SObject> uniqueFieldValueToRecordMap = new Map<Id, SObject>();
        
        for (SObject record : sObjectList) {
            uniqueFieldValueToRecordMap.put((Id) record.get(field), record);
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return uniqueFieldValueToRecordMap;
    }

    /**
     * @description: Creates a Map of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Map of field values to record where that value is present
     */
    public static Map<String, SObject> toFieldValueStringMapUnique(SObjectField field, List<SObject> sObjectList) {
        Map<String, SObject> uniqueFieldValueToRecordMap = new Map<String, SObject>();
        
        for (SObject record : sObjectList) {
            uniqueFieldValueToRecordMap.put((String) record.get(field), record);
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return uniqueFieldValueToRecordMap;
    }

    /**
     * @description: Creates a Map of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Map of field values to record where that value is present
     */
    public static Map<Boolean, SObject> toFieldValueBooleanMapUnique(SObjectField field, List<SObject> sObjectList) {
        Map<Boolean, SObject> uniqueFieldValueToRecordMap = new Map<Boolean, SObject>();
        
        for (SObject record : sObjectList) {
            uniqueFieldValueToRecordMap.put((Boolean) record.get(field), record);
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return uniqueFieldValueToRecordMap;
    }

    /**
     * @description: Creates a Map of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Map of field values to record where that value is present
     */
    public static Map<Double, SObject> toFieldValueDoubleMapUnique(SObjectField field, List<SObject> sObjectList) {
        Map<Double, SObject> uniqueFieldValueToRecordMap = new Map<Double, SObject>();
        
        for (SObject record : sObjectList) {
            uniqueFieldValueToRecordMap.put((Double) record.get(field), record);
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return uniqueFieldValueToRecordMap;
    }

    /**
     * @description: Creates a Map of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Map of field values to record where that value is present
     */
    public static Map<DateTime, SObject> toFieldValueDateTimeMapUnique(SObjectField field, List<SObject> sObjectList) {
        Map<DateTime, SObject> uniqueFieldValueToRecordMap = new Map<DateTime, SObject>();
        
        for (SObject record : sObjectList) {
            uniqueFieldValueToRecordMap.put((DateTime) record.get(field), record);
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return uniqueFieldValueToRecordMap;
    }

    /**
     * @description: Creates a Map of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Map of field values to record where that value is present
     */
    public static Map<Date, SObject> toFieldValueDateMapUnique(SObjectField field, List<SObject> sObjectList) {
        Map<Date, SObject> uniqueFieldValueToRecordMap = new Map<Date, SObject>();
        
        for (SObject record : sObjectList) {
            uniqueFieldValueToRecordMap.put((Date) record.get(field), record);
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return uniqueFieldValueToRecordMap;
    }

    /**
     * @description: Creates a Map of distinct field values for a particular field among a set of records
     * @param: field - field to build set of values from
     * @param: sObjectList - list of records (Should all be of the same type otherwise SF will throw error)
     * @return: Map of field values to record where that value is present
     */
    public static Map<Time, SObject> toFieldValueTimeMapUnique(SObjectField field, List<SObject> sObjectList) {
        Map<Time, SObject> uniqueFieldValueToRecordMap = new Map<Time, SObject>();
        
        for (SObject record : sObjectList) {
            uniqueFieldValueToRecordMap.put((Time) record.get(field), record);
        }
        
        // Adding NULL to a set adds a 'null' element to the set. This set may contain null if any processed record field was empty
        return uniqueFieldValueToRecordMap;
    }

    /**
     * @description: Get the field value for a generic SObject. Primarily used for related record
     *               fields since SObject.get('record.parent.field') is not supported
     * @param: field - SObject field type
     * @param: record - record to get field value for
     * @return: Value of specified field
     */
    public static Object getFieldValue(SObjectField field, SObject record) {
        return getFieldValue(field.getDescribe().getName(), record);
    }

    /**
     * @description: Get the field value for a generic SObject. Primarily used for related record
     *               fields since SObject.get('record.parent.field') is not supported
     * @param: field - String representation
     * @param: record - record to get field value for
     * @return: Value of specified field
     */
    public static Object getFieldValue(String field, SObject record) {
        while (field.contains('.')) {
            List<String> splitRelatedField = field.split('\\.', 2);

            record = record.getSObject(splitRelatedField.get(0));
            field = splitRelatedField.get(1);

            // Return null when record has no parent record to look up to.
            // This avoids de-referencing null values as we follow the relationship
            // Example: trying to get Manager.Name form a User with no Manager
            if (record == null) {
                return null;
            }
        }

        return record.get(field);
    }
    
    /**
     * The following are for casting collections of Object (Apex primitive data type) or collections of primitive data types corresponding to field types in Salesforce
     * API Data Types and Salesforce Field Types: https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/api_ui_datatype_map.htm
     * Found no elegant one-liner for casting collections of Object to other primitives other than round trip serialization for which there are come considerations around Id type comparisons.
     */
    
    /**
     * @description: Casts a set of Objects (primitive) to a set of Ids (primitive)
     * @param: objectsToCastSet - Set of elements to cast
     * @return: Set of Ids corresponding to elements in the passed in list
     */
    public static Set<Id> castIdSet(Set<Object> objectsToCastSet) {
        Set<Id> returnIdSet = new Set<Id>();
        
        for (Object objectToCast : objectsToCastSet) {
            returnIdSet.add((Id) objectToCast);
        }
        
        return returnIdSet;
    }
    
    /**
     * @description: Casts a set of Objects (primitive) to a set of Strings (primitive)
     * @param: objectsToCastSet - Set of elements to cast
     * @return: Set of Strings corresponding to elements in the passed in list
     */
    public static Set<String> castStringSet(Set<Object> objectsToCastSet) {
        Set<String> returnStringSet = new Set<String>();
        
        for (Object objectToCast : objectsToCastSet) {
            returnStringSet.add((String) objectToCast);
        }
        
        return returnStringSet;
    }
    
    /**
     * @description: Casts a set of Objects (primitive) to a set of Booleans (primitive)
     * @param: objectsToCastSet - Set of elements to cast
     * @return: Set of Booleans corresponding to elements in the passed in list
     */
    public static Set<Boolean> castBooleanSet(Set<Object> objectsToCastSet) {
        Set<Boolean> returnBooleanSet = new Set<Boolean>();
        
        for (Object objectToCast : objectsToCastSet) {
            returnBooleanSet.add((Boolean) objectToCast);
        }
        
        return returnBooleanSet;
    }
    
    /**
     * @description: Casts a set of Objects (primitive) to a set of Doubles (primitive)
     * @param: objectsToCastSet - Set of elements to cast
     * @return: Set of Doubles corresponding to elements in the passed in list
     */
    public static Set<Double> castDoubleSet(Set<Object> objectsToCastSet) {
        Set<Double> returnDoubleSet = new Set<Double>();
        
        for (Object objectToCast : objectsToCastSet) {
            returnDoubleSet.add((Double) objectToCast);
        }
        
        return returnDoubleSet;
    }

    /**
     * @description: Casts a set of Objects (primitive) to a set of DateTimess (primitive)
     * @param: objectsToCastSet - Set of elements to cast
     * @return: Set of DateTimess corresponding to elements in the passed in list
     */
    public static Set<DateTime> castDateTimeSet(Set<Object> objectsToCastSet) {
        Set<DateTime> returnDateTimeSet = new Set<DateTime>();
        
        for (Object objectToCast : objectsToCastSet) {
            returnDateTimeSet.add((DateTime) objectToCast);
        }
        
        return returnDateTimeSet;
    }

    /**
     * @description: Casts a set of Objects (primitive) to a set of Dates (primitive)
     * @param: objectsToCastSet - Set of elements to cast
     * @return: Set of Dates corresponding to elements in the passed in list
     */
    public static Set<Date> castDateSet(Set<Object> objectsToCastSet) {
        Set<Date> returnDateSet = new Set<Date>();
        
        for (Object objectToCast : objectsToCastSet) {
            returnDateSet.add((Date) objectToCast);
        }
        
        return returnDateSet;
    }

    /**
     * @description: Casts a set of Objects (primitive) to a set of Times (primitive)
     * @param: objectsToCastSet - Set of elements to cast
     * @return: Set of Times corresponding to elements in the passed in list
     */
    public static Set<Time> castTimeSet(Set<Object> objectsToCastSet) {
        Set<Time> returnTimeSet = new Set<Time>();
        
        for (Object objectToCast : objectsToCastSet) {
            returnTimeSet.add((Time) objectToCast);
        }
        
        return returnTimeSet;
    }

    /**
     * DAS methods
     */

    /**
     * @description: will pass back the className based on an intance of `this`;
     * @param instance: Instance to derrive class name from
     * @return: Class name string
     */
    public static string classNameInstanceToString(Object instance){
        return String.valueOf(instance).split(':').get(0);
    }
    
    /**
     * Formula function inspired methods
     */

    /**
     * @description: Functions similar to formula method BLANKVALUE(value, valueIfBlank)
     * @param: value - value in question
     * @param: valueIfNull - return value if value in question is null
     * @return: value if it is not null. valueIfNull otherwise
     * NOTE: Use the following generic string method to output: String.valueOf(object); 
     */
    public static Object nullValue(Object value, Object valueIfNull) {
        // Takes advantage of Map constructor that is built into the language 
        return value == null ? valueIfNull : value;
    }

    /**
     * Query related methods
     */

    /**
     * @description: Determine if a field can be used in a SOQL WHERE clause with the LIKE operator
     * @param: field - field in question
     * @return: True if the field can be used with LIKE in a SOQL WHERE clause. False otherwise
     */
    public static Boolean isLIKEOperatorCompatible(SObjectField field) {
        Schema.DescribeFieldResult describeFieldResult = field.getDescribe();

        return describeFieldResult.isFilterable() && describeFieldResult.getType() == Schema.DisplayType.STRING;
    }

    /**
     * Date methods
     */

    /**
     * @description: Determine the monthname from a given date
     * @param: dateValue - Date to get month name for
     * @return: Monthname for the specified date
     */
    public static String getMonthName(Date dateValue) {
        String monthName;

        switch on dateValue.month() {
            when 1 {
                monthName = 'January';
            } when 2 {
                monthName = 'February';
            } when 3 {
                monthName = 'March';
            } when 4 {
                monthName = 'April';
            } when 5 {
                monthName = 'May';
            } when 6 {
                monthName = 'June';
            } when 7 {
                monthName = 'July';
            } when 8 {
                monthName = 'August';
            } when 9 {
                monthName = 'September';
            } when 10 {
                monthName = 'October';
            } when 11 {
                monthName = 'November';
            } when 12 {
                monthName = 'December';
            } when else {
                // Default
            }
        }

        return monthName;
    }

    /**
     * Generic utility methods
     */

    /**
     * @description: Generate a random hex string of given length
     * @param: length - Return string length
     * @return: Hex string of predetermined size (length)
     */
    public static String generateRandomHexString(Integer length) {
        String alphabet = '0123456789ABCDEF';
        String randomReturnValue = '';

        while (randomReturnValue.length() < length) {
            Integer indexOfCharToAppend = Math.mod(Math.abs(Crypto.getRandomInteger()), alphabet.length());
            randomReturnValue += alphabet.substring(indexOfCharToAppend, indexOfCharToAppend + 1);
        }

        return randomReturnValue; 
    }
}