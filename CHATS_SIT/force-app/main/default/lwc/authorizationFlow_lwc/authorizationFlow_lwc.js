import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import ERRORS_ON_THIS_PAGE from '@salesforce/label/c.ERRORS_ON_THIS_PAGE';
import Child_Disability_Validation_Msg from '@salesforce/label/c.Child_Disability_Validation_Msg';
import recurrenceErrorMsg from '@salesforce/label/c.recurrenceErrorMsg';
import CASE_ID_FIELD from '@salesforce/schema/T_SBSD_CASE__c.Id';
import CASE_DTE_REDET_FIELD from '@salesforce/schema/T_SBSD_CASE__c.DTE_REDET_CASE__c';
import CASE_COUNTY_FIELD from '@salesforce/schema/T_SBSD_CASE__c.CDE_COUNTY__c';
import AUTH_ID_FIELD from '@salesforce/schema/T_AUTH__c.Id';
import AUTH_NAME_FIELD from '@salesforce/schema/T_AUTH__c.Name';
import AUTH_IDN_EXTNL_FIELD from '@salesforce/schema/T_AUTH__c.IDN_EXTNL__c';
import AUTH_CREATED_BY_FIELD from '@salesforce/schema/T_AUTH__c.CreatedById';
import AUTH_BEGIN_DATE_FIELD from '@salesforce/schema/T_AUTH__c.DTE_BEGIN_EFFV_AUTH__c';
import AUTH_PROVIDER_FIELD from '@salesforce/schema/T_AUTH__c.IDN_PROVR__c';
import AUTH_REL_PROVIDER_FIELD from '@salesforce/schema/T_AUTH__c.CDE_REL_PROVR__c';
import AUTH_PRO_REL_CHILD_FIELD from '@salesforce/schema/T_AUTH__c.CDE_PRO_REL_CHLD__c';
import AUTH_PROV_DIFF_RESI_FIELD from '@salesforce/schema/T_AUTH__c.CDE_PROV_DIFF_RESI__c';
import AUTH_CONTRACT_SLOTS_FIELD from '@salesforce/schema/T_AUTH__c.Contract_for_Slots_indicator__c';
import AUTH_PROTECTIVE_SERVICES_FIELD from '@salesforce/schema/T_AUTH__c.Protective_Services_Indicator__c';
import AUTH_IMM_FIELD from '@salesforce/schema/T_AUTH__c.CDE_IMM__c';
import AUTH_TYPE_VERIF_FIELD from '@salesforce/schema/T_AUTH__c.CDE_TYPE_VERIF__c';
import AUTH_SOURCE_VRFYD_FIELD from '@salesforce/schema/T_AUTH__c.CDE_SOURCE_VRFYD_IMMU__c';
import AUTH_CLIENT_FIELD from '@salesforce/schema/T_AUTH__c.IDN_CLIENT__c';
import AUTH_COUNTY_FIELD from '@salesforce/schema/T_AUTH__c.CDE_COUNTY__c';
import AUTH_DROP_IN_DAYS_FIELD from '@salesforce/schema/T_AUTH__c.Number_of_Drop_in_Days__c';
import AUTH_TRANS_FEE_FIELD from '@salesforce/schema/T_AUTH__c.CDE_TRANS_FEE__c';
import AUTH_CASE_FIELD from '@salesforce/schema/T_AUTH__c.IDN_CASE__c';
import AUTH_END_DATE_FIELD from '@salesforce/schema/T_AUTH__c.DTE_END_EFFV_AUTH__c';
import AUTH_BEGIN_SLOT_FIELD from '@salesforce/schema/T_AUTH__c.DTE_BEGIN_SLOT__c';
import AUTH_SLOT_CONTRACT_FIELD from '@salesforce/schema/T_AUTH__c.IDN_SLOT_CONTRACT__c';
import AUTH_ACTV_AUTH_FIELD from '@salesforce/schema/T_AUTH__c.AMT_ACTV_AUTH__c';
import AUTH_RGSTR_AUTH_FIELD from '@salesforce/schema/T_AUTH__c.AMT_RGSTR_AUTH__c';
import AUTH_TRANSP_AUTH_FIELD from '@salesforce/schema/T_AUTH__c.AMT_TRANSP_AUTH__c';
import AUTH_CLIENT_FIRST_NAME from '@salesforce/schema/T_AUTH__c.IDN_CLIENT__r.NAM_FIRST__c';
import AUTH_CLIENT_LAST_NAME from '@salesforce/schema/T_AUTH__c.IDN_CLIENT__r.NAM_LAST__c';
import AUTH_CLIENT_STATE_ID from '@salesforce/schema/T_AUTH__c.IDN_CLIENT__r.IDN_STATE__c';
import AUTH_CASE_COUNTY from '@salesforce/schema/T_AUTH__c.IDN_CASE__r.CDE_COUNTY__c';
import AUTH_PROVIDER_TYPE from '@salesforce/schema/T_AUTH__c.IDN_PROVR__r.CDE_TYPE_PROVR__c';
import AUTH_UPK_ENROLLED_FIELD from '@salesforce/schema/T_AUTH__c.CDE_CHILD_ENROLLED_IN_UPK__c';
import AUTH_UPK_STACKED_FIELD from '@salesforce/schema/T_AUTH__c.Is_UPK_Stacked__c';
import AUTH_UPK_AWARDED_HOURS_FIELD from '@salesforce/schema/T_AUTH__c.UPK_Awarded_Hours__c';
import AUTH_UPK_START_DATE_FIELD from '@salesforce/schema/T_AUTH__c.UPK_Start_date__c';
import AUTH_UPK_LAST_UPDATED_FIELD from '@salesforce/schema/T_AUTH__c.UPK_Last_Updated_date__c';
import PROVIDER_ID_FIELD from '@salesforce/schema/T_CHATS_PROVR_STATUS__c.Id';
import PROVIDER_NAME_FIELD from '@salesforce/schema/T_CHATS_PROVR_STATUS__c.Name';
import PROVIDER_FACILITY_NAME_FIELD from '@salesforce/schema/T_CHATS_PROVR_STATUS__c.NAM_FACILITY__c';
import PROVIDER_TYPE_FIELD from '@salesforce/schema/T_CHATS_PROVR_STATUS__c.CDE_TYPE_PROVR__c';
import AUTH_STATUS_FIELD from '@salesforce/schema/T_AUTH__c.Authorization_Status__c';
import IS_UPK_PROVIDER_FIELD from '@salesforce/schema/T_CHATS_PROVR_STATUS__c.Is_UPK_Provider__c';

const CASE_FIELDS = [CASE_ID_FIELD, CASE_DTE_REDET_FIELD, CASE_COUNTY_FIELD];
const PROVIDER_FIELDS = [PROVIDER_ID_FIELD, PROVIDER_NAME_FIELD, PROVIDER_FACILITY_NAME_FIELD, PROVIDER_TYPE_FIELD, IS_UPK_PROVIDER_FIELD];
const AUTH_UPDATED_FIELDS = [AUTH_ID_FIELD, AUTH_NAME_FIELD, AUTH_IDN_EXTNL_FIELD, AUTH_CREATED_BY_FIELD, AUTH_DROP_IN_DAYS_FIELD];
const AUTH_FIELDS = [
    AUTH_ID_FIELD, AUTH_BEGIN_DATE_FIELD, AUTH_PROVIDER_FIELD, AUTH_REL_PROVIDER_FIELD,
    AUTH_PRO_REL_CHILD_FIELD, AUTH_PROV_DIFF_RESI_FIELD, AUTH_CONTRACT_SLOTS_FIELD,
    AUTH_PROTECTIVE_SERVICES_FIELD, AUTH_IMM_FIELD, AUTH_TYPE_VERIF_FIELD,
    AUTH_SOURCE_VRFYD_FIELD, AUTH_CLIENT_FIELD, AUTH_COUNTY_FIELD, AUTH_DROP_IN_DAYS_FIELD,
    AUTH_TRANS_FEE_FIELD, AUTH_CASE_FIELD, AUTH_END_DATE_FIELD, AUTH_BEGIN_SLOT_FIELD,
    AUTH_SLOT_CONTRACT_FIELD, AUTH_ACTV_AUTH_FIELD, AUTH_RGSTR_AUTH_FIELD, AUTH_TRANSP_AUTH_FIELD,
    AUTH_CLIENT_FIRST_NAME, AUTH_CLIENT_LAST_NAME, AUTH_CLIENT_STATE_ID,
    AUTH_CASE_COUNTY, AUTH_PROVIDER_TYPE, AUTH_STATUS_FIELD,
    AUTH_UPK_ENROLLED_FIELD, AUTH_UPK_STACKED_FIELD, AUTH_UPK_AWARDED_HOURS_FIELD,
    AUTH_UPK_START_DATE_FIELD, AUTH_UPK_LAST_UPDATED_FIELD
];

