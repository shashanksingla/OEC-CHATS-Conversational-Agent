import { LightningElement, api, track } from 'lwc';
import { abs_helper } from 'c/abstract_Component';

export default class CaseReview_questionRow_lwc extends LightningElement {
    @track internalWrapper;
    @track caseReviewError1Options = [];
    @track caseReviewError2Options = [];
    @track caseReviewError3Options = [];
    @track caseReviewError4Options = [];
    @track caseReviewError1Cause = [];
    @track caseReviewError2Cause = [];
    @track caseReviewError3Cause = [];
    @track caseReviewError4Cause = [];
    @track isNAReasonDisabled = false;
    @track rendered = false;

    @api screenMode;
    @api accessLevel;
    @api allCauseOptions = [];
    @api allErrorOptions = [];
    @api errorCount = 0; 
    @api
    get responseWrapper() {
        return this.internalWrapper;
    }
    set responseWrapper(value) {
        this.internalWrapper = value;
        this.doInit();
    }

    connectedCallback() {
        
    }

    renderedCallback() {
        // set rendered flag once the DOM is ready.
        if (!this.rendered) {
            this.rendered = true;
        }
    }

    /** Show error/cause fields only when main answer is 'NO' */
    get noAnswerClass() {
        return this.responseWrapper?.responseRec?.CaseReview_QuestionMain__c === 'NO'
            ? 'slds-p-vertical_xx-small slds-p-horizontal_small'
            : 'slds-hide';
    }

    /** Show NA reason field only when main answer is 'NA' */
    get naAnswerClass() {
        return this.responseWrapper?.responseRec?.CaseReview_QuestionMain__c === 'NA'
            ? 'slds-p-vertical_xx-small slds-p-horizontal_small'
            : 'slds-hide';
    }

    /** Show action-taken / action-date fields only when Action_Required__c is 'Y' */
    get actionRequiredClass() {
        return this.responseWrapper?.responseRec?.Action_Required__c === 'Y'
            ? 'slds-p-vertical_xx-small slds-p-horizontal_small'
            : 'slds-hide';
    }

    /** Show Error2 view-mode row only when a value exists */
    get error2ViewClass() {
        return this.responseWrapper?.responseRec?.CaseReview_Error2__c
            ? 'slds-p-vertical_xx-small slds-p-horizontal_small'
            : 'slds-hide';
    }

    /** Show Error3 view-mode row only when a value exists */
    get error3ViewClass() {
        return this.responseWrapper?.responseRec?.CaseReview_Error3__c
            ? 'slds-p-vertical_xx-small slds-p-horizontal_small'
            : 'slds-hide';
    }

    /** Show Error4 view-mode row only when a value exists */
    get error4ViewClass() {
        return this.responseWrapper?.responseRec?.CaseReview_Error4__c
            ? 'slds-p-vertical_xx-small slds-p-horizontal_small'
            : 'slds-hide';
    }

    /** View-mode: show payment-error / error rows when main answer is 'No' (view uses 'No', edit uses 'NO') */
    get noAnswerViewClass() {
        return this.responseWrapper?.responseRec?.CaseReview_QuestionMain__c === 'No'
            ? 'slds-p-vertical_xx-small slds-p-horizontal_small'
            : 'slds-hide';
    }

    /** View-mode: show NA reason when main answer is 'N/A' */
    get naAnswerViewClass() {
        return this.responseWrapper?.responseRec?.CaseReview_QuestionMain__c === 'N/A'
            ? 'slds-p-vertical_xx-small slds-p-horizontal_small'
            : 'slds-hide';
    }

    /** View-mode: show action-taken / action-date when Action_Required__c is 'Yes' */
    get actionRequiredViewClass() {
        return this.responseWrapper?.responseRec?.Action_Required__c === 'Yes'
            ? 'slds-p-vertical_xx-small slds-p-horizontal_small'
            : 'slds-hide';
    }

    get isViewMode() {
        return this.screenMode === 'VIEW';
    }

    get isRevieweeAccess() {
        return this.accessLevel === 'reviewee';
    }

    get isNAReasonFieldDisabled() {
        return this.isNAReasonDisabled || this.isRevieweeAccess;
    }

    get isError1Required() {
        return this.responseWrapper?.responseRec?.CaseReview_QuestionMain__c === 'NO';
    }

