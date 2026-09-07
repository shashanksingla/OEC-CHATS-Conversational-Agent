import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { helper } from 'c/generic_Utilities';
import { RefreshEvent } from 'lightning/refresh';

export default class EditRecurrencePatternFlow_lwc extends LightningElement {
    @track recordError = [];
    @track message;
    @track pageMessages = [];
    @track messageType = '';
    @track recordError = [];
    @track fieldValidationErrors = [];
    @track initDataLoaded = false;
    @track isValid = false;
    @track isCurrentPageValid = false;
    @track showSpinner = false;
    @track sObjectName = '';

    @api recordId;
    @api showEditModal = false;
    @api authSchRecurrObj = {
        sobjectType: 'Auth_Schedule_Recurrence__c',
        IDN_AUTH__c: '',
        DTE_Begin_Date__c: '',
        DTE_End_Date__c: '',
        Fri__c: '',
        Mon__c: '',
        RecurDay__c: '',
        RecurDays__c: '',
        Recur_Type__c: '',
        Sat__c: '',
        Sun__c: '',
        Thur__c: '',
        Wed__c: '',
        WeekDays__c: '',
        Name: '',
        Tue__c: '',
        DaysOfMonth__c: ''
    };
    @api authEndDate;

    connectedCallback() {
        this.doInit();
    }

    doInit() {
        const params={
            recordId: this.recordId
        };
        helper.callServer(this,'AuthorizationFlowApxCtrl','getSelectedScheduleRecurrence',(function(res){
            if(res && res.isSuccessful){
                
                if (res.objectData.authSchRecurrObj) {
                    this.authSchRecurrObj = { ...res.objectData.authSchRecurrObj };
                }
                
                this.sObjectName = res.objectData.getSobjectName;
                this.initDataLoaded = true;
            }else{
                this.showToast('Error', 'Problem getting authorization data', 'error');
            }
        }).bind(this), JSON.stringify(params));
    }

    handleValidatePage(event) {
        this.recordError = [];
        this.message = null;
        this.isValid = event.detail.isValid;
        this.isCurrentPageValid = event.detail.isValid;
        
        // Update the authSchRecurrObj from child component
        const childComponent = this.template.querySelector('c-recurrence-patten-pg1_lwc');
        if (childComponent&&this.isValid) {
            this.authSchRecurrObj = { ...childComponent.authSchRecurrObjProp };
        }
    }

    doFinish() {
        // Call validation on child component
        const childComponent = this.template.querySelector('c-recurrence-patten-pg1_lwc');
        if (childComponent) {
            childComponent.callValidateCurrentPage();
        }
                
        if (this.isValid === true) {
            this.showSpinner = true;
            
            let record = this.authSchRecurrObj ;
            record.attributes = { type: 'Auth_Schedule_Recurrence__c' };
            this.recordError = [];
            this.message = null;

            helper.callServer(this, 'GenericDataSaverApxCtrl', 'upsertRecordsFinal', (function(response){
                if(response){
                if(response.isSuccessful){
                        this.showToast('Success!', 'Authorization Recurrence has been updated successfully.', 'success');
                        this.dispatchEvent(new RefreshEvent());
                        this.fireCloseModel(true);
                        this.showSpinner = false;
                }else{
                    this.processErrorResponse(response);
                }
                }else{
                    this.showToast('Error', 'Error updating authorization recurrence', 'error');
                    this.showSpinner = false;
                }
            }).bind(this), JSON.stringify({ lstSObject: [record], isFinalStep: true }));

        }else {
            this.showSpinner = false;
        }
    }

    processErrorResponse(result) {
        this.recordError = [];
        this.message = 'error';
        
        // Process main error message
        if (result.errorMessage) {
            this.recordError.push({
                Id: 'error-' + Date.now() + '-0',
                message: result.errorMessage
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

    handleRecordError(event){
    const { recordError, message } = event.detail;
    this.recordError=recordError;
    this.message=message;
    }

    fireCloseModel(wasSuccessful = false){
        this.dispatchEvent(new CustomEvent('close',{
            detail:{
                value:false,
                wasSuccessful:wasSuccessful
                }
        }));
    }

    doCancel() {
        if (this.recordId) {
            this.fireCloseModel();
        } else {
            window.history.back();
        }
    }

    closeModel() {
        this.fireCloseModel();
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}