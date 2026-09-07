import { LightningElement, api, track, wire } from 'lwc';
import { providerReviewFlowHelper } from './providerReviewFlowHelper.js';
import LOCALE from '@salesforce/i18n/locale';
import timeZone from '@salesforce/i18n/timeZone'
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import { RefreshEvent } from 'lightning/refresh';
import providerReviewModal from 'c/providerReviewModal';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

export default class ProviderReviewFlow extends NavigationMixin(LightningElement) {
    @track
    providerReviewObj = { 'Review_Status__c': '1', 'CDE_REASON_END_AGRMT__c': '' };
    @track hiddenMonths = [];
    FA_Id;
    @api
    screenMode;
    currentState;
    pageError;
    @track
    popupStates = [];
    @api recordId;
    @api
    showSpinner;
    sampleYearOptions;
    currentMode;
    initAgain;
    modalContent;
    buttons;
    showModal;
    @track
    providerInfo = {
        'reviewDate': '', 'currentCounty': '', 'providerID': '',
        'countyId': '',
        'providerName': '', 'providerSFID': '', FAClosureRsn: ''
    };
    @track
    disabledProvReviewData = {
        'providerTypeLabel': '', 'licenseType': '', 'Child_In_Care': '',
        'requiredClosureRsn': false, 'isFAClosureDisabled': true,
        'objectName': '', 'initialResponses': {}, 'initSampleMY': '', 'initProviderReviewObj': {}
    }
    @track
    responseWrapperList;
    accessLevel;
    lastReviewId;
    errorCount = -1;
    isProviderOwner;
    initResult;
    allCauseOptions;
    showReviewForm;
    skipReload;
    @api
    childMode;
    @track isSaving = false; //CCCAP-12989
    @wire(CurrentPageReference)
    currentPageRef;
    @track claimFoundInMonth = false; //CCCAP-13277

