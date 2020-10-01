/** 
 * PermissionService
 * @description: Service class for automating Permission Set Assignments
 * @author: Anthony Martinez
 */
public class PermissionService {
    // Data to process and how to process it
    final PermissionSet permissionSet;
    final Permission_Set_Assignment_Setting__mdt permissionSetAssignmentSetting;
    
    public List<PermissionSetAssignment> assignmentsToUpdate = new List<PermissionSetAssignment>();
    public List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
    public List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>();

    /**
     * PermissionServiceException
     * @description: Common exception class
     */
    public class PermissionServiceException extends Exception {}
    
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
            List<Permission_Set_Assignment_Setting__mdt> permissionSetAssignmentSettingList = new PermissionDataAccessService()
                .queryPermissionSetAssignmentSettingsByName(new List<String>{ 'SOQL_Filter__c', 
                                                                              'PermissionSet__c' }, 
                                                            new Set<String>{ permissionSetAssignmentSettingName }); 
            List<PermissionSet> permissionSetWithAssignmentsList = new PermissionDataAccessService()
                .queryPermissionSetAndAssignmentsByName(new List<String>{'Label',
                                                                         'LicenseId'}, 
                                                        Utils.castStringSet(Utils.toFieldValueObjectSet(Permission_Set_Assignment_Setting__mdt.PermissionSet__c, 
                                                                                                        permissionSetAssignmentSettingList)));
            
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
        // We have the current assigned list. Based on the current query filter, we will need
        // to build a list of users that should be added and a list of those to be removed.
        Map<Id, PermissionSetAssignment> userAssignmentAddMap = new Map<Id, PermissionSetAssignment>();
        Map<Id, PermissionSetAssignment> userAssignmentRemoveMap = new Map<Id, PermissionSetAssignment>();
        // Query users who are already assigned the Permission Set
        Set<Id> currentAssignmentUserIdSet = Utils.castIdSet(Utils.toFieldValueObjectSet(PermissionSetAssignment.AssigneeId, 
                                                                                         this.permissionSet.Assignments));
        // Query users who should be assigned the Permission Set based on the custom filter
        // FB 278407: Ensure license Ids for User assignments match the Permission Set
        Set<Id> validAssignmentUserIdSet = Utils.toIdSet(new UserDataAccessService()
            .queryActiveUserRecordsCustomFilter(new List<String>{ 'Id' }, 
                                                this.permissionSetAssignmentSetting.SOQL_Filter__c));
        
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
                // Arrange to be added
                userAssignmentAddMap.put(userId, 
                                         new PermissionSetAssignment(AssigneeId = userId,
                                                                     PermissionSetId = this.permissionSet.Id));
            }
        }
        
        // Delete PSAs for users that should not have the Permission Set but currently do (allow partial)
        if (!userAssignmentRemoveMap.isEmpty()) {
            this.assignmentsToUpdate.addAll(userAssignmentRemoveMap.values());
            this.deleteResults.addAll(Database.delete(userAssignmentRemoveMap.values(), false));
        }
        
        // Insert PSAs for users that should have the Permission Set but currently don't (allow partial)
        if (!userAssignmentAddMap.isEmpty()) {
            this.assignmentsToUpdate.addAll(userAssignmentAddMap.values());
            // Depending on their license type, users may or may not be able to be assigned to permission sets.
            this.saveResults.addAll(Database.insert(userAssignmentAddMap.values(), false));
        }
        
        return this;
    }
}