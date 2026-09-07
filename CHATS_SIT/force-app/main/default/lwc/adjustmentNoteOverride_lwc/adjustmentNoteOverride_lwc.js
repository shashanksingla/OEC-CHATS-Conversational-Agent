import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { helper } from 'c/generic_Utilities';
import { getRecord } from 'lightning/uiRecordApi';
import { abs_helper } from 'c/abstract_Component';
import { label } from 'c/labelUtility';

// Object and field API names
const OBJ_API = 'T_ADJMT_CMT__c';
const FIELDS = [
    'T_ADJMT_CMT__c.Id',
    'T_ADJMT_CMT__c.Name',
    'T_ADJMT_CMT__c.IDN_ADJMT__c',
    'T_ADJMT_CMT__c.TXT_SUBJ__c',
    'T_ADJMT_CMT__c.TXT_CMT__c'
];

const ADJ_FIELDS = [
    'T_ADJMT__c.Id',
    'T_ADJMT__c.Name',
    'T_ADJMT__c.CDE_TYPE_ADJMT__c'
];

/**
 * Adjustment Note Override component - LWC replacement for Aura adjustmentNoteOverride.
 * Contains ALL business logic for creating/editing adjustment notes.
 * 
 * Can be used:
 * 1. Standalone - as a quick action or button override (uses NavigationMixin)
 * 2. Embedded in Modal - when fromAdjustmentFlow=true, dispatches events instead of navigating
 * 
 * Implements all functionality from Aura component:
 * - flexipage:availableForAllPageTypes
 * - force:hasRecordId
 * - force:hasSObjectName
 * - force:lightningQuickAction
 * - lightning:actionOverride
 * 
 * Events dispatched:
 * - close: When cancel is clicked (in modal context)
 * - save: When save is successful (in modal context), detail: { record, upsertedRecord }
 * 
 * Mirrors Aura component: adjustmentNoteOverride
 */
export default class AdjustmentNoteOverride_lwc extends NavigationMixin(LightningElement) {
    // ─── @api properties (passed from parent or from record context) ─────────────
    @api recordId;                      // From force:hasRecordId - the record Id
    @api objectApiName;                 // From force:hasSObjectName - the object API name
    @api fromAdjustmentFlow = false;    // Flag to indicate if opened from adjustment flow/modal

    // ─── @track properties ───────────────────────────────────────────────────────
    @track adjNoteRec = { sobjectType: OBJ_API, attributes: { type: OBJ_API } };
    @track noteRecordId;
    @track adjRec = { sobjectType: 'T_ADJMT__c', attributes: { type: 'T_ADJMT__c' }, Id: null, Name: null, CDE_TYPE_ADJMT__c: null };
    @track helpText;
    @track pageMessages = [];
    @track messageType = null;
    @track recordError = null;
    @track showSpinner = true;

    @track currentTabNumber = 1;

    // ─── Getters ─────────────────────────────────────────────────────────────────

    /**
     * Returns true if in create mode (no existing note Id)
     */
    get isCreateMode() {
        return !this.adjNoteRec?.Id;
    }

    /**
     * Returns the header mode label based on create/edit mode
     */
    get headerModeLabel() {
        return this.isCreateMode ? 'CREATE NEW' : 'EDIT';
    }

    /**
     * Returns true to show the form (always true in this component)
     */
    get showForm() {
        return true;
    }

    /**
     * Returns the adjustment note name for display
     */
    get adjNoteName() {
        return this.adjNoteRec?.Name || '';
    }

    /**
     * Getter to conditionally return adjNoteRec.IDN_ADJMT__c
     * Returns undefined if empty to prevent wire execution
     */
    get adjRecIdForWire() {
        return this.adjNoteRec?.IDN_ADJMT__c || undefined;
    }

    /**
     * Returns true if there are page messages to display
     */
    get hasPageMessages() {
        return this.pageMessages && this.pageMessages.length > 0;
    }

    /**
     * Returns true if the adjustment lookup should be disabled.
     * Disabled when opened from adjustment flow (adjustment is pre-selected).
     */
    get isAdjustmentLookupDisabled() {
        return !!this.fromAdjustmentFlow;
    }

    // ─── Wire Adapters ───────────────────────────────────────────────────────────