    @api
    get redirectMode() {
        if (this.currentPageRef && this.currentPageRef.state.c__screenMode && !this.screenMode) {
            // eslint-disable-next-line @lwc/lwc/no-api-reassignments
            this.recordId = this.currentPageRef.state.c__recordId;
            // eslint-disable-next-line @lwc/lwc/no-api-reassignments
            this.screenMode = this.currentPageRef.state.c__screenMode;
            this.invokeInit(true, this.recordId);
        }
        return '';
    }
    get isFieldDisabled() {
        return this.isReSubmission || (this.screenMode == 'EDIT' && this.isSubmitted);
    }
    get isReSubmission() {
        return this.currentMode == 'Resubmit';
    }
    get isSubmitted() {
        return this.providerReviewObj && this.providerReviewObj.IsSubmitted__c && this.accessLevel != 'admin';
    }
    get providerReviewTitle() {
        return (this.isReSubmission ? 'Provider Review - Resubmit' : (this.screenMode == 'NEW' ? 'Provider Review - New' : 'Provider Review - Edit'));
    }
    get isFAClosureRequired() {
        return true;
    }
    get submitVariant() {
        return this.isSubmitted ? 'brand' : 'neutral';
    }
    get isImproperPaymentRequired() {
        return (this.providerReviewObj || {}).Improper_Payment__c == 'Y';
    }
    get isRecoveryAmountRequired() {
        return (this.providerReviewObj || {}).Recovery_Needed__c == 'Y';
    }
    get isViewMode() {
        return this.screenMode == 'VIEW' && this.providerReviewObj.Id;
    }
    //CCCAP-13277
    get filteredResponseWrapperList() {
        if (!this.responseWrapperList) {
            return [];
        }
        //Added for CCCAP-14322 to not show the questions when license type is not present
        if(!this.providerReviewObj.License_Type__c){
            return[];
        }
        return this.responseWrapperList.filter(element => {
            if (element.responseRec.Section__c == 'Attendance' ) {               
                return ['Y','Yes'].includes((this.providerReviewObj || {}).Attendance_Recorded__c);
            }
            if (element.responseRec.Section__c == 'Claim') {
                return this.claimFoundInMonth;
            }
            return true;
        })
    }
    //end CCCAP-13277
    showHideMonths() {
        let hideM = [];
        var currentTime = new Date()
        var currentMonth = currentTime.getMonth();
        let currentYear = currentTime.getFullYear();
        if (this.providerReviewObj.Sample_Year__c == currentYear) {
            let i = 12;
            while (i > currentMonth + 1) {
                if (i == this.providerReviewObj.Sample_Month__c) {
                    this.providerReviewObj.Sample_Month__c = undefined;
                }
                hideM.push(i.toString());
                i--;
            }
        }
        this.hiddenMonths = hideM;
    }
    handleOut() {
        if (!this.skipReload)
            location.reload();
        window.removeEventListener("popstate", () => { }, false);
    }
    disconnectedCallback() {
        window.removeEventListener("popstate", () => { }, false);
    }
    connectedCallback() {
        let sampleYOptions = [];
        var currentTime = new Date()
        var currentYear = currentTime.getFullYear();
        let start = 2024;
        while (start <= currentYear) {
            sampleYOptions.push({ 'label': start.toString(), 'value': start.toString() });
            start++;
        }
        this.sampleYearOptions = sampleYOptions;
        window.addEventListener('popstate', this.handleOut.bind(this), false);
        if (this.recordId) {
            this.invokeInit(true, this.recordId);
        }
    }
    invokeInit(isInit, recordId) {
        this.pageError = undefined;
        let params = { 'recordId': recordId, 'screenMode': this.screenMode, 'isDelete': false, 'fetchAllData': true };
        helper.callServer(this, 'providerReviewApexController', 'checkEligibility', (function (result) {
            if (result.isSuccessful) {
                if (result.objectData) {
                    this.accessLevel = result.objectData.accessLevel;
                    this.initResult = result;
                    this.lastReviewId = result.objectData.lastReviewId;
                    if (result.objectData.screenMode == 'NEW' && result.objectData.isProviderOwner) {
                        this.setCurrentState('ownerForm');
                    } else if (result.objectData.showDraftForm == true && isInit) {
                        this.setCurrentState('wouldYouLikeToPickWhereLeft');
                        this.initAgain = false;
                    } else {
                        this.handlePostInit(isInit);
                    }
                }
            } else {
                this.pageError = result.errorMessage;
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
                this.skipReload = true;
                window.history.back();
            }
        }).bind(this), JSON.stringify(params));
    }
    handlePostInit(isInit) {
        let result = this.initResult;
        let newProviderReviewObj = result.objectData.providerReviewObj;
        let FARecord = result.objectData.parentFARecord;
        this.disabledProvReviewData.objectName = result.objectData.objectName;
        this.disabledProvReviewData.licenseType = result.objectData.licenseType;
        this.disabledProvReviewData.firstlicenseType = result.objectData.licenseType;
        this.disabledProvReviewData.providerTypeLabel = result.objectData.providerTypeLabel;
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.screenMode = result.objectData.screenMode;
        this.allCauseOptions = result.objectData.allCauseOptions;
        this.responseWrapperList = result.objectData.responseWrapperList;
        this.disabledProvReviewData.initialResponses = result.objectData;
        this.disabledProvReviewData.initSampleMY = (newProviderReviewObj || {}).Sample_Month__c + (newProviderReviewObj || {}).Sample_Year__c
        this.providerReviewObj.Reviewer_Name__c = result.objectData.reviewerName;
        this.providerReviewObj.Reviewer_Title__c = result.objectData.reviewerTitle;
        this.providerReviewObj.CDE_REASON_END_AGRMT__c = FARecord.CDE_REASON_END_AGRMT__c;
        if (isInit || this.initAgain) {
            this.FA_Id = FARecord.Id;
            this.providerInfo.currentCounty = FARecord.CDE_COUNTY__r.Name;
            this.providerInfo.countyId = FARecord.CDE_COUNTY__c;
            this.providerInfo.providerID = FARecord.ID_SERVICE__r.Name;
            this.providerInfo.providerSFID = FARecord.ID_SERVICE__c;
            this.providerInfo.providerName = FARecord.ID_SERVICE__r.NAM_FACILITY__c;
            let reviewDateObj = (result.objectData.screenMode == 'NEW' || this.currentMode == 'Resubmit')
                ? new Date()
                : new Date(newProviderReviewObj.CreatedDate);
            //CCCAP-15457 - corrected timezone issue
            let rvY = reviewDateObj.getFullYear();
            let rvM = String(reviewDateObj.getMonth() + 1).padStart(2, '0');
            let rvD = String(reviewDateObj.getDate()).padStart(2, '0');
            this.providerInfo.reviewDate = `${rvY}-${rvM}-${rvD}`;
            if (result.objectData.screenMode == 'NEW') {
                if (result.objectData.showInitialForm) {
                    this.setCurrentState('reviewWithin6M');
                }
                this.showReviewForm = !result.objectData.showInitialForm && !result.objectData.isProviderOwner;
            } else if (result.objectData.screenMode == 'EDIT') {
                // eslint-disable-next-line @lwc/lwc/no-api-reassignments
                this.childMode = this.currentMode == 'Resubmit' ? 'reSubmission' : (this.isSubmitted ? 'submitted' : '');
            }
            this.initAgain = false;
        }
        if (result.objectData.screenMode == 'NEW') {
            this.providerReviewObj.Review_Status__c = '1';
            this.providerReviewObj.Provider_Fiscal_Agreement__c = this.recordId;
            this.providerReviewObj.Provider__c = FARecord.ID_SERVICE__c;
            this.providerReviewObj.Fiscal_Agreement_Start_Date__c = FARecord.DTE_BEGIN_AGRMT__c;
            this.providerReviewObj.Fiscal_Agreement_End_Date__c = FARecord.DTE_END_AGRMT__c;
            this.errorCount = -1;
            this.showReviewForm = true;
        }
        else if (result.objectData.screenMode == 'EDIT') {
            this.providerReviewObj = newProviderReviewObj;
            this.errorCount = result.objectData.errorCount;
            this.claimFoundInMonth = result.objectData.claimFoundInMonth;//CCCAP-13277
            this.disabledProvReviewData.providerTypeLabel = result.objectData.providerTypeLabel;
            this.disabledProvReviewData.licenseType = result.objectData.licenseType;
            this.childMode = this.currentMode == 'Resubmit' ? 'reSubmission' : (this.isSubmitted ? 'submitted' : '');
            this.showReviewForm = true;
        }
        else if (result.objectData.screenMode == 'VIEW') {
            this.claimFoundInMonth = result.objectData.claimFoundInMonth;//CCCAP-13277
            this.providerReviewObj = newProviderReviewObj;
            this.disabledProvReviewData.providerTypeLabel = result.objectData.providerTypeLabel;
            this.disabledProvReviewData.licenseType = result.objectData.licenseType;
        }
        if (this.isReSubmission) {
            this.providerReviewObj.IsSubmitted__c = false;
            this.disabledProvReviewData.initProviderReviewObj = JSON.parse(JSON.stringify(this.providerReviewObj));
        }
        this.showHideMonths();
    }
    handleYes() {
        if (this.currentState == 'wouldYouLikeToPickWhereLeft') {
            this.setCurrentState('');
            this.screenMode = 'EDIT';
            this.recordId = this.lastReviewId;
            this.initAgain = true;
            this.invokeInit(false, this.recordId);
        } else if (this.currentState == 'ownerForm') {
            this.setCurrentState('diffReviewerForm');
        } else if (this.currentState == 'draftWillBeDeleted') {
            this.setCurrentState('');
            this.deleteProviderReview();
        } else if (this.currentState == 'reviewWithin6M') {
            this.setCurrentState('wereThereChangesSinceLastReview');
        } else if (this.currentState == 'wereThereChangesSinceLastReview') {
            this.currentMode = '';
            this.setCurrentState('');
            this.resetProviderReviewContext();
            this.providerReviewObj.Change_Indicator__c = 'Y';
            this.invokeInit(false, this.recordId);
        }
    }
    handleNo() {
        if (this.currentState == 'wouldYouLikeToPickWhereLeft') {
            this.setCurrentState('draftWillBeDeleted');
        } else if (this.currentState == 'draftWillBeDeleted') {
            this.setCurrentState('');
            this.doCancel();
        } else if (this.currentState == 'ownerForm') {
            this.setCurrentState('');
            this.doCancel();
        } else if (this.currentState == 'reviewWithin6M') {
            this.setCurrentState('');
            this.resetProviderReviewContext();
            this.invokeInit(false, this.recordId);
        } else if (this.currentState == 'wereThereChangesSinceLastReview') {
            this.currentMode = 'Resubmit';
            this.screenMode = 'EDIT';
            this.providerReviewObj.IsSubmitted__c = false;
            this.recordId = this.lastReviewId;
            this.initAgain = true;
            this.setCurrentState('');
            helper.showToast(this, '', 'Please enter the new Sample Month and Sample Year.', 'warning', 'sticky');
            this.invokeInit(false, this.recordId);
        }
    }
    handleOk() {
        if (this.currentState == 'diffReviewerForm') {
            this.setCurrentState('');
            this.doCancel();
        } else if (this.currentState == 'sampleMonthAfterEndDate') {
            this.setCurrentState('');
        }
    }
    deleteProviderReview() {
        if (this.lastReviewId) {
            this.pageError = undefined;
            let params = { 'recordId': this.lastReviewId };
            helper.callServer(this, 'providerReviewApexController', 'deleteProviderReview', (function (result) {
                if (result.isSuccessful) {
                    this.initAgain = true;
                    this.invokeInit(false, this.recordId);
                    helper.showToast(this, 'Success', 'Record was successfully deleted!', 'success', 'dismissible');
                } else {
                    this.pageError = result.errorMessage;
                    helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
                    window.history.back();
                    this.skipReload = true;
                }
            }).bind(this), JSON.stringify(params));
        }
    }
    doSubmit() {
        if (this.validate()) {
            //CCCAP-12989
            if (this.isSaving) {
                return;
            }
            this.isSaving = true;
            //end CCCAP-12989
            this.calErrorCount();
            providerReviewFlowHelper.setReviewStatus(this);
            let responsesRecords = [];
            if (this.template.querySelectorAll('c-provider-review-flow_question-row')) {
                for (let temp of this.template.querySelectorAll('c-provider-review-flow_question-row')) {
                    responsesRecords.push(temp.responseWrapper.responseRec);
                }
            }
            this.finalAction('doSubmit', responsesRecords);
        }
    }
    doSave() {
        //Added as part of CCCAP-14431
        if(this.providerReviewObj && this.providerReviewObj.IsSubmitted__c&& !this.validate()){
            return;
        }
        //CCCAP-12989
        if (this.isSaving) {
            return;
        }
        this.isSaving = true;
        //end CCCAP-12989
        this.calErrorCount();
        let responsesRecords = [];
        if (this.template.querySelectorAll('c-provider-review-flow_question-row')) {
            for (let temp of this.template.querySelectorAll('c-provider-review-flow_question-row')) {
                responsesRecords.push(temp.responseWrapper.responseRec);
            }
        }
        // Made changes for CCCAP-14101
        if (this.providerReviewObj && this.providerReviewObj.IsSubmitted__c) {
            providerReviewFlowHelper.setReviewStatus(this);
        }
        this.finalAction('doSave', responsesRecords);


    }
    finalAction(methodName, responsesRecords) {
        this.pageError = undefined;
        if (this.isReSubmission) {
            this.providerReviewObj.Id = null;
            this.providerReviewObj.CreatedDate = null; //CCCAP-15751
            this.providerReviewObj.Change_Indicator__c = 'N';
            responsesRecords.forEach(val => {
                val.Id = null
            });
        }
        let params = { 'providerReviewObj': JSON.stringify(this.providerReviewObj), 'responsesRecords': JSON.stringify(responsesRecords), 'screenMode': this.screenMode, 'methodName': methodName, 'hasClaim': this.claimFoundInMonth};
        helper.callServer(this, 'providerReviewApexController', 'saveProviderReview', (function (result) {
            if (result.isSuccessful) {
                this.refresh();
                if (methodName == 'doSave') {
                    helper.showToast(this, 'Success', 'Provider Review record saved successfully', 'success', 'dismissible');
                    helper.redirectToRecord(this, result.objectData.providerReviewObj.Id);
                }
                if (methodName == 'doSubmit') {
                    this.providerReviewObj = result.objectData.providerReviewObj;
                    helper.redirectToRecord(this, result.objectData.providerReviewObj.Id);
                    let submitText = this.isReSubmission ? 're-submitted' : 'record submitted';
                    helper.showToast(this, 'Success', 'Provider Review ' + submitText + ' successfully', 'success', 'dismissible');
                }
            } else {
                this.pageError = result.errorMessage;
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
            }
            this.isSaving = false; //CCCAP-12989
        }).bind(this), JSON.stringify(params));
    }
    validate() {
        let allValid = abs_helper.validateCurrentPage(this);
        if (this.template.querySelectorAll('c-provider-review-flow_question-row')) {
            for (let temp of this.template.querySelectorAll('c-provider-review-flow_question-row')) {
                allValid = allValid && temp.validate();
            }
        }
        
        // Check if sample month and year is before fiscal agreement begin date Added as part of CCCAP-14322
        let sampleDateValid = true;
        if (this.providerReviewObj.Sample_Month__c && this.providerReviewObj.Sample_Year__c && this.providerReviewObj.Fiscal_Agreement_Start_Date__c) {
            let sampleStartDate = new Date(this.providerReviewObj.Sample_Year__c, this.providerReviewObj.Sample_Month__c - 1, 1);
            let fiscalStartDate = new Date(this.providerReviewObj.Fiscal_Agreement_Start_Date__c);
            let todayDate = new Date();
            
            if (sampleStartDate.getFullYear() < fiscalStartDate.getFullYear() || 
                (sampleStartDate.getFullYear() == fiscalStartDate.getFullYear() && sampleStartDate.getMonth() < fiscalStartDate.getMonth()) || 
                (sampleStartDate.getFullYear() == fiscalStartDate.getFullYear() && sampleStartDate.getMonth() == fiscalStartDate.getMonth() && todayDate < fiscalStartDate)) {
                sampleDateValid = false;
            }
        }
        
        if (!allValid) {
            helper.showToast(this, 'Error!', 'There are errors on this page.  Please correct them to proceed', 'error', 'dismissible');
        } else if (this.pageError) {
            helper.showToast(this, 'Error!', this.pageError, 'error', 'dismissible');
        } else if (!sampleDateValid) {//CCCAP-14322
            helper.showToast(this, 'Error!', 'The Sample Month and Year cannot be before the Fiscal Agreement Effective Begin Date.', 'error', 'dismissible');
        } else if (!this.disabledProvReviewData.licenseType) {
            helper.showToast(this, 'Error!', 'License Status/License Type does not exist.', 'error', 'dismissible');
        }
        return allValid && sampleDateValid && this.disabledProvReviewData.licenseType;//Included sampleDateValid for CCCAP-14322
    }
    calErrorCount() {
        this.errorCount = -1;
        let Yes_No = { 'Y': 0, 'N': 0 };
        if (this.template.querySelectorAll('c-provider-review-flow_question-row')) {
            for (let temp of this.template.querySelectorAll('c-provider-review-flow_question-row')) {
                if (temp.responseWrapper.responseRec.ProviderReview_QuestionMain__c == 'YES') {
                    Yes_No.Y += 1;
                } else if (temp.responseWrapper.responseRec.ProviderReview_QuestionMain__c == 'NO') {
                    Yes_No.N += 1;
                }
            }
        }
        this.errorCount = Yes_No.N > 0 ? Yes_No.N : (Yes_No.Y > 0 ? 0 : -1);
    }
    fetchLicense() {
        if (this.providerReviewObj.Sample_Month__c == undefined || this.providerReviewObj.Sample_Year__c == undefined) {
            this.resetSampleMYRelatedData();
        } else {
            if (this.disabledProvReviewData.initSampleMY == this.providerReviewObj.Sample_Month__c + this.providerReviewObj.Sample_Year__c) {
                if (this.isReSubmission) {
                    this.responseWrapperList = undefined;
                    // eslint-disable-next-line @lwc/lwc/no-api-reassignments
                    this.childMode = 'disableDefault';
                    let objectData = JSON.parse(JSON.stringify(this.disabledProvReviewData.initialResponses));
                    let initProviderReviewObj = this.disabledProvReviewData.initProviderReviewObj;
                    this.providerReviewObj.License_Type__c = initProviderReviewObj.License_Type__c;
                    this.providerReviewObj.Quality_of_Rating__c = initProviderReviewObj.Quality_of_Rating__c;
                    this.providerReviewObj.License_Status__c = initProviderReviewObj.License_Status__c;
                    this.providerReviewObj.CDE_TYPE_PROVR__c = initProviderReviewObj.CDE_TYPE_PROVR__c;
                    this.providerReviewObj.No_of_Children_in_care__c = initProviderReviewObj.No_of_Children_in_care__c;
                    this.providerReviewObj.CDE_REASON_END_AGRMT__c = initProviderReviewObj.CDE_REASON_END_AGRMT__c;
                    this.disabledProvReviewData.providerTypeLabel = objectData.providerTypeLabel;
                    this.disabledProvReviewData.licenseType = objectData.licenseType;
                    this.responseWrapperList = JSON.parse(JSON.stringify(objectData.responseWrapperList));
                } else {
                    this.licesneDetails();
                }
            } else {
                this.licesneDetails();
            }
        }
    }
    licesneDetails() {
        this.pageError = undefined;
        let params = {
            'recordId': this.recordId,
            'providerId': this.providerInfo.providerSFID,
            'objectName': this.disabledProvReviewData.objectName,
            'sampleMonth': this.providerReviewObj.Sample_Month__c,
            'sampleYear': this.providerReviewObj.Sample_Year__c,
            'countyId': this.providerInfo.countyId,
            'FA_Id': this.FA_Id
        };
        helper.callServer(this, 'providerReviewApexController', 'handleSample_MY_Update', (function (result) {
            if (result.isSuccessful) {
                if (result.objectData) {
                    let oldLicenseType = this.disabledProvReviewData.firstlicenseType;
                    this.claimFoundInMonth = result.objectData.claimFoundInMonth;
                    this.providerReviewObj.License_Type__c = result.objectData.CDE_TYPE_LICENSE__c;
                    this.providerReviewObj.Quality_of_Rating__c = result.objectData.TXT_CHATS_RATING__c;
                    this.providerReviewObj.License_Status__c = result.objectData.CDE_STATUS_PROVR__c;
                    this.providerReviewObj.CDE_TYPE_PROVR__c = result.objectData.CDE_TYPE_PROVR__c;
                    this.providerReviewObj.No_of_Children_in_care__c = result.objectData.childrenInCare;
                    this.disabledProvReviewData.providerTypeLabel = result.objectData.providerTypeLabel;
                    this.disabledProvReviewData.licenseType = result.objectData.licenseType;
                    if (!this.disabledProvReviewData.firstlicenseType) {
                        this.disabledProvReviewData.firstlicenseType = result.objectData.licenseType;
                        this.disabledProvReviewData.initialResponses = JSON.parse(JSON.stringify(result.objectData));
                        this.disabledProvReviewData.initSampleMY = this.providerReviewObj.Sample_Month__c + this.providerReviewObj.Sample_Year__c;
                    }
                    if (oldLicenseType != result.objectData.licenseType) {
                        this.childMode = '';

                    } else if (this.isReSubmission) {
                        this.childMode = 'reSubmission';
                    }
                    this.responseWrapperList = undefined;
                    this.responseWrapperList = JSON.parse(JSON.stringify(result.objectData.responseWrapperList));
                }
            } else {
                this.pageError = result.errorMessage;
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
                this.resetSampleMYRelatedData();
            }
        }).bind(this), JSON.stringify(params));
    }