    get isCause1Required() {
        return this.responseWrapper?.responseRec?.CaseReview_QuestionMain__c === 'NO';
    }

    get isCause2Required() {
        return !!(this.responseWrapper?.responseRec?.CaseReview_Error2__c);
    }

    get isCause3Required() {
        return !!(this.responseWrapper?.responseRec?.CaseReview_Error3__c);
    }

    get isCause4Required() {
        return !!(this.responseWrapper?.responseRec?.CaseReview_Error4__c);
    }

    get isActionRequired() {
        return this.responseWrapper?.responseRec?.CaseReview_QuestionMain__c === 'NO';
    }

    get isNARequired() {
        return this.responseWrapper?.responseRec?.CaseReview_QuestionMain__c === 'NA';
    }

    get isActionTakenRequired() {
        return this.responseWrapper?.responseRec?.Action_Required__c === 'Y' && this.isRevieweeAccess;
    }

    get isActionDateRequired() {
        return this.responseWrapper?.responseRec?.Action_Required__c === 'Y' && this.isRevieweeAccess;
    }

    get hideErrorsAndCauses() {
        return !!(this.responseWrapper?.questionRec?.Hide_Errors_and_Causes__c);
    }

    doInit() {
        if (!this.internalWrapper || !this.internalWrapper.responseRec) {
            return;
        }

        let wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
        const NAReasonOptions = wrapper.NAReasonOptions || [];
        if (this.screenMode === 'NEW') {
            wrapper.responseRec.CaseReview_QuestionMain__c = '';
            if (NAReasonOptions.length === 2) {
                wrapper.responseRec.CaseReview_NA_Reason__c = NAReasonOptions[1].value;
                this.isNAReasonDisabled = true;
            } else {
                wrapper.responseRec.CaseReview_NA_Reason__c = '';
                this.isNAReasonDisabled = false;
            }
            this.internalWrapper = wrapper;
            this.resetErrorAndCausePicklists();
            const applicableOptions = [{ label: '--None--', value: '' }];
            (this.allErrorOptions || []).forEach(element => {
                applicableOptions.push(element);
            });
            this.caseReviewError1Options = JSON.parse(JSON.stringify(applicableOptions));
            this.caseReviewError2Options = JSON.parse(JSON.stringify(applicableOptions));
            this.caseReviewError3Options = JSON.parse(JSON.stringify(applicableOptions));
            this.caseReviewError4Options = JSON.parse(JSON.stringify(applicableOptions));

        } else if (this.screenMode === 'EDIT') {
            if (NAReasonOptions.length === 2) {
                wrapper.responseRec.CaseReview_NA_Reason__c = NAReasonOptions[1].value;
                this.isNAReasonDisabled = true;
            } else {
                this.isNAReasonDisabled = false;
            }
            if (wrapper.responseRec.CaseReview_QuestionMain__c !== 'NA') {
                wrapper.responseRec.CaseReview_NA_Reason__c = '';
            }
            this.internalWrapper = wrapper;
            this.setErrorPicklistValues(undefined);
            this.setApplicableOptions('CaseReview_Error1__c', true);
            this.setApplicableOptions('CaseReview_Error2__c', true);
            this.setApplicableOptions('CaseReview_Error3__c', true);
            this.setApplicableOptions('CaseReview_Error4__c', true);
        }

        this.internalWrapper = wrapper;
    }

    setCausePicklistValues(eventOrFieldName) {
        let errorFieldName;        
        // Support both event object and direct field name string
        if (typeof eventOrFieldName === 'string') {
            errorFieldName = eventOrFieldName;
        } else if (eventOrFieldName && eventOrFieldName.detail) {
            errorFieldName = eventOrFieldName.detail.fieldName || eventOrFieldName.currentTarget?.dataset?.id;
        } else if (eventOrFieldName && eventOrFieldName.currentTarget) {
            errorFieldName = eventOrFieldName.currentTarget.dataset?.id;
        }
        
        if (errorFieldName && this.rendered) {
            const causeFieldName = errorFieldName.replace('Error', 'Cause'); // CaseReview_Cause1__c
            this.setErrorPicklistValues(errorFieldName);
            this.setApplicableOptions(errorFieldName, false);

            const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
            wrapper.responseRec[causeFieldName] = null;
            this.internalWrapper = wrapper;
        }
    }

