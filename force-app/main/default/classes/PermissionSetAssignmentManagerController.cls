/**
 * PermissionSetAssignmentManagerController
 * description: Server side controller for Permission Set Assignment Manager Lightning Component
 * @author: Anthony Martinez
 */
public class PermissionSetAssignmentManagerController {
    /**
     * @description: Validates the user provided Query Filter input by running the query used to assign Permission Sets
     *               before the setting CMT record is upserted so we can catch any query exceptions and display them to the user
     * @param userProvidedQueryFilterInput: User input for 'Query Filter' field
     * @return: Query Exception error message (if any) or a null value if there are no syntax errors in the query filter string
     */
    @AuraEnabled(cacheable=true)
    public static void validateQueryFilter(String userProvidedQueryFilterInput) {
        try {
            String activeUserQueryFilter = String.isNotBlank(userProvidedQueryFilterInput) ? 'AND (' + userProvidedQueryFilterInput + ')' : '';

            Database.query(
                'SELECT Id ' +
                'FROM User ' +
                'WHERE IsActive = true ' + activeUserQueryFilter
            );
        } catch (Exception caughtException) {
            throw new AuraHandledException(caughtException.getMessage());
        }
    }
    
    /**
     * @description: Upserts 'deploys' Permission Set Assignment Setting CMT records. Deploy triggers the CustomMetadataCallback class which fires the batch to actually manage assignments
     * @param permissionSetAssignmentRecordToUpsertList: Permission Set Assignment record that will be upserted
     * @param permissionSetRecordToInsert: optional new permission set record to insert and assign per the SOQL filter (optional - null means no new perm set is to be created)
     * @return: Deployment Id for enqueued metadata deployment job
     */
    @AuraEnabled
    public static Id upsertPermissionSetAssignmentSettingRecord(Permission_Set_Assignment_Setting__mdt permissionSetAssignmentRecordToUpsert) {
        try {
            if (String.isBlank(permissionSetAssignmentRecordToUpsert.DeveloperName)) {
                String hexIdentifier = Utils.generateRandomHexString(36);

                // PSA Developer Names must be unique. Since the corresponding permission set can have an API name
                // longer than 40 characters, the Developer Name of the setting must be set to random value to avoid name collision
                permissionSetAssignmentRecordToUpsert.MasterLabel = 'PSA-' + hexIdentifier;
                permissionSetAssignmentRecordToUpsert.DeveloperName = 'PSA_' + hexIdentifier;
            }

            return new CustomMetadataService().deploy(permissionSetAssignmentRecordToUpsert);
        } catch (Exception caughtException) {
            throw new AuraHandledException(caughtException.getMessage());
        }
    }

    /**
     * @description: Queries for all Permission Sets and assignment CMT records to determine which Permission Sets
     *               have managed assignment
     * @return: List of all permission sets along with their managed status (whether or not they have a corresponding CMT record)
     */
    @AuraEnabled(cacheable=true)
    public static List<PermissionSetModel> getPermissionSets() {
        try {
            List<PermissionSetModel> permissionSetListItems = new List<PermissionSetModel>();
            List<PermissionSet> allPermissionSets = [
                SELECT Description,
                    Label,
                    Name
                FROM PermissionSet
                WHERE IsOwnedByProfile = false
                ORDER BY Label
            ];
            // Managed Permission Sets
            List<Permission_Set_Assignment_Setting__mdt> allPermissionSetAssignmentSettings = [
                SELECT PermissionSet__c
                FROM Permission_Set_Assignment_Setting__mdt
            ];
            Set<String> managedPermissionSetNameSet = Utils.toFieldValueStringSet(Permission_Set_Assignment_Setting__mdt.PermissionSet__c, allPermissionSetAssignmentSettings);
    
            for (PermissionSet permissionSet : allPermissionSets) {
                PermissionSetModel permissionSetListItem = new PermissionSetModel(permissionSet);
                permissionSetListItem.isManaged = managedPermissionSetNameSet.contains(permissionSet.Name);
                permissionSetListItems.add(permissionSetListItem);
            }
    
            return permissionSetListItems;
        } catch (Exception caughtException) {
            throw new AuraHandledException(caughtException.getMessage());
        }
    }

    /**
     * @description: Queries for a single Permission Set by Name. Not made cacheable because there are issuses with 
     *               Promise.finally in the js
     * @param permissionSetName: API Name of Permission Set to query
     * @return: Permission Set corresponding to the passed in Name
     */
    @AuraEnabled(cacheable=true)
    public static PermissionSetModel getPermissionSet(String permissionSetName) {
        try {
            return new PermissionSetModel([
                SELECT Description,
                    Label,
                    Name
                FROM PermissionSet
                WHERE Name = :permissionSetName
                LIMIT 1
            ]);
        } catch (Exception caughtException) {
            throw new AuraHandledException(caughtException.getMessage());
        }
    }

    /**
     * @description: Queries for a single Permission Set assignment setting by its corresponding Permission Set's API Name. 
     *               Not made cacheable because there are issuses with Promise.finally in the js
     * @param permissionSetName: API Name of Permission Set used to query PSA record
     * @return: Permission Set corresponding to the passed in Permission Set API Name
     */
    @AuraEnabled
    public static Permission_Set_Assignment_Setting__mdt getPermissionSetAssignmentSetting(String permissionSetName) {
        try {
            List<Permission_Set_Assignment_Setting__mdt> matchingPermissionSetAssignmentSettingsList = [
                SELECT DeveloperName,
                    MasterLabel,
                    PermissionSet__c,
                    SOQL_Filter__c
                FROM Permission_Set_Assignment_Setting__mdt
                WHERE PermissionSet__c = :permissionSetName
                LIMIT 1
            ];

            return matchingPermissionSetAssignmentSettingsList.isEmpty() ? null : matchingPermissionSetAssignmentSettingsList.get(0);
        } catch (Exception caughtException) {
            throw new AuraHandledException(caughtException.getTypeName() + ': ' + caughtException.getMessage());
        }
    }

    /**
     * PermissionSetModel
     * @description: Model for describing a permission set for use in a list view
     */
    public class PermissionSetModel {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String href;
        @AuraEnabled
        public Boolean isManaged = false;

        /**
         * @description: Constructor
         * @param permissionSet: Record with managed status in question
         */
        public PermissionSetModel(PermissionSet permissionSet) {
            this.id = permissionSet.Id;
            this.label = permissionSet.Label;
            this.name = permissionSet.Name;
            this.description = permissionSet.Description;
            this.href = '/' + permissionSet.Id;
        }
    }
}