    openModal() {
        providerReviewModal.open({
            'modalHeader': '',
            'modalContent': providerReviewFlowHelper.popUpMessage(this),
            'buttons': providerReviewFlowHelper.getButtons(this),
            'size': 'small'
        }).then((result) => {
            if (result) {
                let type = result.evtType;
                if (type == 'No') {
                    this.handleNo();
                } else if (type == 'Yes') {
                    this.handleYes();
                } else if (type == 'Ok') {
                    this.handleOk();
                } else if (type == 'Cancel') {
                    this.handleClosePopupNoRedirect(type);
                } else if (type == undefined) {
                    this.handleClosePopupNoRedirect(type);
                }
            } else {
                this.handleClosePopupNoRedirect('');
            }
        });
    }
    handleClosePopupNoRedirect(type) {
        if (this.currentState == 'sampleMonthAfterEndDate') {
            this.setCurrentState('');
        } else {
            this.doCancel();
        }
    }
    doCancel() {
        this.setCurrentState('');
        this.refresh();
        window.history.back();
    }
    handlePickselect(event) {
        var payload = event.detail.payload;
        var payloadType = event.detail.payloadType;
        if (payloadType === 'uni-select') {
            providerReviewFlowHelper.handleValueUpdates(this, event.detail.callingContext, payload.value);
        }
    }
    handleCompSelect(evt) {
        providerReviewFlowHelper.handleValueUpdates(this, evt.target.dataset.name, evt.detail.value);
    }
    refresh() {
        this.dispatchEvent(new RefreshEvent());
    }
    setFAReasonState() {
        if (this.providerReviewObj.Fiscal_Agreement_End_Date__c && this.providerReviewObj.Sample_Month__c && this.providerReviewObj.Sample_Year__c) {
            let endDate = new Date(this.providerReviewObj.Fiscal_Agreement_End_Date__c);
            if ((this.providerReviewObj.Sample_Month__c > (endDate.getMonth() + 1) && this.providerReviewObj.Sample_Year__c == endDate.getFullYear())
                || (this.providerReviewObj.Sample_Year__c > endDate.getFullYear())) {
                this.setCurrentState('sampleMonthAfterEndDate');
            }
        }
    }
    setCurrentState(newcontext) {
        this.popupStates = this.popupStates.filter(val => val != this.currentState);
        if (newcontext != '') {
            this.popupStates.push(newcontext);
            this.currentState = (this.popupStates || [])[0];
            this.openModal();
        }
    }
    resetProviderReviewContext() {
        this.disabledProvReviewData = {
            'providerTypeLabel': '', 'licenseType': '', 'firstLicenseType': '', 'Child_In_Care': '',
            'objectName': '', 'requiredClosureRsn': false, 'isFAClosureDisabled': true
        }
        this.providerReviewObj = { 'Review_Status__c': '1' };
        this.screenMode = 'NEW';
        this.showReviewForm = true;
        this.errorCount = -1;
    }
    resetSampleMYRelatedData() {
        //changed as part of CCCAP-14322 to providerReviewObjz to send the data while saving
        this.providerReviewObj.License_Type__c = null;
        this.providerReviewObj.Quality_of_Rating__c = null;
        this.providerReviewObj.License_Status__c = null;
        this.providerReviewObj.CDE_TYPE_PROVR__c = null;
        this.providerReviewObj.No_of_Children_in_care__c = null;
        this.disabledProvReviewData.providerTypeLabel = null;
        this.disabledProvReviewData.licenseType = null;
        this.responseWrapperList = undefined;
        this.claimFoundInMonth = false;
    }
}