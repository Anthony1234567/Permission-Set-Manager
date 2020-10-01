import { LightningElement, api, track } from 'lwc';

export default class IdmModal extends LightningElement {
    // Determines whether the close button icon 'X' is shown
    @api preventClose = false;

    @track isOpen = false; // Modal is closed by default

    /**
     * @description: Access readonly value of isOpen.
     *               Cannot define private setter in lwc so using 
     *               method as alternative
     */
    @api
    getIsOpen() {
        return this.isOpen;
    }

    /**
     * @description: Closes the modal
     */
    @api
    openModal() {
        this.isOpen = true;
        this.dispatchEvent(new CustomEvent('open'));
    }

    /**
     * @description: Closes the modal
     */
    @api
    closeModal() {
        this.isOpen = false;
        this.dispatchEvent(new CustomEvent('close'));
    }
}