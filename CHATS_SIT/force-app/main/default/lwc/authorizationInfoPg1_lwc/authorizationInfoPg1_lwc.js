import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import Exempt_Provider_Type from '@salesforce/label/c.Exempt_Provider_Type';
import authorization_question_transFee from '@salesforce/label/c.authorization_question_transFee';
import NAM_FACILITY_FIELD from '@salesforce/schema/T_CHATS_PROVR_STATUS__c.NAM_FACILITY__c';
import ID_FIELD from '@salesforce/schema/T_CHATS_PROVR_STATUS__c.Id';
import NAME_FIELD from '@salesforce/schema/T_CHATS_PROVR_STATUS__c.Name';
import IS_UPK_PROVIDER_FIELD from '@salesforce/schema/T_CHATS_PROVR_STATUS__c.Is_UPK_Provider__c';

export default class AuthorizationInfoPg1Lwc extends LightningElement {
    @track authBeginDate;
    @track recordError = '';
    @track slotContractIdVal = '';
    @track providerFiscalAgreementId = '';
    @track findProviderName = '';
    @track validatedChild = false;
    @track isFirstRecurrenceEntered = false;
    @track isAuthFlowFirstTime = false;
    @track isAuthUpdatedInCreateFlow = false;
    @track cmpValidated = false;
    @track isEnterRecurrence = false;
    @track isAuthFirstTime = false;
    @track isAuthUpdated = false;
    @track isReqProviderLocation = false;
    @track showTransFeeRestriction = false;
    @track isProviderExempt = false;
    @track authRecId = '';
    @track isProviderRelative = false;
    @track isProviderSibling = false;
    @track mandatory = false;
    @track childAge = null;

    @api authRec = { sobjectType: 'T_AUTH__c' };
    @api authRecClone = { sobjectType: 'T_AUTH__c' };
    @api clientRec = { sobjectType: 'T_SBSD_INDIV__c' };
    @api authProviderRec = { sobjectType: 'T_CHATS_PROVR_STATUS__c' };
    @api caseRec = { sobjectType: 'T_SBSD_CASE__c' };
    @api rateTypeOptions = [];
    @api childStateOptions = [];
    @api isCreate = false;
    @api hoursPerWeekDay = [];
    @api providerIdVal = '';
    @api isCountyRateSCQ = false;
    @api slotContractOptions = [];
    @api isInvalidProvider = false;
    @api isReadOnly = false;
    @api selectedLookUpRecord = {};
    @api providerRec = { sobjectType: 'T_CHATS_PROVR_STATUS__c' };
    @api sCAssociationRec = { sobjectType: 'T_SLOT_CONTRACT__c' };
    @api isShowContractToIndicator = false;
    @api isProtectiveServiceIndicator = false;
    @api isChildWefareCare = false;
    @api isChildDisable = false;
    @api enterRecurrence = false;
    @api isEncumbrnceCreated = false;
    @api isModifiedAfterChange = false;
    @api numberOfDaysDrop = 0;
    @api authDropInDays = 0;
    @api isDropInDaysIndicator = false;
    @api scheduleRecurrObj = { sobjectType: 'Auth_Schedule_Recurrence__c' };
    @api scheduleRecurr = [];
    @api authEndDate;
    @api isUPKEnrollmentManuallySet = false;
    @api upkFetchedValues = null;

    _fieldValidationErrors = [];
    nextUPKYear = false; //CCCAP-15329

    @api
    get fieldValidationErrors() {
        return this._fieldValidationErrors;
    }
    set fieldValidationErrors(value) {
        this._fieldValidationErrors = value;
        this.handleFieldLevelValidation();
    }
    
    @api
    callValidateCurrentPage() {
        return abs_helper.validateCurrentPage(this);
    }

    @api
    childRecurrenceMethod(cmpValidated, isEnterRecurrence, isAuthFirstTime, isAuthUpdated) {
        this.scheduleRecurrence(cmpValidated, isEnterRecurrence, isAuthFirstTime, isAuthUpdated);
    }

    @api
    childDisabilityMethod() {
        return this.checkChildDisabilityVal();
    }

    @api
    checkCustomValidations() {
        return this.validateAuthSlotBeginDate();
    }

    @wire(getRecord, { 
        recordId: '$providerIdVal', 
        fields: [ID_FIELD, NAME_FIELD, NAM_FACILITY_FIELD, IS_UPK_PROVIDER_FIELD] 
    })
    wiredProviderRecord({ error, data }) {
        if (data) {
            this.providerRec = {
                ...this.providerRec,
                Id: data.fields.Id.value,
                Name: data.fields.Name.value,
                NAM_FACILITY__c: data.fields.NAM_FACILITY__c.value,
                Is_UPK_Provider__c: data.fields.Is_UPK_Provider__c?.value || false
            };
            this.fetchUPKInformation();
            this.recordError = '';
        } else if (error) {
            console.error('Error fetching provider record:', error);
            this.recordError = error.body ? error.body.message : 'Error fetching provider data';
            this.providerRec = { sobjectType: 'T_CHATS_PROVR_STATUS__c' };
        }
    }

    connectedCallback() {
        this.doInit();
    }

    get isCreateMode() {
        return this.isCreate;
    }

    get isEditMode() {
        return !this.isCreate;
    }

    get childNameStateDisplay() {
        if (this.authRec && this.authRec.IDN_CLIENT__r) {
            const clientRec = this.authRec.IDN_CLIENT__r;
            const firstName = clientRec.NAM_FIRST__c || '';
            const lastName = clientRec.NAM_LAST__c || '';
            const stateId = clientRec.IDN_STATE__c || '';
            return `${firstName} ${lastName} / ${stateId}`;
        }
        return '';
    }

