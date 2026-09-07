import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { helper } from 'c/generic_Utilities';
import DTE_INIT_CANCEL_FIELD from '@salesforce/schema/T_ADJMT__c.DTE_INIT_CANCEL__c';
import CDE_STATUS_FIELD from '@salesforce/schema/T_ADJMT__c.CDE_STATUS_ADJMT__c';

export default class AdjustmentRecoveryCancellation_LWC extends NavigationMixin(LightningElement) {

    @api recordId;
    @api sObjectName;
    @api modalRef;

    adjCancellationRecord = {};
    adjRecord = {};
    @track isAdmin = false;
    @track recordError = [];
    @track messageType = '';
    @track showConfirmDialog = false;
    @track warningAccepted = false;
    @track showSpinner = false;
    @track action = ''; 
    @track submitStatus = '1';
    _pendingStatus = null;


    reminderMsg = 'Please create a Cancellation Note to document Cancellation record updates.';
    successToastMsg = '';
    error = '';

    @wire(getRecord, { recordId: '$recordId', fields: [DTE_INIT_CANCEL_FIELD, CDE_STATUS_FIELD] })
    wiredAdjRecord({ error, data }) {
        if (data) {
            this.adjRecord = data;
            this.checkForWarning();
        } else if (error) {
            console.error('Error loading adjustment record:', error);
        }
    }

    connectedCallback() {
        this.fetchAdjustmentDetails();
    }

    get showComponent() {
        return this.sObjectName !== 'T_ADJMT_CANCEL__c';
    }

    /** True when adjCancellationRecord exists (for conditional form rendering). */
    get hasAdjCancellationRecord() {
        return this.adjCancellationRecord && Object.keys(this.adjCancellationRecord).length > 0;
    }

    /** True when the cancellation record has a Salesforce Id (existing record). */
    get hasRecordId() {
        return !!this.adjCancellationRecord.Id;
    }

    /** Returns the cancellation record Id for the form. */
    get adjCancellationRecordId() {
        return this.adjCancellationRecord.Id || null;
    }

    /** Returns the cancellation record Name for display. */
    get adjCancellationRecordName() {
        return this.adjCancellationRecord.Name || '';
    }

    get adjCancellationRecordAdjmtId() {
        return this.adjCancellationRecord.IDN_ADJMT__c || this.recordId;
    }

    /** CDE_STATUS__c field is editable only by admins. */
    get isStatusDisabled() {
        return !this.isAdmin;
    }

    /** CDE_RSN_CANCELLATION__c is disabled once the record is Submitted (status '2'). */
    get isReasonDisabled() {
        return this.adjCancellationRecord.CDE_STATUS__c === '2';
    }

    /** DTE_DISC_CANCELLATION__c is disabled once the record is Submitted (status '2'). */
    get isDiscDateDisabled() {
        return this.adjCancellationRecord.CDE_STATUS__c === '2';
    }

    /** RSN_CANCEL_SUBJECT__c is only editable in Draft status ('1'). */
    get isSubjectDisabled() {
        return this.adjCancellationRecord.CDE_STATUS__c !== '1';
    }

    /** RSN_CANCEL_BODY__c is only editable in Draft status ('1'). */
    get isBodyDisabled() {
        return this.adjCancellationRecord.CDE_STATUS__c !== '1';
    }

    /** Save button is disabled when the record is already Submitted. */
    get isSaveDisabled() {
        return this.adjCancellationRecord.CDE_STATUS__c === '2';
    }

    /** Submit button is disabled when the record is already Submitted. */
    get isSubmitDisabled() {
        return this.adjCancellationRecord.CDE_STATUS__c === '2';
    }

    /** Withdraw button is disabled when there is no existing record Id. */
    get isWithdrawDisabled() {
        return !this.adjCancellationRecord.Id;
    }

    /**
     * Fetches adjustment cancellation details from the server.
     * Populates adjCancellationRecord with the existing record or a new draft shell.
     */
    fetchAdjustmentDetails() {
        let params = { adjustmentId: this.recordId };
        helper.callServer(
            this,
            'adjustmentCancellationApxCtrl',
            'getAdjustmentDetails',
            (function (response) {
                if (response && response.isSuccessful) {
                    const userProfile = response.objectData.userProfile;
                    this.isAdmin = userProfile
                        ? userProfile.toLowerCase().includes('admin')
                        : false;

                    if (response.objectData.adjCanRecList) {
                        this.adjCancellationRecord = response.objectData.adjCanRecList;
                    } else {
                        // No existing record — seed a new draft
                        this.adjCancellationRecord = {
                            IDN_ADJMT__c: this.recordId,
                            CDE_STATUS__c: '1'
                        };
                    }
                }
            }).bind(this),
            JSON.stringify(params)
        );
    }

    /**
     * Submit action: set status to '2' (Submitted) and validate before submitting.
     * If the parent adjustment has no DTE_INIT_CANCEL__c, skip the warning dialog.
     */
    handleSubmitCancellation() {
        this._pendingStatus = '2'; 
        this.action = 'submit';
        this.successToastMsg = 'Adjustment Cancellation Submitted Successfully';

        // If the parent adjustment has no initial cancel date, skip the reminder dialog
        const dteInitCancel = getFieldValue(this.adjRecord, DTE_INIT_CANCEL_FIELD);
        if (this.adjRecord && !dteInitCancel) {
            this.warningAccepted = true;
        }

        this.validateForm();
    }

