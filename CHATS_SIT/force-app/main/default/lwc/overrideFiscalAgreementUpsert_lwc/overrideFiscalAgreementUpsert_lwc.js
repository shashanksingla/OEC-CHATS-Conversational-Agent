import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { helper } from 'c/generic_Utilities';
import Id from '@salesforce/user/Id';
import ERRORS_ON_THIS_PAGE from '@salesforce/label/c.ERRORS_ON_THIS_PAGE';

export default class OverrideFiscalAgreementUpsert_lwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api sObjectName;
    @track currentTabNumber = 1;
    @track pageMessages = [];
    @track messageType;
    @track fieldValidationErrors = [];
    @track showSpinner = false;
    @track initDataLoaded = false;
    @track isUpdate = false;
    @track countyMismatchMessage = '';
    @track fieldDefinition = [];
    @track errorComponentIds = [];
    @track userData = {};
    @track ownerId = '';
    @track parentId = '';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            if (currentPageReference.state && currentPageReference.state.c__recordId) {
                this.recordId = currentPageReference.state.c__recordId;
            }
            if (currentPageReference.state && currentPageReference.state.c__sObjectName) {
                this.sObjectName = currentPageReference.state.c__sObjectName;
            }
        }
    }

    // Component configuration
    objectName = 'T_PROVR_FISCAL_AGREMENT__c';
    fieldNames = [
        'T_PROVR_FISCAL_AGREMENT__c.CDE_TYPE_FACILITY__c',
        'T_PROVR_FISCAL_AGREMENT__c.ID_SERVICE__c',
        'T_PROVR_FISCAL_AGREMENT__c.CDE_TYPE_STATUS__c',
        'T_PROVR_FISCAL_AGREMENT__c.CDE_COUNTY__c',
        'T_PROVR_FISCAL_AGREMENT__c.DTE_BEGIN_AGRMT__c',
        'T_PROVR_FISCAL_AGREMENT__c.DTE_END_AGRMT__c',
        'T_PROVR_FISCAL_AGREMENT__c.CDE_REASON_END_AGRMT__c',
        'T_PROVR_FISCAL_AGREMENT__c.DTE_RCV_AGRMT_FISCAL__c',
        'T_PROVR_FISCAL_AGREMENT__c.Record_Type_Name__c',
        'T_PROVR_FISCAL_AGREMENT__c.OwnerId'
    ];
    
    sectionInformation = {
        'CDE_TYPE_FACILITY__c': 'Information'
    };
    
    requiredFields = [
        'T_PROVR_FISCAL_AGREMENT__c.ID_SERVICE__c',
        'T_PROVR_FISCAL_AGREMENT__c.CDE_COUNTY__c',
        'T_PROVR_FISCAL_AGREMENT__c.CDE_TYPE_STATUS__c',
        'T_PROVR_FISCAL_AGREMENT__c.DTE_BEGIN_AGRMT__c',
        'T_PROVR_FISCAL_AGREMENT__c.OwnerId'
    ];

    @track providerFiscalAgreement = {
        sobjectType: 'T_PROVR_FISCAL_AGREMENT__c',
        CDE_TYPE_STATUS__c: 'DFT'
    };

    get cardTitle() {
        return !this.parentId ? 'CREATE NEW' : 'EDIT';
    }

    get isCurrentTab() {
        return this.currentTabNumber === 1;
    }

    get emptySpaceKey() {
        return 'empty-space-key';
    }

    get showCancelButton() {
        return true;
    }

    get showFinishButton() {
        return true;
    }

    get totalTabsValue() {
        return 1;
    }

    get hasPageMessages(){
        return this.pageMessages && this.pageMessages.length > 0;
    }

    connectedCallback() {
        this.initializeComponent();
    }

    initializeComponent() {
        try {           
            if (this.objectName === this.sObjectName) {
                this.parentId = this.recordId;
            }             
            helper.callServer(this, 'DynamicFormGenerationController', 'fetchUserdata', (function (response) {
                if (response.isSuccessful) {
                    this.userData = response.objectData;
                } 
            }).bind(this));            
            this.getInitData();
        } catch (error) {
            console.error('Error in initialization:', error);
        }
    }

    getInitData() {
        this.showSpinner = true;       
        try {
            helper.callServer(this, 'DynamicFormGenerationController', 'getFieldDefinition', (function (response) {
                if (response) {
                    this.processFieldDefinitions(response);
                    this.includeRequiredFieldInFieldDefinition();
                    this.includeReadOnlyInFieldDefinition();

                    if (this.parentId) {
                        const dataString = JSON.stringify(response);
                        helper.callServer(this, 'DynamicFormGenerationController', 'getDataOnLoadInCHATS', (function (response) {
                            if (response && response.Id) {    
                                this.initDataLoaded = false;                          
                                setTimeout(() => {
                                    this.providerFiscalAgreement = { ...response };                                    
                                    if (response.OwnerId) {
                                        this.ownerId = response.OwnerId;
                                    }
                                    this.includeReadOnlyInFieldDefinition();
                                    this.initDataLoaded = true;
                                });
                            } else {
                                console.error(' Condition failed - response:', response);
                            }
                        }).bind(this), JSON.stringify({fieldList: dataString, sObjectId: this.parentId}));
                    } else{
                        this.providerFiscalAgreement.OwnerId = this.getCurrentUserId();  
                    }
                    this.showSpinner = false;
                    this.initDataLoaded = true;
                } 
            }).bind(this), JSON.stringify({ lstObjectToField: this.fieldNames }));
        } catch (error) {
            console.error('Error getting init data:', error);
        } finally {
            this.showSpinner = false;
        }
    }

    processFieldDefinitions(fieldDefinitions) {
        let sectionBreakerPoint = 0;
        fieldDefinitions.forEach((fieldDefinition, index) => {
            fieldDefinition.fieldKey = `field-${fieldDefinition.fieldAPIName}`;
            fieldDefinition.sectionKey = `section-${fieldDefinition.fieldAPIName}`;
            fieldDefinition.sectionBreakKey = `break-${fieldDefinition.fieldAPIName}`;
            fieldDefinition.errorKey = `${fieldDefinition.objectName}-${fieldDefinition.fieldAPIName}`;
            fieldDefinition.isRecordTypeName = fieldDefinition.fieldAPIName === 'Record_Type_Name__c';
            if (this.sectionInformation[fieldDefinition.fieldAPIName]) {
                fieldDefinition.preSectionName = this.sectionInformation[fieldDefinition.fieldAPIName];
                if (index !== 0 && sectionBreakerPoint % 2 === 0) {
                    fieldDefinition.sectionBreakerPoint = true;
                    sectionBreakerPoint = 0;
                } else {
                    sectionBreakerPoint++;
                }
            }
            if (fieldDefinition.referenecedObjectName && 
                this.sObjectName == fieldDefinition.referenecedObjectName) {
                this.providerFiscalAgreement[fieldDefinition.fieldAPIName] = this.recordId;
            }
        });
        this.fieldDefinition = fieldDefinitions;
    }

    includeRequiredFieldInFieldDefinition() {
        this.fieldDefinition.forEach(fieldDefinition => {
            const fieldKey = `${fieldDefinition.objectName}.${fieldDefinition.fieldAPIName}`;
            fieldDefinition.required = this.requiredFields.includes(fieldKey);
        });
    }

    includeReadOnlyInFieldDefinition() {
        let readOnlyFields = ['T_PROVR_FISCAL_AGREMENT__c.CDE_TYPE_FACILITY__c'];
        //Removing reference for CHATS System Administrator CCCAP-14993
        //  Removed if since this.userData.userProfileName !== 'CHATS System Administrator' always returns true
        readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.CDE_TYPE_STATUS__c');
        
        if (!this.parentId) {
            readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.DTE_END_AGRMT__c');
            readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.CDE_REASON_END_AGRMT__c');
        } else if (this.providerFiscalAgreement.Record_Type_Name__c === 'Draft' && 
                   this.providerFiscalAgreement.DTE_END_AGRMT__c && 
                   this.providerFiscalAgreement.DTE_BEGIN_AGRMT__c) {
            readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.DTE_END_AGRMT__c');
            readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.CDE_REASON_END_AGRMT__c');
            readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.CDE_COUNTY__c');
        }
        //CCCAP-14993 Removing reference for CHATS System Administrator
        //  Removed userData since this.userData.userProfileName !== 'CHATS System Administrator' always returns true
        if (this.providerFiscalAgreement.Record_Type_Name__c) {
            
            readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.DTE_END_AGRMT__c');
            readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.CDE_COUNTY__c');
            
            if (this.providerFiscalAgreement.Record_Type_Name__c === 'Open') {
                readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.DTE_RCV_AGRMT_FISCAL__c');
                readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.DTE_END_AGRMT__c');
                readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.CDE_REASON_END_AGRMT__c');
            } else if (this.providerFiscalAgreement.Record_Type_Name__c === 'Finalized') {
                readOnlyFields = [
                    'T_PROVR_FISCAL_AGREMENT__c.CDE_TYPE_FACILITY__c',
                    'T_PROVR_FISCAL_AGREMENT__c.CDE_REASON_END_AGRMT__c',
                    'T_PROVR_FISCAL_AGREMENT__c.ID_SERVICE__c',
                    'T_PROVR_FISCAL_AGREMENT__c.CDE_TYPE_STATUS__c',
                    'T_PROVR_FISCAL_AGREMENT__c.CDE_COUNTY__c',
                    'T_PROVR_FISCAL_AGREMENT__c.DTE_END_AGRMT__c',
                    'T_PROVR_FISCAL_AGREMENT__c.DTE_BEGIN_AGRMT__c',
                    'T_PROVR_FISCAL_AGREMENT__c.DTE_RCV_AGRMT_FISCAL__c'
                ];
            } else if (this.providerFiscalAgreement.Record_Type_Name__c === 'Closed') {
                readOnlyFields = [
                    'T_PROVR_FISCAL_AGREMENT__c.CDE_TYPE_FACILITY__c',
                    'T_PROVR_FISCAL_AGREMENT__c.ID_SERVICE__c',
                    'T_PROVR_FISCAL_AGREMENT__c.CDE_TYPE_STATUS__c',
                    'T_PROVR_FISCAL_AGREMENT__c.CDE_COUNTY__c',
                    'T_PROVR_FISCAL_AGREMENT__c.DTE_BEGIN_AGRMT__c',
                    'T_PROVR_FISCAL_AGREMENT__c.DTE_RCV_AGRMT_FISCAL__c',
                    'T_PROVR_FISCAL_AGREMENT__c.CDE_REASON_END_AGRMT__c'
                ];
            }
        }
        //CCCAP-14993 reference not replaced since checking for only standard profile
        if ((!this.userData || this.userData.userProfileName !== 'System Administrator') &&
            this.providerFiscalAgreement.Record_Type_Name__c === 'Open') {
            readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.DTE_BEGIN_AGRMT__c');
            readOnlyFields.push('T_PROVR_FISCAL_AGREMENT__c.ID_SERVICE__c');
        }

        this.fieldDefinition.forEach(fieldDefinition => {
            const fieldKey = `${fieldDefinition.objectName}.${fieldDefinition.fieldAPIName}`;
            fieldDefinition.readOnly = readOnlyFields.includes(fieldKey);
        });
    }

    handleFinish(event) {
        try {
            const dynamicFormGenerators = this.template.querySelectorAll('c-dynamic-form-generator_lwc');
            let isValid = true;            
            dynamicFormGenerators.forEach(generator => {
                const result = generator.validateAndSetData();
                isValid = isValid && result;
            });

            if (isValid) {
                const providerId = this.providerFiscalAgreement.ID_SERVICE__c;                
                if (!this.providerFiscalAgreement.Id || 
                    this.providerFiscalAgreement.Id === '' || 
                    this.providerFiscalAgreement.Id === undefined) {
                    this.isUpdate = false;
                } else if (this.providerFiscalAgreement.CDE_TYPE_STATUS__c !== 'DFT') {
                    this.isUpdate = true;
                }
                helper.callServer(this, 'DynamicFormGenerationController', 'newFiscalAgreement', (function (response) {
                    if (response.isSuccessful) {
                        this.validateCountyAndSave();
                    } else {
                        this.pageMessages.push({
                            Id: 'error-' + Date.now() + '-0',
                            message: response.errorMessage
                        });
                        this.messageType = 'error';
                    }
                }).bind(this), JSON.stringify({ providerId: providerId, isUpdate: this.isUpdate}));
            } else {
                this.pageMessages.push({
                    Id: 'error-' + Date.now() + '-0',
                    message: ERRORS_ON_THIS_PAGE
                });
                this.messageType = 'error';
            }
        } catch (error) {
            console.error('Error in handleFinish:', error);
        }
    }

    validateCountyAndSave() {
        try {
            let countyMismatchMessage = '';
            const ownerChanged = this.ownerId !== this.providerFiscalAgreement.OwnerId;
            helper.callServer(this, 'DynamicFormGenerationController', 'checkCountyWithOwnerCounty', (function (countyResult) {
                if (!countyResult.objectData.countyMatched && !countyResult.objectData.ownerCountyMatched) {
                    countyMismatchMessage = `The fiscal agreement that you are trying to create is with ${countyResult.objectData.countyName} county. This does not match your assigned county(ies)`;
                    if (ownerChanged) {
                        countyMismatchMessage += ' and county(ies) of new owner.';
                    } else {
                        countyMismatchMessage += '.';
                    }
                    this.pageMessages.push({
                        Id: 'error-' + Date.now() + '-0',
                        message: countyMismatchMessage
                    });
                    this.messageType = 'error';
                } else if (!countyResult.objectData.countyMatched) {
                    countyMismatchMessage = `The fiscal agreement that you are trying to create is with ${countyResult.objectData.countyName} county. This does not match your assigned county(ies).`;
                    this.pageMessages.push({
                        Id: 'error-' + Date.now() + '-0',
                        message: countyMismatchMessage
                    });
                    this.messageType = 'error';
                } else if (!countyResult.objectData.ownerCountyMatched && ownerChanged) {
                    countyMismatchMessage = `The fiscal agreement that you are trying to create is with ${countyResult.objectData.countyName} county. This does not match the county(ies) of new owner.`;
                    this.pageMessages.push({
                        Id: 'error-' + Date.now() + '-0',
                        message: countyMismatchMessage
                    });
                    this.messageType = 'error';
                } else {
                    this.saveRecord();
                }
            }).bind(this), 
            JSON.stringify({ countyId: this.providerFiscalAgreement.CDE_COUNTY__c, ownerId: this.providerFiscalAgreement.OwnerId}));
        } catch (error) {
            console.error('Error in county validation:', error);
        }
    }

    saveRecord() {
        try {
            let record = { ...this.providerFiscalAgreement };
            record.attributes = { type: this.objectName }; 
            helper.callServer(this, 'GenericDataSaverApxCtrl', 'upsertRecordsFinal', (function (result) {
                if (result.isSuccessful) {
                    this.navigateToRecord(result.objectData.upsertedRecords[0].Id);
                    this.showToast('Success', 'Record has been successfully saved.', 'success');
                } else {
                    this.pageMessages.push({
                        Id: 'error-' + Date.now() + '-0',
                        message:  result.errorMessage
                    });
                    this.messageType = 'error';
                    var lstAPXFieldValidationError = result.lstAPXFieldValidationError;
                    if(lstAPXFieldValidationError){
                        var lstOnlyAPXFieldValidationError = [];
                        for(var i=0;i<lstAPXFieldValidationError.length;i++){
                            if(lstAPXFieldValidationError[i].isTopOfPageError==true){
                                this.pageMessages.push({
                                    Id: 'error-' + Date.now() + '-0',
                                    message:  lstAPXFieldValidationError[i].errorMessage
                                });
                            } else{
                                lstOnlyAPXFieldValidationError.push(lstAPXFieldValidationError[i]);
                            }
                        }
                        this.fieldValidationErrors = lstOnlyAPXFieldValidationError;
                        this.handleFieldValidationErrors();
                    }
                }
            }).bind(this), JSON.stringify({ lstSObject: [record], isFinalStep: true }));            
        } catch (error) {
            console.error('Error saving record:', error);
            this.showToast('Error', 'Error saving record', 'error');
        }
    }
    handleFieldValidationErrors() {
        const fieldValidationErrors = this.fieldValidationErrors;        
        const newErrorComponentIds = [];
        const errorComponentIds = this.errorComponentIds;
        const errorMessageComps = this.template.querySelectorAll('c-field-level-message_lwc');
        
        if (fieldValidationErrors && fieldValidationErrors.length > 0) {
            for (let i = 0; i < fieldValidationErrors.length; i++) {
                const errorKey = `${fieldValidationErrors[i].sObjectName}-${fieldValidationErrors[i].fieldName}`;
                
                for (let j = 0; j < errorMessageComps.length; j++) {
                    const errorMessageComp = errorMessageComps[j];
                    const componentErrorKey = errorMessageComp.errorKey;
                    
                    if (componentErrorKey === errorKey) {
                        errorMessageComp.message = fieldValidationErrors[i].errorMessage;
                        newErrorComponentIds.push(errorKey);
                        break;
                    }
                }
            }
        }
        for (let i = 0; i < errorComponentIds.length; i++) {
            if (newErrorComponentIds.indexOf(errorComponentIds[i]) < 0) {
                errorMessageComps.forEach(errorMessageComp => {
                    const componentErrorKey = errorMessageComp.errorKey;
                    if (componentErrorKey === errorComponentIds[i]) {
                        errorMessageComp.message = null;
                    }
                });
            }
        }
        this.errorComponentIds = newErrorComponentIds;
    }

    handleHideCountyMismatch() {
        const modal = this.template.querySelector('c-confirmation-modal_l-w-c');
        if (modal) {
            modal.hideConfirmModal();
        }
        this.saveRecord();
    }

    handleCancel() {
        window.history.back();
    }

    handleValidateAndSetData(event) {
        event.stopPropagation();
        // Handle validation from child components
        const fieldApi = event.target.dataset.fieldApi;
    }

    handleSObjectUpdate(event){
        this.pageMessages = [];
        this.fieldValidationErrors = [];
        this.handleFieldValidationErrors();
        if(event.detail.record){
            this.providerFiscalAgreement = event.detail.record;
        }
        event.stopPropagation();
    }

    getCurrentUserId() {
        return Id;
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(event);
    }
}