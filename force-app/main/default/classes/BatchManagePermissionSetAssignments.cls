/**
 * BatchManagePermissionSetAssignments
 * @description Scheduled batch to maintain User assignments of Permission Sets. 
 *              Runs for Permission Set Assignment Settings where Persist? is true
 *              Implements both batch and corresponding schedulable
 * @author Anthony Martinez
 * NOTE: In order to use as much existing logic this batch should be run with size 1 to avoid hitting limits
 *       Also, due to the nature of Custom Metadata Types, (cannot be built in test context) an apex test class/methods
 *       cannot be built to test this batch class since it takes CMT data that exists in the org and runs the batch on it.
 *       Since this batch runs on ALL CMT with a Persist? value of true we will run into the following error message
 *       'System.UnexpectedException: No more than one executeBatch can be called from within a test method.  
 *        Please make sure the iterable returned from your start method matches the batch size, resulting in one executeBatch invocation.'
 */
public class BatchManagePermissionSetAssignments implements Schedulable, Database.Batchable<SObject>, Database.Stateful {
    Set<String> permissionSetAssignmentSettingNameSet = new Set<String>(); 

    /**
     * @description: Default constructor - Results in a full Permission Set Assignment persist job 
     */
    public BatchManagePermissionSetAssignments() {}

    /**
     * @description: Constructor - used to specify Permission Sets to run on
     */
    public BatchManagePermissionSetAssignments(Set<String> permissionSetAssignmentSettingNameSet) {
        this.permissionSetAssignmentSettingNameSet = permissionSetAssignmentSettingNameSet;
    }

    /**
     * Schedulable
     */

    /**
     * @description: Schedules a batch to run nightly for maintaining Permission Set Assignments
     * Execute Anonymous - System.schedule('Permission Set Assignment Persist Batch', '0 0 2 * * ?', new BatchManagePermSetAssignSchedulable());
     */
    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(new BatchManagePermissionSetAssignments(), 1);
    }
    
    /**
     * Batchable
     */

    /**
     * @description: Queries the permission set assignments that will be processed
     * @param: BC - for tracking job progress/status
     * @return: Database.Querylocator used for tracking job progress
     */
    public Database.Querylocator start(Database.BatchableContext batchableContext) {
        return Database.getQueryLocator([
            SELECT DeveloperName 
            FROM Permission_Set_Assignment_Setting__mdt
        ]);
    }
    
    /**
     * @description: Queries the permission set assignments by name that will be processed
     * @param: BC - for tracking job progress/status
     * @param: permissionSetAssignmentSettingList - List of permission set setting records to process
     */
    public void execute(Database.BatchableContext batchableContext, List<Permission_Set_Assignment_Setting__mdt> permissionSetAssignmentSettingList) {
        List<PermissionSetAssignment> updatedPermissionSetAssignments = new List<PermissionSetAssignment>();

        for (Permission_Set_Assignment_Setting__mdt permissionSetAssignmentSetting : permissionSetAssignmentSettingList) {
            PermissionService permissionService = new PermissionService(permissionSetAssignmentSetting.DeveloperName)
                .calculatePermissionSetAssignments();
        }
    }
    
    /**
     * @description: Does nothing
     * @param: BC - for tracking job progress/status
     */
    public void finish(Database.BatchableContext batchableContext) {}
}