    /**
     * Wire adapter to fetch the adjustment note record when editing an existing note.
     * Only executes when noteRecordId returns a truthy value.
     * Mirrors Aura force:recordData for T_ADJMT_CMT__c
     */
    @wire(getRecord, { recordId: '$noteRecordId', fields: FIELDS })
    wiredAdjNoteRec({ error, data }) {
        if (data) {
            this.adjNoteRec = {
                sobjectType: OBJ_API,
                attributes: { type: OBJ_API },
                Id: data.id,
                Name: data.fields.Name.value,
                IDN_ADJMT__c: data.fields.IDN_ADJMT__c.value,
                TXT_SUBJ__c: data.fields.TXT_SUBJ__c.value,
                TXT_CMT__c: data.fields.TXT_CMT__c.value
            };
            this.setHelpTextFromAdj();
        } else if (error) {
            this.recordError = this.extractError(error);
            this.showSpinner = false;
        }
    }

    /**
     * Wire adapter to fetch the adjustment record for help text.
     * Only executes when adjRecIdForWire returns a truthy value.
     * Mirrors Aura force:recordData for T_ADJMT__c
     */
    @wire(getRecord, { recordId: '$adjRecIdForWire', fields: ADJ_FIELDS })
    wiredAdjRec({ error, data }) {
        if (data) {
            this.adjRec = {
                sobjectType: 'T_ADJMT__c',
                attributes: { type: 'T_ADJMT__c' },
                Id: data.id,
                Name: data.fields.Name.value,
                CDE_TYPE_ADJMT__c: data.fields.CDE_TYPE_ADJMT__c.value
            };
            this.setHelpTextFromAdj();
        } else if (error) {
            this.recordError = this.extractError(error);
            this.showSpinner = false;
        }
    }

    // ─── Lifecycle ───────────────────────────────────────────────────────────────

    /**
     * Lifecycle hook - initializes the component.
     * Mirrors Aura doInit controller method.
     * 
     * Logic from Aura:
     * - If sObjectName == 'T_ADJMT_CMT__c', set adjNoteRec.Id = recordId (editing existing note)
     * - Otherwise, set adjNoteRec.IDN_ADJMT__c = recordId (creating new note for adjustment)
     */
    connectedCallback() {
        // Align to Aura doInit: if launched on T_ADJMT_CMT__c, recordId is the note Id; 
        // else assume recordId is Adjustment Id
        if (this.objectApiName === 'T_ADJMT_CMT__c') {
            // Editing existing note - set noteRecordId to trigger wire
            this.noteRecordId = this.recordId;
        } else {
            // Creating new note for adjustment - set the adjustment lookup
            this.adjNoteRec = { ...this.adjNoteRec, IDN_ADJMT__c: this.recordId };
        }
        this.showSpinner = false;
    }

    // ─── Helper Methods ──────────────────────────────────────────────────────────

    /**
     * Sets the help text based on the adjustment type.
     * Mirrors Aura helper.doSetHelpText method.
     * Uses custom labels adjtNoteHelpTextClaim/Recovery when CDE_TYPE_ADJMT__c == '1' or '2'
     */
    setHelpTextFromAdj() {
        console.log('Setting help text based on adjustment record:', JSON.stringify(this.adjRec));
        let code = this.adjRec?.CDE_TYPE_ADJMT__c;
        if (code == '1') {
            this.helpText = label.adjtNoteHelpTextClaim;
        } else if (code == '2') {
            this.helpText = label.adjtNoteHelpTextRecovery;
        } else {
            this.helpText = null;
        }
        this.showSpinner = false;
        console.log('Help text set based on adjustment type:', this.helpText);
    }

    /**
     * Extracts error message from various error formats.
     */
    extractError(e) {
        if (Array.isArray(e?.body)) {
            return e.body.map(err => err.message).join('; ');
        }
        if (typeof e?.body?.message === 'string') {
            return e.body.message;
        }
        return e?.message || 'Unknown error';
    }

    // ─── Event Handlers ──────────────────────────────────────────────────────────

    /**
     * Handles adjustment lookup field change from customLookup_lwc.
     * Updates the adjNoteRec with the selected adjustment ID.
     * customLookup_lwc fires 'valueselected' event with detail.record containing the selected record.
     */
    handleAdjustmentChange(event) {
        const selectedRecord = event.detail?.record;
        const val = selectedRecord?.Id || null;
        this.adjNoteRec = { ...this.adjNoteRec, IDN_ADJMT__c: val };
        if (!val) {
            // Clear adjustment record and help text when no value selected
            this.adjRec = { sobjectType: 'T_ADJMT__c', attributes: { type: 'T_ADJMT__c' }, Id: null, Name: null, CDE_TYPE_ADJMT__c: null };
            this.setHelpTextFromAdj();
        } else {
            this.showSpinner = true;
        }
        // Wire adapter (wiredAdjRec) will automatically re-execute when adjRecIdForWire getter value changes
    }