    /**
     * Save action: validate and submit the form with current field values.
     */
    handleSaveCancellation() {
        this._pendingStatus = null;
        this.action = 'save';
        this.successToastMsg = 'Adjustment Cancellation Saved Successfully';
        this.validateForm();
    }

    /**
     * Withdraw action: set status to '6' (Withdrawn) and validate before submitting.
     */
    handleWithdrawCancellation(event) {
        event.preventDefault();
        this._pendingStatus = '6'; 
        this.action = 'withdraw';
        this.successToastMsg = 'Adjustment Cancellation Withdrawn Successfully';
        this.validateForm();
    }

    /**
     * Validates required fields.
     * If valid, either shows the reminder confirmation dialog or submits the form directly.
     */
    validateForm() {
        const rec = this.adjCancellationRecord;
        console.log('rec', JSON.stringify(rec));
        this.recordError=[];
        this.messageType='';
const reason   = this.template.querySelector('lightning-input-field[data-field="reason"]')?.value;
const discDate = this.template.querySelector('lightning-input-field[data-field="discovery"]')?.value;
const subject  = this.template.querySelector('lightning-input-field[data-field="cancelSubject"]')?.value;
const body     = this.template.querySelector('lightning-input-field[data-field="cancelBody"]')?.value;
console.log('values',reason,discDate,subject,body );

if (!reason || !discDate || !subject || !body) { 
            this.messageType = 'error';
            this.recordError.push({ 'id': 'error', 'message': 'There are errors on this page.  Please correct them to proceed.' });
            this.showSpinner = false;
            return;
        }

        // Show reminder dialog when:
        //   - action is not 'save'
        //   - warning has not yet been accepted
        //   - the record already exists (has an Id)
        //   - the status is Submitted ('2') or Withdrawn ('6')
        if (
            this.action !== 'save' &&
            !this.warningAccepted &&
            rec.Id &&
            (this._pendingStatus === '2' || this._pendingStatus === '6')
        ) {
            this.showConfirmDialog = true;
            this.showSpinner = false;
            return;
        }

        this.submitStatus = this._pendingStatus || this.adjCancellationRecord.CDE_STATUS__c || '1';
        Promise.resolve().then(() => {
            const form = this.template.querySelector('lightning-record-edit-form');
            if (form) {
                form.submit();
            }
        });
    }


    /**
     * Handles the onsuccess event from lightning-record-edit-form.
     * Refreshes the record, shows a success toast, and closes the popup.
     */
    handleSuccess(event) {
        const recordId = event.detail.id;

        // Notify LDS to refresh the record in the cache
        if (recordId) {
            getRecordNotifyChange([{ recordId: recordId }]);
        }

        // Reset submission state now that the save is confirmed
        this.action = '';
        this._pendingStatus = null;
        this.warningAccepted = false;
        this.showSpinner = false;

        // Show success toast
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: this.successToastMsg || 'Record saved successfully.',
                variant: 'success'
            })
        );

        this.closePopUp();
    }

    handleError(event) {
        this.messageType = 'error';
        const detail = event.detail;
        this.action = '';
        this._pendingStatus = null;
        this.warningAccepted = false;

        let message = 'An unexpected error occurred. Please try again.';
        if (detail) {
            if (detail.detail) {
                message = detail.detail;
            } else if (detail.message) {
                message = detail.message;
            } else if (typeof detail === 'string') {
                message = detail;
            }
        }

        this.recordError = [{ id: 'error', message: message }];
        this.showSpinner = false;
    }

    /**
     * Checks whether a warning toast should be shown to admins.
     * Fires when the parent T_ADJMT__c record status is 3, 4, or 5 and the user is an admin.
     */
    checkForWarning() {
        if (!this.adjRecord) return;

        const status = getFieldValue(this.adjRecord, CDE_STATUS_FIELD);
        const warningStatuses = ['3', '4', '5'];

        if (
            this.sObjectName === 'T_ADJMT_CANCEL__c' &&
            warningStatuses.includes(status) &&
            this.isAdmin
        ) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning!',
                    message: this.reminderMsg,
                    variant: 'warning'
                })
            );
        }
    }

    /**
     * User clicked "Ok" in the confirmation dialog — accept the warning and close the dialog.
     * Does NOT re-submit; the user must click Save/Submit/Withdraw again.
     */
    handleWarningAccept() {
        this.showConfirmDialog = false;
        this.warningAccepted = true;
    }

    /**
     * User clicked "Continue" in the confirmation dialog — accept the warning,
     * close the dialog, and immediately re-run validation to submit the form.
     */
    handleContinue() {
        this.showConfirmDialog = false;
        this.warningAccepted = true;
        this.validateForm();
    }

    /**
     * Closes the confirmation dialog without accepting the warning.
     */
    hideConfirmModal() {
        this.showConfirmDialog = false;
    }

    closePopUp() {
            if (this.modalRef) {
        this.modalRef.close();
    }}

    redirectToCancellation() {
        if (this.adjCancellationRecord && this.adjCancellationRecord.Id) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.adjCancellationRecord.Id,
                    actionName: 'view'
                }
            });
        }
    }
}