import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';

export default class TaxInterceptDetails_lwc extends NavigationMixin(LightningElement) {
    // Public properties
    @api taxRecord;
    @api showDetailsModal = false;
    @api removeAccess = false;
    @api removeReason;
    @api isAdmin = false;

    // Private properties
    @track showSpinner = false;
    @track pageMessages = [];
    @track messageType;
    @track fieldValidationErrors = [];

    // Close modal
    closeModal() {
        if (this.taxRecord) {
            this.removeReason = this.taxRecord.Remove_Reason__c;
        }
        this.dispatchEvent(new CustomEvent('close'));
    }

    // Save button function
    save() {
        if (this.validateReinstate()) {
            this.showSpinner = true;

            const params = {
                recordId: this.taxRecord.Id,
                removeReasonOld: this.taxRecord.Remove_Reason__c,
                removeReasonNew: this.removeReason
            };

            helper.callServer(
                this,
                'TaxInterceptApexController',
                'saveRecord',
                (response) => {
                    let taxRecord = JSON.parse(JSON.stringify(this.taxRecord));
                    taxRecord.Remove_Reason__c = response.objectData.taxRecord.Remove_Reason__c;
                    taxRecord.Remove_Reason_Text__c = response.objectData.taxRecord.Remove_Reason_Text__c;
                    taxRecord.Reinstate__c = response.objectData.taxRecord.Reinstate__c;
                    taxRecord.Remove_Date__c = response.objectData.taxRecord.Remove_Date__c;
                    taxRecord.Reinstate_Date__c = response.objectData.taxRecord.Reinstate_Date__c;
                    this.taxRecord = taxRecord;
                    this.showSpinner = false;
                    // Fire event to parent with updated taxRecord
                    this.dispatchEvent(new CustomEvent('taxrecordupdate', { detail: { taxRecord } }));
                    this.closeModal();
                    helper.showToast(this, 'Success!', 'Update successful', 'success');
                },
                JSON.stringify(params)
            );
        }
    }

    // Validate reinstate
    validateReinstate() {
        let canReinstate = true;
        const today = new Date();
        const november1st = new Date(today.getFullYear(), 10, 1); // Month is 0-indexed, so 10 = November
        const removeReasonOld = this.taxRecord.Remove_Reason__c;
        const removeReasonNew = this.removeReason;

        if (!this.isAdmin && today >= november1st && !removeReasonNew && removeReasonOld) {
            canReinstate = false;
            helper.showToast(this, 'Error!', 'Cannot reinstate after November 1st', 'error');
        }

        return canReinstate;
    }

    // Navigation helper methods
    gotoAdjustmentRecord() {
        if (this.taxRecord && this.taxRecord.Adjustment__c) {
            this.navigateToRecord(this.taxRecord.Adjustment__c);
        }
    }

    gotoTaxInterceptRecord() {
        if (this.taxRecord && this.taxRecord.Id) {
            this.navigateToRecord(this.taxRecord.Id);
        }
    }

    gotoProviderRecord() {
        if (this.taxRecord && this.taxRecord.Provider__c) {
            this.navigateToRecord(this.taxRecord.Provider__c);
        }
    }

    gotoCaseRecord() {
        if (this.taxRecord && this.taxRecord.Case__c) {
            this.navigateToRecord(this.taxRecord.Case__c);
        }
    }

    // Navigate to record
    navigateToRecord(recordId) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }

    // Handle removal reason change
    handleRemoveReasonChange(event) {
        this.removeReason = event.detail.payload.value;
    }

    // Getters
    get showRemovalField() {
        return this.showDetailsModal && this.removeAccess;
    }

    get isCaseType() {
        return this.taxRecord && this.taxRecord.Type__c === 'Case';
    }

    get isProviderType() {
        return this.taxRecord && this.taxRecord.Type__c === 'Provider';
    }
}