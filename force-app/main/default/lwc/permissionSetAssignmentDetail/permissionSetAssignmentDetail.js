import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getPermissionSet from '@salesforce/apex/PermissionSetAssignmentManagerController.getPermissionSet';
import getPermissionSetAssignmentSetting from '@salesforce/apex/PermissionSetAssignmentManagerController.getPermissionSetAssignmentSetting';
import validateQueryFilter from '@salesforce/apex/PermissionSetAssignmentManagerController.validateQueryFilter';
import upsertPermissionSetAssignmentSettingRecord from '@salesforce/apex/PermissionSetAssignmentManagerController.upsertPermissionSetAssignmentSettingRecord';

export default class PermissionSetAssignmentDetail extends LightningElement {
    @api 
    get permissionSetName() {
        return this._permissionSetName;
    } set permissionSetName(permissionSetName) {
        if (permissionSetName && this._permissionSetName !== permissionSetName) {
            this._permissionSetName = permissionSetName;
            this.isLoading = true;

            Promise.all([
                getPermissionSet({ permissionSetName: this._permissionSetName }),
                getPermissionSetAssignmentSetting({ permissionSetName: this._permissionSetName })
            ]).then(([ permissionSet, permissionSetAssignmentSetting ]) => {
                this.permissionSet = permissionSet;
                this.permissionSetAssignmentSetting = permissionSetAssignmentSetting;

                // Setup the modal contents here
                this.permissionSetAssignmentSettingToUpsert = this.permissionSetAssignmentSetting;

                if (!this.permissionSetAssignmentSettingToUpsert) {
                    this.permissionSetAssignmentSettingToUpsert = {
                        PermissionSet__c: this.permissionSet.name,
                        SOQL_Filter__c: ''
                    };
                }
            }).catch(error => {
                console.error('Error', error);
            }).finally(() => {
                this.isLoading = false;
                this.error = undefined;
            });
        }
    }

    @track isLoading = false;
    @track error;
    @track permissionSet; // Modal header (Permission Set label)
    @track permissionSetAssignmentSetting; 
    @track permissionSetAssignmentSettingToUpsert; // Component capable of insert/update via apex matadata class

    get isEmptyState() {
        // Once a permission set has been passed in and the query returned, if there is no assignment setting
        // the user will be given an option to create one 
        return this.permissionSetName && !this.isLoading && !this.permissionSetAssignmentSetting;
    }

    /**
     * @description: Click event handler
     * @param {*} event 
     */
    handleClick(event) {
        switch(event.target.name) {
            case 'manageAssignmentsEdit':
            case 'manageAssignmentsNew':
                this.template.querySelector('c-modal').openModal();
                break;
            case 'save':
                validateQueryFilter({ 
                    userProvidedQueryFilterInput: this.permissionSetAssignmentSettingToUpsert.SOQL_Filter__c 
                }).then(() => {
                    return upsertPermissionSetAssignmentSettingRecord({ permissionSetAssignmentRecordToUpsert: this.permissionSetAssignmentSettingToUpsert });
                }).then(() => {
                    this.error = undefined;
                    this.template.querySelector('c-modal').closeModal();
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Permission Set Assignment Setting save enqueued successfully.',
                        variant: 'success'
                    }));
                }).catch(error => {
                    this.error = error.body.message;
                });

                break;
            case 'cancel':
                this.template.querySelector('c-modal').closeModal();
                break;
            default:
                console.warn('Unexpected click type.');
        }
    }

    /**
     * @description: Change event handler
     * @param {*} event 
     */
    handleChange(event) {
        switch(event.target.name) {
            case 'userCriteria':
                this.permissionSetAssignmentSettingToUpsert.SOQL_Filter__c = event.target.value;
                break;
            default:
                console.warn('Unexpected change type.');
        }
    }
}