    get showSlotContractSection() {
        return this.isCountyRateSCQ;
    }

    get showProtectiveServices() {
        return (this.isCreate && this.isProtectiveServiceIndicator && this.isChildWefareCare) || (this.isReadOnly && this.authRec.Protective_Services_Indicator__c == true);
    }

    get showDropInDays() {
        return this.isReadOnly || (!this.isReadOnly && this.isDropInDaysIndicator);
    }

    get isReqDropInDays(){
        return !this.isReadOnly;
    }

    get upkEnrollmentPicklistOptions() {
        return [
            { label: 'Not Applicable', value: 'Not Applicable' },
            { label: 'No', value: 'No' },
            { label: 'Yes', value: 'Yes' },
            { label: 'Unknown', value: 'Unknown' }
        ];
    }

    get isUPKStackedOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
            { label: 'Declined', value: 'Declined' }
        ];
    }

    get isUPKEnrollmentDisabled() {
        if (this.isReadOnly) return true;
        if (!this.clientRec || this.clientRec.Age__c == null || this.clientRec.Age__c == undefined) return false;
        return this.clientRec.Age__c < 3 || this.clientRec.Age__c >= 6;
    }

    get defaultUPKEnrollmentValue() {
        if (!this.clientRec || this.clientRec.Age__c == null || this.clientRec.Age__c == undefined) return 'Not Applicable';
        if (this.clientRec.Age__c >= 3 && this.clientRec.Age__c < 6) return 'Unknown';
        return 'Not Applicable';
    }

    get isUPKRequired() {
        const endDate = this.authRec && this.authRec.DTE_END_EFFV_AUTH__c;
        if (!endDate) return true;
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const eDateArr = endDate.split('-');
        const eDate = new Date(Number(eDateArr[0]), Number(eDateArr[1]) - 1, Number(eDateArr[2]));
        return eDate >= today;
    }

    get isUPKStackedDisabled() {
        if (this.isReadOnly) return true;
        return this.authRec.CDE_CHILD_ENROLLED_IN_UPK__c !== 'Yes';
    }

    get showTransportationFee() {
        return (this.showTransFeeRestriction && !this.isProviderExempt) || !this.isEmpty(this.authRec.CDE_TRANS_FEE__c);
    }

    get transFeeQuestionLabel() {
        return authorization_question_transFee;
    }

    get providerLocationRequired() {
        return this.isCreate? this.isReqProviderLocation : (this.authProviderRec.CDE_TYPE_PROVR__c == 'EFACH' && !this.isReadOnly ? true : false);
    }

    get providerRelationshipRequired() {
        return this.isProviderRelative && !this.isReadOnly;
    }

    get providerResidenceRequired() {
        return (this.authRec.CDE_PRO_REL_CHLD__c == 'B' || this.authRec.CDE_PRO_REL_CHLD__c == 'S') && !this.isReadOnly;
    }

    get isProvRel() {
        const relProvr = this.authRec?.CDE_REL_PROVR__c;
        return relProvr === '2' || relProvr === '4';
    }

    get dropInDaysMax() {
        return this.numberOfDaysDrop;
    }

    get sundayHours() { return this.getHoursByDayIndex(0); }
    get mondayHours() { return this.getHoursByDayIndex(1); }
    get tuesdayHours() { return this.getHoursByDayIndex(2); }
    get wednesdayHours() { return this.getHoursByDayIndex(3); }
    get thursdayHours() { return this.getHoursByDayIndex(4); }
    get fridayHours() { return this.getHoursByDayIndex(5); }
    get saturdayHours() { return this.getHoursByDayIndex(6); }

    get sundayRateType() { return this.getRateTypeByDayIndex(0); }
    get mondayRateType() { return this.getRateTypeByDayIndex(1); }
    get tuesdayRateType() { return this.getRateTypeByDayIndex(2); }
    get wednesdayRateType() { return this.getRateTypeByDayIndex(3); }
    get thursdayRateType() { return this.getRateTypeByDayIndex(4); }
    get fridayRateType() { return this.getRateTypeByDayIndex(5); }
    get saturdayRateType() { return this.getRateTypeByDayIndex(6); }

    doInit() {
        this.initializeHoursPerWeekDay();
        if (!this.isCreate) {
            const authRecClone = { ...this.authRecClone };
            const authRec = { ...this.authRec };
            const authRecId = this.authRec.Id;
            this.authRecId = authRecId;
            this.mandatory = !this.isEmpty(authRec.IDN_SLOT_CONTRACT__c);
            
            if (!this.isEmpty(authRecClone.Id)) {
                authRec.IDN_SLOT_CONTRACT__c = authRecClone.IDN_SLOT_CONTRACT__c;
                authRec.DTE_BEGIN_SLOT__c = authRecClone.DTE_BEGIN_SLOT__c;
            }
            
            this.authRecClone = authRec;
            this.fireAuthRecCloneUpdateEvent();
            this.getRateTypeOptionsVal();
            this.validateIndicatorInEditFlow();
            this.setTransFeeRestriction();
            this.getSCAssociationsVal();
            this.populateSlotFields();
        }
        this.fetchClientDetails();
    }

    handleInputChange(event) {
        event.stopPropagation();
        try {
            const field = event.target.dataset.field;
            const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
            if (field && this.authRec) {
                this.authRec = {...this.authRec, [field] : value};                
                if (field === 'DTE_BEGIN_EFFV_AUTH__c') {
                    this.getRateTypes();
                    if(value >= this.getUpcomingJune30()){
                        this.nextUPKYear = true;
                        if(this.upkFetchedValues != null){
                            this.upkFetchedValues = null;
                            this.authRec = {
                                ...this.authRec,
                                CDE_CHILD_ENROLLED_IN_UPK__c: this.defaultUPKEnrollmentValue,
                                UPK_Start_date__c: null,
                                UPK_Awarded_Hours__c: null,
                                Is_UPK_Stacked__c: 'No'
                            };
                        }
                    } else{
                        this.nextUPKYear = false;
                        this.isUPKEnrollmentManuallySet = false;
                        this.fetchUPKInformation();
                    }
                } else if (field === 'Number_of_Drop_in_Days__c') {
                    this.authDropInDays = value;
                }
                const inputField = this.template.querySelector(`[data-field="${field}"]`);
                if(inputField){
                    if(inputField.tagName === 'C-MULTISELECT-COMBOBOX' || inputField.tagName === 'C-CUSTOM-LOOKUP_LWC') {
                        inputField.customErrorMessage = '';
                        inputField.reportValidity();
                    } else{
                        inputField.setCustomValidity('');
                        inputField.reportValidity();
                    }
                }
            }
        } catch (error) {
            console.error('Error in handleInputChange:', error);
            this.showToast('Error', 'An error occurred while updating the field: ' + error.message, 'error');
        }
    }

    handlePicklistChange(event) {
        event.stopPropagation();
        if (event.detail && event.detail.callingContext && event.detail.payload) {
            const contextParts = event.detail.callingContext.split('_');
            if (contextParts.length >= 3) {
                const fieldName = event.detail.callingContext.replace('T_AUTH__c_', '');
                this.authRec = { ...this.authRec, [fieldName]: event.detail.payload.value };
                if (fieldName === 'IDN_CLIENT__c') {
                    this.isUPKEnrollmentManuallySet = false;
                    this.getRateTypesBasedOnChild();
                    this.fetchClientDetails();
                } else if( fieldName === 'CDE_REL_PROVR__c') {
                    this.chkRelativeStatus();
                } else if( fieldName === 'CDE_PRO_REL_CHLD__c') {
                    this.getProviderRelationship();
                } else if( fieldName === 'IDN_SLOT_CONTRACT__c') {
                    this.populateSlotFields();
                }
                if (fieldName === 'CDE_CHILD_ENROLLED_IN_UPK__c') {
                    this.isUPKEnrollmentManuallySet = true;
                    const selectedValue = event.detail.payload.value;
                    const provRec = this.isCreate ? this.providerRec : this.authProviderRec;
                    if (selectedValue === 'Yes' && provRec && !provRec.Is_UPK_Provider__c) {
                        this.showToast('Warning', 'The selected provider is not a UPK Provider. Please select a UPK participating provider to update the child\'s dually enrolled status.','warning');
                    }
                    if (selectedValue === 'Yes') {
                        if(this.upkFetchedValues != null && this.upkFetchedValues.CDE_CHILD_ENROLLED_IN_UPK__c === 'Yes'){
                            this.authRec = {
                                ...this.authRec,
                                UPK_Start_date__c: this.upkFetchedValues.UPK_Start_date__c,
                                UPK_Awarded_Hours__c: this.upkFetchedValues.UPK_Awarded_Hours__c,
                            };
                        }
                    } else {
                        this.authRec = {
                            ...this.authRec,
                            UPK_Start_date__c: null,
                            UPK_Awarded_Hours__c: null,
                            Is_UPK_Stacked__c: 'No'
                        };
                    }
                    console.log('upk stacked after upk enrolled change: ' + this.authRec.Is_UPK_Stacked__c);
                }
                if(fieldName=='CDE_TYPE_VERIF__c'){
                const FIELD = 'CDE_SOURCE_VRFYD_IMMU__c';
                const ms = this.template.querySelector(`c-multiselect-combobox[data-field="${FIELD}"]`);
                ms.customErrorMessage='';
                ms.reportValidity();
                }
                const inputField = this.template.querySelector(`[data-field="${fieldName}"]`);
                if(inputField){
                    inputField.customErrorMessage = '';
                    inputField.reportValidity();
                }
            }
        }
    }

    handleProviderIdChange(event) {
        event.stopPropagation();
        try {
            this.providerIdVal = event.detail.record.Id;
            this.isUPKEnrollmentManuallySet = false;
            const providerLookup = this.template.querySelector('c-custom-lookup_lwc');
            if (providerLookup) {
                providerLookup.customErrorMessage = '';
                providerLookup.reportValidity();
            }
            this.validateProviderId();
            // CCCAP-15452 - Track provider record view to update RecentlyViewed
            this.trackProviderRecordView();
        } catch (error) {
            console.error('Error in handleProviderIdChange:', error);
            this.showToast('Error', 'An error occurred while updating provider ID: ' + error.message, 'error');
        }
    }

    trackProviderRecordView() {
        if (this.providerIdVal) {
            const params = {
                recordId: this.providerIdVal
            };
            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'trackProviderRecordView', (function (response) {
                // Record will appear in RecentlyViewed
            }).bind(this), JSON.stringify(params));
        }
    }

    handleHoursChange(event) {
        const dayIndex = parseInt(event.target.dataset.day);
        const updatedHoursPerWeekDay = [...this.hoursPerWeekDay];
        updatedHoursPerWeekDay[dayIndex] = {
            ...updatedHoursPerWeekDay[dayIndex],
            CNT_HOUR_CARE__c: event.target.value
        };
        this.hoursPerWeekDay = updatedHoursPerWeekDay;
    }

    handleRateTypeChange(event) {
        const dayIndex = parseInt(event.target.dataset.day);
        const updatedHoursPerWeekDay = [...this.hoursPerWeekDay];
        updatedHoursPerWeekDay[dayIndex] = {
            ...updatedHoursPerWeekDay[dayIndex],
            CDE_TYPE_UNIT_CARE__c: event.target.value
        };
        this.hoursPerWeekDay = updatedHoursPerWeekDay;
    }

    initializeHoursPerWeekDay() {
        if (!this.hoursPerWeekDay || this.hoursPerWeekDay.length === 0) {
            this.hoursPerWeekDay = [
                { CDE_TYPE_UNIT_CARE__c: '' },
                { CDE_TYPE_UNIT_CARE__c: '' },
                { CDE_TYPE_UNIT_CARE__c: '' },
                { CDE_TYPE_UNIT_CARE__c: '' },
                { CDE_TYPE_UNIT_CARE__c: '' },
                { CDE_TYPE_UNIT_CARE__c: '' },
                { CDE_TYPE_UNIT_CARE__c: '' }
            ];
        }
    }

    doSchedule() {
        if (this.isReadOnly) {
            this.enterRecurrence = true;
        } else {
            const event = new CustomEvent('recurrence', {
                detail: { cmpValidated: false }
            });
            this.dispatchEvent(event);
        }
    }

    scheduleRecurrence(cmpValidated, isEnterRecurrence, isAuthFirstTime, isAuthUpdated) {
        this.validatedChild = cmpValidated;
        this.isFirstRecurrenceEntered = isEnterRecurrence;
        this.isAuthFlowFirstTime = isAuthFirstTime;
        this.isAuthUpdatedInCreateFlow = isAuthUpdated;

        const authRec = this.authRec;
        const beginDate = authRec.DTE_BEGIN_EFFV_AUTH__c;
        const authRecId = authRec.Id;
        
        this.authRecId = authRecId;

        if (cmpValidated) {
            this.authBeginDate = beginDate;
            this.scheduleRecurrObj = {
                sobjectType: 'Auth_Schedule_Recurrence__c',
                Recur_Type__c: '',
                RecurDay__c: '',
                DTE_Begin_Date__c: '',
                DTE_End_Date__c: '',
                Sun__c: '',
                Mon__c: '',
                Tue__c: '',
                Wed__c: '',
                Thur__c: '',
                Fri__c: '',
                Sat__c: '',
                WeekDays__c: '',
                DaysOfMonth__c: ''
            };
            this.enterRecurrence = true;
        }
    }

    populateProviderId() {
        const providerRec = this.providerRec;        
        if (providerRec) {
            this.authRec = {
                ...this.authRec,
                IDN_PROVR__c: providerRec.ID_SERVICE__c
            };
            const provSelectedEvent = new CustomEvent('provselected', {
                detail: {
                    providerRec: providerRec
                }
            });
            this.dispatchEvent(provSelectedEvent);
        }
    }

    validateProviderId() {
        const providerId = this.providerIdVal;
        
        if (this.isEmpty(providerId)) {
            this.rateTypeOptions = [];
        } else {
            this.validateProviderIdVal();
            this.getSCAssociationsVal();
        }
    }

    getRateTypes() {
        this.isModifiedAfterChange = false;
        const authRec = this.authRec;
        const beginDate = authRec.DTE_BEGIN_EFFV_AUTH__c;
        const providerId = this.providerIdVal;
        const childId = authRec.IDN_CLIENT__c;
        
        if (this.isEmpty(beginDate)) {
            this.rateTypeOptions = [];
        } else if (this.isEmpty(childId)) {
            this.rateTypeOptions = [];
        } else if (providerId && beginDate) {
            this.validateProviderBasedOnBeginDt();
        }

        if (!this.isEmpty(beginDate)) {
            this.validateIndicatorBasedOnBeginDtVal();
            this.checkChildDisabilityVal();
            this.getSCAssociationsVal();
        }
    }

    getRateTypesBasedOnChild() {
        this.isModifiedAfterChange = false;
        const authRec = this.authRec;
        const beginDate = authRec.DTE_BEGIN_EFFV_AUTH__c;
        const providerId = this.providerIdVal;
        const childId = authRec.IDN_CLIENT__c;
        
        if (this.isEmpty(beginDate)) {
            this.rateTypeOptions = [];
        } else if (this.isEmpty(childId)) {
            this.rateTypeOptions = [];
        } else if (providerId && beginDate) {
            this.getRateTypeOptionsVal();
        }
        this.checkChildDisabilityVal();
    }

    chkRelativeStatus() {
        const authRec = this.authRec;
        const relativeStat = authRec.CDE_REL_PROVR__c;
        
        if (relativeStat != '2' && relativeStat != '4') {
            this.authRec.CDE_PRO_REL_CHLD__c = '';
            this.authRec.CDE_PROV_DIFF_RESI__c = '';
        }
    }

    getProviderRelationship() {
        const sibling = this.authRec.CDE_PRO_REL_CHLD__c;
        if(!sibling){            
            this.authRec.CDE_PROV_DIFF_RESI__c = '';
        }
    }

    isEmpty(value) {
        return value === null || value === undefined || value === '' || value === '--None--';
    }

    getUpcomingJune30() { //CCCAP-15329
        const today = new Date();
        const currentYear = today.getFullYear();
        const june30ThisYear = new Date(currentYear, 5, 30);
        const targetYear = today > june30ThisYear ? currentYear + 1 : currentYear;
        const month = String(6).padStart(2, '0');
        const day = String(30).padStart(2, '0');
        return `${targetYear}-${month}-${day}`;
    }

    fireAuthRecCloneUpdateEvent() {
        const updateEvent = new CustomEvent('authreccloneupdate', {
            detail: { authRecClone: this.authRecClone },
            bubbles: false,
            composed: false
        });
        this.dispatchEvent(updateEvent);
    }

    validateProviderIdVal() {
        const { isCreate, authRec, providerIdVal, caseRec } = this;
        const { DTE_BEGIN_EFFV_AUTH__c: beginDate } = authRec;
        if (providerIdVal && beginDate) {
            if (isCreate) {
                let params = {
                    providerId: providerIdVal,
                    beginDate: beginDate,
                    caseObj: caseRec
                };

                helper.callServer(this, 'AuthorizationFlowApxCtrl', 'validateProviders', (function (response) {
                    if (response && response.isSuccessful) {
                        this.isInvalidProvider = false;
                        this.isReqProviderLocation = response.objectData.isReqProviderLocation || false;
                        this.authRec = {
                            ...this.authRec,
                            IDN_PROVR__c: providerIdVal
                        };
                        const providerLookup = this.template.querySelector('c-custom-lookup_lwc');
                        if (providerLookup) {
                            providerLookup.customErrorMessage = '';
                            providerLookup.reportValidity();
                        }
                        this.findProviderName = providerIdVal;
                        this.getRateTypeOptionsVal();
                        this.fetchUPKInformation();
                        this.isProviderExempt = response.objectData.isProviderExempt || false;
                        if (!response.objectData.isProviderExempt) {
                            this.setTransFeeRestriction();
                        }
                    } else {
                        this.isInvalidProvider = true;
                        const providerLookup = this.template.querySelector('c-custom-lookup_lwc');
                        if (providerLookup) {
                            providerLookup.customErrorMessage = 'Invalid provider, please check related Fiscal Agreement and Rate Schedule records for this provider or select different provider. Or change the Authorization Begin Date';
                            providerLookup.reportValidity();
                        }
                    }
                }).bind(this), JSON.stringify(params));
            }
        } else if (!beginDate) {
            this.showToast('Info', 'Please select Authorization begin date to validate the provider.', 'info');
        }
    }

    getRateTypeOptionsVal() {
        const authId = this.isCreate ? this.caseRec.Id : this.authRec.Id;
        const beginDate = this.authRec.DTE_BEGIN_EFFV_AUTH__c;
        const clientId = this.authRec.IDN_CLIENT__c;
        
        if (!this.isEmpty(clientId)) {
            const params = {
                authId: authId,
                isCreate: this.isCreate,
                providerId: this.providerIdVal,
                beginDate: beginDate,
                clientId: clientId
            };

            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getRateTypeOptions', (function (response) {
                if (response && response.isSuccessful) {
                    this.rateTypeOptions = response.objectData.rateTypeOptions || [];
                } else {
                    this.rateTypeOptions = [];
                }
                this.rateTypeOptions.unshift({ 'label': '--None--', 'value': '' });
            }).bind(this), JSON.stringify(params));
        }
    }

    getSCAssociationsVal() {
        const beginDate = this.authRec.DTE_BEGIN_EFFV_AUTH__c;
        let params;        
        if (this.isCreate) {
            params = {
                SCId: null,
                providerId: this.providerIdVal,
                caseObj: this.caseRec,
                authBeginDate: beginDate
            };
        } else {
            const providerId = this.authRec.IDN_PROVR__c;
            const caseCountyId = this.authRec.IDN_CASE__r ? this.authRec.IDN_CASE__r.CDE_COUNTY__c : null;
            const slotId = this.authRec.IDN_SLOT_CONTRACT__c ? this.authRec.IDN_SLOT_CONTRACT__c : null;
            if (caseCountyId) {
                this.caseRec = {
                    ...this.caseRec,
                    CDE_COUNTY__c: caseCountyId
                };
            }
            params = {
                SCId: slotId,
                providerId: providerId,
                caseObj: this.caseRec,
                authBeginDate: beginDate
            };
        }

        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'fetchSCAssociations', (function (response) {
            if (response && response.isSuccessful) {
                this.slotContractOptions = response.objectData.slotContractOptions || [];
                this.isCountyRateSCQ = true;
            } else {
                this.slotContractOptions = [];
                this.isCountyRateSCQ = false;
            }
        }).bind(this), JSON.stringify(params));
    }

    checkChildDisabilityVal() {
        return new Promise((resolve) => {
            if (this.authRec.IDN_CLIENT__c && this.authRec.DTE_BEGIN_EFFV_AUTH__c) {
                const params = {
                    individualRecId: this.authRec.IDN_CLIENT__c,
                    currentBeginDate: this.authRec.DTE_BEGIN_EFFV_AUTH__c
                };

                helper.callServer(this, 'AuthorizationFlowApxCtrl', 'disabilityCheck', (function (response) {
                    if (response && response.isSuccessful) {
                        this.isChildDisable = response.objectData.isChildDisable || false;
                    } else {
                        const clientCmp = this.template.querySelector('[data-field="IDN_CLIENT__c"]');
                        if (clientCmp && response.errorMessage) {
                            clientCmp.setCustomValidity(response.errorMessage);
                            clientCmp.reportValidity();
                        }
                    }
                    resolve(this.isChildDisable);
                }).bind(this), JSON.stringify(params));
            } else {
                resolve(this.isChildDisable);
            }
        });
    }

    validateIndicatorBasedOnBeginDtVal() {
        if (this.isCreate) {
            const beginDate = this.authRec.DTE_BEGIN_EFFV_AUTH__c;
            const caseId = this.caseRec.Id;
            let params = {
                recordId: caseId,
                beginDate: beginDate
            };
            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'checkCountyIndicator', (function (response) {
                if (response && response.isSuccessful) {
                    if (response.objectData.showContractToIndicator) {
                        this.isShowContractToIndicator = response.objectData.showContractToIndicator;
                    }
                    if (response.objectData.protectiveServiceIndicator) {
                        this.isProtectiveServiceIndicator = response.objectData.protectiveServiceIndicator;
                    }
                    if (response.objectData.showDropInDaysIndicator) {
                        this.isDropInDaysIndicator = response.objectData.showDropInDaysIndicator;
                        this.numberOfDaysDrop = response.objectData.numberOfDaysDrop || 0;
                    } else {
                        this.isDropInDaysIndicator = false;
                        this.numberOfDaysDrop = 0;
                    }
                    if (!this.isProviderExempt) {
                        this.setTransFeeRestriction();
                    }
                } else {
                    console.error('Indicator validation error:', response);
                }
            }).bind(this), JSON.stringify(params));
        }
    }

    validateProviderBasedOnBeginDt() {
        const { isCreate, authRec, providerIdVal, caseRec } = this;
        const { DTE_BEGIN_EFFV_AUTH__c: beginDate } = authRec;
        if (providerIdVal && providerIdVal !== '' && providerIdVal !== undefined && 
            beginDate && beginDate !== '' && beginDate !== undefined) {
            if (isCreate) {
                let params = {
                    providerId: providerIdVal,
                    beginDate: beginDate,
                    caseObj: caseRec
                };
                helper.callServer(this, 'AuthorizationFlowApxCtrl', 'validateProviders', (function (response) {
                    if (response && response.isSuccessful) {
                        this.isInvalidProvider = false;
                        this.isReqProviderLocation = response.objectData.isReqProviderLocation || false;
                        this.authRec.IDN_PROVR__c = providerIdVal;
                        const providerLookup = this.template.querySelector('c-custom-lookup_lwc');
                        if (providerLookup) {
                            providerLookup.customErrorMessage = '';
                            providerLookup.reportValidity();
                        }
                        this.getRateTypeOptionsVal();
                    } else {
                        this.isInvalidProvider = true;
                        this.rateTypeOptions = [];
                        
                        // Set error message on provider lookup field
                        const providerLookup = this.template.querySelector('c-custom-lookup_lwc');
                        if (providerLookup) {
                            providerLookup.customErrorMessage = 'Invalid provider, please check related fiscal agreement records for this provider or select different provider.';
                            providerLookup.reportValidity();
                        }
                    }
                }).bind(this), JSON.stringify(params));
            }
        } else {
            if (!beginDate || beginDate === '' || beginDate === undefined) {
                this.showToast('Info', 'Please select Authorization begin date to validate the provider.', 'info');
            }
        }
    }

    validateIndicatorInEditFlow() {
        const beginDate = this.authRec.DTE_BEGIN_EFFV_AUTH__c;
        const countyId = this.authRec.CDE_COUNTY__c;
        let params = {
            recordId: countyId,
            beginDate: beginDate
        };
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'checkCountyIndicator', (function (response) {
            if (response && response.isSuccessful) {
                if (response.objectData.showDropInDaysIndicator) {
                    this.isDropInDaysIndicator = response.objectData.showDropInDaysIndicator;
                    this.numberOfDaysDrop = response.objectData.numberOfDaysDrop || 0;
                    if (!this.isCreate) {
                        this.authDropInDays = this.authRec.Number_of_Drop_in_Days__c || 0;
                    } else {
                        this.authDropInDays = response.objectData.numberOfDaysDrop || 0;
                    }
                } else {
                    this.isDropInDaysIndicator = false;
                    this.numberOfDaysDrop = 0;
                }
            } else {
                console.error('Error in validateIndicatorInEditFlow:', response);
            }
        }).bind(this), JSON.stringify(params));
    }

    setTransFeeRestriction() {
        if (this.isCreate) {
            const beginDate = this.authRec.DTE_BEGIN_EFFV_AUTH__c;
            const providerId = this.providerIdVal;
            const caseCountyId = this.caseRec.CDE_COUNTY__c;
            if (!this.isEmpty(caseCountyId) && !this.isEmpty(beginDate) && !this.isEmpty(providerId)) {
                let params = {
                    beginDate: beginDate,
                    providerId: providerId,
                    caseCountyId: caseCountyId
                };
                helper.callServer(this, 'AuthorizationFlowApxCtrl', 'executeTransportationFeeLogic', (function (response) {
                    if (response && response.isSuccessful) {
                        this.showTransFeeRestriction = response.objectData.showTransFeeRestriction || false;
                        this.authRec = {
                            ...this.authRec,
                            CDE_TRANS_FEE__c: response.objectData.transFeeRestrictionValue
                        };
                    }
                }).bind(this), JSON.stringify(params));
            }
        } else {
            const providerType = this.authRec.IDN_PROVR__r ? this.authRec.IDN_PROVR__r.CDE_TYPE_PROVR__c : null;
            if (providerType && Exempt_Provider_Type && Exempt_Provider_Type.includes(providerType)) {
                this.isProviderExempt = true;
                this.showTransFeeRestriction = false;
                if (!this.isReadOnly) {
                    this.authRec = {
                        ...this.authRec,
                        CDE_TRANS_FEE__c: null
                    };
                }
            } else {
                const beginDate = this.authRec.DTE_BEGIN_EFFV_AUTH__c;
                const providerId = this.authRec.IDN_PROVR__c;
                const caseCountyId = this.authRec.IDN_CASE__r ? this.authRec.IDN_CASE__r.CDE_COUNTY__c : null;
                
                if (!this.isEmpty(caseCountyId) && !this.isEmpty(beginDate) && !this.isEmpty(providerId)) {
                    let params = {
                        beginDate: beginDate,
                        providerId: providerId,
                        caseCountyId: caseCountyId
                    };
                    helper.callServer(this, 'AuthorizationFlowApxCtrl', 'executeTransportationFeeLogic', (function (response) {
                        if (response && response.isSuccessful) {
                            this.showTransFeeRestriction = response.objectData.showTransFeeRestriction || false;
                        }
                    }).bind(this), JSON.stringify(params));
                }
            }
        }
    }

    populateSlotFields() {
        const scAssRecId = this.authRec.IDN_SLOT_CONTRACT__c;
        let params = {
            scAssId: scAssRecId
        };
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'queryPopulateSCAssRecord', (function (response) {
            if (response && response.isSuccessful) {
                if (!this.isEmpty(scAssRecId)) {
                    this.sCAssociationRec = {
                        ...this.sCAssociationRec,
                        DTE_BEGIN_SLOT__c: response.objectData.scAssRecBgnDte,
                        DTE_END_SLOT__c: response.objectData.scAssRecEndDte,
                        CDE_CARE_LEVEL__c: response.objectData.scAssCareLvl,
                        SLOT_CONTRACT_DESCRIPTION__c: response.objectData.scAssDesc
                    };
                    this.mandatory = true;
                } else {
                    this.sCAssociationRec = {
                        sobjectType: 'T_SLOT_CONTRACT__c',
                        IDN_AUTH__c: '',
                        DTE_BEGIN_SLOT__c: '',
                        DTE_END_SLOT__c: '',
                        CDE_CARE_LEVEL__c: '',
                        SLOT_CONTRACT_DESCRIPTION__c: ''
                    };
                    this.mandatory = false;
                }
            }
        }).bind(this), JSON.stringify(params));
    }

    handleFieldLevelValidation() {
        const errors = this.fieldValidationErrors || [];
        errors.forEach(error => {
            const fieldElement = this.template.querySelector(`[data-field="${error.fieldName}"]`);
            if (fieldElement) {
                if(fieldElement.tagName === 'C-MULTISELECT-COMBOBOX' || fieldElement.tagName === 'C-CUSTOM-LOOKUP_LWC') {
                    fieldElement.customErrorMessage = error.errorMessage;
                    fieldElement.reportValidity();
                } else{
                    fieldElement.setCustomValidity(error.errorMessage);
                    fieldElement.reportValidity();
                }
            }
        });
    }

    validateAuthSlotBeginDate() {
        let isValid = true;
        const authRec = this.authRec;
        const scAsscRecId = authRec.IDN_SLOT_CONTRACT__c;
        const authBginDate = authRec.DTE_BEGIN_EFFV_AUTH__c;
        const authEndDate = authRec.DTE_END_EFFV_AUTH__c;
        const authSlotBginDate = authRec.DTE_BEGIN_SLOT__c;
        const scAssRec = this.sCAssociationRec;
        const slotEndDte = scAssRec.DTE_END_SLOT__c;
        const slotBgnDte = scAssRec.DTE_BEGIN_SLOT__c;
        const authRecClone = this.authRecClone;
        const oldSlotId = authRecClone.IDN_SLOT_CONTRACT__c;
        const oldSlotDate = authRecClone.DTE_BEGIN_SLOT__c;
        let checkValidations = false;
        if (!this.isEmpty(authBginDate)) {
            const bDateArr = authBginDate.split('-');
            const bDate = new Date(bDateArr[0], bDateArr[1] - 1, bDateArr[2]);
            const today = new Date();
            const differenceInTime = today.getTime() - bDate.getTime();
            const differenceInDays = differenceInTime / (1000 * 3600 * 24);

            const authBginDateCmp = this.template.querySelector('[data-field="DTE_BEGIN_EFFV_AUTH__c"]');
            if (this.isCreate && differenceInDays > 10 && !this.isReadOnly) {
                isValid = false;
                if (authBginDateCmp) {
                    authBginDateCmp.setCustomValidity('Cannot be prior to {today + 9 days in the past}');
                    authBginDateCmp.reportValidity();
                }
            } else {
                if (authBginDateCmp) {
                    authBginDateCmp.setCustomValidity('');
                    authBginDateCmp.reportValidity();
                }
            }
        }
        if (!this.isReadOnly && (this.isCreate || oldSlotId !== scAsscRecId || oldSlotDate !== authSlotBginDate)) {
            checkValidations = true;
        }
        if (checkValidations && !this.isEmpty(authSlotBginDate)) {
            const bDateArr = authSlotBginDate.split('-');
            const bDate = new Date(bDateArr[0], bDateArr[1] - 1, bDateArr[2]);
            const today = new Date();
            const differenceInTime = today.getTime() - bDate.getTime();
            const differenceInDays = differenceInTime / (1000 * 3600 * 24);
            const authSlotBginDateCmp = this.template.querySelector('[data-field="DTE_BEGIN_SLOT__c"]');
            if (!this.isEmpty(authBginDate) && authSlotBginDate < authBginDate) {
                isValid = false;
                if (authSlotBginDateCmp) {
                    authSlotBginDateCmp.setCustomValidity('Authorization Slot Begin Date should be greater than or equal to Authorization Begin Date');
                    authSlotBginDateCmp.reportValidity();
                }
            } else if (!this.isEmpty(authEndDate) && authSlotBginDate > authEndDate) {
                isValid = false;
                if (authSlotBginDateCmp) {
                    authSlotBginDateCmp.setCustomValidity('Authorization Slot Begin Date should be less than or equal to Authorization End Date');
                    authSlotBginDateCmp.reportValidity();
                }
            } else if (differenceInDays > 10) {
                isValid = false;
                if (authSlotBginDateCmp) {
                    authSlotBginDateCmp.setCustomValidity('Authorization Slot Begin Date cannot have a date prior to today minus 9 days in past');
                    authSlotBginDateCmp.reportValidity();
                }
            } else if (!this.isEmpty(slotEndDte) && authSlotBginDate > slotEndDte) {
                isValid = false;
                if (authSlotBginDateCmp) {
                    authSlotBginDateCmp.setCustomValidity('Authorization Slot Begin Date should be less than the Slot Contract End Date');
                    authSlotBginDateCmp.reportValidity();
                }
            } else if (!this.isEmpty(slotBgnDte) && authSlotBginDate < slotBgnDte) {
                isValid = false;
                if (authSlotBginDateCmp) {
                    authSlotBginDateCmp.setCustomValidity('Authorization Slot Begin Date should be greater than equal to Slot Contract Begin Date');
                    authSlotBginDateCmp.reportValidity();
                }
            } else {
                if (authSlotBginDateCmp) {
                    authSlotBginDateCmp.setCustomValidity('');
                    authSlotBginDateCmp.reportValidity();
                }
            }
        }
        
        // Update sCAssociationRec with Id if slot contract is selected
        if (!this.isEmpty(scAsscRecId)) {
            this.sCAssociationRec = {
                ...this.sCAssociationRec,
                Id: scAsscRecId
            };
        }
        return isValid;
    }

    handleSendRecurrence(event){
        this.enterRecurrence=event.detail.value;
        const childCmp = this.template.querySelector('c-schedule-Encumbrance_lwc');
        if (childCmp) {
            this.scheduleRecurr = [ ...childCmp.scheduleRecurr ];
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    getHoursByDayIndex(dayIndex) {
        return this.hoursPerWeekDay?.[dayIndex]?.CNT_HOUR_CARE__c || '';
    }

    getRateTypeByDayIndex(dayIndex) {
        return this.hoursPerWeekDay?.[dayIndex]?.CDE_TYPE_UNIT_CARE__c || '';
    }

    fetchClientDetails() {
        if (!this.authRec.IDN_CLIENT__c) return;

        const childParams = { clientId: this.authRec.IDN_CLIENT__c };
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getClientDetails', (function (result) {
            this.clientRec = result;
            if (this.isCreate && !this.isUPKEnrollmentManuallySet && (!this.providerIdVal || !this.authRec.CDE_CHILD_ENROLLED_IN_UPK__c)){
                this.authRec = {
                    ...this.authRec,
                    CDE_CHILD_ENROLLED_IN_UPK__c: this.defaultUPKEnrollmentValue
                };
            }
            this.fetchUPKInformation();
        }).bind(this), JSON.stringify(childParams));
    }

    fetchUPKInformation() {
        if ((this.isCreate && (!this.clientRec.Name || !this.providerRec.Name)) || this.isReadOnly || this.nextUPKYear) return;
        if (!this.isCreate && (!this.clientRec.Name || !this.authProviderRec.Name)) return;

        if (!this.clientRec.Age__c || this.clientRec.Age__c < 3 || this.clientRec.Age__c >= 6) {
            this.authRec = {
                ...this.authRec,
                CDE_CHILD_ENROLLED_IN_UPK__c: 'Not Applicable',
                UPK_Awarded_Hours__c: null,
                UPK_Start_date__c: null,
                Is_UPK_Stacked__c: 'No'
            };
            return;
        }
        const upkParams = { clientId: this.clientRec.Name, 
            providerId: this.isCreate? this.providerRec.Name : this.authProviderRec.Name };
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getLatestUPKInfo', (function (result) {
            if (result) {
                if(result.Is_the_child_dually_enrolled_in_UPK__c == 'Yes'){
                    this.upkFetchedValues = {
                        CDE_CHILD_ENROLLED_IN_UPK__c: result.Is_the_child_dually_enrolled_in_UPK__c,
                        UPK_Awarded_Hours__c: result.UPK_Stacking_Hours__c || null,
                        UPK_Start_date__c: result.UPK_Enrollment_Start_Date__c || null
                    };
                    if(this.isCreate && !this.isUPKEnrollmentManuallySet){
                        this.authRec = {
                            ...this.authRec,
                            CDE_CHILD_ENROLLED_IN_UPK__c: result.Is_the_child_dually_enrolled_in_UPK__c || this.defaultUPKEnrollmentValue,
                            UPK_Awarded_Hours__c: result.UPK_Stacking_Hours__c || null,
                            UPK_Start_date__c: result.UPK_Enrollment_Start_Date__c || null
                        }
                        if(!this.providerRec.Is_UPK_Provider__c){
                            this.showToast('Warning', 'The selected provider is not a UPK Provider. Please select a UPK participating provider to update the child\'s dually enrolled status.','warning');
                        }
                    }
                } else{
                    this.upkFetchedValues = {
                        CDE_CHILD_ENROLLED_IN_UPK__c: result.Is_the_child_dually_enrolled_in_UPK__c
                    };
                    if(this.isCreate && !this.isUPKEnrollmentManuallySet){
                        this.authRec = {
                            ...this.authRec,
                            CDE_CHILD_ENROLLED_IN_UPK__c: result.Is_the_child_dually_enrolled_in_UPK__c || this.defaultUPKEnrollmentValue,
                        };
                    }
                }
            } else {
                if(this.isCreate && !this.isUPKEnrollmentManuallySet){
                    this.authRec = {
                        ...this.authRec,
                        CDE_CHILD_ENROLLED_IN_UPK__c: this.defaultUPKEnrollmentValue
                    };
                }
            }
        }).bind(this), JSON.stringify(upkParams));
    }
}