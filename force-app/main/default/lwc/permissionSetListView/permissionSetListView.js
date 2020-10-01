import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

import getPermissionSets from '@salesforce/apex/PermissionSetAssignmentManagerController.getPermissionSets';

export default class PermissionSetListView extends LightningElement {
    @track permissionSets;
    @track displayedPermissionSets;
    @track selectedPermissionSet;
    @track searchKey = '';
    @track listView = 'All_Permission_Sets'

    listViewOptions = [
        { value: 'All_Permission_Sets', label: 'All Permission Sets' },
        { value: 'Managed', label: 'Managed' },
        { value: 'Unmanaged', label: 'Unmanaged' }
    ];

    @wire(CurrentPageReference) pageRef;

    @wire(getPermissionSets)
    getPermissionSets({ error, data }) {
        if (data) {
            this.permissionSets = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.permissionSets = undefined;
        }

        this.setDisplayedPermissionSets(this.permissionSets);
    }

    /**
     * @description: Click Event handler. Bubbles event up to parent for selected Permission Set
     * @param {*} event 
     */
    handleClick(event) {
        // Fire permissionSetSelected event
        fireEvent(this.pageRef, 'permissionSetSelected', event.currentTarget.dataset.permissionSetName);
    }

    /**
     * @description: Change event handler
     * @param {*} event 
     */
    handleChange(event) {
        switch (event.target.name) {
            case 'listView':
                this.listView = event.detail.value;
                break;
            case 'permissionSetSearch':
                this.searchKey = event.target.value;
                break;
            default:
                console.warn('Unexpected change type', event.currentTarget.dataset.source);
        }

        this.setDisplayedPermissionSets(this.permissionSets.filter(permissionSet => {
            // Escape special characters here
            const containsSearchKey = new RegExp(this.searchKey.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), 'i').test(permissionSet.label);

            switch (this.listView) {
                case 'All_Permission_Sets':
                    return containsSearchKey;
                case 'Managed':
                    return permissionSet.isManaged && containsSearchKey;
                case 'Unmanaged':
                    return !permissionSet.isManaged && containsSearchKey;
                default:
                    console.warn('Unexpected list view selected', this.listView);
            }
        }));
    }

    /**
     * @description: Sets the tracked property displayedPermissionSets to either the 
     *  set of permission sets that should be displayed or an null (used to display empty message)
     * @param {*} displayedPermissionSets 
     */
    setDisplayedPermissionSets(displayedPermissionSets) {
        if (displayedPermissionSets === undefined || displayedPermissionSets.length == 0) {
            this.displayedPermissionSets = undefined;
        } else {
            this.displayedPermissionSets = displayedPermissionSets;
        }
    }
}