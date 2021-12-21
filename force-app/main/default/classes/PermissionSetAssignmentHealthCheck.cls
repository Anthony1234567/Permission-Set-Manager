/**
 * PermissionSetAssignmentManagerHealthCheck
 * @description: Health check tests for the PSA Manager tool
 * @author: Anthony Martinez
 */
@IsTest(SeeAllData=true)
class PermissionSetAssignmentHealthCheck {
    static final List<Permission_Set_Assignment_Setting__mdt> allPermissionSetAssignmentSettings = [
        SELECT MasterLabel,
            DeveloperName,
            PermissionSet__c,
            SOQL_Filter__c
        FROM Permission_Set_Assignment_Setting__mdt
    ];

    // Health check thresholds - BatchManagePermissionSetAssignments runs periodically to 
    // maintain user assignments but users can be updated to meet or fall outside of the matching
    // criteria between runs. If this runs after users have been updated but before the batch gets a 
    // chance to keep up assignments, accuracy will drop below 100
    static final Integer ASSIGNMENT_ACCURACY_THRESHOLD = 80;

    /**
     * @description: Runs through all PSA setting CMT records and performs a query against the set of users who it should be assigned to
     *               Each PSA assignment set should not fall below accuracy threshold 
     */
    @IsTest
    static void checkAssignmentAccuracy() {
        Double averageAccuracy = 0;
        Map<String, SObject> allPermissionSetAssignmentSettingsByPermissionSetMap = Utils.toFieldValueStringMapUnique(Permission_Set_Assignment_Setting__mdt.PermissionSet__c, 
                                                                                                                      allPermissionSetAssignmentSettings);
        List<AggregateResult> managedPermissionSetAssignmentCounts = [
            SELECT COUNT(Id) assignedCount,
                PermissionSet.Name permissionSetName,
                PermissionSet.LicenseId licenseId
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name IN :Utils.toFieldValueStringSet(Permission_Set_Assignment_Setting__mdt.PermissionSet__c, PermissionSetAssignmentHealthCheck.allPermissionSetAssignmentSettings)
            GROUP BY PermissionSet.Name, 
                PermissionSet.LicenseId
        ];

        for (AggregateResult managedPermissionSetAssignmentCount : managedPermissionSetAssignmentCounts) {
            Permission_Set_Assignment_Setting__mdt permissionSetAssignmentSetting = (Permission_Set_Assignment_Setting__mdt) allPermissionSetAssignmentSettingsByPermissionSetMap.get((String) managedPermissionSetAssignmentCount.get('permissionSetName'));
            String activeUserQueryFilter = String.isNotBlank(permissionSetAssignmentSetting.SOQL_Filter__c) ? 'AND (' + permissionSetAssignmentSetting.SOQL_Filter__c + ')' : '';
            Integer expectedAssignedCount = Database.query(
                'SELECT Id ' +
                'FROM User ' +
                'WHERE IsActive = true ' + activeUserQueryFilter
            ).size();
            Integer userAssignmentCountDiscrepancy = Math.abs(expectedAssignedCount - (Integer) managedPermissionSetAssignmentCount.get('assignedCount'));
            Decimal assignmentAccuracy = 1 - ((Decimal) userAssignmentCountDiscrepancy / (Decimal) expectedAssignedCount);

            averageAccuracy += assignmentAccuracy * 100;
        }

        averageAccuracy /= allPermissionSetAssignmentSettingsByPermissionSetMap.size();
        
        System.assert(averageAccuracy >= ASSIGNMENT_ACCURACY_THRESHOLD, 'Average Permission Set Assignment accuracy is below threshold please run BatchManagePermissionSetAssignments more frequently to keep these metrics up: ' +
                                                                        'Threshold: ' + ASSIGNMENT_ACCURACY_THRESHOLD + ', ' +
                                                                        'Average Accuracy: ' + averageAccuracy);
    }

    /**
     * @description: Runs through all PSA setting CMT records and performs a query against the Permission Sets
     *               specified in the setting. Validate each PSA is associated to an actual Permission Set
     */
    @IsTest
    static void checkExistanceOfPermissionSets() {
        Map<String, String> psaLabelToNonExistingPermissionSetMap = new Map<String, String>();
        Set<String> allPermissionSetNamesSet = Utils.toFieldValueStringSet(
            PermissionSet.Name, 
            [
                SELECT Name
                FROM PermissionSet
            ]
        );

        for (Permission_Set_Assignment_Setting__mdt permissionSetAssignmentSetting : PermissionSetAssignmentHealthCheck.allPermissionSetAssignmentSettings) {
            if (!allPermissionSetNamesSet.contains(permissionSetAssignmentSetting.PermissionSet__c)) {
                psaLabelToNonExistingPermissionSetMap.put(permissionSetAssignmentSetting.MasterLabel, permissionSetAssignmentSetting.PermissionSet__c);
            }
        }                                                 
        
        System.assert(psaLabelToNonExistingPermissionSetMap.isEmpty(), 'The following PSA Setting records point to a Permission Set that does not exist. ' +
                                                                       'Please ensure that each Permission Set Assignment Setting CMT is associated to an existing Permission Set: ' + 
                                                                       psaLabelToNonExistingPermissionSetMap);
    }
}