    handelMainQuestionUpdate(newValue, oldValue) {
        let errorCount = this.errorCount;

        if (oldValue !== 'NO' && newValue === 'NO') {
            if (errorCount < 0) {
                errorCount = errorCount + 2;
            } else {
                errorCount = errorCount + 1;
            }
            const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
            wrapper.responseRec.CaseReview_NA_Reason__c = '';
            this.internalWrapper = wrapper;
            this.resetErrorAndCausePicklists();
        }

        if (oldValue === 'NO' && newValue !== 'NO') {
            errorCount = errorCount - 1;
        }

        if (oldValue !== 'NA' && newValue === 'NA') {
            this.resetErrorAndCausePicklists();
            const NAReasonOptions = this.internalWrapper.NAReasonOptions || [];
            if (NAReasonOptions.length === 2) {
                const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
                wrapper.responseRec.CaseReview_NA_Reason__c = NAReasonOptions[1].value;
                this.internalWrapper = wrapper;
                this.isNAReasonDisabled = true;
            }
            if (errorCount < 0) {
                errorCount = 0;
            }
        }

        if (oldValue !== 'YES' && newValue === 'YES') {
            const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
            wrapper.responseRec.CaseReview_NA_Reason__c = '';
            this.internalWrapper = wrapper;
            this.resetErrorAndCausePicklists();
            if (errorCount < 0) {
                errorCount = 0;
            }
        }

        this.errorCount = errorCount;
        // Notify parent of errorCount change
        this.dispatchEvent(new CustomEvent('errorchange', { detail: { errorCount: this.errorCount } }));
    }

    @api
    checkRowValidity() {
        return abs_helper.validateCurrentPage(this);
    }

    resetErrorAndCausePicklists() {
        if (!this.internalWrapper || !this.internalWrapper.responseRec) return;
        const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
        wrapper.responseRec.CaseReview_Cause1__c = '';
        wrapper.responseRec.CaseReview_Cause2__c = '';
        wrapper.responseRec.CaseReview_Cause3__c = '';
        wrapper.responseRec.CaseReview_Cause4__c = '';
        wrapper.responseRec.CaseReview_Error1__c = '';
        wrapper.responseRec.CaseReview_Error2__c = '';
        wrapper.responseRec.CaseReview_Error3__c = '';
        wrapper.responseRec.CaseReview_Error4__c = '';
        wrapper.responseRec.Causes_Payment_Error__c = ''; // CCCAP-7697
        this.internalWrapper = wrapper;

        this.setCausePicklistValues('CaseReview_Error1__c');
        this.setCausePicklistValues('CaseReview_Error2__c');
        this.setCausePicklistValues('CaseReview_Error3__c');
        this.setCausePicklistValues('CaseReview_Error4__c');

        this.caseReviewError1Cause = [];
        this.caseReviewError2Cause = [];
        this.caseReviewError3Cause = [];
        this.caseReviewError4Cause = [];
    }

    setApplicableOptions(errorFieldName, isInit) {
        const errorFieldValue = this.internalWrapper?.responseRec?.[errorFieldName];
        const causeAttributeName = this.toCauseAttributeName(errorFieldName);
        let applicableOptions = [{ label: '--None--', value: '' }];
        if (errorFieldValue) {
            const allCauseOptions = JSON.parse(JSON.stringify(this.allCauseOptions || []));
            const errorCauseMap = new Map([
                ['1', ['1', '2', '3']],
                ['2', ['4', '5', '6']],
                ['3', ['7', '8']],
                ['4', ['9', '10']]
            ]);
            const causeAPIs = errorCauseMap.get(errorFieldValue) || [];
            allCauseOptions.forEach(element => {
                if (causeAPIs.includes(element.value)) {
                    if (!isInit) {
                        element.selected = false;
                    }
                    applicableOptions.push(element);
                }
            });
        }
        this[causeAttributeName] = JSON.parse(JSON.stringify(applicableOptions));
    }

