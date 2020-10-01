import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';

import getPermissionSet from '@salesforce/apex/PermissionSetAssignmentManagerController.getPermissionSet';

export default class PermissionSetDetail extends LightningElement {
    @track permissionSet;
    @track isLoading = false;

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        registerListener('permissionSetSelected', this.handlePermissionSetSelected, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handlePermissionSetSelected(permissionSetName) {
        if (!this.permissionSet || this.permissionSet.name !== permissionSetName) {
            this.isLoading = true;
            
            getPermissionSet({
                permissionSetName: permissionSetName
            }).then(permissionSet => {
                this.permissionSet = permissionSet;
            }).catch(error => {
                console.error('Error', error);
            }).finally(() => {
                this.isLoading = false;
            });
        }
    }
}