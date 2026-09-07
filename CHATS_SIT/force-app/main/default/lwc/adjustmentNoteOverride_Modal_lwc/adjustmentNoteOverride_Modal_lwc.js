import { api } from 'lwc';
import LightningModal from 'lightning/modal';

/**
 * Adjustment Note Override Modal - Thin wrapper component that extends LightningModal.
 * 
 * This component is a CONTAINER ONLY - all business logic lives in c-adjustment-note-override_lwc.
 * This pattern allows:
 * 1. Easy maintenance - logic in one place
 * 2. Reusability - standalone component can be used directly or in modal
 * 3. Consistent behavior - same logic regardless of context
 * 
 * Usage as Modal (programmatic):
 *   import AdjustmentNoteModal from 'c/adjustmentNoteOverride_Modal_lwc';
 *   const result = await AdjustmentNoteModal.open({
 *       size: 'large',
 *       recordId: this.recordId,
 *       objectApiName: 'T_ADJMT__c'
 *   });
 *   // result = { action: 'save', record: {...}, upsertedRecord: {...} } or { action: 'cancel' }
 * 
 * The embedded component handles all:
 * - Wire adapters for record data
 * - Form validation
 * - Server calls
 * - Toast notifications
 * 
 * Events from embedded component:
 * - save: Closes modal with success result
 * - close: Closes modal with cancel result
 */
export default class AdjustmentNoteOverride_Modal_lwc extends LightningModal {

    // ─── @api properties (passed when opening the modal) ─────────────────────────
    @api recordId;          // The record Id (Adjustment or Adjustment Note)
    @api objectApiName;     // The object API name (T_ADJMT__c or T_ADJMT_CMT__c)

    // ─── Getters ─────────────────────────────────────────────────────────────────

    /**
     * Returns the header label for the modal.
     * The embedded component handles CREATE NEW / EDIT distinction in its own header.
     */
    get modalLabel() {
        return 'Adjustment Note';
    }

    /**
     * Always true — tells the embedded component it is running inside the modal,
     * so the adjustment lookup field should be disabled (the record-id is already
     * known from the modal's @api recordId property).
     * Passed as a boolean binding so the strict equality check
     * `this.fromAdjustmentFlow === true` in adjustmentNoteOverride_lwc works correctly.
     */
    get isFromAdjustmentFlow() {
        return true;
    }

    // ─── Lifecycle ───────────────────────────────────────────────────────────────

    connectedCallback() {
        // Handle browser back button - close modal gracefully
        // Bind once and store reference so addEventListener/removeEventListener use the same instance
        this.handlePopState = this.handlePopState.bind(this);
        window.addEventListener('popstate', this.handlePopState);
    }

    disconnectedCallback() {
        // Clean up event listener using the same bound reference stored in connectedCallback
        window.removeEventListener('popstate', this.handlePopState);
        // Ensure modal closes properly on disconnect
        this.close({ action: 'cancel' });
    }

    handlePopState() {
        this.close({ action: 'cancel' });
        window.removeEventListener('popstate', this.handlePopState);
    }

    // ─── Event Handlers ──────────────────────────────────────────────────────────

    /**
     * Handles the save event from the embedded component.
     * Closes the modal with success result containing the saved record.
     * @param {CustomEvent} event - Contains detail: { record, upsertedRecord }
     */
    handleSave(event) {
        this.close({
            action: 'save',
            record: event.detail?.record,
            upsertedRecord: event.detail?.upsertedRecord
        });
    }

    /**
     * Handles the close event from the embedded component.
     * Closes the modal with cancel result.
     */
    handleClose() {
        this.close({ action: 'cancel' });
    }

    /**
     * Handles the Cancel button click in the modal footer.
     * Closes the modal with cancel result.
     */
    handleCancel() {
        this.close({ action: 'cancel' });
    }

    /**
     * Handles the Save button click in the modal footer.
     * Triggers the save action on the embedded component.
     */
    handleFooterSave() {
        // Get reference to the embedded component and call its handleFinish method
        const embeddedComponent = this.template.querySelector('c-adjustment-note-override_lwc');
        if (embeddedComponent) {
            embeddedComponent.handleFinish();
        }
    }
}