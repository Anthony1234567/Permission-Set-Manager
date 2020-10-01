/**
 * CustomMetadataService
 * @description: Handles enqueue deployment logic for deploying/updating custom metadata types.
 * 				 Does this by casting SObject (SObjectType ends in '__mdt') into an instance of 
 * 				 CustomMetadataType (private sub class of CustomMetadataService) and performs 
 * 				 validation/mutates the data to be used with the Metadata API. Works with all 
 * 				 custom metadata types.
 * 				 Result handling in CustomMetadataCallback.cls
 * 				 Winter '19 update brings the ability to instantiate Custom Metadata Types in Apex.
 * 				    Source: https://releasenotes.docs.salesforce.com/en-us/winter19/release-notes/rn_forcecom_development_custom_metadata_types_apex.htm
 * @author: Anthony Martinez
 */
public class CustomMetadataService {
    /**
     * @description: Handles creation/deployment of Custom Metadata records. Calls on bulk deploy method.
     * @param customMetadataTypeRecord: Single metadata type record (SObjectType ends in '__mdt')
     * @return: Job Id for enqueued deployment job.
     */
    public Id deploy(SObject customMetadataTypeRecord) {
        return deploy(customMetadataTypeRecord == null ? null : new List<SObject>{customMetadataTypeRecord});
    }
    
    /**
     * @description: Handles creation/deployment of Custom Metadata records. 
     * 				 Currently these need to be enqueued as DML operations aren’t 
     * 				 allowed on custom metadata so DML operations need to be done 
     * 				 through Metadata API.
	 * 				 Source - https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Metadata_Operations.htm
     * @param customMetadataTypeRecordList: List of custom metadata type records (SObjectType for each element ends in '__mdt')
     * @return: Job Id for enqueued deployment job. Passing in an empty list returns null. Passing in null throws exception.
     */
    public Id deploy(List<SObject> customMetadataTypeRecordList) {
        Id deploymentId;
        
        try {
            Metadata.DeployContainer metadataDeployContainer = new Metadata.DeployContainer();
			
            for (SObject customMetadataTypeRecord : customMetadataTypeRecordList) {
                // Validate that the required fields 'DeveloperName' and 'MasterLabel' are set
                CustomMetadataType genericCustomMetadataType = new CustomMetadataType(customMetadataTypeRecord);
                
                // Set up custom metadata to be created in the subscriber org.
                Metadata.CustomMetadata customMetadataRecordToDeploy =  new Metadata.CustomMetadata();
                // Limit to 40 otherwise will return an error in the callback
                customMetadataRecordToDeploy.fullName = genericCustomMetadataType.fullName;
                customMetadataRecordToDeploy.label = genericCustomMetadataType.masterLabel;
                
                // Iterate over all custom fields
                for (String field : genericCustomMetadataType.fieldValueMap.keySet()) {
                    Metadata.CustomMetadataValue fieldValue = new Metadata.CustomMetadataValue();
                    fieldValue.field = field;
            		fieldValue.value = genericCustomMetadataType.fieldValueMap.get(field);
                    customMetadataRecordToDeploy.values.add(fieldValue);
                }
                
                metadataDeployContainer.addMetadata(customMetadataRecordToDeploy);
            }
            
            // Enqueue custom metadata deployment
            if (!metadataDeployContainer.getMetadata().isEmpty()) {
            	deploymentId = Metadata.Operations.enqueueDeployment(metadataDeployContainer, new CustomMetadataCallback());
            }
        } catch (Exception caughtException) {
            throw new CustomMetadataServiceException(caughtException.getMessage() + ' - ' + caughtException.getStackTraceString());
        }
        
        return deploymentId;
    }
    
    /**
     * CustomMetadataServiceException
     * @description: Common exception class
     */
    class CustomMetadataServiceException extends Exception {}
    
    /**
     * CustomMetadataType
     * @description: Class representation of generic Custom Metadata types.
     * 				(Similar to SObjects in functionality)
     * 				For CMT, the DeveloperName is used for identifying a record. (Id is not used for this)
     * 				Deploying a record to an org where this name already exists will result in an update 
     */
    class CustomMetadataType {
        // NOT API Name (i.e. Without __mdt)
        String objectName {
            get;
            set {
                this.objectName = value.removeEndIgnoreCase('__mdt');
        	}
        } 

        // There is a 40 character limit on DeveloperName and Label (SFDC)
        String developerName {
            get;
            set {
                this.developerName = (value == null ? '' : value.left(40));
        	}
        }
        
        String masterLabel {
            get;
            set {
                this.masterLabel = (value == null ? '' : value.left(40));
        	}
        }
        
        // Private inner class property. Internal use only.
        String fullName {
            get {
                return this.objectName + '.' + this.developerName;
        	}
        }
        
        // Maps {API Name => Field Value}
        Map<String, Object> fieldValueMap {
            get {
                Map<String, Object> mutatedFieldValueMap = this.fieldValueMap.clone();
                mutatedFieldValueMap.remove('Id');
                mutatedFieldValueMap.remove('DeveloperName');
                mutatedFieldValueMap.remove('MasterLabel');
                
                return mutatedFieldValueMap;
        	}
            set;
        }
        
        /**
         * @description: Constructor - Fitted to take a CMT Record. Calls on full constructor
         * @param objectName: Object Name for specific CMT or API Name (without trailing __mdt)
         * @param developerName: DeveloperName for specific CMT record
         * @param label: Human readable
         */
        CustomMetadataType(SObject customMetadataType) {
            if (customMetadataType.getSObjectType().getDescribe().getName().endsWithIgnoreCase('__mdt')) {
                this(customMetadataType.getSObjectType().getDescribe().getName(), 
                     (String)customMetadataType.get('DeveloperName'), 
                     (String)customMetadataType.get('MasterLabel'), 
                     customMetadataType.getPopulatedFieldsAsMap());
            } else {
                throw new CustomMetadataServiceException('Could not cast the following SObject to CustomMetadataType. ' + customMetadataType);
            }
        }
        
		/**
         * @description: Constructor
         * @param objectName: Object Name for specific CMT or API Name (without trailing __mdt)
         * @param developerName: DeveloperName for specific CMT record
         * @param label: Human readable
         * @param fieldValueMap: field value map
         */
        CustomMetadataType(String objectName, String developerName, String masterLabel, Map<String, Object> fieldValueMap) {
            if (!String.isBlank(objectName)) {
                this.objectName = objectName;
            } else {
                throw new CustomMetadataServiceException('Please specify the Custom Metadata Type\'s ObjectName. ' + this);
            }
            
            if (!String.isBlank(developerName)) {
                this.developerName = developerName;
            } else {
                throw new CustomMetadataServiceException('DeveloperName is required. ' + this);
            }
            
            if (!String.isBlank(masterLabel)) {
                this.masterLabel = masterLabel;
            } else {
                throw new CustomMetadataServiceException('Label is required. ' + this);
            }
            
            this.fieldValueMap = (fieldValueMap == null ? new Map<String, Object>() : new Map<String, Object>(fieldValueMap));
        }
    }
}