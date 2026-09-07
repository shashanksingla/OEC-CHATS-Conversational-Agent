import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';

const CASE_COUNTY_FIELD   = 'T_SBSD_CASE__c.CDE_COUNTY__c';
const COUNTY_CODE_FIELD   = 'T_COUNTY__c.CDE_COUNTY__c';

const STATUS_IN_PROGRESS  = 'In progress';
const STATUS_RESOLVED     = 'Resolved';
const STATUS_NEW          = 'New';

export default class NewClientComplaint_lwc extends NavigationMixin(LightningElement) {

    _recordId = null;
    @track _screenMode = 'NEW';
    _modeInitialized = false;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this._tryInitEditMode();
    }

    @api
    get screenMode() {
        return this._screenMode;
    }
    set screenMode(value) {
        this._screenMode = value || 'NEW';
        this._tryInitEditMode();
    }

    _tryInitEditMode() {
        if (!this._modeInitialized && this._screenMode === 'EDIT' && this._recordId) {
            this._modeInitialized = true;
            this._loadExistingRecord();
        }
    }

    showSpinner      = false;
    isLoadingRecord  = false;
    savedRecordId    = null;
    isSaving         = false;

    _pendingCountyId         = null;
    _selectedCountyId        = null;
    _selectedCountyCode      = null;
    _wireCaseId              = null;
    _wireCountyId            = null;
    _pendingProposedCountyId = null;
    _pendingAssigneeClear    = false;

    @track caseError             = '';
    @track providerError         = '';
    @track caseProviderBothError = '';
    @track showCountyError       = false;
    countyError = 'Case ID does not match county. Please update as needed.';
    @track showAssigneeError     = false;
    assigneeError = 'Please enter an associated county before entering assignee';
    @track dteInitialComplaintError  = '';
    @track dteCountyResponseError    = '';
    @track dteComplaintResolvedError = '';

    @track searchWrapper = {
        selectedCase     : null,
        selectedProvider : null,
        selectedCounty   : null,
        selectedAssignee : null,
        complaintRecord  : {
            Complaint_Types__c               : '',
            Complaint_Status__c              : 'New',
            Method_of_Contact__c             : '',
            Person_who_Provided_Complaint__c : '',
            Subject__c                       : '',
            Complaint_Body__c                : '',
            Notes__c                         : '',
            DTE_Initial_Complaint__c         : '',
            DTE_County_Response__c           : '',
            DTE_Complaint_Resolved__c        : '',
            DTE_County_Transfer__c           : ''
        }
    };
    _initialDateSaved    = false;
    _countyResponseSaved = false;
    _resolvedDateSaved   = false;
    _complaintBodySaved  = false;

    connectedCallback() {
        Promise.resolve().then(() => {
            if (!this._modeInitialized) {
                this._modeInitialized = true;
                if (this._screenMode === 'EDIT' && this._recordId) {
                    this._loadExistingRecord();
                } else {
                    this.initSearchWrapper();
                }
            }
        });
    }

    initSearchWrapper() {
        this.searchWrapper = JSON.parse(JSON.stringify({
            selectedCase     : null,
            selectedProvider : null,
            selectedCounty   : null,
            selectedAssignee : null,
            complaintRecord  : {
                Complaint_Types__c               : '',
                Complaint_Status__c              : STATUS_NEW,
                Method_of_Contact__c             : '',
                Person_who_Provided_Complaint__c : '',
                Subject__c                       : '',
                Complaint_Body__c                : '',
                Notes__c                         : '',
                DTE_Initial_Complaint__c         : '',
                DTE_County_Response__c           : '',
                DTE_Complaint_Resolved__c        : '',
                DTE_County_Transfer__c           : ''
            }
        }));
    }

    _loadExistingRecord() {
        this.isLoadingRecord = true;
        helper.callServer(
            this,
            'ClientComplaintApxCtrl',
            'getComplaintForEdit',
            (response) => {
                this.isLoadingRecord = false;
                if (response.isSuccessful) {
                    const rec = response.objectData.complaint;
                    this.savedRecordId        = rec.Id;
                    this._initialDateSaved    = !!rec.DTE_Initial_Complaint__c;
                    this._countyResponseSaved = !!rec.DTE_County_Response__c;
                    this._resolvedDateSaved   = !!rec.DTE_Complaint_Resolved__c;
                    this._complaintBodySaved  = !!rec.Complaint_Body__c;
                    this.searchWrapper = {
                        selectedCase     : rec.IDN_CASE__c     || null,
                        selectedProvider : rec.IDN_PROVR__c    || null,
                        selectedCounty   : rec.IDN_COUNTY__c   || null,
                        selectedAssignee : rec.Assignee__c     || null,
                        complaintRecord  : {
                            Complaint_Types__c               : rec.Complaint_Types__c               || '',
                            Complaint_Status__c              : rec.Complaint_Status__c              || STATUS_NEW,
                            Method_of_Contact__c             : rec.Method_of_Contact__c             || '',
                            Person_who_Provided_Complaint__c : rec.Person_who_Provided_Complaint__c || '',
                            Subject__c                       : rec.Subject__c                       || '',
                            Complaint_Body__c                : rec.Complaint_Body__c                || '',
                            Notes__c                         : '',
                            DTE_Initial_Complaint__c         : rec.DTE_Initial_Complaint__c         || '',
                            DTE_County_Response__c           : rec.DTE_County_Response__c           || '',
                            DTE_Complaint_Resolved__c        : rec.DTE_Complaint_Resolved__c        || '',
                            DTE_County_Transfer__c           : rec.DTE_County_Transfer__c           || ''
                        }
                    };
                    if (rec.IDN_COUNTY__c) {
                        this._selectedCountyId = rec.IDN_COUNTY__c;
                        this._wireCountyId     = rec.IDN_COUNTY__c;
                    }
                    this.showAssigneeError = false;
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title   : 'Error',
                        message : 'Failed to load record: ' + (response.errorMessage || 'Unknown error'),
                        variant : 'error'
                    }));
                }
            },
            JSON.stringify({ recordId: this.recordId })
        );
    }

    get isEditMode()               { return this._screenMode === 'EDIT'; }
    get isCountyRequired()         { return !this.isEditMode; }
    get showCountyErrorVisible()   { return this.showCountyError && !this.isEditMode; }
    get showAssigneeErrorVisible() { return this.showAssigneeError && !this.isEditMode; }
    get assigneeCustomError()      { return this.isEditMode ? '' : (this.showAssigneeError ? this.assigneeError : ''); }
    get modalTitle()          { return this.isEditMode ? 'Edit Client Complaint or Contact' : 'New Client Complaint or Contact'; }
    get isSpinnerVisible()    { return this.showSpinner || this.isLoadingRecord; }

    get isCaseProviderLocked()  { return this.savedRecordId != null; }
    get isCountyLocked()        { return this.savedRecordId != null; }
    get isInitialDateLocked()   { return this._initialDateSaved; }

    get isCountyResponseRequired() {
        const s = this.searchWrapper.complaintRecord?.Complaint_Status__c;
        return s === STATUS_IN_PROGRESS;
    }
    get isCountyResponseLocked()   {
        return this._countyResponseSaved && !!this.searchWrapper.complaintRecord?.DTE_County_Response__c;
    }

    get isResolvedDateRequired() {
        const s = this.searchWrapper.complaintRecord?.Complaint_Status__c;
        return s === STATUS_RESOLVED;
    }
    get isResolvedDateLocked() {
        return this._resolvedDateSaved && !!this.searchWrapper.complaintRecord?.DTE_Complaint_Resolved__c;
    }

    get isComplaintBodyRequired() {
        return this.searchWrapper.complaintRecord?.Complaint_Status__c === STATUS_NEW;
    }
    get isComplaintBodyLocked() {
        return this._complaintBodySaved && !!this.searchWrapper.complaintRecord?.Complaint_Body__c;
    }

    get isNotesRequired() {
        const s = this.searchWrapper.complaintRecord?.Complaint_Status__c;
        return s === STATUS_RESOLVED || s === STATUS_IN_PROGRESS;
    }

    get assigneeFilter() {
        const code = this._selectedCountyCode;
        if (!code) return 'IsActive = true';
        return `IsActive = true AND (Owner_County__c = '${code}' OR Owner_County__c = '66' OR Common_County__c INCLUDES ('${code}'))`;
    }

    get caseEffectiveError()     { return this.caseProviderBothError || this.caseError; }
    get providerEffectiveError() { return this.caseProviderBothError || this.providerError; }

    get hasInlineErrors() {
        return !!(
            this.dteInitialComplaintError  ||
            this.dteCountyResponseError    ||
            this.dteComplaintResolvedError ||
            this.showCountyErrorVisible    ||
            this.showAssigneeErrorVisible
        );
    }

    handleLookupValue(event) {
        const pickerName = event.detail.uniqueKey;
        const recordId   = event.detail.record?.Id || null;

        if (pickerName === 'caseId') {
            this.searchWrapper.selectedCase = recordId;
            if (recordId) {
                this.caseError     = '';
                this.providerError = '';
                const countyToCheck = this.searchWrapper.selectedCounty || this._pendingCountyId;
                if (countyToCheck) {
                    this._checkCaseCountyMismatch(recordId, countyToCheck);
                }
            } else {
                this.showCountyError          = false;
                this._wireCaseId              = null;
                this._pendingProposedCountyId = null;
            }
            if (!recordId || !this.searchWrapper.selectedProvider) {
                this.caseProviderBothError = '';
            }
        } else if (pickerName === 'providerId') {
            this.searchWrapper.selectedProvider = recordId;
            if (recordId) {
                this.providerError = '';
                this.caseError     = '';
            }
            if (!recordId || !this.searchWrapper.selectedCase) {
                this.caseProviderBothError = '';
            }
        } else if (pickerName === 'countyId') {
            if (recordId) {
                if (this.searchWrapper.selectedCase) {
                    this._pendingCountyId  = recordId;
                    this._selectedCountyId = recordId;
                    if (this._wireCountyId !== recordId) {
                        this._selectedCountyCode   = null;
                        this._pendingAssigneeClear = true;
                        this._wireCountyId         = recordId;
                    }
                    this._checkCaseCountyMismatch(this.searchWrapper.selectedCase, recordId);
                } else {
                    this._applyCountySelection(recordId);
                    this.showAssigneeError = false;
                }
            } else {
                this.searchWrapper.selectedCounty = null;
                //this.countyError                  = '';
                this._selectedCountyId            = null;
                this._selectedCountyCode          = null;
                this._wireCountyId                = null;
                this._pendingCountyId             = null;
                this.showCountyError              = false;
                this._clearAssignee();
            }
        } else if (pickerName === 'assigneeId') {
            this.searchWrapper.selectedAssignee = recordId;
            if (!this.isEditMode && recordId !== null) {
                const hasCounty = !!this.searchWrapper.selectedCounty || !!this._pendingCountyId;
                this.showAssigneeError = !hasCounty;
            }
        }
    }

    _applyCountySelection(countyId) {
        this.searchWrapper.selectedCounty = countyId;
        this._selectedCountyId            = countyId;
        this._wireCountyId = countyId;
        this._clearAssignee();
    }

    _clearAssignee() {
        this.searchWrapper.selectedAssignee = null;
        const assigneePicker = this.template.querySelector('c-custom-lookup_lwc[unique-key="assigneeId"]');
        this.showAssigneeError = false;
        if (assigneePicker) assigneePicker.clearSelectedValue();
    }

    _checkCaseCountyMismatch(caseId, proposedCountyId) {
        this._pendingProposedCountyId = proposedCountyId;
        getRecordNotifyChange([{ recordId: caseId }]);
        this._wireCaseId = caseId;
    }

    @wire(getRecord, { recordId: '$_wireCaseId', fields: [CASE_COUNTY_FIELD] })
    wiredCaseRecord({ data, error }) {
        if (!this._pendingProposedCountyId) return;
        if (data) {
            const caseCountyId = getFieldValue(data, CASE_COUNTY_FIELD);
            const proposed     = this._pendingProposedCountyId;
            this._wireCaseId              = null;
            this._pendingProposedCountyId = null;
            if (caseCountyId && caseCountyId !== proposed) {
                this._pendingCountyId = proposed;
                this.showCountyError  = true;
            } else {
                this._applyCountySelection(proposed);
            }
        } else if (error) {
            const proposed                = this._pendingProposedCountyId;
            this._wireCaseId              = null;
            this._pendingProposedCountyId = null;
            this._applyCountySelection(proposed);
        }
    }

    @wire(getRecord, { recordId: '$_wireCountyId', fields: [COUNTY_CODE_FIELD] })
    wiredCountyRecord({ data, error }) {
        if (data) {
            const newCode = getFieldValue(data, COUNTY_CODE_FIELD) || null;
            const codeChanged = newCode !== this._selectedCountyCode;
            this._selectedCountyCode = newCode;
            if (codeChanged && this._pendingAssigneeClear) {
                this._pendingAssigneeClear = false;
                this._clearAssignee();
            }
        } else if (error) {
            this._selectedCountyCode   = null;
            this._pendingAssigneeClear = false;
        }
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        if (!field || !this.searchWrapper.complaintRecord) return;

        this.searchWrapper.complaintRecord[field] = value;

        const initialDate = field === 'DTE_Initial_Complaint__c'
            ? value
            : this.searchWrapper.complaintRecord.DTE_Initial_Complaint__c;

        if (field === 'DTE_Initial_Complaint__c') {
            this.dteInitialComplaintError = this._validateDate(value, 'Initial Date of Complaint cannot be in the future');
            this.dteCountyResponseError    = this._validateDateAgainstInitial(
                this.searchWrapper.complaintRecord.DTE_County_Response__c, value
            ) || this._validateDate(this.searchWrapper.complaintRecord.DTE_County_Response__c, 'Initial Date County Responded cannot be in the future');
            this.dteComplaintResolvedError = this._validateDateAgainstInitial(
                this.searchWrapper.complaintRecord.DTE_Complaint_Resolved__c, value
            ) || this._validateDate(this.searchWrapper.complaintRecord.DTE_Complaint_Resolved__c, 'Date Complaint Resolved cannot be in the future');
        } else if (field === 'DTE_County_Response__c') {
            this.dteCountyResponseError = this._validateDateAgainstInitial(value, initialDate)
                || this._validateDate(value, 'Initial Date County Responded cannot be in the future');
        } else if (field === 'DTE_Complaint_Resolved__c') {
            this.dteComplaintResolvedError = this._validateDateAgainstInitial(value, initialDate)
                || this._validateDate(value, 'Date Complaint Resolved cannot be in the future');
        }
    }

    handlePicklistChange(event) {
        if (!event.detail || !event.detail.callingContext || !event.detail.payload) return;
        const contextParts = event.detail.callingContext.split('_');
        if (contextParts.length >= 3){
            const field = event.detail.callingContext.replace('Client_Complaint__c_', '');
            const value = event.detail.payload.value || '';
            if (!this.searchWrapper.complaintRecord) return;
            this.searchWrapper = {...this.searchWrapper, complaintRecord: {...this.searchWrapper.complaintRecord, [field]: value}};
            if (field === 'Complaint_Status__c') {
                if (value !== STATUS_RESOLVED) { this.dteComplaintResolvedError = '';}
            }
        }
    }

    _validateDate(dateString, futureDateMsg) {
        if (!dateString) return '';
        const d = new Date(dateString + 'T00:00:00');
        const today = new Date(); today.setHours(0, 0, 0, 0);
        return d > today ? futureDateMsg : '';
    }

    _validateDateAgainstInitial(dateString, initialDate) {
        if (!dateString || !initialDate) return '';
        const d       = new Date(dateString  + 'T00:00:00');
        const initial = new Date(initialDate + 'T00:00:00');
        return d < initial ? 'Date cannot be less than Initial Date of Complaint' : '';
    }

    _validateForm() {
        let valid = true;
        const rec = this.searchWrapper.complaintRecord;

        if (!this.isEditMode) {
            if (!this.searchWrapper.selectedCase && !this.searchWrapper.selectedProvider) {
                this.caseError             = 'Please enter a value';
                this.providerError         = 'Please enter a value';
                this.caseProviderBothError = '';
                valid = false;
            } else if (this.searchWrapper.selectedCase && this.searchWrapper.selectedProvider) {
                this.caseError             = '';
                this.providerError         = '';
                this.caseProviderBothError = 'Either Case or Provider must be entered. Not both.';
                valid = false;
            } else {
                this.caseError             = '';
                this.providerError         = '';
                this.caseProviderBothError = '';
            }
        }

        if (rec.DTE_Initial_Complaint__c) {
            this.dteInitialComplaintError = this._validateDate(
                rec.DTE_Initial_Complaint__c,
                'Initial Date of Complaint cannot be in the future'
            );
            if (this.dteInitialComplaintError) valid = false;
        } else {
            this.dteInitialComplaintError = '';
        }

        if (rec.DTE_County_Response__c) {
            this.dteCountyResponseError =
                this._validateDateAgainstInitial(rec.DTE_County_Response__c, rec.DTE_Initial_Complaint__c) ||
                this._validateDate(rec.DTE_County_Response__c, 'Initial Date County Responded cannot be in the future');
            if (this.dteCountyResponseError) valid = false;
        } else if (!this.isCountyResponseRequired) {
            this.dteCountyResponseError = '';
        }

        if (rec.DTE_Complaint_Resolved__c) {
            this.dteComplaintResolvedError =
                this._validateDateAgainstInitial(rec.DTE_Complaint_Resolved__c, rec.DTE_Initial_Complaint__c) ||
                this._validateDate(rec.DTE_Complaint_Resolved__c, 'Date Complaint Resolved cannot be in the future');
            if (this.dteComplaintResolvedError) valid = false;
        } else if (!this.isResolvedDateRequired) {
            this.dteComplaintResolvedError = '';
        }

        valid = abs_helper.validateCurrentPage(this) && valid;
        return valid;
    }

    handleSave() {
        if (!this._validateForm()) return;
        if (this.hasInlineErrors) return;

        this.isSaving = true;
        const rec = this.searchWrapper.complaintRecord;

        const complaintData = {
            recordId                         : this.savedRecordId || null,
            IDN_CASE__c                      : this.searchWrapper.selectedCase     || null,
            IDN_PROVR__c                     : this.searchWrapper.selectedProvider || null,
            IDN_COUNTY__c                    : this.searchWrapper.selectedCounty   || null,
            Assignee__c                      : this.searchWrapper.selectedAssignee || null,
            Person_who_Provided_Complaint__c : rec.Person_who_Provided_Complaint__c || null,
            Complaint_Types__c               : rec.Complaint_Types__c              || null,
            Complaint_Status__c              : rec.Complaint_Status__c,
            Method_of_Contact__c             : rec.Method_of_Contact__c,
            Subject__c                       : rec.Subject__c                      || null,
            Complaint_Body__c                : rec.Complaint_Body__c               || null,
            DTE_Initial_Complaint__c         : rec.DTE_Initial_Complaint__c        || null,
            DTE_County_Response__c           : rec.DTE_County_Response__c          || null,
            DTE_Complaint_Resolved__c        : rec.DTE_Complaint_Resolved__c       || null
        };

        const noteText = rec.Notes__c ? rec.Notes__c.trim() : null;

        helper.callServer(this, 'ClientComplaintApxCtrl', 'saveComplaint',
            (function(response) {
                this.isSaving = false;
                if (response.isSuccessful) {
                    this.savedRecordId       = response.objectData.recordId;
                    this._initialDateSaved   = true;
                    this._complaintBodySaved = true;
                    if (rec.DTE_County_Response__c)   this._countyResponseSaved = true;
                    if (rec.DTE_Complaint_Resolved__c) this._resolvedDateSaved   = true;
                    this.searchWrapper.complaintRecord.Notes__c = '';
                    this.dispatchEvent(new ShowToastEvent({
                        title   : 'Success',
                        message : 'Complaint saved successfully.',
                        variant : 'success'
                    }));
                    this.dispatchEvent(new CustomEvent('complaintsaved', {
                        detail  : { recordId: this.savedRecordId },
                        bubbles : true
                    }));
                    if (this.isEditMode) {
                        getRecordNotifyChange([{ recordId: this.savedRecordId }]);
                    }
                    this[NavigationMixin.Navigate]({
                        type       : 'standard__recordPage',
                        attributes : { recordId: this.savedRecordId, actionName: 'view' }
                    });
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title   : 'Error',
                        message : 'Save failed: ' + (response.errorMessage || 'Unknown error'),
                        variant : 'error'
                    }));
                }
            }).bind(this),
            JSON.stringify({ complaintData, noteText })
        );
    }

    handleCancel() {
        if (this.isEditMode) {
            this[NavigationMixin.Navigate]({
                type       : 'standard__recordPage',
                attributes : { recordId: this.recordId, actionName: 'view' }
            });
        } else {
            this.dispatchEvent(new CustomEvent('cancel', { bubbles: true }));
        }
    }
}