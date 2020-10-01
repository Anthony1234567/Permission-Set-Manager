/**
 * PermissionDataAccessService
 * @description: Data Access Service class for the User object.
 * @author: Anthony Martinez
 */
public class PermissionDataAccessService {
    /**
     * @description: Queries specific permission set assignment setting records by DeveloperName. Sorted for display purposes.
     * @param specifiedQueryFieldAPINameSet: queries all fields by default, or accepts a list of specified fields to include.
     * @param permissionSetDeveloperNameList: Developer Name prefixes for the desired Permission Set Assignment Setting record.
     * @return: Corresponding Permission Set Assignment Setting records
     */
    public List<Permission_Set_Assignment_Setting__mdt> queryPermissionSetAssignmentSettingsByName(List<String> specifiedQueryFieldAPINameList, Set<String> permissionSetDeveloperNameSet) {
        try {
            return Database.query('SELECT ' + String.join(specifiedQueryFieldAPINameList, ',') + ' ' +
                                  'FROM Permission_Set_Assignment_Setting__mdt ' +
                                  'WHERE DeveloperName = :permissionSetDeveloperNameSet');
        } catch (Exception generalException) {
            throw new PermissionDataAccessServiceException(generalException.getMessage());
        }
    }
    
    /**
     * @description: Queries specific permission set records by API Name
     * @param specifiedQueryFieldAPINameSet: queries all fields by default, or accepts a list of specified fields to include.
     * @param permissionSetNameList: Names of the desired Permission Sets.
     * @return: Permission Sets an corresponding user assignment records
     */
    public List<PermissionSet> queryPermissionSetAndAssignmentsByName(List<String> specifiedQueryFieldAPINameList, Set<String> permissionSetNameSet) {
        try {
            return Database.query('SELECT ' + String.join(specifiedQueryFieldAPINameList, ',') + ', ' +
                                         '(SELECT AssigneeId ' +
                                          'FROM Assignments) ' +
                                  'FROM PermissionSet ' +
                                  'WHERE IsOwnedByProfile = false AND ' + 
                                  		'Name IN :permissionSetNameSet');
        } catch (Exception generalException) {
            throw new PermissionDataAccessServiceException(generalException.getMessage());
        }
    }
    
    /**
     * @description: Queries specific permission set assignment setting records by PermissionSet__c. Sorted for display purposes.
     * @param specifiedQueryFieldAPINameSet: queries all fields by default, or accepts a list of specified fields to include.
     * @param permissionSetId: PermissionSet__c for the desired Permission Set Assignment Setting record.
     * @return: Corresponding Permission Set Assignment Setting records
     */
    public List<Permission_Set_Assignment_Setting__mdt> queryPermissionSetAssignmentSettingByPermissionSet(List<String> specifiedQueryFieldAPINameList, Set<String> permissionSetAPINameSet) {
        try {
            return Database.query('SELECT ' + String.join(specifiedQueryFieldAPINameList, ',') + ' ' +
                                  'FROM Permission_Set_Assignment_Setting__mdt ' +
                                  'WHERE PermissionSet__c IN :permissionSetAPINameSet');
        } catch (Exception generalException) {
            throw new PermissionDataAccessServiceException(generalException.getMessage());
        }
    }
    
    /**
     * @description: Queries all Permission Set records - Used in LWC (Order By)
     * @param specifiedQueryFieldAPINameSet: queries all fields by default, or accepts a list of specified fields to include.
     * @return: List of all Permission Set records
     */
    public List<PermissionSet> queryAllPermissionSetRecords(List<String> specifiedQueryFieldAPINameList) {
        try {
            return Database.query('SELECT ' + String.join(specifiedQueryFieldAPINameList, ',') + ' ' +
                                  'FROM PermissionSet ' + 
                                  'WHERE IsOwnedByProfile = false ' +
                                  'ORDER BY Label');
        } catch(Exception generalException) {
            throw new PermissionDataAccessServiceException(generalException.getMessage());
        }
    }
    
    /**
     * @description: Queries all Permission Set Assignemnt Setting records
     * @param specifiedQueryFieldAPINameSet: queries all fields by default, or accepts a list of specified fields to include.
     * @return: List of all Permission Set Assignment Setting records
     */
    public List<Permission_Set_Assignment_Setting__mdt> queryAllPermissionSetAssignmentSettingRecords(List<String> specifiedQueryFieldAPINameList) {
        try {
            return Database.query('SELECT ' + String.join(specifiedQueryFieldAPINameList, ',') + ' ' +
                                  'FROM Permission_Set_Assignment_Setting__mdt');
        } catch (Exception generalException) {
            throw new PermissionDataAccessServiceException(generalException.getMessage());
        }
    }

    /**
     * @description: Querying for a specific Permission Set by API Name.
     * @param specifiedQueryFieldAPINameSet: queries all fields by default, or accepts a list of specified fields to include.
     * @param permissionSetName: the api name of the desired permission set
     * @return: Permission Set record mathcing API Name
     * @note: Throws an error if permission set does not exist
     * TODO: Combine this method with queryPermissionSetByApiName
     */
    public PermissionSet queryPermissionSetByName(List<String> specifiedQueryFieldAPINameList, String permissionSetName) {
        try {
            return Database.query('SELECT ' + String.join(specifiedQueryFieldAPINameList, ',') + ' ' +
                                  'FROM PermissionSet ' + 
                                  'WHERE Name = :permissionSetName ' +
                                  'LIMIT 1');
        } catch (Exception generalException) {
            throw new PermissionDataAccessServiceException(generalException.getMessage());
        }
    }

    /**
     * @description: Querying for permission set assignments 
     * @param specifiedQueryFieldAPINameSet: queries all fields by default, or accepts a list of specified fields to include.
     * @param permissionSetIds: set of Permission sets of interest
     * @param asigneeIdSet: Set of Users with potential Permission Set Assignments
     * @return: matching PermissionSetAssignments
     */
    public List<PermissionSetAssignment> queryPermissionSetAssignmentsByAsigneeId(List<String> specifiedQueryFieldAPINameList, Set<Id> permissionSetIds, Set<Id> asigneeIdSet) {
        try {
            return Database.query('SELECT ' + String.join(specifiedQueryFieldAPINameList, ',') + ' ' + 
                                  'FROM PermissionSetAssignment ' +
                                  'WHERE permissionSetId IN :permissionSetIds ' +
                                    'AND assigneeId IN :asigneeIdSet');
        } catch (Exception generalException) {
            throw new PermissionDataAccessServiceException(generalException.getMessage());
        }
    }

    /**
     * PermissionPermissionDataAccessServiceException
     * @description: Common exception class
     */
    class PermissionDataAccessServiceException extends Exception {}
}