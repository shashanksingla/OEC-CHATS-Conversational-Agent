import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import Id from '@salesforce/user/Id';

export default class AuthorizationNotes_lwc extends NavigationMixin(LightningElement) {
    @track authStatus = null;
    @track pageMessages = [];
    @track messageType = '';
    @track authId;
    @track note;
    loggedInUserId = Id;
    authNoteParentId;
    noteId;
    sObjectName = '';
    showSpinner = false;

    @api recordId;

    // Lifecycle hooks
    connectedCallback() {
        this.showSpinner = true;
        this.getSobjectName();
    }

    // Computed properties
    get cardTitle() {
        return this.sObjectName == 'T_AUTH__c' ? 'New Authorization Note' : 'Edit Authorization Note';
    }

    get hasPageMessages() {
        return this.pageMessages && this.pageMessages.length > 0;
    }
    get authIdChanged() {
        return this.sObjName == 'T_AUTH__c' ? (this.authId != this.recordId) : (this.authId != this.authNoteParentId);
    }
    
    // Get SObject name to determine if new or edit mode
    getSobjectName() {
        const params = { recordId: this.recordId };
        helper.callServer(this, 'AuthorizationNotesController', 'getSobjectName', (function (result) {
            if (result.isSuccessful) {
                const res = result.objectData;
                this.sObjectName = result.objectData.sObjName;
                if (result.objectData.sObjName === 'T_AUTH__c') {
                    this.authId = this.recordId;
                }
                if (res.authNote && res.authNote.length > 0) {
                    const authNote = res.authNote[0];
                    this.authId = authNote.idn_auth__r?.Id || '';
                    this.authNoteParentId = authNote.idn_auth__r?.Id || '';
                    this.note = authNote.txt_notes__c || '';
                    this.noteId = authNote.Id;
                }
                this.showSpinner = false;
            } else {
                this.handleError(result.errorMessage);
                this.showSpinner = false;
            }
        }).bind(this), JSON.stringify(params));
    }

    // Handle Authorization Id lookup change
    handleAuthIdChange(event) {
        const selectedRecord = event.detail.record;
        // customLookup_lwc returns record with Id property directly
        if (selectedRecord && selectedRecord.Id) {
            this.authId = selectedRecord.Id;
        } else {
            this.authId = '';
        }
    }

    // Handle description change
    handleDescriptionChange(event) {
        this.note = event.target.value;
    }

    // Validate form fields
    validateFields() {
        let isValid = true;
        this.pageMessages = [];
        this.messageType = '';

        if (!this.authId) {
            this.pageMessages.push({ 'id': 'error', 'message': 'Please enter Mandatory fields' });
            this.messageType = 'error';
            isValid = false;
        } else if (!this.note) {
            this.pageMessages.push({ 'id': 'error', 'message': 'Please enter Mandatory fields' });
            this.messageType = 'error';
            isValid = false;
        }

        // Validate input fields
        const inputFields = this.template.querySelectorAll('lightning-textarea, c-custom-lookup_lwc');
        inputFields.forEach(field => {
            if (field.reportValidity) {
                if (!field.reportValidity()) {
                    isValid = false;
                }
            }
        });

        return isValid;
    }

    // Save record
    handleSave() {
        if (!this.validateFields()) {
            return;
        }
        this.checkValidations();
    }

    // Check validations before saving
    checkValidations() {
        this.showSpinner = true;
        const params = {
            authId: this.authId,
            isNew: this.sObjectName == 'T_AUTH__c',
            isAuthIdChange: this.authIdChanged
        };

        helper.callServer(this, 'AuthorizationNotesController', 'getAuthorizationNotesStatus', (function (result) {
            if (result.isSuccessful) {
                this.authStatus = result.objectData;
                this.processAuthStatus();
            } else {
                this.handleError(result.errorMessage);
                this.showSpinner = false;
            }
        }).bind(this), JSON.stringify(params));
    }

    // Process authorization status and save if valid
    processAuthStatus() {
        if (this.authStatus && !this.authStatus.isUpdate) {
            // Authorization is terminated
            const errorMsg = this.sObjectName == 'T_AUTH__c'
                ? 'Can not create Authorization Note as it\'s Authorization is terminated'
                : 'Can not update authorization Note as it\'s Authorization is terminated.';
            this.pageMessages = [{ 'id': 'error', 'message': errorMsg }];
            this.messageType = 'error';
            this.showSpinner = false;
        } else if (this.authStatus && !this.authStatus.isAuthFlowCompleted) {
            // Authorization flow not completed
            const errorMsg = 'This action cannot be taken for an Incomplete Authorization. Please complete or delete the authorization.';
            this.pageMessages = [{ 'id': 'error', 'message': errorMsg }];
            this.messageType = 'error';
            this.showSpinner = false;
        } else {
            // Valid - proceed with save
            this.saveAuthorizationNote();
        }
    }

    // Save authorization note to external object
    saveAuthorizationNote() {
        let authNoteInstance = {
            attributes: { 'type': 'batchsit_t_auth_notes__x' },
            idn_auth__c: this.authId,
            txt_notes__c: this.note,
            Id: this.noteId
        };
        // Set timestamps and user info
        if (this.sObjectName == 'T_AUTH__c') {
            authNoteInstance.createddate__c = new Date().toISOString();
            authNoteInstance.createdbyid__c = this.loggedInUserId;
        }
        authNoteInstance.lastmodifieddate__c = new Date().toISOString();
        authNoteInstance.lastmodifiedbyid__c = this.loggedInUserId;

        // Set external ID from auth status
        if (this.authStatus && this.authStatus.auth) {
            authNoteInstance.idn_auth__c = this.authStatus.auth.IDN_EXTNL__c;
        }
        const lstSObject = [authNoteInstance];
        const params = {
            lstSObject: JSON.stringify(lstSObject),
            isFinalStep: true
        };

        abs_helper.callServerForExternalObjAndHandleError(
            this,
            'insertExternalObjRecords',
            (function (response) {
                // Success - redirect to record
                this.navigateToRecord(this.recordId);

                // Generate CR213 Correspondence
                this.generateCR213Correspondence();
            }).bind(this),
            JSON.stringify(params),
            null
        );
    }

    // Generate CR213 Correspondence after saving
    generateCR213Correspondence() {
        const params = { authId: this.authId };
        helper.callServer(this, 'AuthorizationNotesController', 'CR213Corr', (function (result) {
            // Correspondence generation is fire-and-forget
            if (!result.isSuccessful) {
                console.error('CR213 Correspondence generation failed:', result.errorMessage);
            }
        }).bind(this), JSON.stringify(params));
    }

    // Handle cancel button
    handleCancel() {
        this.navigateToRecord(this.recordId);
    }

    // Handle error display
    handleError(errorMessage) {
        this.pageMessages = [{ 'id': 'error', 'message': errorMessage }];
        this.messageType = 'error';
        helper.showToast(this, 'Error!', errorMessage, 'error', 'dismissible');
    }

    // Get date in UTC format
    getDateInUTC(date) {
        const d = new Date(date);
        return new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(),
            d.getUTCHours(), d.getUTCMinutes(), d.getUTCSeconds());
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
}