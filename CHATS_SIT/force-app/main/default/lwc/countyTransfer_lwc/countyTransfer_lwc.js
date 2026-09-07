import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';

const COUNTY_CODE_FIELD = 'T_COUNTY__c.CDE_COUNTY__c';
const APEX_CLASS        = 'ClientComplaintApxCtrl';

export default class CountyTransfer_lwc extends NavigationMixin(LightningElement) {

    @api recordId;
    @api modalRef;

    @track selectedCountyId    = null;
    @track selectedAssigneeId  = null;
    @track notes               = '';
    @track pageError           = '';

    _wireCountyId        = null;
    _selectedCountyCode  = null;

    isSaving = false;

    get isSpinnerVisible() {
        return this.isSaving;
    }

    get assigneeFilter() {
        const code = this._selectedCountyCode;
        if (!code) return 'IsActive = true';
        return `IsActive = true AND (Owner_County__c = '${code}' OR Owner_County__c = '66' OR Common_County__c INCLUDES ('${code}'))`;
    }

    @wire(getRecord, { recordId: '$_wireCountyId', fields: [COUNTY_CODE_FIELD] })
    wiredCountyRecord({ data, error }) {
        if (data) {
            this._selectedCountyCode = getFieldValue(data, COUNTY_CODE_FIELD) || null;
        } else if (error) {
            this._selectedCountyCode = null;
        }
    }

    handleLookupValue(event) {
        const key      = event.detail.uniqueKey;
        const recordId = event.detail.record ? event.detail.record.Id : null;
        if (key === 'countyId') {
            this.selectedCountyId    = recordId;
            this._wireCountyId       = recordId;
            this._selectedCountyCode = null;
            // Clear assignee when county changes
            this.selectedAssigneeId  = null;
            const assigneePicker = this.template.querySelector('c-custom-lookup_lwc[unique-key="assigneeId"]');
            if (assigneePicker && typeof assigneePicker.clearSelectedValue === 'function') {
                assigneePicker.clearSelectedValue();
            }
        } else if (key === 'assigneeId') {
            this.selectedAssigneeId = recordId;
        }
    }

    handleNotesChange(event) {
        this.notes = event.detail.value;
    }

    _validateForm() {
        let isValid = true;
        isValid = abs_helper.validateCurrentPage(this);
        console.log('validateForm: isValid = ' + isValid);
        return isValid;
    }

    handleSave() {
        this.pageError = '';

        if (!this._validateForm()) {
            return;
        }

        this.isSaving = true;

        const params = JSON.stringify({
            oldComplaintId : this.recordId,
            countyId       : this.selectedCountyId,
            notes          : this.notes.trim(),
            assigneeId     : this.selectedAssigneeId || ''
        });

        helper.callServer( this, APEX_CLASS, 'countyTransfer',
            (response) => {
                this.isSaving = false;
                if (response && response.isSuccessful) {
                    const newComplaintId = response.objectData && response.objectData.newComplaintId
                        ? response.objectData.newComplaintId
                        : null;

                    this.dispatchEvent(new ShowToastEvent({
                        title   : 'Success',
                        message : 'County transfer completed successfully.',
                        variant : 'success'
                    }));
                    this._closeModal();
                    if (newComplaintId) {
                        this[NavigationMixin.Navigate]({
                            type       : 'standard__recordPage',
                            attributes : {
                                recordId   : newComplaintId,
                                actionName : 'view'
                            }
                        });
                    }
                } else {
                    const errorMsg = (response && response.errorMessage)
                        ? response.errorMessage
                        : 'An error occurred during county transfer.';
                    this.pageError = errorMsg;
                }
            }, params);
    }

    handleCancel() {
        this._closeModal();
    }

    _closeModal() {
        if (this.modalRef) {
            this.modalRef.close();
        }
    }
}