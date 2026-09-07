import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ConfirmationModalLWC from 'c/confirmationModal_LWC';
import { helper } from 'c/generic_Utilities';

export default class AdjustmentPaymentFlow_lwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api parentObjectAPI;
    @api parentObjectId;
    
    mapObjectApiName(apiName) {
        if (!apiName) return null;
        
        const objectNameMapping = {
            'Case': 'T_SBSD_CASE__c',
            'Provider': 'T_CHATS_PROVR_STATUS__c',
            'Payment': 'T_PAYMT__c'
        };        
        if (apiName.indexOf('__c') > -1) {
            return apiName;
        }
        
        if (objectNameMapping[apiName]) {
            return objectNameMapping[apiName];
        }
        
        return apiName;
    }

    @api setParentObjectValues(parentObjectId, parentObjectAPI) {
        this.parentObjectId = parentObjectId;
        this.parentObjectAPI = this.mapObjectApiName(parentObjectAPI);
        
        // Special handling for T_ADJMT_PMT__c
        if (this.parentObjectAPI === 'T_ADJMT_PMT__c' && (!this.parentObjectId || this.parentObjectId === '')) {
            this.parentObjectId = "DUMMY_ID_FOR_T_ADJMT_PMT";
        }
        
        this.initializeData();
    }
    
    @track parentObjectName;
    @track recordError = [];
    @track message;
    @track caseLookupLabel;
    @track providerLookupLabel;
    @track paymentLookupLabel;
    @track adjPaymentObj = {
        sobjectType: 'T_ADJMT_PMT__c',
        AMT_PMT_ADJMT__c: '',
        CDE_COUNTY__c: '',
        CDE_ACTION_ADMIN__c: '',
        CDE_TYPE_PMT_ADJMT__c: '',
        IDN_CASE__c: '',
        DTE_PMT_ADJMT__c: '',
        IDN_PROVR__c: '',
        IDN_PMT__c: '',
        TXT_INFO_OTHER__c: '',
        IDN_RCPT_PMT__c: '',
        TXT_NBR_CHECK_PMT__c: ''
    };
    @track assignedCounties = [];
    @track isReadyToRender = false;
    @track showSpinner = false;
    @track isCurrentPageValid = true;
    @track fieldValidationErrors = {
        AMT_PMT_ADJMT__c: '',
        CDE_COUNTY__c: '',
        CDE_ACTION_ADMIN__c: '',
        CDE_TYPE_PMT_ADJMT__c: '',
        IDN_CASE__c: '',
        DTE_PMT_ADJMT__c: '',
        IDN_PROVR__c: '',
        IDN_PMT__c: '',
        TXT_INFO_OTHER__c: '',
        IDN_RCPT_PMT__c: '',
        TXT_NBR_CHECK_PMT__c: ''
    };
    @track showConfirmationModal = false;

    connectedCallback() {
        this.clearAllFields();
    }
    
    renderedCallback() {
        if (!this.isReadyToRender) return;
        
        // Get all lookup components
        const caseLookup = this.template.querySelector('c-custom-lookup_lwc[name="IDN_CASE__c"]');
        const providerLookup = this.template.querySelector('c-custom-lookup_lwc[name="IDN_PROVR__c"]');
        const paymentLookup = this.template.querySelector('c-custom-lookup_lwc[name="IDN_PMT__c"]');
        
        // Set lookup values for each component
        this.setLookupValue(caseLookup, this.adjPaymentObj.IDN_CASE__c, this.caseLookupLabel, 'Case');
        this.setLookupValue(providerLookup, this.adjPaymentObj.IDN_PROVR__c, this.providerLookupLabel, 'Provider');
        this.setLookupValue(paymentLookup, this.adjPaymentObj.IDN_PMT__c, this.paymentLookupLabel, 'Payment');
    }


    initializeData() {
        // Special handling for T_ADJMT_PMT__c
        if (this.parentObjectAPI === 'T_ADJMT_PMT__c') {
            this.showSpinner = true;
            this.getCountiesOnly();
            this.parentObjectName = 'New Adjustment Payment';
            this.clearAllFields();
            
            this.isReadyToRender = true;
            this.showSpinner = false;
            return;
        }
        
        if (!this.parentObjectId || !this.parentObjectAPI) {
            this.handleError('Missing required parameters for initialization');
            return;
        }
        
        this.showSpinner = true;
        let params = {'parentObjectId': this.parentObjectId, 'parentObjectAPI': this.parentObjectAPI };
        this.recordError = [];
        this.message = null;
        this.resetFieldValidationErrors();
        
        helper.callServer(this,'adjustmentPaymentFlowApexController','getInitData',(function(result){
            if (result.isSuccessful) {
                this.assignedCounties = result.objectData.assignedCounties;
                this.parentObjectName = result.objectData.parentObjectName;
                
                this.clearAllFields();
                
                // Set values based on parent object type
                if (this.parentObjectAPI === 'T_SBSD_CASE__c') {
                    this.adjPaymentObj.IDN_CASE__c = this.parentObjectId;
                    this.caseLookupLabel = this.parentObjectName;
                } 
                else if (this.parentObjectAPI === 'T_CHATS_PROVR_STATUS__c') {
                    this.adjPaymentObj.IDN_PROVR__c = this.parentObjectId;
                    this.providerLookupLabel = this.parentObjectName;
                } 
                else if (this.parentObjectAPI === 'T_PAYMT__c') {
                    this.adjPaymentObj.IDN_PMT__c = this.parentObjectId;
                    this.paymentLookupLabel = this.parentObjectName;
                }
                
                this.adjPaymentObj = {...this.adjPaymentObj};
                this.isReadyToRender = true;
            } else {
                this.processErrorResponse(result);
            }
            this.showSpinner = false;
        }).bind(this),JSON.stringify(params));
    }

    clearAllFields() {
        this.adjPaymentObj = {
            sobjectType: 'T_ADJMT_PMT__c',
            AMT_PMT_ADJMT__c: '',
            CDE_COUNTY__c: '',
            CDE_ACTION_ADMIN__c: '',
            CDE_TYPE_PMT_ADJMT__c: '',
            IDN_CASE__c: '',
            DTE_PMT_ADJMT__c: '',
            IDN_PROVR__c: '',
            IDN_PMT__c: '',
            TXT_INFO_OTHER__c: '',
            IDN_RCPT_PMT__c: '',
            TXT_NBR_CHECK_PMT__c: ''
        };
    }

    handleSave() {
        if (this.checkCustomValidations()) {
            this.showConfirmationModal = true;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('refresh'));
        this.navigateBack();
    }

    handleConfirmationYes() {
        this.showConfirmationModal = false;
        this.saveRecord();
    }

    handleConfirmationNo() {
        this.showConfirmationModal = false;
    }

    saveRecord() {
        this.showSpinner = true;
        
        let adjPaymentObjToSave = {...this.adjPaymentObj};
        
        // Special handling for T_ADJMT_PMT__c with dummy ID
        if (this.parentObjectAPI === 'T_ADJMT_PMT__c' && 
            this.parentObjectId === 'DUMMY_ID_FOR_T_ADJMT_PMT') {
            if (adjPaymentObjToSave.Id) {
                delete adjPaymentObjToSave.Id;
            }
        }
        
        let params = {'adjPaymentObj': adjPaymentObjToSave};
        this.recordError = [];
        this.message = null;
        this.resetFieldValidationErrors();
        
        helper.callServer(this,'adjustmentPaymentFlowApexController','saveAdjustmentPayment',(function(result){
            if (result.isSuccessful) {
                this.handleSuccess('Adjustment Payment created successfully');
                // Refresh the view
                this.dispatchEvent(new CustomEvent('refresh'));
                // Navigate back
                if (!this.parentObjectId || this.parentObjectId === 'DUMMY_ID_FOR_T_ADJMT_PMT') {
                    this.navigateBack();
                } else {
                    this.navigateToRecord(this.parentObjectId);
                }
            } else {
                this.processErrorResponse(result);
                this.showConfirmationModal = false;
            }
            this.showSpinner = false;
        }).bind(this),JSON.stringify(params));
    }
    
    processErrorResponse(result) {
        this.recordError = [];
        this.message = 'error';
        
        // Process main error message
        if (result.message) {
            this.recordError.push({
                Id: 'error-' + Date.now() + '-0',
                message: result.message
            });
        }
        
        // Process field validation errors
        if (result.lstAPXFieldValidationError && Array.isArray(result.lstAPXFieldValidationError)) {
            for (let i = 0; i < result.lstAPXFieldValidationError.length; i++) {
                const error = result.lstAPXFieldValidationError[i];
                if (error.isTopOfPageError) {
                    this.recordError.push({
                        Id: 'error-' + Date.now() + '-' + (i + 1),
                        message: error.errorMessage
                    });
                } else {
                    const fieldName = error.fieldName;
                    if (fieldName && this.fieldValidationErrors.hasOwnProperty(fieldName)) {
                        this.fieldValidationErrors[fieldName] = error.errorMessage;
                    }
                }
            }
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        }
        
        // Process DML errors
        if (result.objectData && result.objectData.dmlErrorMessages && Array.isArray(result.objectData.dmlErrorMessages)) {
            const dmlErrors = result.objectData.dmlErrorMessages;
            for (let i = 0; i < dmlErrors.length; i++) {
                this.recordError.push({
                    Id: 'error-' + Date.now() + '-dml-' + i,
                    message: dmlErrors[i]
                });
            }
        }
    }

    checkCustomValidations() {
        let isRequiredFieldsVerified = true;
        let blankFieldNames = '';
        let amountError = false;

        this.resetFieldValidationErrors();

        if (this.isEmpty(this.adjPaymentObj.AMT_PMT_ADJMT__c)) {
            isRequiredFieldsVerified = false;
            blankFieldNames = this.checkBlankFields(blankFieldNames, 'Amount');
            this.fieldValidationErrors.AMT_PMT_ADJMT__c = 'Amount is required';
        }
        if (this.isEmpty(this.adjPaymentObj.CDE_COUNTY__c)) {
            isRequiredFieldsVerified = false;
            blankFieldNames = this.checkBlankFields(blankFieldNames, 'County');
            this.fieldValidationErrors.CDE_COUNTY__c = 'County is required';
        }
        if (this.isEmpty(this.adjPaymentObj.CDE_TYPE_PMT_ADJMT__c)) {
            isRequiredFieldsVerified = false;
            blankFieldNames = this.checkBlankFields(blankFieldNames, 'Payment Type');
            this.fieldValidationErrors.CDE_TYPE_PMT_ADJMT__c = 'Payment Type is required';
        }
        if (this.isEmpty(this.adjPaymentObj.DTE_PMT_ADJMT__c)) {
            isRequiredFieldsVerified = false;
            blankFieldNames = this.checkBlankFields(blankFieldNames, 'Date Paid');
            this.fieldValidationErrors.DTE_PMT_ADJMT__c = 'Date Paid is required';
        }
         if (!this.isEmpty(this.adjPaymentObj.AMT_PMT_ADJMT__c) && this.adjPaymentObj.AMT_PMT_ADJMT__c <=0) {
            this.fieldValidationErrors.AMT_PMT_ADJMT__c = 'Please enter an amount greater than 0.';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
            amountError = true;
        }

        this.fieldValidationErrors = {...this.fieldValidationErrors};

        if (!isRequiredFieldsVerified) {
            this.handleError('Please fill all the mandatory fields: ' + blankFieldNames);
            return false;
        }
         if(amountError){  
            return false;
        }
        return true;
    }
    
    resetFieldValidationErrors() {
        this.fieldValidationErrors = {
            AMT_PMT_ADJMT__c: '',
            CDE_COUNTY__c: '',
            CDE_ACTION_ADMIN__c: '',
            CDE_TYPE_PMT_ADJMT__c: '',
            IDN_CASE__c: '',
            DTE_PMT_ADJMT__c: '',
            IDN_PROVR__c: '',
            IDN_PMT__c: '',
            TXT_INFO_OTHER__c: '',
            IDN_RCPT_PMT__c: '',
            TXT_NBR_CHECK_PMT__c: ''
        };
    }

    checkBlankFields(blankFieldNames, fieldName) {
        if (this.isEmpty(blankFieldNames)) {
            blankFieldNames += fieldName;
        } else {
            blankFieldNames += ', ' + fieldName;
        }
        return blankFieldNames;
    }

    isEmpty(value) {
        return value === null || value === undefined || value === '';
    }

    handleSuccess(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success'
            })
        );
    }

    handleError(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }

    extractErrorMessage(error) {
        let message = 'Unknown error';
        if (error) {
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (error.body && typeof error.body.message === 'string') {
                message = error.body.message;
            } else if (typeof error.message === 'string') {
                message = error.message;
            }
        }
        return message;
    }

    // Navigate back
    navigateBack() {
        window.history.back();
    }

    // Navigate to record
    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    handleAmountChange(event) {
        this.adjPaymentObj.AMT_PMT_ADJMT__c = event.target.value;
        // Clear field error when value is entered
        if (!this.isEmpty(this.adjPaymentObj.AMT_PMT_ADJMT__c)) {
            this.fieldValidationErrors.AMT_PMT_ADJMT__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        }
        if (!this.isEmpty(this.adjPaymentObj.AMT_PMT_ADJMT__c)) {
            if(this.adjPaymentObj.AMT_PMT_ADJMT__c <= 0){
                this.fieldValidationErrors.AMT_PMT_ADJMT__c = 'Please enter an amount greater than 0.';
                this.fieldValidationErrors = {...this.fieldValidationErrors};    
            }
        }
    }

    handleCountyChange(event) {
        this.adjPaymentObj.CDE_COUNTY__c = event.target.value;
        // Clear field error when value is selected
        if (!this.isEmpty(this.adjPaymentObj.CDE_COUNTY__c)) {
            this.fieldValidationErrors.CDE_COUNTY__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        }
    }

    handleAdminActionChange(event) {
        this.adjPaymentObj.CDE_ACTION_ADMIN__c = event.detail.value;
        // Clear field error when value is selected
        if (!this.isEmpty(this.adjPaymentObj.CDE_ACTION_ADMIN__c)) {
            this.fieldValidationErrors.CDE_ACTION_ADMIN__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        }
    }

    handlePaymentTypeChange(event) {
        this.adjPaymentObj.CDE_TYPE_PMT_ADJMT__c = event.detail.value;
        // Clear field error when value is selected
        if (!this.isEmpty(this.adjPaymentObj.CDE_TYPE_PMT_ADJMT__c)) {
            this.fieldValidationErrors.CDE_TYPE_PMT_ADJMT__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        }
    }

    handleDatePaidChange(event) {
        this.adjPaymentObj.DTE_PMT_ADJMT__c = event.target.value;
        // Clear field error when value is entered
        if (!this.isEmpty(this.adjPaymentObj.DTE_PMT_ADJMT__c)) {
            this.fieldValidationErrors.DTE_PMT_ADJMT__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        }
    }

    handleOtherChange(event) {
        this.adjPaymentObj.TXT_INFO_OTHER__c = event.target.value;
        // Clear field error when value is entered
        if (!this.isEmpty(this.adjPaymentObj.TXT_INFO_OTHER__c)) {
            this.fieldValidationErrors.TXT_INFO_OTHER__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        }
    }

    handleReceiptNumberChange(event) {
        this.adjPaymentObj.IDN_RCPT_PMT__c = event.target.value;
        // Clear field error when value is entered
        if (!this.isEmpty(this.adjPaymentObj.IDN_RCPT_PMT__c)) {
            this.fieldValidationErrors.IDN_RCPT_PMT__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        }
    }

    handleCheckNumberChange(event) {
        this.adjPaymentObj.TXT_NBR_CHECK_PMT__c = event.target.value;
        // Clear field error when value is entered
        if (!this.isEmpty(this.adjPaymentObj.TXT_NBR_CHECK_PMT__c)) {
            this.fieldValidationErrors.TXT_NBR_CHECK_PMT__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        }
    }

    handleCaseSelected(event) {
        if (event.detail && event.detail.record) {
            this.adjPaymentObj.IDN_CASE__c = event.detail.record.Id;
            this.caseLookupLabel = event.detail.record.Name;
            // Clear field error when value is selected
            this.fieldValidationErrors.IDN_CASE__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        } else {
            this.adjPaymentObj.IDN_CASE__c = '';
            this.caseLookupLabel = '';
        }
    }

    handleProviderSelected(event) {
        if (event.detail && event.detail.record) {
            this.adjPaymentObj.IDN_PROVR__c = event.detail.record.Id;
            this.providerLookupLabel = event.detail.record.Name;
            // Clear field error when value is selected
            this.fieldValidationErrors.IDN_PROVR__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        } else {
            this.adjPaymentObj.IDN_PROVR__c = '';
            this.providerLookupLabel = '';
        }
    }

    handlePaymentSelected(event) {
        if (event.detail && event.detail.record) {
            this.adjPaymentObj.IDN_PMT__c = event.detail.record.Id;
            this.paymentLookupLabel = event.detail.record.Name;
            // Clear field error when value is selected
            this.fieldValidationErrors.IDN_PMT__c = '';
            this.fieldValidationErrors = {...this.fieldValidationErrors};
        } else {
            this.adjPaymentObj.IDN_PMT__c = '';
            this.paymentLookupLabel = '';
        }
    }

    // Handle page error - called when the page-messages component fires a message-type-change event
    handlePageError(event) {
        const messageType = event.detail.value;
        if (messageType === 'error') {
            this.showConfirmationModal = false;
        }
    }
    
    getCountiesOnly() {
        // Call the server to get just the counties
        let params = {'parentObjectId': '', 'parentObjectAPI': 'T_ADJMT_PMT__c' };
        
        this.recordError = [];
        this.message = null;
        
        helper.callServer(this,'adjustmentPaymentFlowApexController','getInitData',(function(result){
            if (result.isSuccessful) {
                this.assignedCounties = result.objectData.assignedCounties;
            } else {
                this.processErrorResponse(result);
            }
        }).bind(this),JSON.stringify(params));
    }
    
    setLookupValue(lookupComponent, recordId, recordName) {
        
        if (!lookupComponent || !recordId || !recordName) {
            return;
        }
        
        try {
            if (typeof lookupComponent.setSelectedRecord === 'function') {
                lookupComponent.setSelectedRecord({
                    Id: recordId,
                    Name: recordName
                });
            }
            else if (typeof lookupComponent.setSelectedRecordId === 'function') {
                lookupComponent.setSelectedRecordId(recordId, recordName);
            }
        } catch (error) {
            console.error('Error setting lookup value:', error);
        }
    }
}