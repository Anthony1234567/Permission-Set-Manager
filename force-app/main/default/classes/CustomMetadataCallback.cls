/**
 * CustomMetadataCallback
 * @description: Handles callback logic for deploying custom metadata types. 
 *               Called from CustomMetadataService
 * 				 Source: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_interface_Metadata_DeployCallback.htm#apex_interface_Metadata_DeployCallback
 * @author: Anthony Martinez
 */
public class CustomMetadataCallback implements Metadata.DeployCallback {
    /**
     * @description: Handles results of deployment job
     * @param: result - Deployment result object
     * @param: context - context of deployment
     */
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            Set<String> permissionSetAssignmentSettingNameSet = new Set<String>(); 
            
            for (Metadata.DeployMessage successMessage : result.details.componentSuccesses) {
                if (successMessage.fullName.startsWith('Permission_Set_Assignment.')) {
                    permissionSetAssignmentSettingNameSet.add(successMessage.fullName.removeStart('Permission_Set_Assignment.'));
                }	
            }

            if (!permissionSetAssignmentSettingNameSet.isEmpty()) {
                // TODO: Uncomment
                // Database.executeBatch(new BatchManagePermissionSetAssignments(permissionSetAssignmentSettingNameSet), 1);
            }
        } else {
            // TODO: Send notification
        }
    }
}