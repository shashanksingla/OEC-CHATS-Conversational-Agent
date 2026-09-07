import { LightningElement, api, track } from 'lwc';
import { provReviewQuestionHelper } from './providerReviewFlow_questionRowHelper.js';
import { abs_helper } from 'c/abstract_Component';
export default class providerReviewFlow_questionRow extends LightningElement {

    @api screenMode;
    @api childMode;
    @api accessLevel;
    @api rowIndice;
    @api allCauseOptions = [];
    @api allErrorOptions = [];
    @api actionDateErrors = [];
    @track Cause1_Options;
    @track Cause2_Options;
    @track Cause3_Options;
    @track Cause4_Options;
    @track internalWrapper;
    @track isNAReasonDisabled = true;

    @api
    get responseWrapper() {
        return this.internalWrapper;
    }
    set responseWrapper(items) {
        this.internalWrapper = items;
        this.doInit();
    }
    get elementNumber() { //CCCAP-13277
        return (this.rowIndice + 1);
    }
    get isViewMode() {
        return this.screenMode == 'VIEW';
    }
    get isReviewee() {
        return this.accessLevel === 'reviewee' || this.childMode != '';
    }
    get showElementApplyToCase() {
        return this.questFieldValue('Does_the_Element_Apply_to_Case__c');
    }
    get hideErrorsAndCauses() {
        return this.questFieldValue('Hide_Errors_and_Causes__c');
    }
    get isNoMainQuestion() {
        return ['No', 'NO'].includes(this.responseFieldValue('ProviderReview_QuestionMain__c'));
    }
    get showActionRequired() {
        return ['Y', 'Yes'].includes(this.responseFieldValue('Action_Required__c'));
    }
    get isNAMainQuestion() {
        return ['NA','N/A'].includes(this.responseFieldValue('ProviderReview_QuestionMain__c'));
    }
    get actionDateValue() {
        return this.responseFieldValue('Action_Date__c');
    }
    get isNA_Disabled() {
        return this.isNAReasonDisabled || this.isReviewee;
    }
    get actionDisabled() {
        return this.childMode == 'disableDefault' || this.childMode == 'reSubmission';
    }
    get isActionRequiredAndReviewee() {
        return this.responseFieldValue('Action_Required__c') && this.accessLevel === 'reviewee';
    }
    get ErrorNCauses() {
        let errorsNCauses=[];
        (this.allErrorOptions || []).forEach((element, index) => {
            let QIndex = index + 1;
            let errorValue = this.responseFieldValue('ProviderReview_Error' + QIndex + '__c');
            //CCCAP-13466
            if(errorValue){
                this.findCauseValues(QIndex, this.questFieldValue('Element__c'));
            }
            //end CCCAP-13466
            errorsNCauses.push({
                'errorLabel': 'If No, Reason for Error #' + QIndex + ':',
                'errorField': 'ProviderReview_Error' + QIndex + '__c',
                'errorValue': errorValue,
                'errorOptions': this.setErrorPicklistValues('ProviderReview_Error' + QIndex + '__c'),
                'errorRequired': index == 0,
                'errorDisabled': ((QIndex > 1 && !this.responseFieldValue('ProviderReview_Error' + index + '__c')) || this.isReviewee),
                'causeField': 'ProviderReview_Cause' + QIndex + '__c',
                'causeValue': this.responseFieldValue('ProviderReview_Cause' + QIndex + '__c'),
                'causeOptions': this['Cause' + QIndex + '_Options'],
                'causeRequired': errorValue,
                'causeDisabled': (!errorValue || this.isReviewee)
            })
        })
        return errorsNCauses;
    }
    @api
    validate() {
        return abs_helper.validateCurrentPage(this);
    }
    responseFieldValue(fieldName) {
        return (this.internalWrapper.responseRec || {})[fieldName];
    }
    questFieldValue(fieldName) {
        return (this.internalWrapper.questionRec || {})[fieldName];
    }
    doInit() {
        if (this.internalWrapper && this.internalWrapper.responseRec) {
            let internalWrapper = JSON.parse(JSON.stringify(this.internalWrapper));
            this.internalWrapper = internalWrapper;
            var NAReasonOptions = this.internalWrapper.NAReasonOptions || [];
            if (this.screenMode === 'NEW') {
                provReviewQuestionHelper.resetErrorAndCausePicklists(this);
                if (NAReasonOptions.length == 2) {
                    internalWrapper.responseRec.ProviderReview_NA_Reason__c = NAReasonOptions[1].value;
                    this.isNAReasonDisabled = true;
                } else {
                    internalWrapper.responseRec.ProviderReview_NA_Reason__c = '';
                    this.isNAReasonDisabled = false;
                }
            } else if (this.screenMode === 'EDIT') {
                if (NAReasonOptions.length == 2) {
                    internalWrapper.responseRec.ProviderReview_NA_Reason__c = NAReasonOptions[1].value;
                    this.isNAReasonDisabled = true;
                } else {
                    this.isNAReasonDisabled = false;
                }
                if (internalWrapper.responseRec.ProviderReview_QuestionMain__c != 'NA') {
                    internalWrapper.responseRec.ProviderReview_NA_Reason__c = '';
                }
                this.internalWrapper = internalWrapper;
                //added order for cccap-13277
                (this.allErrorOptions || []).forEach((element, index) => {
                    this.findCauseValues(index + 1, internalWrapper.questionRec.Element__c);
                });
            }
            this.internalWrapper = internalWrapper;
        }
    }
    //added order for CCCAP-13277
    findCauseValues(index, element) {
        let errorFieldName = 'ProviderReview_Error' + index + '__c';
        const errorFieldValue = this.internalWrapper.responseRec[errorFieldName];
        let clauseFielOptions = 'Cause' + index + '_Options';
        let allCauseOptions = JSON.parse(JSON.stringify(this.allCauseOptions));
        let returnCauses = [];
        if (errorFieldValue) {
            const errorCauseMap = new Map();
            if (element != 'Attendance Records' && element != 'Manual Claim Form') {
                errorCauseMap.set('1', ['1', '2']);
            } else {
                errorCauseMap.set('1', ['2']); //CCCAP-13277
            }
            errorCauseMap.set('2', ['3', '4', '5']);
            errorCauseMap.set('3', ['6', '7']);
            errorCauseMap.set('4', ['8', '9', '10']);
            const causeAPIs = errorCauseMap.get(errorFieldValue) || [];
            returnCauses = allCauseOptions.filter(val => causeAPIs.includes(val.value));
        }
        if (errorFieldName == 'ProviderReview_Error1__c' && !errorFieldValue) {
            if (this.allErrorOptions.length > 1) {
                this.internalWrapper.responseRec.ProviderReview_Error2__c = '';
                this.internalWrapper.responseRec.ProviderReview_Cause2__c = '';
            }
            if (this.allErrorOptions.length > 2) {
                this.internalWrapper.responseRec.ProviderReview_Error3__c = '';
                this.internalWrapper.responseRec.ProviderReview_Cause3__c = '';
            }
            if (this.allErrorOptions.length > 3) {
                this.internalWrapper.responseRec.ProviderReview_Error4__c = '';
                this.internalWrapper.responseRec.ProviderReview_Cause4__c = '';
            }
        } else if (errorFieldName == 'ProviderReview_Error2__c' && !errorFieldValue) {
            if (this.allErrorOptions.length > 2) {
                this.internalWrapper.responseRec.ProviderReview_Error3__c = '';
                this.internalWrapper.responseRec.ProviderReview_Cause3__c = '';
            }
            if (this.allErrorOptions.length > 3) {
                this.internalWrapper.responseRec.ProviderReview_Error4__c = '';
                this.internalWrapper.responseRec.ProviderReview_Cause4__c = '';
            }
        } else if (errorFieldName == 'ProviderReview_Error3__c' && !errorFieldValue) {
            if (this.allErrorOptions.length > 3) {
                this.internalWrapper.responseRec.ProviderReview_Error4__c = '';
                this.internalWrapper.responseRec.ProviderReview_Cause4__c = '';
            }

        }
        this[clauseFielOptions] = JSON.parse(JSON.stringify(returnCauses));
    }


