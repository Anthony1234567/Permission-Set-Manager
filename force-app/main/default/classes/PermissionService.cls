/** 
 * PermissionService
 * @description: Service class for automating Permission Set Assignments
 * @author: Anthony Martinez
 */
public class PermissionService {
    // Data to process and how to process it
    final PermissionSet permissionSet;
    final Permission_Set_Assignment_Setting__mdt permissionSetAssignmentSetting;
    
    /**
     * @description: Queries the permission set as well as the corresponding 
     * 				 Permission Set Assignment Custom Metadata Type record.
     * 				 CMT record will have PermissionSet__c field populated with the
     * 				 API Name of the associated Permission Set.
     * @param permissionSetAssignmentSettingName: Name of the Permission Set assignment setting to process
     */
    public PermissionService(String permissionSetAssignmentSettingName) {
        if (String.isNotBlank(permissionSetAssignmentSettingName)) {
            // Query Permission Set along with all related assignment records 
            List<Permission_Set_Assignment_Setting__mdt> permissionSetAssignmentSettingList = [
                SELECT PermissionSet__c,
                    SOQL_Filter__c
                FROM Permission_Set_Assignment_Setting__mdt
                WHERE DeveloperName = :new Set<String>{ permissionSetAssignmentSettingName }
            ];
            List<PermissionSet> permissionSetWithAssignmentsList = [
                SELECT Label,
                    LicenseId, (
                        SELECT AssigneeId
                        FROM Assignments
                    )
                FROM PermissionSet
                WHERE IsOwnedByProfile = false AND 
                    Name IN :Utils.toFieldValueStringSet(Permission_Set_Assignment_Setting__mdt.PermissionSet__c, permissionSetAssignmentSettingList)
            ];
            
            if (!permissionSetWithAssignmentsList.isEmpty() && !permissionSetAssignmentSettingList.isEmpty()) {
                this.permissionSet = permissionSetWithAssignmentsList.get(0);
                this.permissionSetAssignmentSetting = permissionSetAssignmentSettingList.get(0);
            } else {
                throw new PermissionServiceException('Unable to process Permission Set Assignment setting record with the provided Name (' + permissionSetAssignmentSettingName + '). ' +
                                                     'Please ensure that there is both a Custom Metadata type and a corresponding Permission Set record to process associated via the PermissionSet__c field on the setting record.');
            }
        } else {
            throw new PermissionServiceException('No Permission Set setting to prcess. Please provide a valid Name for a Permission Set Assignment Setting (CMT).');
        }
    }
    
    /**
     * @description: Determines users that should be removed and added to a permissin set assignment based on
     * 				 the logic in the custom metadata record corresponding to the permission set.
     * @return: Instance of PermissionService
     */
    public PermissionService calculatePermissionSetAssignments() {
        String activeUserQueryFilter = String.isNotBlank(this.permissionSetAssignmentSetting.SOQL_Filter__c) ? 'AND (' + this.permissionSetAssignmentSetting.SOQL_Filter__c + ')' : '';
        // We have the current assigned list. Based on the current query filter, we will need
        // to build a list of users that should be added and a list of those to be removed.
        Map<Id, PermissionSetAssignment> userAssignmentAddMap = new Map<Id, PermissionSetAssignment>();
        Map<Id, PermissionSetAssignment> userAssignmentRemoveMap = new Map<Id, PermissionSetAssignment>();
        // Query users who are already assigned the Permission Set
        Set<Id> currentAssignmentUserIdSet = Utils.toFieldValueIdSet(PermissionSetAssignment.AssigneeId, this.permissionSet.Assignments);
        // Query users who should be assigned the Permission Set based on the custom filter
        // Ensure license Ids for User assignments match the Permission Set
        Set<Id> validAssignmentUserIdSet = Utils.toIdSet(
            Database.query(
                'SELECT Id ' +
                'FROM User ' +
                'WHERE IsActive = true ' + activeUserQueryFilter
            )
        );
        
        // Determine which users currently assigned the Permission Set do not meet the filter criteria
        for (PermissionSetAssignment assignment : this.permissionSet.Assignments) {
            if (!validAssignmentUserIdSet.contains(assignment.AssigneeId)) {
                // Arrange to be removed
                userAssignmentRemoveMap.put(assignment.AssigneeId, assignment);
            }
        }
        
        // Determine which of the users that qualify are currently not assigned the Permission Set
        for (Id userId : validAssignmentUserIdSet) {
            if (!currentAssignmentUserIdSet.contains(userId)) {
                PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
                    AssigneeId = userId,
                    PermissionSetId = this.permissionSet.Id
                );

                // Arrange to be added
                userAssignmentAddMap.put(userId, permissionSetAssignment);
            }
        }
        
        // Delete PSAs for users that should not have the Permission Set but currently do (allow partial)
        if (!userAssignmentRemoveMap.isEmpty()) {
            Database.delete(userAssignmentRemoveMap.values(), false);
        }
        
        // Insert PSAs for users that should have the Permission Set but currently don't (allow partial)
        if (!userAssignmentAddMap.isEmpty()) {
            Database.insert(userAssignmentAddMap.values(), false);
        }
        
        return this;
    }

    /**
     * PermissionServiceException
     * @description: Common exception class
     */
    public class PermissionServiceException extends Exception {}
}