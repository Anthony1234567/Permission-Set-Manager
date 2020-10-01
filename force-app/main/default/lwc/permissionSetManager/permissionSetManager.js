import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';

export default class PermissionSetManager extends LightningElement {
    @track permissionSetName;

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        registerListener('permissionSetSelected', this.handlePermissionSetSelected, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handlePermissionSetSelected(permissionSetName) {
        this.permissionSetName = permissionSetName;
    }
}