    setErrorPicklistValues(errorFieldName) {
        const errorFields = [
            'CaseReview_Error1__c',
            'CaseReview_Error2__c',
            'CaseReview_Error3__c',
            'CaseReview_Error4__c'
        ];

        const responseRec = this.internalWrapper?.responseRec || {};
        let error1Value = responseRec.CaseReview_Error1__c;
        let error2Value = responseRec.CaseReview_Error2__c;
        let error3Value = responseRec.CaseReview_Error3__c;
        let error4Value = responseRec.CaseReview_Error4__c;

        // Normalise undefined to ''
        if (error1Value === undefined) {
            const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
            wrapper.responseRec.CaseReview_Error1__c = '';
            this.internalWrapper = wrapper;
            error1Value = '';
        }
        if (error2Value === undefined) {
            const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
            wrapper.responseRec.CaseReview_Error2__c = '';
            this.internalWrapper = wrapper;
            error2Value = '';
        }
        if (error3Value === undefined) {
            const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
            wrapper.responseRec.CaseReview_Error3__c = '';
            this.internalWrapper = wrapper;
            error3Value = '';
        }
        if (error4Value === undefined) {
            const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
            wrapper.responseRec.CaseReview_Error4__c = '';
            this.internalWrapper = wrapper;
            error4Value = '';
        }

        errorFields.forEach(currentFieldName => {
            if (errorFieldName === currentFieldName) return;

            const currentFieldValue = (this.internalWrapper?.responseRec || {})[currentFieldName];
            const optionsAttributeName = this.toErrorOptionsAttributeName(currentFieldName);

            let applicableOptions = [{ label: '--None--', value: '' }];
            (this.allErrorOptions || []).forEach(element => {
                if (element.value === currentFieldValue && currentFieldValue) {
                    applicableOptions.push(Object.assign({}, element, { selected: true }));
                    return;
                }
                if (
                    element.value !== error1Value &&
                    element.value !== error2Value &&
                    element.value !== error3Value &&
                    element.value !== error4Value
                ) {
                    applicableOptions.push(Object.assign({}, element, { selected: false }));
                }
            });
            this[optionsAttributeName] = JSON.parse(JSON.stringify(applicableOptions));
        });
    }

    handlePicklistChange(event) {
        event.stopPropagation();
        if (event.detail && event.detail.callingContext && event.detail.payload) {
            const contextParts = event.detail.callingContext.split('_');
            if (contextParts.length >= 3) {
                const fieldName = event.detail.callingContext.replace('Case_Review_Response__c_', '');
                const newValue = event.detail.payload.value;
                const currentValue = this.internalWrapper?.responseRec?.[fieldName];
                
                if (newValue !== currentValue && this.internalWrapper && newValue !== undefined) {
                    const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
                    wrapper.responseRec[fieldName] = newValue;                    
                    // Handle error picklists (Error1 to Error4) - clear corresponding cause
                    const errorFieldPattern = /^CaseReview_Error[1-4]__c$/;
                    if (errorFieldPattern.test(fieldName)) {
                        const causeFieldName = fieldName.replace('Error', 'Cause');
                        wrapper.responseRec[causeFieldName] = null;
                    }

                    this.internalWrapper = wrapper;
                    if (fieldName === 'CaseReview_QuestionMain__c' && event.detail.payload.oldValue !== undefined) {
                        this.handelMainQuestionUpdate(newValue, event.detail.payload.oldValue);
                    }                    
                    if (errorFieldPattern.test(fieldName) && this.rendered) {
                        this.setErrorPicklistValues(fieldName);
                        this.setApplicableOptions(fieldName, false);
                    }                    
                }
            }
        }        
    }

    handleInputChange(event) {
        const fieldName = event.currentTarget.dataset.field;
        if (fieldName && this.internalWrapper) {
            const wrapper = JSON.parse(JSON.stringify(this.internalWrapper));
            wrapper.responseRec[fieldName] = event.target.value;
            this.internalWrapper = wrapper;
        }
    }

    toCauseAttributeName(errorFieldName) {
        // CaseReview_Error1__c → caseReviewError1Cause
        const match = errorFieldName.match(/Error(\d)/);
        if (match) {
            return 'caseReviewError' + match[1] + 'Cause';
        }
        return null;
    }

    toErrorOptionsAttributeName(errorFieldName) {
        // CaseReview_Error1__c → caseReviewError1Options
        const match = errorFieldName.match(/Error(\d)/);
        if (match) {
            return 'caseReviewError' + match[1] + 'Options';
        }
        return null;
    }
}