    setErrorPicklistValues(errorFieldName) {
        let allErrorOptions = this.allErrorOptions;
        let internalWrapper = this.internalWrapper;
        const currentFieldValue = internalWrapper.responseRec[errorFieldName];
        const error1Value = internalWrapper.responseRec.ProviderReview_Error1__c;
        const error2Value = internalWrapper.responseRec.ProviderReview_Error2__c;
        const error3Value = internalWrapper.responseRec.ProviderReview_Error3__c;
        const error4Value = internalWrapper.responseRec.ProviderReview_Error4__c;

        let applicableOptions = allErrorOptions.filter(element => (element.value === currentFieldValue && currentFieldValue)
            || (element.value !== error1Value &&
                element.value !== error2Value &&
                element.value !== error3Value &&
                element.value !== error4Value));
        return JSON.parse(JSON.stringify(applicableOptions));
    }
    handelMainQuestionUpdate(newValue) {
        provReviewQuestionHelper.resetErrorAndCausePicklists(this);
        if (['No', 'NO'].includes(newValue)) {
            if (this.showElementApplyToCase) {
                this.internalWrapper.responseRec.Element_Apply_to_Case__c = 'Y';
            }
        } else if (['NA'].includes(newValue)) {
            var NAReasonOptions = this.internalWrapper.NAReasonOptions;
            if (NAReasonOptions.length == 2) {
                this.internalWrapper.responseRec.ProviderReview_NA_Reason__c = NAReasonOptions[1].value;
                this.isNAReasonDisabled = true;
            } else {
                this.isNAReasonDisabled = false;
            }
        }
    }
    handlePickselect(event) {
        var payload = event.detail.payload;
        var payloadType = event.detail.payloadType;
        if (payloadType === 'uni-select') {
            provReviewQuestionHelper.handleValueUpdates(this, event.detail.callingContext, payload.value);
        }
    }
    handleCompSelect(event) {
        provReviewQuestionHelper.handleValueUpdates(this, event.target.dataset.name, event.detail.value);
    }
}