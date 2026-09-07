import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import { CurrentPageReference } from 'lightning/navigation';
import { label } from 'c/labelUtility';

export default class CaseReviewFlow_lwc extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference)
    currentPageRef;

    @track showSpinner = false;
    @track caseRecord = {};
    @track caseReviewObj = { Case__c: '', Review_Status__c: '1' };
    _lastSampleMonth = null;
    _lastSampleYear = null;
    @track responseWrapperList = [];
    @track accessLevel = '';
    @track allCauseOptions = [];
    @track allErrorOptions = [];
    @track sampleYearOptions = [];
    @track showReviewForm = false;
    @track showQuestion1 = false;
    @track showQuestion2 = false;
    @track showTaskReminder = false;
    @track showCaseOwnerForm1 = false;
    @track showCaseOwnerForm2 = false;
    @track showDraftForm = false;
    @track showDraftForm_Q1 = false;
    @track showDraftForm_Q2 = false;
    @track showDraftForm_Q3 = false;
    @track showQuestions = false;
    @track errorCount = -1;
    @track correctSubsidyAmount;
    @track caseType = '';
    @track caseTypeLabel = '';
    @track reviewDate;
    @track lastDraftReviewId;
    @track firstProgramFetch = false;

    label = {
        CaseReview_Error_PageError: label.CaseReview_Error_PageError,
        CaseReview_Error_FutureDate: label.CaseReview_Error_FutureDate,
        CaseReview_Error_SampleMonth: label.CaseReview_Error_SampleMonth,
        CaseReview_Error_ToDateFromDate: label.CaseReview_Error_ToDateFromDate
    };

    @api recordId;
    @api screenMode;
    @api sourceRecord;
    @api caseId;
    @api
    get redirectMode() {
        if (this.currentPageRef && this.currentPageRef.state.c__screenMode && !this.screenMode) {
            this.recordId = this.currentPageRef.state.c__recordId;
            this.screenMode = this.currentPageRef.state.c__screenMode;
            this.sourceRecord = this.currentPageRef.state.c__sourceRecord;
            this.invokeInit(true, this.recordId);
        }
        return '';
    }

    set improperPayment(value) {
        this.caseReviewObj = { ...this.caseReviewObj, Improper_Payment__c: value };
        this.calculateCorrectSubsidyAmount();
    }

    set improperPaymentAmount(value) {
        this.caseReviewObj = { ...this.caseReviewObj, Improper_Payment_Amount__c: value };
        this.calculateCorrectSubsidyAmount();
    }

    set improperPaymentType(value) {
        this.caseReviewObj = { ...this.caseReviewObj, Improper_Payment_Type__c: value };
        this.calculateCorrectSubsidyAmount();
    }

    set subsidyAmountPaid(value) {
        this.caseReviewObj = { ...this.caseReviewObj, Subsidy_Amount_Paid__c: value };
        this.calculateCorrectSubsidyAmount();
    }

    get isRevieweeAccess() {
        return this.accessLevel === 'reviewee';
    }

    get isViewMode() {
        return this.screenMode === 'VIEW';
    }

    get isNewMode() {
        return this.screenMode === 'NEW';
    }

    get isEditMode() {
        return this.screenMode === 'EDIT';
    }

    get isLiCaseType() {
        return this.caseType === 'LI';
    }

    get isTfCaseType() {
        return this.caseType === 'TF';
    }

    get showQuestionsSection() {
        return this.showQuestions && (this.caseType === 'LI' || this.caseType === 'TF');
    }

    get saveButtonVariant() {
        return this.caseReviewObj.IsSubmitted__c !== true ? 'neutral' : 'brand';
    }

    get eligFromRequired() {
        return this.caseType !== 'LI';
    }

    get eligFromDisabled() {
        return this.caseType === 'LI' || this.accessLevel === 'reviewee';
    }

    get eligToRequired() {
        return this.caseType !== 'LI';
    }

    get eligToDisabled() {
        return this.caseType === 'LI' || this.accessLevel === 'reviewee';
    }

    get improperPaymentAmountRequired() {
        return this.caseReviewObj.Improper_Payment__c === 'Y';
    }

    get improperPaymentAmountDisabled() {
        return this.accessLevel === 'reviewee' || this.caseReviewObj.Improper_Payment__c !== 'Y';
    }

    get improperPaymentTypeRequired() {
        return this.caseReviewObj.Improper_Payment__c === 'Y';
    }

    get improperPaymentTypeDisabled() {
        return this.accessLevel === 'reviewee' || this.caseReviewObj.Improper_Payment__c !== 'Y';
    }

    get currentCaseStatus() {
        return this.caseRecord?.T_SBSD_CASE10__r?.records?.[0]?.CDE_STATUS_CASE__c || '';
    }

    get countyName() {
        return this.caseRecord?.CDE_COUNTY__r?.Name || '';
    }

    _formatDateString(dateStr) {
        if (!dateStr) return '';
        const datePart = dateStr.split('T')[0];
        const parts = datePart.split('-');
        if (parts.length !== 3) return dateStr;
        const [yyyy, mm, dd] = parts;
        return `${yyyy}-${mm}-${dd}`;
    }

    get formattedEligibilityFrom() {
        return this._formatDateString(this.caseReviewObj.Eligibility_Period_From__c);
    }

    get formattedEligibilityTo() {
        return this._formatDateString(this.caseReviewObj.Eligibility_Period_To__c);
    }

    get formattedClosureDate() {
        return this._formatDateString(this.caseReviewObj.Closure_Date__c);
    }

    connectedCallback() {
        if(this.recordId) {
            this.invokeInit(true, this.recordId);
        }
    }

    invokeInit(isInit, recordId) {
        document.title = "Eligibility Case Review | Salesforce";
        this.showSpinner = true;
        let params = {
            recordId: this.recordId,
            isDelete: false
        };
        helper.callServer(this, 'caseReviewApexController','checkEligibility', (function(response) {
            if (response && response.isSuccessful) {
                this.accessLevel = response.objectData.accessLevel;
                this.showSpinner = false;
                this.showDraftForm = response.objectData.showDraftForm;
                if (response.objectData.showDraftForm) {
                    this.showDraftForm_Q1 = true;
                    this.lastDraftReviewId = response.objectData.lastDraftReviewId;
                } else {
                    this.launchInitialForm();
                }
            } else {
                this.showSpinner = false;
                helper.showToast(this, 'Error!', response.errorMessage, 'error', 'dismissible');
                if(this.screenMode === 'EDIT' && this.sourceRecord === 'Case' && this.caseId){
                    setTimeout(() => {
                        helper.redirectToRecord(this, this.caseId);
                    }, 2000);
                } else{
                    window.history.back();
                }
            }
        }).bind(this),JSON.stringify(params));
    }

    doYes1() {
        this.showQuestion2 = true;
    }

    doYes2() {
        this.showReviewForm = true;
        this.showQuestion1 = false;
        this.showCaseOwnerForm1 = false;
        // CCCAP-11863: Change is there in Case Review since last Case Review
        this.caseReviewObj = { ...this.caseReviewObj, No_Change_Indicator__c: 'Y' };
    }

    // Added for CCCAP-7603
    doYes3() {
        this.showReviewForm = true;
        this.showCaseOwnerForm1 = false;
    }

    // Added for CCCAP-7603
    doYes4() {
        this.showDraftForm = false;
        this.recordId = this.lastDraftReviewId;
        this.screenMode = 'EDIT';
        this.launchInitialForm();
    }

    // Added for CCCAP-7603
    doYes5() {
        this.showDraftForm = false;
        this.showSpinner = true;
        let params = { recordId: this.lastDraftReviewId };
        helper.callServer( this, 'caseReviewApexController', 'deleteCaseReview',
            (function(response) {
                if (response && response.isSuccessful) {
                    this.showSpinner = false;
                    this.launchInitialForm();
                } else {
                    this.showSpinner = false;
                    helper.showToast(this, 'Error!', response.errorMessage, 'error', 'dismissible');
                }
            }).bind(this),
            JSON.stringify(params)
        );
    }

    doNo1() {
        this.showReviewForm = true;
        this.showQuestion1 = false;
        this.showCaseOwnerForm1 = false;
    }

    doNo2() {
        let params = { recordId: this.recordId };
        helper.callServer(this, 'caseReviewApexController', 'resubmitLastReview', (function(response) {
            if (response && response.isSuccessful) {
                this.showSpinner = false;
                helper.showToast(this, 'Success!', 'Case Review re-submitted successfully', 'success', 'dismissible');
                helper.redirectToRecord(this, response.objectData.caseReviewId);
            } else {
                this.showSpinner = false;
                helper.showToast(this, 'Error!', response.errorMessage, 'error', 'dismissible');
            }
        }).bind(this), JSON.stringify(params));
    }

    // Added for CCCAP-7603
    doNo3() {
        this.showCaseOwnerForm2 = true;
    }

    // Added for CCCAP-7603
    doNo4() {
        this.showDraftForm_Q1 = false;
        this.showDraftForm_Q2 = true;
    }

    // Added for CCCAP-7603
    doNo5() {
        this.showDraftForm_Q2 = false;
        this.showDraftForm_Q3 = true;
    }

    doOk() {
        helper.redirectToRecord(this, this.caseReviewObj.Id);
    }

    // Added for CCCAP-7603
    doOk2() {
        helper.redirectToRecord(this, this.recordId);
    }

    // Added for CCCAP-7603
    doOk3() {
        window.history.back();
    }

    doSave() {
        this.upsertCaseReview('doSave');
    }

    doCancel() {
        if(this.screenMode === 'NEW') {
            window.history.back();
        } else{
            if(this.sourceRecord === 'Case') {
                let caseid = this.caseRecord.Id ? this.caseRecord.Id : this.caseReviewObj.Case__c;
                helper.redirectToRecord(this, caseid);
            }
            else if (this.sourceRecord === 'CaseReview' || this.sourceRecord == undefined) {
                helper.redirectToRecord(this, this.recordId);
            }
        }
    }

    doSubmit() {
        this.upsertCaseReview('doSubmit');
    }

    handlePicklistChange(event) {
        event.stopPropagation();
        if (event.detail && event.detail.callingContext && event.detail.payload) {
            const contextParts = event.detail.callingContext.split('_');
            if (contextParts.length >= 3) {
                const fieldName = event.detail.callingContext.replace('Case_Review__c_', '');
                const value = event.target.value;
                
                // Use individual setters for payment fields to trigger recalculation
                if (fieldName === 'Improper_Payment__c') {
                    this.improperPayment = value;
                } else if (fieldName === 'Improper_Payment_Type__c') {
                    this.improperPaymentType = value;
                } else {
                    this.caseReviewObj = { ...this.caseReviewObj, [fieldName]: value };
                    if (fieldName === 'Sample_Month__c' || fieldName === 'Sample_Year__c') {
                        this.updateParentFee();
                    }
                }
                this.clearFieldValidationError(fieldName);
            }
        }        
    }

    handleInputChange(event){
        const fieldName = event.target.dataset.field;
        const value = event.target.value;
    
        if (fieldName === 'Improper_Payment_Amount__c') {
            this.improperPaymentAmount = value;
        } else {
            this.caseReviewObj = { ...this.caseReviewObj, [fieldName]: value };
        }
        this.clearFieldValidationError(fieldName);
        
    }

    clearFieldValidationError(fieldName) {
        if (!fieldName) return;
        
        const inputField = this.template.querySelector(`[data-field="${fieldName}"]`);
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

    handleErrorCountChange(event) {
        this.errorCount = event.detail.errorCount;
    }

    checkSampleMonthYearChange() {
        const currentMonth = this.caseReviewObj.Sample_Month__c;
        const currentYear = this.caseReviewObj.Sample_Year__c;
        if (this._lastSampleMonth !== currentMonth || this._lastSampleYear !== currentYear) {
            this._lastSampleMonth = currentMonth;
            this._lastSampleYear = currentYear;
            this.updateParentFee();
        }
    }

    updateParentFee() {
        const sampleMonth = this.caseReviewObj.Sample_Month__c;
        const sampleYear = this.caseReviewObj.Sample_Year__c;

        if (this.screenMode !== 'VIEW') {
            if (sampleMonth && sampleYear) {
                this.showSpinner = true;
                let params = {
                    recordId: this.caseRecord.Id,
                    sampleMonth: sampleMonth,
                    sampleYear: sampleYear,
                    screenMode: this.screenMode
                };
                helper.callServer(
                    this,
                    'caseReviewApexController',
                    'getParentFeeSubsidyAmount',
                    (function(response) {
                        if (response && response.isSuccessful) {
                            this.showSpinner = false;
                            let isParentFeeBlank = false;
                            let isSubsidyAmountBlank = false;
                            let errorMessage = '';

                            if (response.objectData.parentFee) {
                                this.caseReviewObj = {
                                    ...this.caseReviewObj,
                                    Parent_Fee__c: response.objectData.parentFee.amt_copay_case_assesd__c
                                };
                            } else {
                                this.caseReviewObj = { ...this.caseReviewObj, Parent_Fee__c: 0.00 };
                                isParentFeeBlank = true;
                            }

                            if (response.objectData.subsidyAmount) {
                                this.subsidyAmountPaid = response.objectData.subsidyAmount;
                            } else {
                                this.subsidyAmountPaid = 0.00;
                                isSubsidyAmountBlank = true;
                            }

                            if (isParentFeeBlank && isSubsidyAmountBlank) {
                                errorMessage = 'There is no Parent Fee allocated and no Subsidy Amount paid for the selected Sample Month and Sample Year.';
                            } else if (isParentFeeBlank && !isSubsidyAmountBlank) {
                                errorMessage = 'There is no Parent Fee allocated for the selected Sample Month and Sample Year.';
                            } else if (isSubsidyAmountBlank && !isParentFeeBlank) {
                                errorMessage = 'There is no Subsidy Amount paid for the selected Sample Month and Sample Year.';
                            }

                            if (errorMessage) {
                                helper.showToast(this, 'Warning!', errorMessage, 'warning', 'dismissible');
                            }
                        } else {
                            this.showSpinner = false;
                            helper.showToast(this, 'Error!', response.errorMessage, 'error', 'dismissible');
                        }
                    }).bind(this),
                    JSON.stringify(params)
                );
            }
        }

        if (sampleMonth && sampleYear) {
            this.handleSampleMonthYear();
        } else {
            this.caseType = '';
            this.caseTypeLabel = ''; // CCCAP-12378
            this.showQuestions = false;
        }
    }

    calculateCorrectSubsidyAmount() {
        const isPmtImproper = this.caseReviewObj.Improper_Payment__c;
        const subsidyAmt = this.caseReviewObj.Subsidy_Amount_Paid__c;

        if (isPmtImproper === 'Y' || isPmtImproper === 'Yes') {
            const pmtType = this.caseReviewObj.Improper_Payment_Type__c;
            const pmtAmount = parseFloat(this.caseReviewObj.Improper_Payment_Amount__c);
            const subAmount = parseFloat(this.caseReviewObj.Subsidy_Amount_Paid__c);

            if (!isNaN(pmtAmount) && !isNaN(subAmount)) {
                if (pmtType === 'Overpayment') {
                    this.correctSubsidyAmount = subAmount - pmtAmount;
                }
                if (pmtType === 'Underpayment') {
                    this.correctSubsidyAmount = subAmount + pmtAmount;
                }
            } else {
                this.correctSubsidyAmount = subsidyAmt;
            }
        } else {
            this.caseReviewObj = {
                ...this.caseReviewObj,
                Improper_Payment_Amount__c: 0.00,
                Improper_Payment_Type__c: null
            };
            this.correctSubsidyAmount = subsidyAmt;
        }
    }

    // Added for CCCAP-9347
    roundOffPaymentAmount() {
        const pmtAmount = this.caseReviewObj.Improper_Payment_Amount__c;
        const pmtAmountRounded = Number(pmtAmount).toFixed(2);
        this.improperPaymentAmount = pmtAmountRounded;
    }

    launchInitialForm() {
        this.setSampleYear();
        let params = {
            recordId: this.recordId,
            screenMode: this.screenMode
        };
        helper.callServer(
            this,
            'caseReviewApexController',
            'getInitData',
            (function(response) {
                if (response && response.isSuccessful) {
                    this.caseRecord = response.objectData.caseRecord;
                    this.screenMode = response.objectData.screenMode;
                    this.allCauseOptions = response.objectData.allCauseOptions;
                    this.allErrorOptions = response.objectData.allErrorOptions;
                    this.caseReviewObj = {
                        ...this.caseReviewObj,
                        Reviewer_Name__c: response.objectData.reviewerName,
                        Reviewer_Title__c: response.objectData.reviewerTitle
                    };

                    if (response.objectData.screenMode === 'NEW') {
                        this.showCaseOwnerForm1 = response.objectData.showCaseOwnerForm; // CCCAP-7603
                        this.showQuestion1 = response.objectData.showInitialForm;
                        this.showReviewForm = !response.objectData.showInitialForm && !response.objectData.showCaseOwnerForm;
                        this.caseReviewObj = { ...this.caseReviewObj, Sample_Year__c: null, Case__c: this.recordId };
                        const now = new Date();
                        const nowYyyy = now.getFullYear();
                        const nowMm = String(now.getMonth() + 1).padStart(2, '0');
                        const nowDd = String(now.getDate()).padStart(2, '0');
                        this.reviewDate = `${nowYyyy}-${nowMm}-${nowDd}`;
                        this.calculateCorrectSubsidyAmount();
                    } else if (response.objectData.screenMode === 'EDIT') {
                        this.caseType = response.objectData.caseType;
                        this.showReviewForm = true;
                        this.caseReviewObj = response.objectData.caseReviewObj;
                        const createdDate = new Date(response.objectData.caseReviewObj.CreatedDate);
                        const yyyy = createdDate.getFullYear();
                        const mm = String(createdDate.getMonth() + 1).padStart(2, '0');
                        const dd = String(createdDate.getDate()).padStart(2, '0');
                        this.reviewDate = `${yyyy}-${mm}-${dd}`;
                        this.errorCount = response.objectData.errorCount;

                    } else if (response.objectData.screenMode === 'VIEW') {
                        this.caseType = response.objectData.caseType;
                        this.showReviewForm = false;
                        this.showQuestion1 = false;
                        this.caseReviewObj = response.objectData.caseReviewObj;
                    }
                    this.checkSampleMonthYearChange();
                } else {
                    helper.showToast(this, 'Error!', response.errorMessage, 'error', 'dismissible');
                }
            }).bind(this),
            JSON.stringify(params)
        );
    }

    setSampleYear() {
        const today = new Date();
        const currentYear = today.getFullYear();
        // sampleYearOptions may be initialised with a start year as first element
        const startYear = (this.sampleYearOptions && this.sampleYearOptions.length > 0 && !isNaN(this.sampleYearOptions[0]))
            ? Number(this.sampleYearOptions[0])
            : 2021;

        const options = [];
        for (let i = startYear; i <= currentYear; i++) {
            options.push({ label: i.toString(), value: i.toString() });
        }
        this.sampleYearOptions = options;
    }

    setReviewStatus() {
        if (this.errorCount > 0) {
            this.caseReviewObj = { ...this.caseReviewObj, Review_Status__c: '3' };
        } else if (this.errorCount < 0) {
            this.caseReviewObj = { ...this.caseReviewObj, Review_Status__c: '1' };
        } else {
            this.caseReviewObj = { ...this.caseReviewObj, Review_Status__c: '2' };
        }
    }

    upsertCaseReview(methodName) {
        let isValid = true;

        // Skip required field validation while Saving in Draft status (CCCAP-7603)
        if (methodName === 'doSubmit' || (methodName === 'doSave' && this.caseReviewObj.Review_Status__c !== '1')) {
            isValid = abs_helper.validateCurrentPage(this);
            const questionRows = this.template.querySelectorAll('c-case-review_question-row_lwc');
            if (questionRows && questionRows.length > 0) {
                questionRows.forEach(row => {
                    if (!row.checkRowValidity('')) {
                        isValid = false;
                    }
                });
            } else{
                isValid = false;
            }
        }

        if (this.caseType !== 'LI') {
            isValid = this.validateEligibilityDates(isValid);
        }

        if (isValid) {
            if (this.screenMode === 'NEW' || this.caseReviewObj.Review_Status__c === '1') {
                this.updateProgramType();
            }

            if (methodName === 'doSave') {
                if (this.caseReviewObj.IsSubmitted__c) {
                    this.setReviewStatus();
                }
            } else {
                this.setReviewStatus();
            }

            let caseReviewObj = this.caseReviewObj;

            // Collect updated response data from all child components (matching providerReviewFlow pattern)
            const questionRows = this.template.querySelectorAll('c-case-review_question-row_lwc');
            if (questionRows && questionRows.length > 0) {
                for (let childRow of questionRows) {
                    // Find matching wrapper in parent list and update with child's current data
                    const childData = childRow.responseWrapper;
                    if (childData && childData.questionRec) {
                        const idx = this.responseWrapperList.findIndex(w => w.questionRec.Id === childData.questionRec.Id);
                        if (idx !== -1) {
                            this.responseWrapperList[idx].responseRec = childData.responseRec;
                        }
                    }
                }
            }

            let responseWrapperList = this.responseWrapperList;

            if (this.caseType !== 'LI' && this.caseType !== 'TF') {
                responseWrapperList = [];
            }

            let params = {
                caseReviewObj: caseReviewObj,
                responseWrapperList: responseWrapperList,
                methodName: methodName,
                screenMode: this.screenMode
            };

            helper.callServer(
                this,
                'caseReviewApexController',
                'saveCaseReview',
                (function(response) {
                    if (response && response.isSuccessful) {
                        if (methodName === 'doSave') {
                            helper.showToast(this, 'Success!', 'Case Review record saved successfully', 'success', 'dismissible');
                            helper.redirectToRecord(this, response.objectData.caseReviewObj.Id);
                        }
                        if (methodName === 'doSubmit') {
                            this.caseReviewObj = response.objectData.caseReviewObj;
                            this.showTaskReminder = true;
                        }
                    } else {
                        helper.showToast(this, 'Error!', response.errorMessage, 'error', 'dismissible');
                    }
                }).bind(this),
                JSON.stringify(params)
            );
        } else {
            helper.showToast(this, 'Error!', this.label.CaseReview_Error_PageError, 'error', 'dismissible');
        }
    }

    validateEligibilityDates(isValidTillNow) {
        let isValid = isValidTillNow;
        const currentDate = this.getDateInUTC(new Date());
        const fromDate = this.getDateInUTC(this.caseReviewObj.Eligibility_Period_From__c);
        const toDate = this.getDateInUTC(this.caseReviewObj.Eligibility_Period_To__c);

        // Validate From Date — must not be in the future
        if (fromDate > currentDate) {
            isValid = false;
            const fromInput = this.template.querySelector('[data-field="Eligibility_Period_From__c"]');
            if (fromInput) {
                fromInput.setCustomValidity(this.label.CaseReview_Error_FutureDate);
                fromInput.reportValidity();
            }
        } else {
            const fromInput = this.template.querySelector('[data-field="Eligibility_Period_From__c"]');
            if (fromInput) {
                fromInput.setCustomValidity('');
                fromInput.reportValidity();
            }
        }

        // Validate To Date
        const sampleMonth = this.caseReviewObj.Sample_Month__c;
        const sampleYear = this.caseReviewObj.Sample_Year__c;
        const toInput = this.template.querySelector('[data-field="Eligibility_Period_To__c"]');

        if (sampleMonth && sampleYear) {
            const sampleDate = new Date(sampleYear, sampleMonth - 1, 1);
            if (toDate < sampleDate) {
                isValid = false;
                if (toInput) {
                    toInput.setCustomValidity(this.label.CaseReview_Error_SampleMonth);
                    toInput.reportValidity();
                }
            } else if (fromDate > toDate) {
                isValid = false;
                if (toInput) {
                    toInput.setCustomValidity(this.label.CaseReview_Error_ToDateFromDate);
                    toInput.reportValidity();
                }
            } else {
                if (toInput) {
                    toInput.setCustomValidity('');
                    toInput.reportValidity();
                }
            }
        } else if (fromDate > toDate) {
            isValid = false;
            if (toInput) {
                toInput.setCustomValidity(this.label.CaseReview_Error_ToDateFromDate);
                toInput.reportValidity();
            }
        } else {
            if (toInput) {
                toInput.setCustomValidity('');
                toInput.reportValidity();
            }
        }

        return isValid;
    }

    getDateInUTC(date) {
        const d = new Date(date);
        return new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());
    }

    // Added for CCCAP-9146
    updateProgramType() {
        this.caseReviewObj = { ...this.caseReviewObj, Program_Type__c: this.caseType };
    }

    // CCCAP-12156
    handleSampleMonthYear() {
        const lastProgram = this.caseType;
        this.showQuestions = false;

        let params = {
            recordId: this.recordId,
            sampleMonth: this.caseReviewObj.Sample_Month__c,
            sampleYear: this.caseReviewObj.Sample_Year__c,
            screenMode: this.screenMode,
            caseId: this.recordId
        };

        if (this.screenMode !== 'NEW') {
            params.caseId = this.caseReviewObj.Case__c;
        }

        helper.callServer(
            this,
            'caseReviewApexController',
            'handleSampleMonthUpdates',
            (function(response) {
                if (response && response.isSuccessful) {
                    if(!this.isViewMode){
                        if (response.objectData.caseType === 'LI') {
                            this.caseReviewObj = {
                                ...this.caseReviewObj,
                                Eligibility_Period_From__c: this.caseRecord.DTE_APPLN__c,
                                Eligibility_Period_To__c: response.objectData.redetDateAsOfSampleMonth || null
                            };
                        }
                        if(response.objectData.caseType === 'TF' && lastProgram !== response.objectData.caseType){ //CCCAP-15694
                            this.caseReviewObj = {
                                ...this.caseReviewObj,
                                Eligibility_Period_From__c: null,
                                Eligibility_Period_To__c: null
                            };
                        }
                        Promise.resolve().then(() => {
                            const eligibilityFields = ['Eligibility_Period_From__c', 'Eligibility_Period_To__c'];
                            eligibilityFields.forEach(field => {
                                const inputField = this.template.querySelector(`[data-field="${field}"]`);
                                if (inputField) {
                                    inputField.setCustomValidity('');
                                    inputField.reportValidity();
                                }
                            });
                        });
                    }
                    this.caseType = response.objectData.caseType;
                    this.caseTypeLabel = response.objectData.caseTypeLabel; // CCCAP-12378

                    if (lastProgram !== response.objectData.caseType || this.firstProgramFetch === false) {
                        this.responseWrapperList = JSON.parse(JSON.stringify(response.objectData.responseWrapperList));
                    }
                    this.showQuestions = true;
                } else {
                    if (response.objectData && response.objectData.programNotExpected) {
                        this.caseType = '';
                        this.caseTypeLabel = ''; // CCCAP-12378
                        helper.showToast(this, 'Error!', response.errorMessage, 'error', 'dismissible');
                        this.responseWrapperList = [];
                    }
                }
                this.showSpinner = false;
                this.firstProgramFetch = true;
            }).bind(this),
            JSON.stringify(params)
        );
    }
}