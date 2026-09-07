import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import { label } from 'c/labelUtility';
import { NavigationMixin } from 'lightning/navigation';


export default class CompareCountyPlan_lwc extends NavigationMixin(LightningElement) {
    @api
    recordId;
    @api screenMode;
    @api isCPFlow = false;
    @track
    submitted_cp;
    @track myLabel = label;
    @track
    initDone = false;
    mode = 'CP';
    countyId;
    @track
    overAllFeedback = {};
    feedbackIds = {};
    compareList = {};
    isSupervisor = true;
    showSpinner;
    isvalidCompare;
    hasPriorSubmissions = true;
    connectedCallback() {
        this.invokeInit();
    }
    handlePrint() {
        window.open('/apex/CP_CRP_Compare_generatePDF?recordId=' + this.recordId + '&mode=' + this.mode, '_blank');
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
        let d = new Date(this.submitted_cp.DTE_BEGIN_EFFEV__c);
        return (d.getUTCMonth() + 1 + '/' + d.getUTCDate() + '/' + d.getUTCFullYear());
    }
    get isReadonly() {
        return this.screenMode == 'readonly' ? true : false;
    }
    invokeInit() {
        let params = { 'recordId': this.recordId, 'isCPFlow': true };
        helper.callServer(this, 'CompareCP_CRP_lwc', 'getAllData', (function (result) {
            if (result.isSuccessful) {
                if (result.objectData) {
                    try {
                        if (result.objectData.approvedRecord) {
                            this.submitted_cp = result.objectData.cntyPlanRecs.filter(val => val.Id == this.recordId)[0];
                            let compareList = [];
                            this.isvalidCompare = true;
                            this.countyId = result.objectData.countyId;
                            compareList.push((result.objectData.approvedRecord || [{}])[0]);
                            let submissions = result.objectData.cntyPlanRecs.filter(val => val.County_Plan__c == this.recordId);
                            if (submissions.length == 0) {
                                submissions.push(this.submitted_cp);
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
                        }
                        this.initDone = true;
                    } catch (err) {
                        console.log('Error in parsing data' + err.message);
                    }
                }
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
                objectApiName: 'T_COUNTY_PLAN__c',
                actionName: 'view',
            }
        }).then(url => {
            window.open(url, '_self');
        });
    }
    handleSave() {
        let feedbacks = [];
        let mainQComponent = this.template.querySelector('c-county-plan-info_lwc');
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