    /**
     * Handles input field changes.
     * Updates the adjNoteRec with the new field value.
     */
    handleInputChange(event) {
        const field = event.target?.dataset?.field;
        const value = event.detail?.value;
        if (field) {
            this.adjNoteRec = { ...this.adjNoteRec, [field]: value };
        }
    }

    /**
     * Handles the Save/Finish button click.
     * Validates inputs, calls server to upsert the record.
     * Mirrors Aura helper.doFinish method.
     * 
     * Exposed as @api so parent modal can trigger save from its footer button.
     * 
     * Behavior:
     * - If fromAdjustmentFlow: dispatches 'save' event with record data
     * - Otherwise: redirects to the saved record using NavigationMixin
     */
    @api
    handleFinish() {
        // Validate required inputs like Aura helper.showHelpMessageIfInvalid
        const inputs = Array.from(this.template.querySelectorAll('lightning-input, lightning-textarea, c-custom-lookup_lwc'));
        let allValid = true;

        // Validate each input - mirrors Aura's reduce pattern for validation
        if (inputs && inputs.length > 0) {
            inputs.forEach((cmp) => {
                if (typeof cmp.reportValidity === 'function') {
                    const valid = cmp.reportValidity();
                    allValid = allValid && valid;
                }
            });
        }

        if (!allValid) {
            return;
        }

        this.showSpinner = true;
        this.pageMessages = [];
        this.messageType = null;

        // Build payload to mirror Aura helper -> upsertRecordsFinal
        const sObj = {
            sobjectType: OBJ_API,
            attributes: { type: OBJ_API },
            Id: this.adjNoteRec.Id || null,
            IDN_ADJMT__c: this.adjNoteRec.IDN_ADJMT__c,
            TXT_SUBJ__c: this.adjNoteRec.TXT_SUBJ__c,
            TXT_CMT__c: this.adjNoteRec.TXT_CMT__c
        };
        const params = {
            lstSObject: [sObj],
            isFinalStep: true
        };

        // Use abstract_Component's callServerAndHandleError pattern like Aura helper
        abs_helper.callServerAndHandleError(
            this,
            'GenericDataSaverApxCtrl',
            'upsertRecordsFinal',
            (result => {
                if (result.isSuccessful) {
                    // Merge returned record like Aura helper.merge(...)
                    const upserted = (result.objectData && result.objectData.upsertedRecords && result.objectData.upsertedRecords[0]) || null;
                    if (upserted) {
                        this.adjNoteRec = helper.merge(this.adjNoteRec, upserted);
                    }

                    // Behavior based on context - mirrors Aura helper.doFinish
                    if (this.fromAdjustmentFlow) {
                        // Mirror Aura: helper.fireToast("dismissible","success",...) fires BEFORE
                        // helper.closeModal(). Toast is dispatched while this component is still
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Adjustment Note created successfully.',
                                variant: 'success',
                                mode: 'dismissible'
                            })
                        );
                        // Then close the modal by dispatching the save event. Toast is handled by callServerAndHandleError
                        this.dispatchEvent(new CustomEvent('save', {
                            detail: {
                                record: this.adjNoteRec,
                                upsertedRecord: upserted
                            }
                        }));
                    } else {
                        // Not from adjustment flow: redirect to the record
                        // This mirrors Aura's helper.redirectToRecord behavior
                        const recordIdToNavigate = this.adjNoteRec.Id || (upserted && upserted.Id);
                        if (recordIdToNavigate) {
                            helper.navigateToRecord(this, recordIdToNavigate);
                        }
                    }
                } else {
                    // Handle error - show error messages
                    if (result.message) {
                        this.pageMessages = [...this.pageMessages, { id: 'error-1', message: result.message }];
                        this.messageType = 'error';
                    }
                }
                this.showSpinner = false;
            }).bind(this),
            JSON.stringify(params),
            'Adjustment Note Created Successfully'
        );
    }

    /**
     * Handles the Cancel button click.
     * Mirrors Aura helper.doCancel method.
     * 
     * Behavior:
     * - If fromAdjustmentFlow: dispatches 'close' event for parent modal to handle
     * - Otherwise: goes back in history (window.history.back())
     */
    handleCancel() {
        if (this.fromAdjustmentFlow) {
            // From adjustment flow/modal: dispatch close event for parent to handle
            // Mirrors Aura helper.closeModal which fires closeModal event
            this.dispatchEvent(new CustomEvent('close'));
        } else {
            // Not from adjustment flow: go back in history
            // Mirrors Aura's window.history.back()
            window.history.back();
        }
    }
}