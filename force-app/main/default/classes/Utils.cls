/**
 * Utils
 * description: General purpose static utility methods
 * @author: Anthony Martinez
 */
public class Utils {
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