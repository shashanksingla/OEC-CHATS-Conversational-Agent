import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import { label } from 'c/labelUtility';
import { NavigationMixin } from 'lightning/navigation';


export default class CompareCountyRatePlan_lwc extends NavigationMixin(LightningElement) {
    @api
    recordId;
    @api screenMode;
    @track
    centerRatesTemp;
    @track
    homeRatesTemp;
    @track
    exemptRatesTemp;
    @track
    approvedCenterRatesTemp;
    @track
    approvedHomeRatesTemp;
    @track
    approvedExemptRatesTemp;
    @track
    submitted_crp;
    @track
    approved_crp;
    @track myLabel = label;
    @track
    initDone = false;
    mode = 'CRP';
    @track
    overAllFeedback = {};
    hasPriorSubmissions = true;
    feedbackIds = {};
    compareList = {};
    isSupervisor = true;
    showSpinner;
    isvalidCompare;
    countyId;

    connectedCallback() {
        this.invokeInit();
    }
    renderedCallback() {

        const renderedEvent = new CustomEvent('componentready', {
            detail: {
                message: 'The component has been rendered successfully!',
                timestamp: new Date().toISOString()
            },
            bubbles: true, // Allow the event to bubble up
            composed: true // Allow the event to cross shadow DOM boundaries
        });

        this.dispatchEvent(renderedEvent);
    }
    get CP_Month() {
        let d = new Date(this.submitted_crp.DTE_BEGIN_EFFV_RATE__c);
        return (d.getUTCMonth() + 1 + '/' + d.getUTCDate() + '/' + d.getUTCFullYear());
    }
    get isReadonly() {
        return this.screenMode == 'readonly' ? true : false;
    }
    invokeInit() {
        let params = { 'recordId': this.recordId, 'isCPFlow': false };
        helper.callServer(this, 'CompareCP_CRP_lwc', 'getAllData', (function (result) {
            if (result.isSuccessful) {
                if (result.objectData && result.objectData.approvedRecord) {
                    this.isvalidCompare = true;
                    this.countyId = result.objectData.countyId
                    this.submitted_crp = result.objectData.cntyRatePlanRecs.filter(val => val.Id == this.recordId)[0];
                    let compareList = [];
                    compareList.push((result.objectData.approvedRecord || [{}])[0]);
                    let submissions = result.objectData.cntyRatePlanRecs.filter(val => val.County_Rate_Plan__c == this.recordId);
                    if (submissions.length == 0) {
                        submissions.push(this.submitted_crp);
                        this.hasPriorSubmissions = false;
                    }
                    else if (submissions.length > 3) {
                        submissions = submissions.slice(-3);
                    }
                    compareList = [...compareList, ...submissions];
                    this.compareList = compareList;
                    let existingFeedbacks = result.objectData.existingFeedbacks || [];
                    existingFeedbacks.forEach(feed => {
                        this.overAllFeedback[feed.Identifier__c] = { 'feedback': feed.Feedback__c, 'section': feed.Section__c, 'Id': feed.Id };
                        this.feedbackIds[feed.Identifier__c] = feed.Id;
                    })
                    // exempted Rates
                    this.approvedExemptRatesTemp = this.prepareRatesList(true, result.objectData.ApprovedExemptRateList);
                    this.exemptRatesTemp = this.prepareRatesList(true, result.objectData.exemptRateList);

                    // Home Rates
                    this.approvedHomeRatesTemp = this.prepareRatesList(false, result.objectData.ApprovedHomeRateList);
                    this.homeRatesTemp = this.prepareRatesList(false, result.objectData.homeRateList);

                    // Center Rates
                    this.approvedCenterRatesTemp = this.prepareRatesList(false, result.objectData.ApprovedCenterRateList);
                    this.centerRatesTemp = this.prepareRatesList(false, result.objectData.centerRateList);
                }
                this.initDone = true;
            } else {
                this.pageError = result.errorMessage;
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
            }
        }).bind(this), JSON.stringify(params));
    }
    navigateBackToRecord() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'T_COUNTY_RATE__c',
                actionName: 'view',
            }
        }).then(url => {
            window.open(url, '_self');
        });
    }
    prepareRatesList(isExempt, rList) {
        let resultMap = new Map();
        if (isExempt) {
            rList.forEach(item => {
                let key = item.CDE_RATE_TYPE__c + '@@' + item.CDE_AGE_GROUP__c + '@@' + item.CDE_PROVR_TYPE__c;
                if (!resultMap.has(key)) {
                    let age = item.CDE_AGE_GROUP__c == '36 - School Age' ? this.myLabel.X5_Years : this.myLabel.X5_Years_Less;
                    resultMap.set(key, { 'key': key, 'rType': item.CDE_RATE_TYPE__c, 'ageGroup': age, 'unit': item.CDE_UNIT__c, 'FeedbackDisabled': true });
                }
                resultMap.get(key)['unit' + item.CDE_UNIT__c + 'Amt'] = item.NBR_AMOUNT__c;
            });
        } else {
            rList.forEach(item => {
                let key = item.CDE_RATE_TYPE__c + '@@' + item.CDE_AGE_GROUP__c + '@@' + item.CDE_UNIT__c + '@@' + item.CDE_PROVR_TYPE__c;
                if (!resultMap.has(key)) {
                    resultMap.set(key, { 'key': key, 'rType': item.CDE_RATE_TYPE__c, 'tier': item.CDE_TIER__c, 'ageGroup': item.CDE_AGE_GROUP__c, 'unit': item.CDE_UNIT__c, 'FeedbackDisabled': true });
                }
                let indice = item.CDE_TIER__c - 1;
                if (indice > 0) {
                    resultMap.get(key)['tier' + indice + 'Amt'] = item.NBR_AMOUNT__c;
                }
            });
        }
        return Array.from(resultMap.values());
    }
    handlePrint() {
        window.open('/apex/CP_CRP_Compare_generatePDF?recordId=' + this.recordId + '&mode=' + this.mode, '_blank');
    }
    handleSave() {
        let feedbacks = [];
        let allRatesCmp = this.template.querySelectorAll('c-county-rate-table_lwc');
        if (allRatesCmp) {
            allRatesCmp.forEach(element => {
                Object.keys(element.sectionFeedback).forEach(feedbackKey => {
                    feedbacks.push({
                        'Id': this.feedbackIds[feedbackKey], 'attributes': { 'type': 'CP_CRP_Feedback__c' },
                        'County__c': this.countyId, 'Feedback__c': element.sectionFeedback[feedbackKey].feedback || "",
                        'Identifier__c': feedbackKey, 'Section__c': element.sectionFeedback[feedbackKey].section,
                        'feedback_type__c': 'CRP_Rate'
                    });

                })
            });
        }
        let mainQComponent = this.template.querySelector('c-county-rate-plan-info_lwc');
        if (mainQComponent) {
            let allQRows = mainQComponent.getAllSubChilds() || [];
            allQRows.forEach(element => {
                Object.keys(element.sectionFeedback).forEach(feedbackKey => {
                    feedbacks.push({
                        'Id': this.feedbackIds[feedbackKey], 'attributes': { 'type': 'CP_CRP_Feedback__c' },
                        'County__c': this.countyId, 'Feedback__c': element.sectionFeedback[feedbackKey].feedback || "",
                        'Identifier__c': feedbackKey, 'Section__c': element.sectionFeedback[feedbackKey].section,
                        'feedback_type__c': this.mode
                    });

                })
            });
        }
        let params = { 'recordId': this.recordId, 'feedbacks': JSON.stringify(feedbacks) };
        helper.callServer(this, 'CompareCP_CRP_lwc', 'saveFeedbacks', (function (result) {
            if (result.isSuccessful) {
                if (result.objectData) {
                    result.objectData.existingFeedbacks.forEach(feed => {
                        this.feedbackIds[feed.Identifier__c] = feed.Id;
                    });
                    helper.showToast(this, 'Success', 'your Feedback were saved successfully!', 'success', 'dismissible');
                }
            } else {
                this.pageError = result.errorMessage;
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
            }
        }).bind(this), JSON.stringify(params));
    }
}