export default class AuthorizationFlowLwc extends NavigationMixin(LightningElement) {
    @track childStateOptions = [];
    @track rateTypeOptions = [];
    @track authId = '';
    @track _pageMessages = [];
    @track _messageType = '';
    @track recordError1 = '';
    @track isCountyRateSCQ = false;
    @track slotContractOptions = [];
    @track originalSCId = '';
    @track isCreate = true;
    @track authProviderRec = { sobjectType: 'T_CHATS_PROVR_STATUS__c' };
    @track authRec = { 
        sobjectType: 'T_AUTH__c', 
        Authorization_Status__c: '2',
        Is_UPK_Stacked__c: 'No'
    };
    @track sCAssociationRec = { 
        sobjectType: 'T_SLOT_CONTRACT__c',
        IDN_AUTH__c: '',
        DTE_BEGIN_SLOT__c: '',
        DTE_END_SLOT__c: '',
        CDE_CARE_LEVEL__c: '',
        SLOT_CONTRACT_DESCRIPTION__c: ''
    };
    @track authRecClone = { 
        sobjectType: 'T_AUTH__c',
        DTE_BEGIN_EFFV_AUTH__c: '',
        Contract_for_Slots_indicator__c: false,
        Protective_Services_Indicator__c: false,
        Do_we_need_to_allow_drop_in_days_for__c: false
    };
    @track initialUPKEnrolledValue = null;
    initialUPKStackedValue;
    @track isUPKEnrollmentManuallySet = false;
    @track upkFetchedValues = null;
    @track authRecUpdated = { sobjectType: 'T_AUTH__c' };
    @track caseRec = { sobjectType: 'T_SBSD_CASE__c' };
    @track careDateToAuthEncmbr = {};
    @track hoursPerWeekDayChanged = false;
    @track isInvalidProvider = false;
    @track isAuthCreate = false;
    @track authTerminated = false;
    @track countySFId = '';
    @track showWarningForCounty = false;
    @track showWarningChildCareLevel = false;
    @track careLevelMessage = '';
    @track replaceMessage = '';
    @track cancelMessage = 'Any changes made to Slot Contract association will not be saved.';
    @track showCancelButton = true;
    @track message = '';
    @track countyMessage = '';
    @track eligibleChildEndDate;
    @track providerIdVal = '';
    @track provIdValtwo = '';
    @track originalBeginDate = '';
    @track originalProviderId = '';
    @track originalClientId = '';
    @track isEncumbrnceCreated = false;
    @track isCreateCorrp = false;
    @track isChildWefareCare = false;
    @track isChildDisable = false;
    @track authDropInDays = 0;
    @track isDropInDaysIndicator = false;
    @track numberOfDaysDrop = 0;
    @track isProtectiveServiceIndicator = false;
    @track isShowContractToIndicator = false;
    @track authStatusRecord = {
        dteEndEffv: '',
        dteBeginEffv: '',
        cdeStatusAuth: '',
        cdeReasonChangeAuth: '',
        idnAuth: '',
        createdById: '',
        createdDate: ''
    };
    @track enterRecurrence = false;
    @track scheduleRecurr = [];
    @track authEndDate;
    @track isModifiedAfterChange = false;
    @track scheduleRecurrObj = {
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
    @track showWarningBelowSchoolAge = false;
    @track warningMessageBelowSchoolAge = '';
    @track confirmationModalOnCancel = false;
    @track confirmationModalBelowSchoolAge = false;
    @track confirmationModalOnReplaceofscAssRec = false;
    @track confirmationModalOnCareLevel = false;
    @track confirmationModalOnCountyCheck = false;
    @track confirmationModalUnsavedChanges = false;
    @track showUPKDualEnrollmentModal = false;
    @track xLogAuthStatus = {
        sobjectType: 'Exception_Log__c',
        Class__c: 'authorizationFlowHelper',
        Method__c: 'createAuthStatusRecord',
        Exception_Message__c: 'calling auth status creation service after encumbrance',
        Exception_Type__c: 'Success',
        Request__c: '',
        Response__c: '',
        Log_Type__c: ''
    };
    @track showSpinner = false;
    @track isCurrentPageValid = false;
    @track isDataLoaded = false;
    @track providerRecordId = null;
    @track authRecIdForUpdate = null;
    @track __currentTabNumber = 1;
    _hoursPerWeekDay = [];
    @track providerRec = { sobjectType: 'T_CHATS_PROVR_STATUS__c' };
    @api recordId;
    @api sObjectName;
    @api isReadOnly = false;
    @api fieldValidationErrors = [];

    @api
    set pageMessages(value) {
        this._pageMessages = value || [];
    }

    get pageMessages() {
        return this._pageMessages;
    }

    @api
    set messageType(value) {
        this._messageType = value || '';
    }

    get messageType() {
        if (this._messageType) {
            return this._messageType;
        }
        return this._pageMessages && this._pageMessages.length > 0 ? 'error' : '';
    }

    get currentTabNumber() {
        return this.__currentTabNumber;
    }

    set currentTabNumber(value) {
        const oldValue = this.__currentTabNumber;
        if (oldValue !== value) {
            this.__currentTabNumber = value;
            this.handleTabNumberChange();
        }
    }

    get hoursPerWeekDay() {
        return this._hoursPerWeekDay;
    }

    set hoursPerWeekDay(value) {
        const oldValue = this._hoursPerWeekDay;
        this._hoursPerWeekDay = value;
        if (oldValue !== value) {
            this.hoursPerWeekDayChange();
        }
    }

    get totalTabsValue() {
        return 2;
    }

    get recordFields() {
        return this.sObjectName === 'T_SBSD_CASE__c' ? CASE_FIELDS : AUTH_FIELDS;
    }

    get isTabOne() {
        return this.currentTabNumber === 1;
    }

    get isTabTwo() {
        return this.currentTabNumber === 2;
    }

    get cardTitle() {
        return this.sObjectName === 'T_AUTH__c' ? (this.isReadOnly ? 'VIEW' : 'EDIT') : 'CREATE NEW';
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$recordFields' })
    wiredRecord({ error, data }) {
        if (data) {            
            if (this.sObjectName === 'T_SBSD_CASE__c') {
                const normalizedCaseRec = this.normalizeRecordData(data.fields);
                this.caseRec = normalizedCaseRec;
                this.isDataLoaded = true;
            } else if (this.sObjectName === 'T_AUTH__c') {
                const normalizedAuthRec = this.normalizeRecordData(data.fields);
                this.authRec = { 
                    ...this.authRec,
                    ...normalizedAuthRec 
                };
                if (normalizedAuthRec.IDN_PROVR__c) {
                    this.providerRecordId = normalizedAuthRec.IDN_PROVR__c;
                } else {
                    this.isDataLoaded = true;
                }
            }
        } else if (error) {
            this.handleError(error);
        }
    }

    @wire(getRecord, { recordId: '$providerRecordId', fields: PROVIDER_FIELDS })
    wiredProviderRecord({ error, data }) {
        if (data) {
            const normalizedProviderRec = this.normalizeRecordData(data.fields);
            this.authProviderRec = {
                ...this.authProviderRec,
                ...normalizedProviderRec
            };
            this.isDataLoaded = true;
        } else if (error) {
            console.error('Error loading provider record:', error);
            this.isDataLoaded = true;
        }
    }

    @wire(getRecord, { recordId: '$authRecIdForUpdate', fields: AUTH_UPDATED_FIELDS })
    wiredAuthRecordForUpdate({ error, data }) {
        if (data) {
            const normalizedAuthRecUpdated = this.normalizeRecordData(data.fields);
            this.authRecUpdated = {
                ...this.authRecUpdated,
                ...normalizedAuthRecUpdated
            };
            this.recordError1 = '';
        } else if (error) {
            console.error('Error loading auth record for update:', error);
            this.recordError1 = error.body ? error.body.message : 'Error fetching auth record data';
        }
    }

    connectedCallback() {
        this.doInit();
    }

    // Normalizes record data from wire service format {displayValue, value} to plain values
    normalizeRecordData(record) {
        if (!record || typeof record !== 'object') {
            return record;
        }
        
        const normalized = {};
        for (const key in record) {
            if (Object.prototype.hasOwnProperty.call(record, key)) {
                const fieldValue = record[key];
                if (key.endsWith('__r') && fieldValue && typeof fieldValue === 'object' && 'value' in fieldValue) {
                    const relValue = fieldValue.value;
                    if (relValue && typeof relValue === 'object' && relValue.fields) {
                        const relationshipNormalized = { Id: relValue.id };
                        for (const fieldKey in relValue.fields) {
                            if (Object.prototype.hasOwnProperty.call(relValue.fields, fieldKey)) {
                                const relFieldValue = relValue.fields[fieldKey];
                                if (relFieldValue && typeof relFieldValue === 'object' && 'value' in relFieldValue) {
                                    relationshipNormalized[fieldKey] = relFieldValue.value;
                                } else {
                                    relationshipNormalized[fieldKey] = relFieldValue;
                                }
                            }
                        }
                        normalized[key] = relationshipNormalized;
                    } else {
                        normalized[key] = relValue;
                    }
                }
                else if (fieldValue && typeof fieldValue === 'object' && 'value' in fieldValue) {
                    normalized[key] = fieldValue.value;
                } 
                else if (key.endsWith('__r') && fieldValue && typeof fieldValue === 'object') {
                    normalized[key] = this.normalizeRecordData(fieldValue);
                }
                else {
                    normalized[key] = fieldValue;
                }
            }
        }
        return normalized;
    }

    doInit() {
        this.showSpinner = true; //will be set to false in individual method callbacks
        
        this.setChildStateOptions();
        this.initializeData();
        
        if (this.sObjectName === 'T_AUTH__c') {
            this.isCreate = false;
            this.loadScheduleRecurrences();
        } else {
            this.isDataLoaded = true;
            this.checkChildProgram();
        }
    }

    initializeData() {
        let params = {
            recordId: this.recordId,
            fieldName: 'CDE_COUNTY__c'
        };

        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'checkOwnerCountyMatch', (function (response) {
            if (response && response.isSuccessful) {
                if (response.objectData.caseObj) {
                    this.caseRec = response.objectData.caseObj;
                }
                this.showWarningForCounty = response.objectData.showWarning;
                this.countyMessage = response.objectData.warningMessage;
                if (response.objectData.isCaseClosed) {
                    this.isReadOnly = response.objectData.isCaseClosed;
                }
                if(response.objectData.countyId){
                    this.countySFId = response.objectData.countyId;
                }
            } else {
                this.handleError(response);
            }
        }).bind(this), JSON.stringify(params));
    }

    setChildStateOptions() {
        let params = {
            recordId: this.recordId
        };

        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getChildStateOptions', (function (response) {
            if (response && response.isSuccessful) {
                if (response.objectData.childStateOptions) {
                    const options = response.objectData.childStateOptions.map(v => ({
                        label: v.label,
                        value: v.value
                    }));
                    this.childStateOptions = options;
                }
            } else {
                console.error('Error loading picklist options:', response);
                this.handleError(response);
            }
        }).bind(this), JSON.stringify(params));
    }

    loadScheduleRecurrences() {
        let params = {
            recordId: this.recordId
        };

        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getScheduleRecurrences', (function (response) {
            if (response && response.isSuccessful && response.objectData.recurrenceList) {
                this.scheduleRecurr = response.objectData.recurrenceList;
            } else if (!response.isSuccessful) {
                console.error('Error loading schedule recurrences:', response);
                this.handleError(response);
            }
        }).bind(this), JSON.stringify(params));
    }

    checkChildProgram() {
        let params = {
            recordId: this.recordId
        };

        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'checkChildProgram', (function (response) {
            if (response && response.isSuccessful) {
                if (response.objectData.isChildProgram !== undefined) {
                    this.isChildWefareCare = response.objectData.isChildProgram;
                }
            } else {
                console.error('Error fetching child program:', response);
                this.handleError(response);
            }
        }).bind(this), JSON.stringify(params));
    }

    handleTabNumberChange() {
        this.showCancelButton = this.currentTabNumber === 1;
    }

    hoursPerWeekDayChange() {
        this.hoursPerWeekDayChanged = true;
    }

    async doNext() {
        this.showSpinner = true;
        const currentTabNumber = this.currentTabNumber;
        const sObjectName = this.sObjectName;
        let isValid = true;
        this._pageMessages = [];
        if (currentTabNumber === 1) {
            const childCmp = this.template.querySelector('c-authorization-info-pg1_lwc');
            if (childCmp) {
                await childCmp.childDisabilityMethod();
                this.authRec = { ...childCmp.authRec };
                this.providerIdVal = childCmp.providerIdVal;
                this.providerRec = { ...childCmp.providerRec };
                this.isInvalidProvider = childCmp.isInvalidProvider;
                this.sCAssociationRec = { ...childCmp.sCAssociationRec };
                this.isCountyRateSCQ = childCmp.isCountyRateSCQ;
                this.slotContractOptions = childCmp.slotContractOptions;
                this.hoursPerWeekDay = childCmp.hoursPerWeekDay;
                this.rateTypeOptions = childCmp.rateTypeOptions;
                this.isChildDisable = childCmp.isChildDisable;
                this.authDropInDays = childCmp.authDropInDays;
                this.isDropInDaysIndicator = childCmp.isDropInDaysIndicator;
                this.numberOfDaysDrop = childCmp.numberOfDaysDrop;
                this.isProtectiveServiceIndicator = childCmp.isProtectiveServiceIndicator;
                this.isShowContractToIndicator = childCmp.isShowContractToIndicator;
                this.scheduleRecurr=[...childCmp.scheduleRecurr];
                this.isUPKEnrollmentManuallySet = childCmp.isUPKEnrollmentManuallySet;
                this.upkFetchedValues = childCmp.upkFetchedValues ? { ...childCmp.upkFetchedValues } : null;
                this.isCurrentPageValid = childCmp.callValidateCurrentPage();
                if (this.isCurrentPageValid === false) {
                    this.showSpinner = false;
                    this.message = 'error';
                    this._pageMessages = this.formatMessages([ERRORS_ON_THIS_PAGE]);
                }
            }
            const authRecToBeUpserted = this.authRec;  
            const relativeStatus = authRecToBeUpserted.CDE_REL_PROVR__c;
            const provRelation = authRecToBeUpserted.CDE_PRO_REL_CHLD__c;
            const sameResidence = authRecToBeUpserted.CDE_PROV_DIFF_RESI__c;            
            if ((relativeStatus === '2' || relativeStatus === '4') && (provRelation === 'B' || provRelation === 'S') && sameResidence === 'N') {
                const message = 'This provider does not meet the Qualified Exempt Provider qualification requirements at this time.';
                this.message = 'error';
                this._pageMessages = this.formatMessages([message]);
                this.showSpinner = false;
                isValid = false;
            }
            
            if (this.isCurrentPageValid === true && isValid) {
                if (childCmp) {
                    childCmp.childDisabilityMethod();
                }
                
                this.provIdValtwo = authRecToBeUpserted.IDN_PROVR__c;
                const caseRec = this.caseRec;
                
                if (sObjectName === 'T_SBSD_CASE__c') {
                    this.showSpinner = true;
                    authRecToBeUpserted.CDE_COUNTY__c = caseRec.CDE_COUNTY__c;
                    authRecToBeUpserted.IDN_CASE__c = caseRec.Id;
                    
                    let date, lastDay;
                    if (caseRec.DTE_REDET_CASE__c) {
                        date = new Date(caseRec.DTE_REDET_CASE__c);
                        lastDay = new Date(date.getFullYear(), date.getMonth() + 1, 0);
                    } else {
                        const authBeginDate = new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c);
                        lastDay = new Date(authBeginDate.getFullYear() + 1, authBeginDate.getMonth() + 1, 0);
                    }
                    authRecToBeUpserted.DTE_END_EFFV_AUTH__c = this.formatDateToString(lastDay);
                    const caseId = this.recordId;
                    const clientId = authRecToBeUpserted.IDN_CLIENT__c;                    
                    let eligibilityParams = {
                        caseRecId: caseId,
                        individualRecId: clientId,
                        newAuthorizations: authRecToBeUpserted
                    };                    
                    helper.callServer(this, 'AuthorizationFlowApxCtrl', 'isCaseEligible', (function (response) {
                        if (response && response.isSuccessful) {
                            const isInvalidProvider = this.isInvalidProvider;
                            if (!isInvalidProvider) {
                                if (response.objectData && response.objectData.Enddate) {
                                    this.eligibleChildEndDate = response.objectData.Enddate;
                                }
                                
                                const isCountyValid = this.showWarningForCounty;
                                if (!isCountyValid) {
                                    this.showSpinner = false;
                                    this.message = 'error';
                                    this._pageMessages = this.formatMessages([this.countyMessage]);
                                } else {
                                    let careLevelParams = {
                                        authId: this.caseRec.Id,
                                        recordId: this.recordId,
                                        currentBeginDate: authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c,
                                        currentProviderId: authRecToBeUpserted.IDN_PROVR__c,
                                        currentClientId: authRecToBeUpserted.IDN_CLIENT__c,
                                        hoursPerWeekDayStr: JSON.stringify(this.hoursPerWeekDay)
                                    };                                    
                                    helper.callServer(this, 'AuthorizationFlowApxCtrl', 'careLevelOfferedByProvider', (function (careLevelResponse) {
                                        if (careLevelResponse && careLevelResponse.isSuccessful) {
                                            if (careLevelResponse.objectData.showWarningCareLevel) {
                                                this.showWarningChildCareLevel = true;
                                                this.careLevelMessage = careLevelResponse.objectData.warningMessageCareLevel;
                                                this.confirmationModalOnCareLevel = true;
                                            } else {
                                                this.showWarningChildCareLevel = false;
                                                this.careLevelMessage = careLevelResponse.objectData.warningMessageCareLevel;
                                                this.validateIfBelowSchoolAge();
                                            }
                                        } else {
                                            console.error('Error in careLevelOfferedByProvider');
                                            this.showSpinner = false;
                                        }
                                    }).bind(this), JSON.stringify(careLevelParams));
                                }
                            } else {
                                this.showSpinner = false;
                                const message1 = 'Invalid provider, please check related fiscal agreement records for this provider or select different provider.';
                                this.message = 'error';
                                this._pageMessages = this.formatMessages([message1]);
                            }
                        } else {
                            this.showSpinner = false;
                            const message = response.errorMessage;
                            this.message = 'error';
                            this._pageMessages = this.formatMessages([message]);
                        }
                    }).bind(this), JSON.stringify(eligibilityParams));
                } else {
                    const isCountyValid = this.showWarningForCounty || this.isReadOnly;
                    if (!isCountyValid) {
                        this.showSpinner = false;
                        this.message = 'error';
                        this._pageMessages = this.formatMessages([this.countyMessage]);
                    } else {
                        const isValid = this.callModalOnChngSCRec();
                        if (isValid) {
                            this.showSpinner = true;
                            const authNewFiltered = {};
                            for (const key in authRecToBeUpserted) {
                                if (authRecToBeUpserted.hasOwnProperty(key) && authRecToBeUpserted[key] !== '') {
                                    authNewFiltered[key] = authRecToBeUpserted[key];
                                }
                            }
                            let authStatusParams = {
                                authId: authRecToBeUpserted.Id,
                                authNew: authNewFiltered
                            };                            
                            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getAuthorizationNotesStatusValidation', (function (response) {
                                if (response && response.isSuccessful) {
                                    if (response.objectData.AuthTerminated) {
                                        this.authTerminated = true;
                                    }
                                    this.validateIfBelowSchoolAge();
                                } else {
                                    this.showSpinner = false;
                                    let message = '';                                    
                                    if (response.objectData.UpdateAuthorization) {
                                        message = 'A terminated authorization cannot be updated';
                                    }
                                    this.message = 'error';
                                    this._pageMessages = message !== '' ? this.formatMessages([message]) : [];
                                }
                            }).bind(this), JSON.stringify(authStatusParams));
                        }
                    }
                }
            } else {
                this.showSpinner = false;
            }
        }
    }

    doPrevious() {
        const recordId = this.recordId;
        const sObjectName = this.sObjectName;
        const currentTabNumber = this.currentTabNumber;
        const authRecToBeUpserted = this.authRec;        
        if (authRecToBeUpserted !== undefined && authRecToBeUpserted.Id !== undefined) {
            let params = {
                recordId: authRecToBeUpserted.Id
            };            
            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getScheduleRecurrences', (function (response) {
                if (response && response.isSuccessful && response.objectData.recurrenceList) {
                    this.scheduleRecurr = response.objectData.recurrenceList;
                }
            }).bind(this), JSON.stringify(params));
        }
        if (currentTabNumber === 2) {
            const schedPg2Cmp = this.template.querySelector('c-authorization-sched-pg2_lwc');
            if (schedPg2Cmp) {
                this.isEncumbrnceCreated = schedPg2Cmp.getIsEncumbrnceCreated();
            }
        }        
        if (sObjectName === 'T_SBSD_CASE__c' && currentTabNumber === 2) {
            if (authRecToBeUpserted !== undefined && authRecToBeUpserted.Id !== undefined) {
                this.currentTabNumber = this.currentTabNumber - 1;
                this.originalBeginDate = authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c;
                this.originalClientId = authRecToBeUpserted.IDN_CLIENT__c;
                this.originalProviderId = authRecToBeUpserted.IDN_PROVR__c;
                this.originalSCId = authRecToBeUpserted.IDN_SLOT_CONTRACT__c;
            }
        } else if (sObjectName === 'T_AUTH__c' && currentTabNumber === 2) {
            this.currentTabNumber = this.currentTabNumber - 1;
        }
    }

    doFinish() {
        this.showSpinner = true;
        let isInvalid = false;
        const childComp = this.template.querySelector('c-authorization-sched-pg2_lwc');
        if (childComp) {
            isInvalid = childComp.handleUnsavedChanges();
        }
        const authRecUpserted = this.authRec;
        const isReadOnly = this.isReadOnly;  
        if (isInvalid === true) {
            this.confirmationModalUnsavedChanges = true;
            this.showSpinner = false;
        } else if (!isReadOnly) {
            let params = {
                lstSObject: [authRecUpserted],
                isFinalStep: true
            };
            abs_helper.callServerAndHandleError(this, 'GenericDataSaverApxCtrl', 'upsertRecordsFinal', (function (response) {
                if (response && response.isSuccessful) {
                    // CCCAP-15329: Trigger CR215 if UPK Enrolled = Yes AND UPK Stacked = No.
                    const upkEnrolledIsYes = this.authRec.CDE_CHILD_ENROLLED_IN_UPK__c === 'Yes';
                    const upkStackedIsNo = this.authRec.Is_UPK_Stacked__c === 'No';
                    const upkEnrolledChanged = this.initialUPKEnrolledValue !== this.authRec.CDE_CHILD_ENROLLED_IN_UPK__c;
                    const upkStackedChanged = this.initialUPKStackedValue !== this.authRec.Is_UPK_Stacked__c;
                    const shouldCreateCR215 = upkEnrolledIsYes && upkStackedIsNo && (this.sObjectName === 'T_SBSD_CASE__c' || upkEnrolledChanged || upkStackedChanged);
                    let authParams = {
                        authId: authRecUpserted.Id,
                        isCreate: this.isCreate,
                        isCreateCorrp: this.isCreateCorrp,
                        createTaskT122: false //CCCAP-15753
                    };                    
                    const setAuthFlagPromise = new Promise((resolve) => {
                        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'setAuthorizationFlag', (function (resp) {
                            if (shouldCreateCR215) {
                                let cr215Params = { authId: authRecUpserted.Id };
                                helper.callServer(this, 'AuthorizationFlowApxCtrl', 'CR215CorrBulk', (function (cr215Resp) {
                                    resolve(resp);
                                }).bind(this), JSON.stringify(cr215Params));
                            } else {
                                resolve(resp);
                            }
                        }).bind(this), JSON.stringify(authParams));
                    });
                    // Ensure each schedule recurrence record has 'attributes' as a property for proper deserialization
                    const schedRecurr = this.scheduleRecurr.length > 0 
                        ? this.scheduleRecurr.map(rec => {
                            const { attributes, sobjectType, ...restFields } = rec;
                            const attrObj = attributes || { type: sobjectType || 'Auth_Schedule_Recurrence__c' };
                            return { attributes: attrObj, ...restFields };
                        })
                        : [];
                    let scheduleParams = {
                        lstSObject: schedRecurr,
                        isFinalStep: true
                    };
                    
                    const scAssociationPromise = new Promise((resolve) => {
                        abs_helper.callServerAndHandleError(this, 'GenericDataSaverApxCtrl', 'upsertRecordsFinal', (function (schedResponse) {
                            const oldSlotId = this.authRecClone.IDN_SLOT_CONTRACT__c;
                            let scParams = {
                                authId: authRecUpserted.Id,
                                scAssRec: authRecUpserted.IDN_SLOT_CONTRACT__c,
                                scAssRecOldValue: oldSlotId
                            };                            
                            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'createSCAssociationRecord', (function (scResp) {
                                resolve(scResp);
                            }).bind(this), JSON.stringify(scParams));
                        }).bind(this), JSON.stringify(scheduleParams), null);
                    });
                    
                    Promise.allSettled([setAuthFlagPromise, scAssociationPromise])
                        .then(() => {
                            helper.redirectToRecord(this, authRecUpserted.Id);
                        });
                } else {
                    this.showSpinner = false;
                }
            }).bind(this), JSON.stringify(params), null);
        } else {
            helper.redirectToRecord(this, authRecUpserted.Id);
        }
    }

    doCancel() {
        const recordId = this.recordId;
        const sObjectName = this.sObjectName;
        const currentTabNumber = this.currentTabNumber;
        if (currentTabNumber === 1) {
            const authPg1 = this.template.querySelector('c-authorization-info-pg1_lwc');
            if (authPg1) {
                this.authRec = { ...authPg1.authRec };
            }
            if (sObjectName === 'T_SBSD_CASE__c') {
                const authRecToBeUpserted = this.authRec;
                if (authRecToBeUpserted !== undefined && authRecToBeUpserted.Id !== undefined) {
                    abs_helper.callServerAndDeleteRecords(this, (function (response) {
                        this.navigateToRecord(recordId);
                    }).bind(this), [authRecToBeUpserted]);
                } else {
                    this.navigateToRecord(recordId);
                }
            } else {
                const authRecClone = this.authRecClone;
                const authRec = this.authRec;
                const scAsscRecId = authRec.IDN_SLOT_CONTRACT__c;
                const authSlotBginDate = authRec.DTE_BEGIN_SLOT__c;
                const oldSlotId = authRecClone.IDN_SLOT_CONTRACT__c;
                const oldSlotDate = authRecClone.DTE_BEGIN_SLOT__c;
                
                if (oldSlotId !== scAsscRecId || oldSlotDate !== authSlotBginDate) {
                    this.confirmationModalOnCancel = true;
                } else {
                    this.navigateToRecord(recordId);
                }
            }
        } else {
            this.navigateToRecord(recordId);
        }
    }

    confirmCancel() {
        this.confirmationModalOnCancel = false;
        this.navigateToRecord(this.recordId);
        let params = {
            lstSObject: [this.authRecClone],
            isFinalStep: true
        };
        abs_helper.callServerAndHandleError(this, 'GenericDataSaverApxCtrl', 'upsertRecordsFinal', function(response) {
            this.navigateToRecord(this.recordId);
        }.bind(this), JSON.stringify(params), null);
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

    confirmCancelNo() {
        this.confirmationModalOnCancel = false;
    }

    confirmYes() {
        this.confirmationModalOnCountyCheck = false;
        this.showSpinner = false;      
        let params = {
            authId: this.caseRec.Id,
            recordId: this.recordId,
            currentBeginDate: this.authRec.DTE_BEGIN_EFFV_AUTH__c,
            currentProviderId: this.authRec.IDN_PROVR__c,
            currentClientId: this.authRec.IDN_CLIENT__c
        };        
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'careLevelOfferedByProvider', (function(response) {
            if (response && response.isSuccessful) {
                if (response.objectData.showWarningCareLevel) {
                    this.showWarningChildCareLevel = true;
                    this.careLevelMessage = response.objectData.warningMessageCareLevel;
                    this.showSpinner = false;
                    this.confirmationModalOnCareLevel = true;
                } else {
                    this.showWarningChildCareLevel = false;
                    this.careLevelMessage = response.objectData.warningMessageCareLevel;
                    this.checkUPKDualEnrollment();
                }
            } else {
                console.error('Error in careLevelOfferedByProvider');
                this.showSpinner = false;
            }
        }).bind(this), JSON.stringify(params));
    }

    confirmNo() {
        this.confirmationModalOnCountyCheck = false;
    }

    confirmYes1() {
        this.confirmationModalOnCareLevel = false;
        this.showSpinner = true;
        this.validateIfBelowSchoolAge();
    }

    confirmNo1() {
        this.confirmationModalOnCareLevel = false;
        this.showSpinner = false;
    }

    confirmYes2() {
        this.confirmationModalOnReplaceofscAssRec = false;        
        this.showSpinner = true;        
        let params = {
            authId: this.authRec.Id,
            authNew: this.authRec
        };        
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getAuthorizationNotesStatusValidation', (function(response) {
            if (response && response.isSuccessful) {
                if (response.objectData.AuthTerminated) {
                    this.authTerminated = true;
                }
                this.validateIfBelowSchoolAge();
            } else {
                this.showSpinner = false;
                let message = '';
                
                if (response.objectData.UpdateAuthorization) {
                    message = 'A terminated authorization cannot be updated';
                }
                if (response.objectData.AMT_ACTV_AUTH__c) {
                    message = 'Registration can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                } else if (response.objectData.AMT_TRANSP_AUTH__c) {
                    message = 'Transportation can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                } else if (response.objectData.AMT_RGSTR_AUTH__c) {
                    message = 'Activity can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                } else if (response.objectData.CDE_REL_PROVR__c) {
                    message = 'Provider Location / Relation to Child can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                }
                
                this.message = 'error';
                this._pageMessages = message !== '' ? this.formatMessages([message]) : [];
            }
        }).bind(this), JSON.stringify(params));
    }

    confirmNo2() {
        this.confirmationModalOnReplaceofscAssRec = false;        
        const authRecClone = this.authRecClone;
        const scAssRecOldValue = authRecClone.IDN_SLOT_CONTRACT__c;
        let authRec = { ...this.authRec };
        authRec.IDN_SLOT_CONTRACT__c = scAssRecOldValue;
        authRec.DTE_BEGIN_SLOT__c = authRecClone.DTE_BEGIN_SLOT__c;
        this.authRec = authRec;        
        const scAssRecId = authRec.IDN_SLOT_CONTRACT__c;        
        let params = {
            scAssId: scAssRecId
        };        
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'queryPopulateSCAssRecord', (function(response) {
            if (response && response.isSuccessful) {
                if (!this.isEmpty(scAssRecId)) {
                    let scAssRec = { ...this.sCAssociationRec };
                    scAssRec.DTE_BEGIN_SLOT__c = response.objectData.scAssRecBgnDte;
                    scAssRec.DTE_END_SLOT__c = response.objectData.scAssRecEndDte;
                    scAssRec.CDE_CARE_LEVEL__c = response.objectData.scAssCareLvl;
                    scAssRec.SLOT_CONTRACT_DESCRIPTION__c = response.objectData.scAssDesc;
                    this.sCAssociationRec = scAssRec;
                } else {
                    this.sCAssociationRec = {
                        sobjectType: 'T_SLOT_CONTRACT__c',
                        IDN_AUTH__c: ''
                    };
                }
            }
        }).bind(this), JSON.stringify(params));
    }

    confirmYes3() {
        this.confirmationModalBelowSchoolAge = false;
        this.showSpinner = true;
        this.checkUPKDualEnrollment();
    }

    confirmNo3() {
        this.confirmationModalBelowSchoolAge = false;
    }

    checkUPKDualEnrollment() {
        if (!this.isReadOnly && this.authRec.CDE_CHILD_ENROLLED_IN_UPK__c === 'Yes' && ((this.sObjectName === 'T_AUTH__c' && this.authProviderRec && this.authProviderRec.Is_UPK_Provider__c === true) 
            || (this.sObjectName === 'T_SBSD_CASE__c' && this.providerRec && this.providerRec.Is_UPK_Provider__c === true))) {
            this.showUPKDualEnrollmentModal = true;
            this.showSpinner = false;
        } else{
            this.checkValidations();
        }
    }

    confirmUPKDualEnrollmentYes() {
        this.showUPKDualEnrollmentModal = false;
        this.showSpinner = true;
        this.checkValidations();
    }

    confirmUPKDualEnrollmentNo() {
        this.showUPKDualEnrollmentModal = false;
    }

    actionOnYesUnsavedChanges() {
        this.confirmationModalUnsavedChanges = false;
        let params = {
            authId: this.authRec.Id
        };        
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'finishAuthorization', (function(response) {
            if (response) {
                helper.redirectToRecord(this, this.authRec.Id);
            }
        }).bind(this), JSON.stringify(params));
    }

    actionOnNoUnsavedChanges() {
        this.confirmationModalUnsavedChanges = false;
    }

    doValidateRecurrence(event) {
        this.showSpinner = true;
        const currentTabNumber = this.currentTabNumber;
        let date, lastDay;        
        if (currentTabNumber === 1) {
            const childCmp = this.template.querySelector('c-authorization-info-pg1_lwc');
            if (childCmp) {
                this.authRec = { ...childCmp.authRec };
                this.providerIdVal = childCmp.providerIdVal;
                this.isInvalidProvider = childCmp.isInvalidProvider;
                this.sCAssociationRec = { ...childCmp.sCAssociationRec };
                this.isCountyRateSCQ = childCmp.isCountyRateSCQ;
                this.slotContractOptions = childCmp.slotContractOptions;
                this.hoursPerWeekDay = childCmp.hoursPerWeekDay;
                this.rateTypeOptions = childCmp.rateTypeOptions;
                this.isChildDisable = childCmp.isChildDisable;
                this.authDropInDays = childCmp.authDropInDays;
                this.isDropInDaysIndicator = childCmp.isDropInDaysIndicator;
                this.numberOfDaysDrop = childCmp.numberOfDaysDrop;
                this.isProtectiveServiceIndicator = childCmp.isProtectiveServiceIndicator;
                this.isShowContractToIndicator = childCmp.isShowContractToIndicator;
                this.isCurrentPageValid = childCmp.callValidateCurrentPage();
            }            
            if (this.isCurrentPageValid === true) {
                if (childCmp) {
                    childCmp.childDisabilityMethod();
                }                
                const caseRec = this.caseRec;
                const authRecToBeUpserted = this.authRec;
                const sObjectName = this.sObjectName;                
                if (sObjectName === 'T_SBSD_CASE__c') {
                    this.showSpinner = true;
                    authRecToBeUpserted.CDE_COUNTY__c = caseRec.CDE_COUNTY__c;
                    authRecToBeUpserted.IDN_CASE__c = caseRec.Id;                    
                    if (caseRec.DTE_REDET_CASE__c) {
                        date = new Date(caseRec.DTE_REDET_CASE__c);
                        lastDay = new Date(date.getFullYear(), date.getMonth() + 1, 0);
                    } else {
                        const authBeginDate = new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c);
                        lastDay = new Date(authBeginDate.getFullYear() + 1, authBeginDate.getMonth() + 1, 0);
                    }
                    authRecToBeUpserted.DTE_END_EFFV_AUTH__c = this.formatDateToString(lastDay);                    
                    const caseId = this.recordId;
                    const clientId = authRecToBeUpserted.IDN_CLIENT__c;                    
                    let params = {
                        caseRecId: caseId,
                        individualRecId: clientId,
                        newAuthorizations: authRecToBeUpserted
                    };                    
                    helper.callServer(this, 'AuthorizationFlowApxCtrl', 'isCaseEligible', (function(response) {
                        if (response && response.isSuccessful) {
                            const isInvalidProvider = this.isInvalidProvider;
                            if (!isInvalidProvider) {
                                if (response.objectData) {
                                    if (response.objectData.Enddate) {
                                        this.eligibleChildEndDate = response.objectData.Enddate;
                                    }
                                }                                
                                const authRecToBeUpserted1 = this.authRec;
                                const currentBeginDate = authRecToBeUpserted1.DTE_BEGIN_EFFV_AUTH__c;
                                const currentProviderId = authRecToBeUpserted1.IDN_PROVR__c;
                                const currentClientId = authRecToBeUpserted1.IDN_CLIENT__c;
                                const authId = this.caseRec.Id;                                
                                let careLevelParams = {
                                    authId: authId,
                                    recordId: this.recordId,
                                    currentBeginDate: currentBeginDate,
                                    currentProviderId: currentProviderId,
                                    currentClientId: currentClientId
                                };                                
                                helper.callServer(this, 'AuthorizationFlowApxCtrl', 'careLevelOfferedByProvider', (function(careLevelResponse) {
                                    if (careLevelResponse && careLevelResponse.isSuccessful) {
                                        this.showWarningChildCareLevel = false;
                                        this.careLevelMessage = careLevelResponse.objectData.warningMessageCareLevel;
                                        this.doValidateRecurrenceHlp();
                                    } else {
                                        console.error('Error in careLevelOfferedByProvider');
                                        this.showSpinner = false;
                                    }
                                }).bind(this), JSON.stringify(careLevelParams));
                            } else {
                                this.showSpinner = false;
                                const message1 = 'Invalid provider, please check related fiscal agreement records for this provider or select different provider.';
                                this.message = 'error';
                                this._pageMessages = this.formatMessages([message1]);
                            }
                        } else {
                            this.showSpinner = false;
                            const message = response.errorMessage;
                            this.message = 'error';
                            this._pageMessages = this.formatMessages([message]);
                        }
                    }).bind(this), JSON.stringify(params));
                } else {
                    this.showSpinner = true;                    
                    let params = {
                        authId: authRecToBeUpserted.Id,
                        authNew: authRecToBeUpserted
                    };                    
                    helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getAuthorizationNotesStatusValidation', (function(response) {
                        if (response && response.isSuccessful) {
                            if (response.objectData.AuthTerminated) {
                                this.authTerminated = true;
                            }
                            this.doValidateRecurrenceHlp();
                        } else {
                            this.showSpinner = false;
                            let message = '';                            
                            if (response.objectData.UpdateAuthorization) {
                                message = 'A terminated authorization cannot be updated';
                            }
                            if (response.objectData.AMT_ACTV_AUTH__c) {
                                message = 'Registration can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                            } else if (response.objectData.AMT_TRANSP_AUTH__c) {
                                message = 'Transportation can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                            } else if (response.objectData.AMT_RGSTR_AUTH__c) {
                                message = 'Activity can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                            } else if (response.objectData.CDE_REL_PROVR__c) {
                                message = 'Provider Location / Relation to Child can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                            }                            
                            this.message = 'error';
                            this._pageMessages = message !== '' ? this.formatMessages([message]) : [];
                        }
                    }).bind(this), JSON.stringify(params));
                }
            } else {
                this.showSpinner = false;
                this.message = 'error';
                this._pageMessages = this.formatMessages([ERRORS_ON_THIS_PAGE]);
            }
        }
    }

    handleAuthRecCloneUpdate(event) {
        if (event.detail && event.detail.authRecClone) {
            this.authRecClone = { ...event.detail.authRecClone };
            if (this.initialUPKEnrolledValue === null) {
                this.initialUPKEnrolledValue = this.authRecClone.CDE_CHILD_ENROLLED_IN_UPK__c || null;
            }
            if (this.initialUPKStackedValue === undefined) {
                this.initialUPKStackedValue = this.authRecClone.Is_UPK_Stacked__c || null;
            }
        }
    }

    handleProviderSelected(event) {
        if (this.authRec && this.authRec.Id) {
            this.authRecIdForUpdate = this.authRec.Id;
        }
    }

    handleError(error) {
        console.error('Error:', error);
        let message = 'An unexpected error occurred';
        if (error.body && error.body.message) {
            message = error.body.message;
        } else if (error.message) {
            message = error.message;
        }
        helper.showToast(this, 'Error', message, 'error', 'dismissable');
    }

    handleValidationErrors(result) {
        if (result.errorMessages && result.errorMessages.length > 0) {
            this.pageMessages.push({
                Id: 'error-' + Date.now() + '-0',
                message: result.errorMessages
            });
            this.messageType = 'error';
        }
    }

    padNumber(number) {
        return String(number).padStart(2, '0');
    }

    formatDateToString(dateObj) {
        if (!dateObj || !(dateObj instanceof Date) || isNaN(dateObj.getTime())) {
            return '';
        }
        return dateObj.getFullYear() + '-' + 
            String(dateObj.getMonth() + 1).padStart(2, '0') + '-' + 
            String(dateObj.getDate()).padStart(2, '0');
    }

    isEmpty(value) {
        return value === null || value === undefined || value === '' || value === '--None--';
    }

    checkValidations() {
        const caseRec = this.caseRec;
        const authRecToBeUpserted = { ...this.authRec };
        const authRecClone = this.authRecClone;
        const authDropInDays = JSON.parse(JSON.stringify(this.authDropInDays));
        const sObjectName = this.sObjectName;
        let isBeginDateValid = true;
        const isReadOnly = this.isReadOnly;
        let isCreateCorrp = false;        
        if (!isReadOnly) {
            authRecToBeUpserted.Number_of_Drop_in_Days__c = authDropInDays;            
            if (authRecToBeUpserted.Number_of_Drop_in_Days__c !== authRecClone.Number_of_Drop_in_Days__c) {
                if (sObjectName === 'T_AUTH__c') {
                    isCreateCorrp = true;
                }
            }
        }        
        this.isCreateCorrp = isCreateCorrp;        
        let date, lastDay, lastCsReder;
        let key = '';        
        if (sObjectName === 'T_SBSD_CASE__c') {
            this.confirmationModalOnCountyCheck = false;
            this.confirmationModalOnCareLevel = false;            
            authRecToBeUpserted.CDE_COUNTY__c = caseRec.CDE_COUNTY__c;
            authRecToBeUpserted.IDN_CASE__c = caseRec.Id;            
            if (caseRec.DTE_REDET_CASE__c) {
                date = helper.getDateInUTC(new Date(caseRec.DTE_REDET_CASE__c));
                lastCsReder = new Date(date.getFullYear(), parseInt(date.getMonth()) + 1, 0);
            }            
            if (caseRec.DTE_REDET_CASE__c && !this.isChildWefareCare) {
                date = helper.getDateInUTC(new Date(caseRec.DTE_REDET_CASE__c));
                lastDay = new Date(date.getFullYear(), parseInt(date.getMonth()) + 1, 0);
            } else {
                date = helper.getDateInUTC(new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c));
                lastDay = new Date(date.getFullYear() + 1, parseInt(date.getMonth()) + 1, 0);
            }            
            let childEndDate = this.eligibleChildEndDate;
            if (!this.isEmpty(childEndDate)) {
                childEndDate = helper.getDateInUTC(new Date(childEndDate));
            }            
            if (!this.isEmpty(childEndDate) && !this.isChildWefareCare) {
                if (childEndDate < lastDay) {
                    lastDay = childEndDate;
                }
            }            
            this.authEndDate = lastDay;            
            if (!this.isChildWefareCare && sObjectName === 'T_SBSD_CASE__c') {
                if (helper.getDateInUTC(new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c)) > lastCsReder) {
                    isBeginDateValid = false;
                }
            }            
            key = lastDay.getFullYear() + '-' + (lastDay.getMonth() + 1) + '-' + lastDay.getDate();
            authRecToBeUpserted.DTE_END_EFFV_AUTH__c = this.formatDateToString(lastDay);
        }
        let isProceedAuthEncumb = true;
        let isProceedAuthEncumbRecurr = true;
        const hoursPerWeekDayChanged = this.hoursPerWeekDayChanged;
        let hoursPerWeekDay = JSON.parse(JSON.stringify(this.hoursPerWeekDay || []));
        hoursPerWeekDay.forEach(item => {
            if (item.CDE_TYPE_UNIT_CARE__c === '') {
                item.CDE_TYPE_UNIT_CARE__c = '--None--';
            }
        });
        let isValidCareUnit = true;
        let rateTypeErrorMsg = '';        
        for (let i = 0; i < hoursPerWeekDay.length; i++) {
            if (((hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c !== '--None--') && (hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c !== undefined)) &&
                ((hoursPerWeekDay[i].CNT_HOUR_CARE__c !== '') && (hoursPerWeekDay[i].CNT_HOUR_CARE__c !== undefined))) {
                if (hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c.indexOf(';') > -1) {
                    rateTypeErrorMsg = hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c;
                    isValidCareUnit = false;
                    break;
                }
            } else {
                isProceedAuthEncumb = false;
                break;
            }
        }        
        const authTerminated = this.authTerminated;
        const isEncumbrnceCreated = this.isEncumbrnceCreated;
        const originalBeginDate = this.originalBeginDate;
        const currentBeginDate = authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c;
        const originalProviderId = this.originalProviderId;
        const currentProviderId = authRecToBeUpserted.IDN_PROVR__c;
        const originalClientId = this.originalClientId;
        const currentClientId = authRecToBeUpserted.IDN_CLIENT__c;        
        if (sObjectName === 'T_SBSD_CASE__c' && isEncumbrnceCreated && 
            (originalBeginDate !== currentBeginDate || originalProviderId !== currentProviderId || originalClientId !== currentClientId)) {
            if (!this.isModifiedAfterChange) {
                this.scheduleRecurr = [];
            }
        }
        let scheduleRecurr = this.scheduleRecurr;
        if (this.isEmpty(scheduleRecurr) || scheduleRecurr.length === 0) {
            isProceedAuthEncumbRecurr = false;
        }
        let missedSchedule = false;
        let isInValidRecurrence = false;
        let currentBeginDateTemp = currentBeginDate;
        let authEndDate = this.authEndDate;
        const authRec = this.authRec;        
        if (sObjectName === 'T_SBSD_CASE__c') {
            if (authEndDate == null) {
                authEndDate = lastDay;
            }
        } else {
            authEndDate = helper.getDateInUTC(new Date(authRec.DTE_END_EFFV_AUTH__c));
            this.authEndDate = authEndDate;
        }
        if (!this.isEmpty(scheduleRecurr) && scheduleRecurr.length > 0) {
            if (authEndDate == null) {
                authEndDate = lastDay;
            }            
            const formattedAuthEndDate = authEndDate.getFullYear() + '-' + this.padNumber(authEndDate.getMonth() + 1) + '-' + this.padNumber(authEndDate.getDate());
            let formattedBeginDate;            
            scheduleRecurr.sort(function compare(a, b) {
                const dateA = new Date(a.DTE_Begin_Date__c);
                const dateB = new Date(b.DTE_Begin_Date__c);
                return dateA - dateB;
            });            
            const lastRecurr = scheduleRecurr[scheduleRecurr.length - 1];
            const firstRecurr = scheduleRecurr[0];            
            if (currentBeginDate && currentBeginDate.indexOf('T') > -1) {
                const beginDateTemp = currentBeginDate.split('T');
                if (!this.isEmpty(beginDateTemp)) {
                    formattedBeginDate = beginDateTemp[0];
                }
            } else {
                formattedBeginDate = currentBeginDate;
            }            
            for (let obj of scheduleRecurr) {
                if (firstRecurr.DTE_Begin_Date__c !== formattedBeginDate) {
                    missedSchedule = true;
                }
                if (lastRecurr.DTE_End_Date__c !== formattedAuthEndDate) {
                    missedSchedule = true;
                }
                if (obj.DTE_Begin_Date__c <= currentBeginDateTemp && obj.DTE_End_Date__c >= currentBeginDateTemp) {
                    currentBeginDateTemp = obj.DTE_End_Date__c;
                    const dateA = new Date(currentBeginDateTemp);
                    dateA.setDate(dateA.getDate() + 1);
                    const formatted = dateA.getFullYear() + '-' + this.padNumber(dateA.getMonth() + 1) + '-' + this.padNumber(dateA.getDate());
                    currentBeginDateTemp = formatted;
                } else {
                    missedSchedule = true;
                }
            }            
            if (firstRecurr.DTE_Begin_Date__c < formattedBeginDate) {
                isInValidRecurrence = true;
            }
        }        
        let isChildRateTypeCorrect = false;
        for (let i = 0; i < hoursPerWeekDay.length; i++) {
            if (hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c === '55') {
                if (!this.isChildDisable) {
                    isChildRateTypeCorrect = true;
                    break;
                } else {
                    isChildRateTypeCorrect = false;
                    break;
                }
            }
        }
        if ((!isProceedAuthEncumb || isChildRateTypeCorrect) && sObjectName === 'T_SBSD_CASE__c') {
            this.showSpinner = false;
            let message;
            if (!isProceedAuthEncumb) {
                message = 'Please fill all fields of Standard Schedule Section.';
            } else if (isChildRateTypeCorrect) {
                message = Child_Disability_Validation_Msg;
            }
            this.message = 'error';
            this._pageMessages = this.formatMessages([message]);
        } else if (isInValidRecurrence && sObjectName === 'T_SBSD_CASE__c') {
            this.message = 'error';
            this._pageMessages = this.formatMessages([recurrenceErrorMsg]);
            this.showSpinner = false;
        } else {
            if (sObjectName === 'T_SBSD_CASE__c' && isEncumbrnceCreated && 
                (originalBeginDate !== currentBeginDate || originalProviderId !== currentProviderId || originalClientId !== currentClientId)) {
                abs_helper.callServerAndDeleteRecords(this, (function(response) {
                    let authRecTemp = { ...this.authRec };
                    authRecTemp.Id = null;
                    this.authRec = authRecTemp;
                    this.isEncumbrnceCreated = false;
                    authRecToBeUpserted.Id = null;
                    let upsertParams = {
                        lstSObject: [authRecToBeUpserted],
                        lastDay: key,
                        isBeginDateValid: isBeginDateValid
                    };                    
                    abs_helper.callServerAndHandleError(this, 'GenericDataSaverApxCtrl', 'upsertRecordAuth', (function(upsertResponse) {
                        if (upsertResponse && upsertResponse.isSuccessful && isBeginDateValid) {
                            const mergedAuth = { ...this.authRec, ...upsertResponse.objectData.upsertedRecords[0] };
                            this.authRec = mergedAuth;
                            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getLatestAuthDetails', (function(upkResp) {
                                if (upkResp && upkResp.isSuccessful && upkResp.objectData) {
                                    this.authRec = {
                                        ...this.authRec,
                                        UPK_Last_Updated_date__c: upkResp.objectData.UPK_Last_Updated_date__c || null
                                    };
                                }
                            }).bind(this), JSON.stringify({ authId: mergedAuth.Id }));
                            const isEncumCreate = this.isEncumbrnceCreated;
                            if (sObjectName === 'T_SBSD_CASE__c') {
                                if (isProceedAuthEncumb) {
                                    if (isValidCareUnit) {
                                        if (!isEncumCreate) {
                                            let createParams = {
                                                authRecId: mergedAuth.Id,
                                                hoursPerWeekDayStr: JSON.stringify(hoursPerWeekDay),
                                                hoursPerWeekDayRecurrStr: JSON.stringify(scheduleRecurr)
                                            };                                            
                                            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'createAuthEncmbrRecords', (function(createResp) {
                                                if (createResp) {
                                                    const isSuccess = createResp.isSuccessful;
                                                    if (isSuccess) {
                                                        const authRecUpdated = this.authRecUpdated;
                                                        this.createAuthStatusRecord(authRecUpdated, mergedAuth);
                                                        const xLog = this.xLogAuthStatus;
                                                        this.logWebservice(xLog);                                                        
                                                        const careDateToAuthEncmbr = createResp.objectData.careDateToAuthEncmbr;
                                                        this.careDateToAuthEncmbr = careDateToAuthEncmbr;
                                                        this.showSpinner = false;
                                                        this.currentTabNumber = this.currentTabNumber + 1;
                                                        this.message = '';
                                                        this._pageMessages = [];
                                                        if (createResp.objectData && createResp.objectData.xLog) {
                                                            this.logWebservice(createResp.objectData.xLog);
                                                        }
                                                    } else {
                                                        if(createResp.errorMessage){
                                                            this.message = 'error';
                                                            this._pageMessages = this.formatMessages([createResp.errorMessage]);
                                                        }
                                                        if (createResp.objectData && createResp.objectData.xLog) {
                                                            this.logWebservice(createResp.objectData.xLog);
                                                        }
                                                        this.showSpinner = false;
                                                    }
                                                }
                                            }).bind(this), JSON.stringify(createParams));
                                        } else {
                                            let updateParams = {
                                                authRecId: mergedAuth.Id,
                                                hoursPerWeekDayStr: JSON.stringify(hoursPerWeekDay),
                                                isUpdate: isProceedAuthEncumb,
                                                hoursPerWeekDayRecurrStr: JSON.stringify(scheduleRecurr),
                                                currentMode: sObjectName === 'T_SBSD_Case__c' ? 'case' : (isReadOnly ? 'viewAuth' : 'editAuth')
                                            };                                            
                                            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'updateAuthEncmbrRecordsBasedOnPatterns', (function(updateResp) {
                                                if (updateResp) {
                                                    const careDateToAuthEncmbr = updateResp.objectData.careDateToAuthEncmbr;
                                                    if (updateResp.successMessage === 'No encumbrance records returned from web service') {
                                                        this.showSpinner = false;
                                                        this.message = 'error';
                                                        this._pageMessages = this.formatMessages([updateResp.successMessage]);
                                                    } else {
                                                        this.careDateToAuthEncmbr = careDateToAuthEncmbr;
                                                        this.showSpinner = false;
                                                        this.currentTabNumber = this.currentTabNumber + 1;
                                                        this._pageMessages = [];
                                                        this.message = '';
                                                    }
                                                }
                                            }).bind(this), JSON.stringify(updateParams));
                                        }
                                    } else {
                                        this.showSpinner = false;
                                        this.message = 'error';
                                        this._pageMessages = this.formatMessages(['Invalid Rate Type ' + rateTypeErrorMsg + ' please select one rate type per record.']);
                                    }
                                } else {
                                    this.showSpinner = false;
                                    this.message = 'error';
                                    this._pageMessages = this.formatMessages(['Please fill all fields of Standard Schedule Section.']);
                                }
                            } else {
                                if (isValidCareUnit) {
                                    let updateParams = {
                                        authRecId: mergedAuth.Id,
                                        hoursPerWeekDayStr: JSON.stringify(hoursPerWeekDay),
                                        isUpdate: isProceedAuthEncumb,
                                        hoursPerWeekDayRecurrStr: JSON.stringify(scheduleRecurr),
                                        currentMode: sObjectName === 'T_SBSD_Case__c' ? 'case' : (isReadOnly ? 'viewAuth' : 'editAuth')
                                    };                                    
                                    helper.callServer(this, 'AuthorizationFlowApxCtrl', 'updateAuthEncmbrRecordsBasedOnPatterns', (function(updateResp) {
                                        if (updateResp) {
                                            if (updateResp.successMessage === 'No encumbrance records returned from web service') {
                                                this.message = 'error';
                                                this._pageMessages = this.formatMessages([updateResp.successMessage]);
                                            } else {
                                                const careDateToAuthEncmbr = updateResp.objectData.careDateToAuthEncmbr;
                                                this.careDateToAuthEncmbr = careDateToAuthEncmbr;
                                                this.currentTabNumber = this.currentTabNumber + 1;
                                                this.message = '';
                                                this._pageMessages = [];
                                            }
                                        }
                                        this.showSpinner = false;
                                    }).bind(this), JSON.stringify(updateParams));
                                } else {
                                    this.message = 'error';
                                    this._pageMessages = this.formatMessages(['Invalid Rate Type ' + rateTypeErrorMsg + ' please select one rate type per record.']);
                                    this.showSpinner = false;
                                }
                            }
                        } else {
                            this.showSpinner = false;
                        }
                    }).bind(this), JSON.stringify(upsertParams), null);
                    
                }).bind(this), [authRecToBeUpserted]);
                
            } else {
                if (isReadOnly) {
                    let readOnlyParams = {
                        authRecId: this.authRec.Id,
                        hoursPerWeekDayStr: JSON.stringify(hoursPerWeekDay),
                        isUpdate: false,
                        hoursPerWeekDayRecurrStr: JSON.stringify(scheduleRecurr),
                        currentMode: sObjectName === 'T_SBSD_Case__c' ? 'case' : (isReadOnly ? 'viewAuth' : 'editAuth')
                    };                    
                    helper.callServer(this, 'AuthorizationFlowApxCtrl', 'updateAuthEncmbrRecordsBasedOnPatterns', (function(resp) {
                        if (resp) {
                            if (resp.successMessage === 'No encumbrance records returned from web service') {
                                this.message = 'error';
                                this._pageMessages = this.formatMessages([resp.successMessage]);
                            } else {
                                const careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                this.careDateToAuthEncmbr = careDateToAuthEncmbr;
                                this.currentTabNumber = this.currentTabNumber + 1;
                                this.message = '';
                                this._pageMessages = [];
                            }
                        }
                        this.showSpinner = false;
                    }).bind(this), JSON.stringify(readOnlyParams));
                } else {
                    let upsertParams = {
                        lstSObject: [authRecToBeUpserted],
                        lastDay: key,
                        isBeginDateValid: isBeginDateValid
                    };
                    abs_helper.callServerAndHandleError(this, 'GenericDataSaverApxCtrl', 'upsertRecordAuth', (function(response) {
                        if (response && response.isSuccessful && isBeginDateValid) {
                            const mergedAuth = { ...this.authRec, ...response.objectData.upsertedRecords[0] };
                            this.authRec = mergedAuth;
                            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'getLatestAuthDetails', (function(upkResp) {
                                if (upkResp && upkResp.isSuccessful && upkResp.objectData) {
                                    this.authRec = {
                                        ...this.authRec,
                                        UPK_Last_Updated_date__c: upkResp.objectData.UPK_Last_Updated_date__c || null
                                    };
                                }
                            }).bind(this), JSON.stringify({ authId: mergedAuth.Id }));
                            const isEncumCreate = this.isEncumbrnceCreated;
                            this.showSpinner = false;
                            if (sObjectName === 'T_SBSD_CASE__c') {
                                if (isProceedAuthEncumb) {
                                    if (!authTerminated) {
                                        if (isValidCareUnit) {
                                            if (!isEncumCreate) {
                                                let createParams = {
                                                    authRecId: mergedAuth.Id,
                                                    hoursPerWeekDayStr: JSON.stringify(hoursPerWeekDay),
                                                    hoursPerWeekDayRecurrStr: JSON.stringify(scheduleRecurr)
                                                };                                                
                                                helper.callServer(this, 'AuthorizationFlowApxCtrl', 'createAuthEncmbrRecords', (function(resp) {
                                                    if (resp) {
                                                        const isSuccess = resp.isSuccessful;
                                                        if (isSuccess) {
                                                            const authRecUpdated = this.authRecUpdated;
                                                            const xLog = this.xLogAuthStatus;
                                                            this.logWebservice(xLog);
                                                            this.createAuthStatusRecord(authRecUpdated, mergedAuth);
                                                            const careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                            this.careDateToAuthEncmbr = careDateToAuthEncmbr;
                                                            this.currentTabNumber = this.currentTabNumber + 1;
                                                            this.message = '';
                                                            this._pageMessages = [];
                                                            if (resp.objectData && resp.objectData.xLog) {
                                                                this.logWebservice(resp.objectData.xLog);
                                                            }
                                                        } else {
                                                            if (resp.objectData && resp.objectData.xLog) {
                                                                this.logWebservice(resp.objectData.xLog);
                                                            }
                                                            if(resp.errorMessage){
                                                                this.message = 'error';
                                                                this._pageMessages = this.formatMessages([resp.errorMessage]);
                                                            }
                                                        }
                                                    }
                                                }).bind(this), JSON.stringify(createParams));
                                            } else {
                                                let updateParams = {
                                                    authRecId: mergedAuth.Id,
                                                    hoursPerWeekDayStr: JSON.stringify(hoursPerWeekDay),
                                                    isUpdate: isProceedAuthEncumb,
                                                    hoursPerWeekDayRecurrStr: JSON.stringify(scheduleRecurr),
                                                    currentMode: sObjectName === 'T_SBSD_Case__c' ? 'case' : (isReadOnly ? 'viewAuth' : 'editAuth')
                                                };                                                
                                                helper.callServer(this, 'AuthorizationFlowApxCtrl', 'updateAuthEncmbrRecordsBasedOnPatterns', (function(resp) {
                                                    if (resp) {
                                                        const careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                        if (resp.successMessage === 'No encumbrance records returned from web service') {
                                                            this.message = 'error';
                                                            this._pageMessages = this.formatMessages([resp.successMessage]);
                                                        } else {
                                                            this.careDateToAuthEncmbr = careDateToAuthEncmbr;
                                                            this.currentTabNumber = this.currentTabNumber + 1;
                                                            this.message = '';
                                                            this._pageMessages = [];
                                                        }
                                                    }
                                                }).bind(this), JSON.stringify(updateParams));
                                            }
                                        } else {
                                            this.message = 'error';
                                            this._pageMessages = this.formatMessages(['Invalid Rate Type ' + rateTypeErrorMsg + ' please select one rate type per record.']);
                                        }
                                    } else {
                                        this.message = 'error';
                                        this._pageMessages = this.formatMessages(['A terminated authorization cannot be updated']);
                                    }
                                } else {
                                    this.message = 'error';
                                    this._pageMessages = this.formatMessages(['Please fill all fields of Standard Schedule Section.']);
                                }
                            } else {
                                if (isValidCareUnit) {
                                    if (isProceedAuthEncumb) {
                                        if (!authTerminated) {
                                            let updateParams = {
                                                authRecId: mergedAuth.Id,
                                                hoursPerWeekDayStr: JSON.stringify(hoursPerWeekDay),
                                                isUpdate: isProceedAuthEncumb,
                                                hoursPerWeekDayRecurrStr: JSON.stringify(scheduleRecurr),
                                                currentMode: sObjectName === 'T_SBSD_Case__c' ? 'case' : (isReadOnly ? 'viewAuth' : 'editAuth')
                                            };                                            
                                            helper.callServer(this, 'AuthorizationFlowApxCtrl', 'updateAuthEncmbrRecordsBasedOnPatterns', (function(resp) {
                                                if (resp) {
                                                    if (resp.successMessage === 'No encumbrance records returned from web service') {
                                                        this.message = 'error';
                                                        this._pageMessages = this.formatMessages([resp.successMessage]);
                                                    } else {
                                                        const careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                        this.careDateToAuthEncmbr = careDateToAuthEncmbr;
                                                        this.currentTabNumber = this.currentTabNumber + 1;
                                                        this.message = '';
                                                        this._pageMessages = [];
                                                    }
                                                }
                                            }).bind(this), JSON.stringify(updateParams));
                                        } else {
                                            this.message = 'error';
                                            this._pageMessages = this.formatMessages(['A terminated authorization cannot be updated']);
                                        }
                                    } else {
                                        let updateParams = {
                                            authRecId: mergedAuth.Id,
                                            hoursPerWeekDayStr: JSON.stringify(hoursPerWeekDay),
                                            isUpdate: false,
                                            hoursPerWeekDayRecurrStr: JSON.stringify(scheduleRecurr),
                                            currentMode: sObjectName === 'T_SBSD_Case__c' ? 'case' : (isReadOnly ? 'viewAuth' : 'editAuth')
                                        };                                        
                                        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'updateAuthEncmbrRecordsBasedOnPatterns', (function(resp) {
                                            if (resp) {
                                                if (resp.successMessage === 'No encumbrance records returned from web service') {
                                                    this.message = 'error';
                                                    this._pageMessages = this.formatMessages([resp.successMessage]);
                                                } else {
                                                    const careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                    this.careDateToAuthEncmbr = careDateToAuthEncmbr;
                                                    this.currentTabNumber = this.currentTabNumber + 1;
                                                    this.message = '';
                                                    this._pageMessages = [];
                                                }
                                            }
                                        }).bind(this), JSON.stringify(updateParams));
                                    }
                                } else {
                                    this.message = 'error';
                                    this._pageMessages = this.formatMessages(['Invalid Rate Type ' + rateTypeErrorMsg + ' please select one rate type per record.']);
                                }
                            }
                        } else {
                            this.showSpinner = false;
                        }
                    }).bind(this), JSON.stringify(upsertParams), null);
                }
            }
        }
    }

    createAuthStatusRecord(authRecUpdated, mergedAuth) {
        const authStatusRecord = { ...this.authStatusRecord };
        authStatusRecord.createdById = authRecUpdated.CreatedById;
        authStatusRecord.createdDate = new Date();
        authStatusRecord.lastModifiedById = authRecUpdated.CreatedById;
        authStatusRecord.lastModifiedDate = new Date();
        authStatusRecord.idnAuth = mergedAuth.Id;
        authStatusRecord.cdeStatusAuth = '2';
        authStatusRecord.dteBeginEffv = mergedAuth.DTE_BEGIN_EFFV_AUTH__c;
        const xLog = { ...this.xLogAuthStatus };
        xLog.Method__c = 'createAuthStatusRecord';
        xLog.Class__c = 'authorizationFlowHelper';
        xLog.Exception_Message__c = 'calling auth status creation service with auth id ' + mergedAuth.Id;
        this.logWebservice(xLog);        
        let params = {
            authStatus: authStatusRecord,
            isNew: true
        };
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'upsertAuthStatus', (function (response) {
            if (response && response.objectData && response.objectData.xLog) {
                this.logWebservice(response.objectData.xLog);
            }
        }).bind(this), JSON.stringify(params));
    }

    logWebservice(xlog) {
        let params = {
            xLog: xlog
        };

        helper.callServer(this, 'GenericDataSaverApxCtrl', 'logException', (function (response) {
            console.log('Exception occurred on server and has been logged.');
        }).bind(this), JSON.stringify(params));
    }

    validateIfBelowSchoolAge() {
        this.showSpinner = false;
        const authRec = this.authRec;
        let hoursPerWeekDay = JSON.parse(JSON.stringify(this.hoursPerWeekDay || []));
        hoursPerWeekDay.forEach(item => {
            if (item.CDE_TYPE_UNIT_CARE__c === '') {
                item.CDE_TYPE_UNIT_CARE__c = '--None--';
            }
        });        
        let params = {
            authBeginDate: authRec.DTE_BEGIN_EFFV_AUTH__c,
            clientId: authRec.IDN_CLIENT__c,
            hoursPerWeekDay: hoursPerWeekDay
        };
        helper.callServer(this, 'AuthorizationFlowApxCtrl', 'validateIfBelowSchoolAge', (function (response) {
            if (response && response.isSuccessful) {
                if (response.objectData.showWarningBelowSchoolAge) {
                    this.warningMessageBelowSchoolAge = response.objectData.warningMessageBelowSchoolAge;
                    this.confirmationModalBelowSchoolAge = true;
                } else {
                    this.warningMessageBelowSchoolAge = response.objectData.warningMessageBelowSchoolAge;
                    this.checkUPKDualEnrollment();
                }
            } else {
                this.handleError(response);
            }
        }).bind(this), JSON.stringify(params));
    }

    doValidateRecurrenceHlp() {
        const caseRec = this.caseRec;
        const authRecToBeUpserted = this.authRec;
        const sObjectName = this.sObjectName;
        let isBeginDateValid = true;        
        if (sObjectName === 'T_SBSD_CASE__c') {
            this.confirmationModalOnCountyCheck = false;
            this.confirmationModalOnCareLevel = false;
            let date, lastDay;            
            if (caseRec.DTE_REDET_CASE__c && !this.isChildWefareCare) {
                date = helper.getDateInUTC(new Date(caseRec.DTE_REDET_CASE__c));
                lastDay = new Date(date.getFullYear(), parseInt(date.getMonth()) + 1, 0);
            } else {
                date = helper.getDateInUTC(new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c));
                lastDay = new Date(date.getFullYear() + 1, parseInt(date.getMonth()) + 1, 0);
            }            
            let childEndDate = this.eligibleChildEndDate;
            if (!this.isEmpty(childEndDate)) {
                childEndDate = helper.getDateInUTC(new Date(childEndDate));
            }            
            if (!this.isEmpty(childEndDate) && !this.isChildWefareCare) {
                if (childEndDate < lastDay) {
                    lastDay = childEndDate;
                }
            }            
            this.authEndDate = lastDay;
            if (!this.isChildWefareCare && sObjectName === 'T_SBSD_CASE__c') {
                if (helper.getDateInUTC(new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c)) > helper.getDateInUTC(new Date(caseRec.DTE_REDET_CASE__c))) {
                    isBeginDateValid = false;
                }
            }
            authRecToBeUpserted.DTE_END_EFFV_AUTH__c = this.formatDateToString(lastDay);
        }
        
        if (sObjectName !== 'T_SBSD_CASE__c') {
            const authEndDate = helper.getDateInUTC(new Date(authRecToBeUpserted.DTE_END_EFFV_AUTH__c));
            this.authEndDate = authEndDate;
        }        
        let isProceedAuthEncumb = true;
        let hoursPerWeekDay = JSON.parse(JSON.stringify(this.hoursPerWeekDay || []));
        hoursPerWeekDay.forEach(item => {
            if (item.CDE_TYPE_UNIT_CARE__c === '') {
                item.CDE_TYPE_UNIT_CARE__c = '--None--';
            }
        });
        let isValidCareUnit = true;
        let rateTypeErrorMsg = '';        
        for (let i = 0; i < hoursPerWeekDay.length; i++) {
            if (((hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c !== '--None--') && (hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c !== undefined)) &&
                ((hoursPerWeekDay[i].CNT_HOUR_CARE__c !== '') && (hoursPerWeekDay[i].CNT_HOUR_CARE__c !== undefined))) {
                if (hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c.indexOf(';') > -1) {
                    rateTypeErrorMsg = hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c;
                    isValidCareUnit = false;
                    break;
                }
            } else {
                isProceedAuthEncumb = false;
                break;
            }
        }        
        let isChildRateTypeCorrect = false;
        for (let i = 0; i < hoursPerWeekDay.length; i++) {
            if (hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c === '55') {
                if (!this.isChildDisable) {
                    isChildRateTypeCorrect = true;
                    break;
                } else {
                    isChildRateTypeCorrect = false;
                    break;
                }
            }
        }        
        if (!isProceedAuthEncumb || isChildRateTypeCorrect) {
            this.showSpinner = false;
            let message;
            if (!isProceedAuthEncumb) {
                message = 'Please fill all fields of Standard Schedule Section.';
            } else if (isChildRateTypeCorrect) {
                message = Child_Disability_Validation_Msg;
            }
            this.message = 'error';
            this._pageMessages = this.formatMessages([message]);
        } else {
            const isEncumbrnceCreated = this.isEncumbrnceCreated;
            const originalBeginDate = this.originalBeginDate;
            const currentBeginDate = authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c;
            const originalProviderId = this.originalProviderId;
            const currentProviderId = authRecToBeUpserted.IDN_PROVR__c;
            const originalClientId = this.originalClientId;
            const currentClientId = authRecToBeUpserted.IDN_CLIENT__c;
            let isAuthUpdated = false;
            let isAuthFirstTime = true;            
            if (sObjectName === 'T_SBSD_CASE__c' && isEncumbrnceCreated) {
                isAuthFirstTime = false;
                if (originalBeginDate !== currentBeginDate || originalProviderId !== currentProviderId || originalClientId !== currentClientId) {
                    isAuthUpdated = true;
                }
            }            
            this.showSpinner = false;
            this.message = '';
            this._pageMessages = [];            
            const childComponent = this.template.querySelector('c-authorization-info-pg1_lwc');
            if (childComponent) {
                childComponent.childRecurrenceMethod(true, true, isAuthFirstTime, isAuthUpdated);
            }
        }
    }

    callModalOnChngSCRec() {
        let doProceed = true;
        const isCreate = this.isCreate;
        const authRecToBeUpserted = this.authRec;
        const authSlotContID = authRecToBeUpserted.IDN_SLOT_CONTRACT__c;
        const authRecClone = this.authRecClone;
        const scAssRecOldValue = authRecClone.IDN_SLOT_CONTRACT__c;        
        if (!isCreate) {
            if (!this.isEmpty(scAssRecOldValue) && !this.isEmpty(authSlotContID) && scAssRecOldValue !== authSlotContID) {
                this.replaceMessage = 'Slot Contract association on the authorization is being replaced. Do you want to proceed further with changes?';
                this.showSpinner = false;
                this.confirmationModalOnReplaceofscAssRec = true;
                doProceed = false;
            } else if (!this.isEmpty(scAssRecOldValue) && this.isEmpty(authSlotContID)) {
                this.replaceMessage = 'Slot Contract association on the authorization is being removed. Do you want to proceed further with changes?';
                this.showSpinner = false;
                this.confirmationModalOnReplaceofscAssRec = true;
                doProceed = false;
            }
        }
        return doProceed;
    }

    formatMessages(messages) {
        if (!messages || messages.length === 0) {
            return [];
        }
        return messages.map((msg, index) => ({
            Id: 'error-' + Date.now() + '-' + index,
            message: msg
        }));
    }
}