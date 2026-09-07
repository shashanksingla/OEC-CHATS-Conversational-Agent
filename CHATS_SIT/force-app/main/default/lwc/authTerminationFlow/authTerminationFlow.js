import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { helper } from 'c/generic_Utilities';
import Id from '@salesforce/user/Id';

// Import custom label for Auth Termination Message
import AUTH_TERMINATION_MSG from '@salesforce/label/c.Auth_Termination_Msg';

// Import fields for wire service
import AUTH_ID_FIELD from '@salesforce/schema/T_AUTH__c.Id';
import AUTH_IDN_EXTNL_FIELD from '@salesforce/schema/T_AUTH__c.IDN_EXTNL__c';
import AUTH_END_DATE_FIELD from '@salesforce/schema/T_AUTH__c.DTE_END_EFFV_AUTH__c';
import AUTH_BEGIN_DATE_FIELD from '@salesforce/schema/T_AUTH__c.DTE_BEGIN_EFFV_AUTH__c';

const AUTH_FIELDS = [
    AUTH_ID_FIELD,
    AUTH_IDN_EXTNL_FIELD,
    AUTH_END_DATE_FIELD,
    AUTH_BEGIN_DATE_FIELD
];

export default class AuthTerminationFlow extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @track pageMessages = [];
    @track messageType = '';
    @track createProcess = false;
    @track isAuthFlowCompleted = false;
    @track showWarningForCounty = false;
    @track countyMessage = '';
    @track showCountyConfirmModal = false;
    @track showParentFeeConfirmModal = false;
    // Auth Status Record - uses Apex wrapper (AuthStatusWrapper) instead of external object reference
    @track authStatusRecord = {
        dteEndEffv: '',
        dteBeginEffv: '',
        cdeStatusAuth: '4', // Terminated status
        cdeReasonChangeAuth: '',
        idnAuth: '',
        createdById: '',
        createdDate: '',
        lastModifiedById: '',
        lastModifiedDate: '',
        idnStatusAuth: ''
    };
    @track authRecord = {};

    authTerminationMessage = AUTH_TERMINATION_MSG;
    loggedInUserId = Id;
    initSuccess = false;

    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: AUTH_FIELDS })
    wiredAuthRecord({ error, data }) {
        if (data) {
            this.authRecord = {
                Id: getFieldValue(data, AUTH_ID_FIELD),
                IDN_EXTNL__c: getFieldValue(data, AUTH_IDN_EXTNL_FIELD),
                DTE_END_EFFV_AUTH__c: getFieldValue(data, AUTH_END_DATE_FIELD),
                DTE_BEGIN_EFFV_AUTH__c: getFieldValue(data, AUTH_BEGIN_DATE_FIELD),
                
            };
        } else if (error) {
            this.handleError(error);
        }
    }

    connectedCallback() {
        this.checkOwnerCountyMatch();
    }
    
    get initFailure(){
        return !this.initSuccess;
    }

    /**
     * Check owner county match
     */
    checkOwnerCountyMatch() {
        const params = {
            recordId: this.recordId,
            fieldName: 'CDE_COUNTY__c'
        };
        helper.callServer(this, 'AuthorizationStatusController', 'checkOwnerCountyMatch', (function (response) {
            if (response && response.isSuccessful) {
                this.createProcess = response.objectData.createProcess;
                this.isAuthFlowCompleted = response.objectData.isAuthFlowCompleted;
                if (response.objectData.showWarning) {
                    this.showWarningForCounty = true;
                    this.countyMessage = response.objectData.warningMessage;
                } else {
                    this.showWarningForCounty = false;
                    this.countyMessage = response.objectData.warningMessage;
                }
                this.initSuccess = true;
            } else {
                this.initSuccess = false;
                helper.showToast(this, 'Error!', response.errorMessage, 'error', 'dismissible');
            }
        }).bind(this), JSON.stringify(params));
    }

    /**
     * Handle Status Change Reason change from multiselect-combobox
     * Event format: { detail: { payload: { value: 'selectedValue' } } }
     */
    handleStatusChangeReasonChange(event) {
        const selectedValue = event.detail.payload ? event.detail.payload.value : event.detail.value;
        this.authStatusRecord = {
            ...this.authStatusRecord,
            cdeReasonChangeAuth: selectedValue
        };
    }

    /**
     * Handle Effective Date change
     */
    handleEffectiveDateChange(event) {
        this.authStatusRecord = {
            ...this.authStatusRecord,
            dteBeginEffv: event.detail.value
        };
    }

    /**
     * Handle Submit button click
     */
    handleSubmit() {
        this.clearPageMessages();
        if (!this.validateForm()) {
            return;
        }

        this.verifyUserCounty();
    }

    /**
     * Validate the form
     */
    validateForm() {
        // Validate multiselect-combobox components
        const comboboxes = this.template.querySelectorAll('c-multiselect-combobox');
        let comboboxValid = true;
        comboboxes.forEach((combobox) => {
            combobox.reportValidity();
            if (!combobox.checkValidity()) {
                comboboxValid = false;
            }
        });

        // Validate lightning-input components
        const inputsValid = [...this.template.querySelectorAll('lightning-input')].reduce(
            (validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            },
            true
        );

        const allValid = comboboxValid && inputsValid;

        if (!allValid) {
            this.setPageMessages(['Please enter mandatory fields'], 'error');
            return false;
        }

        return true;
    }

    /**
     * Verify user county and proceed with submission
     */
    verifyUserCounty() {
        // Set auth status record fields
        this.authStatusRecord = {
            ...this.authStatusRecord,
            createdById: this.loggedInUserId,
            createdDate: new Date().toISOString(),
            lastModifiedById: this.loggedInUserId,
            lastModifiedDate: new Date().toISOString(),
            idnAuth: this.authRecord.IDN_EXTNL__c,
            cdeStatusAuth: '4' // Terminated
        };
        const authBeginDate = this.getDateInUTC(this.authRecord.DTE_BEGIN_EFFV_AUTH__c);
        const authEndDate = this.getDateInUTC(this.authRecord.DTE_END_EFFV_AUTH__c);
        const authStatusBeginDate = this.getDateInUTC(this.authStatusRecord.dteBeginEffv);


        // Validate effective date is not before auth begin date
        if (
            this.authStatusRecord.dteBeginEffv &&
            this.authStatusRecord.cdeStatusAuth &&
            authStatusBeginDate < authBeginDate
        ) {
            this.setPageMessages(
                ['Authorization Status Effective Date can not be before Authorization Begin Date.'],
                'error'
            );
            return;
        }
        // Validate effective date is not after auth end date
        if (
            this.authStatusRecord.dteBeginEffv &&
            this.authStatusRecord.cdeStatusAuth &&
            authStatusBeginDate > authEndDate
        ) {
            this.setPageMessages(
                ['Authorization Status Effective Date can not be after Authorization End Date.'],
                'error'
            );
            return;
        }

        // Check if auth flow is completed
        if (!this.isAuthFlowCompleted) {
            this.setPageMessages(
                [
                    'This action cannot be taken for an Incomplete Authorization. Please complete or delete the authorization.'
                ],
                'error'
            );
            return;
        }

        // Show appropriate confirmation modal
        if (this.showWarningForCounty) {
            this.showParentFeeConfirmModal = true;
        } else {
            this.setPageMessages([this.countyMessage], 'error');
        }
    }

    /**
     * Handle County Confirm Yes
     */
    handleCountyConfirmYes() {
        this.showCountyConfirmModal = false;
        this.showParentFeeConfirmModal = true;
    }

    /**
     * Handle County Confirm No
     */
    handleCountyConfirmNo() {
        this.showCountyConfirmModal = false;
    }

    /**
     * Handle Parent Fee Confirm Yes
     */
    handleParentFeeConfirmYes() {
        this.showParentFeeConfirmModal = false;
        this.saveRecord();
    }

    /**
     * Handle Parent Fee Confirm No
     */
    handleParentFeeConfirmNo() {
        this.showParentFeeConfirmModal = false;
    }

    /**
     * Save the authorization status record
     */
    saveRecord() {
        this.showSpinner = true;

        // Update timestamps
        this.authStatusRecord = {
            ...this.authStatusRecord,
            createdById: this.loggedInUserId,
            createdDate: this.getDateInUTC(new Date()).toISOString(),
            lastModifiedById: this.loggedInUserId,
            lastModifiedDate: this.getDateInUTC(new Date()).toISOString(),
            idnAuth: this.authRecord.IDN_EXTNL__c,
            cdeStatusAuth: '4'
        };

        const authId = this.authRecord.Id;

        if (this.createProcess) {
            this.upsertAuthStatus(authId);
        } else {
            this.updateAuthStatus(authId);
        }
    }

    /**
     * Upsert authorization status (create process)
     */
    upsertAuthStatus(authId) {
        const params = {
            authStatus: this.authStatusRecord,
            isNew: false,
            isAuthIdChange: false,
            authorizationId: authId,
            isBatchInsert: false
        };

        helper.callServer(
            this,
            'AuthorizationStatusController',
            'upsertAuthStatus',
            (response) => {
                this.handleUpsertResponse(response, authId);
            },
            JSON.stringify(params)
        );
    }

    /**
     * Update authorization status (update process)
     */
    updateAuthStatus(authId) {
        const params = {
            authStatus: this.authStatusRecord,
            isNew: false,
            isAuthIdChange: false,
            authorizationId: authId
        };

        helper.callServer(
            this,
            'AuthorizationStatusController',
            'updateAuthStatus',
            (response) => {
                this.handleUpdateResponse(response, authId);
            },
            JSON.stringify(params)
        );
    }

    /**
     * Handle upsert response
     */
    handleUpsertResponse(response, authId) {
        this.showSpinner = false;

        if (response && response.objectData && response.objectData.xLog) {
            this.logWebservice(response.objectData.xLog);
        }

        if (response && response.isSuccessful) {
            this.deleteAuthorizationCopay(authId);
        } else {
            this.handleErrorResponse(response);
        }
    }

    /**
     * Handle update response
     */
    handleUpdateResponse(response, authId) {
        this.showSpinner = false;

        if (response && response.isSuccessful) {
            this.deleteAuthorizationCopay(authId);
        } else {
            this.handleErrorResponse(response);
        }
    }

    /**
     * Handle error response from server
     */
    handleErrorResponse(response) {
        const recordErrors = [];

        if (response && response.objectData) {
            if (response.objectData.Authorized && response.objectData.Terminated) {
                recordErrors.push(
                    'Authorization has authorization status with status Authorized and Terminated'
                );
            } else if (response.objectData.Authorized) {
                recordErrors.push('Authorization has authorization status with status Authorized');
            }

            if (response.objectData.EffectiveBeginInvalid) {
                recordErrors.push(
                    'Authorization Status is Terminated so Effective Begin Date should be in Future.'
                );
            }

            if (response.objectData.InvalidChangeReason) {
                recordErrors.push(
                    "Authorization cannot be terminated with an effective date within 15 days except for reasons 'Qualified Exempt Child Care Provider is no longer eligible to provide child care due to Must Take Action. (Maintain next day closure)'"
                );
            }

            if (response.objectData.HerokuValidFail && response.errorMessage) {
                recordErrors.push(response.errorMessage);
            }
        }

        if (response && response.errorMessage && recordErrors.length === 0) {
            recordErrors.push(response.errorMessage);
        }

        if (recordErrors.length > 0) {
            this.setPageMessages(recordErrors, 'error');
        }
    }

    /**
     * Delete authorization copay
     */
    deleteAuthorizationCopay(authId) {
        this.showSpinner = true;

        const params = {
            recordId: authId
        };

        helper.callServer(
            this,
            'AuthorizationStatusController',
            'authorizationCopayDelete',
            (response) => {
                if (response) {
                    this.deleteAuthEncumbrance(authId);
                }
            },
            JSON.stringify(params)
        );
    }

    /**
     * Delete auth encumbrance
     */
    deleteAuthEncumbrance(authId) {
        const params = {
            recordId: authId
        };

        helper.callServer(
            this,
            'AuthorizationStatusController',
            'authEncumbDelete',
            (response) => {
                this.showSpinner = false;
                if (response) {
                    this.navigateToRecord(this.recordId);
                }
            },
            JSON.stringify(params)
        );
    }

    /**
     * Log webservice exception
     */
    logWebservice(xLog) {
        const params = {
            xLog: xLog
        };

        helper.callServer(
            this,
            'GenericDataSaverApxCtrl',
            'logException',
            () => {
                console.log('Exception occurred on server and has been logged.');
            },
            JSON.stringify(params)
        );
    }

    /**
     * Handle Cancel button click
     */
    handleCancel() {
        this.navigateToRecord(this.recordId);
    }

    /**
     * Redirect to record page
     */
    navigateToRecord(recordId) {
        helper.navigateToRecord(this, recordId);
    }

    /**
     * Set page messages
     */
    setPageMessages(messages, type) {
        this.pageMessages = messages.map((msg, index) => ({
            Id: index,
            message: msg
        }));
        this.messageType = type;
    }

    /**
     * Clear page messages
     */
    clearPageMessages() {
        this.pageMessages = [];
        this.messageType = '';
    }

    /**
     * Get date in UTC
     */
    getDateInUTC(date) {
        if (!date) {
            return null;
        }
        const inputDate = new Date(date);
        return new Date(
            inputDate.getUTCFullYear(),
            inputDate.getUTCMonth(),
            inputDate.getUTCDate(),
            inputDate.getUTCHours(),
            inputDate.getUTCMinutes(),
            inputDate.getUTCSeconds()
        );
    }

    /**
     * Handle errors
     */
    handleError(error) {
        console.error('Error:', error);
        let message = 'An unexpected error occurred';
        if (error.body && error.body.message) {
            message = error.body.message;
        } else if (error.message) {
            message = error.message;
        }
        this.setPageMessages([message], 'error');
    }
}