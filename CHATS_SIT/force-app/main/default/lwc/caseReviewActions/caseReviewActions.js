import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import SUBMITTED from '@salesforce/schema/Case_Review__c.IsSubmitted__c';
import REVIEW_STATUS from '@salesforce/schema/Case_Review__c.Review_Status__c';
import REVIEWEE from '@salesforce/schema/Case_Review__c.Reviewee__c';
import COUNTY_NAME from '@salesforce/schema/Case_Review__c.Case__r.CDE_COUNTY__r.Name';
import Id from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import { label } from 'c/labelUtility';
import { helper } from 'c/generic_Utilities';
import { RefreshEvent } from 'lightning/refresh';
import caseReviewModal from 'c/caseReviewModal';

export default class CaseReviewActions extends NavigationMixin(LightningElement) {
    @api recordId;
    @api actionMode;
    @track showSpinner = false;
    taskComment;
    revieweeId;
    userId = Id;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [SUBMITTED, REVIEW_STATUS, REVIEWEE, COUNTY_NAME]
    }) caseReview;

    get isAction() {
        return this.actionMode == 'recordActions';
    }

    get Is_Submitted() {
        return getFieldValue(this.caseReview.data, SUBMITTED);
    }

    get Is_Draft() {
        return getFieldValue(this.caseReview.data, REVIEW_STATUS) === '1';
    }

    get isReviewee() {
        return getFieldValue(this.caseReview.data, REVIEWEE) === this.userId;
    }

    get showReversalButtons() {
        return this.Is_Submitted;
    }

    handleButtonClick(evt) {
        if (evt.target.dataset.name == 'delete') {
            this.handleDelete();
        } else if (evt.target.dataset.name == 'view') {
            this.handleView();
        } else if (evt.target.dataset.name == 'review') {
            this.handleReview();
        } else if (evt.target.dataset.name == 'submitForReversal') {
            this.handleStateReversal();
        } else if (evt.target.dataset.name == 'submitToReviewee') {
            this.handleSubmitToReviewee();
        }
    }

    // Delete

    handleDelete() {
        let params = { 'recordId': this.recordId };
        helper.callServer(this, 'caseReviewApexController', 'deleteCaseReviewButton', (function (result) {
            if (result.isSuccessful) {
                helper.showToast(this, 'Success!', 'Case Review deleted successfully', 'success', 'dismissible');
                helper.redirectToRecord(this, result.objectData.parentCase);
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
            }
        }).bind(this), JSON.stringify(params));
    }

    // View (PDF)

    handleView() {
        let params = { 'recordId': this.recordId, 'isDelete': false };
        helper.callServer(this, 'caseReviewApexController', 'checkEligibility', (function (result) {
            if (result.isSuccessful) {
                helper.callServer(this, 'caseReviewApexController', 'getVFBaseURL', (function (result1) {
                    if (result1.isSuccessful) {
                        if (result1.objectData) {
                            var hosturl = result1.objectData.sfUrl;
                            window.open(hosturl + '/apex/caseReviewFlow_generatePDF?recordId=' + this.recordId, '_blank');
                        }
                    } else {
                        helper.showToast(this, 'Error!', result1.errorMessage, 'error', 'dismissable');
                    }
                }).bind(this), undefined);
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissable');
            }
        }).bind(this), JSON.stringify(params));
    }

    // Review (Navigate to Flow)

    handleReview() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__caseReviewFlow_lwc'
            },
            state: {
                'c__recordId': this.recordId,
                'c__screenMode': 'EDIT',
                'c__sourceRecord' : 'CaseReview'
            }
        });
    }

    // State Reversal 

    handleStateReversal() {
        let countyName = getFieldValue(this.caseReview.data, COUNTY_NAME);
        let descr = label.Task_T121_Description;
        this.taskComment = descr.replace('{!countyName}', countyName);
        caseReviewModal.open({
            'initialTaskComment': this.taskComment,
            'buttons': [
                { 'label': 'Complete', 'Id': 'Complete', 'variant': 'brand' }
            ],
            'lwcToImport': 'c/stateReversalPopup',
            'size': 'small',
            'showHeader': true,
            'modalHeader': 'Submit for State Reversal'
        }).then((result) => {
            if (result) {
                let type = result.evtType;
                if (type == 'Complete') {
                    let payload = result.payload;
                    this.taskComment = payload.taskComment;
                    this.sendStateReversal();
                } else {
                    this.doCancel();
                }
            } else {
                this.doCancel();
            }
        });
    }

    sendStateReversal() {
        let params = { 'recordId': this.recordId, 'taskComment': this.taskComment };
        helper.callServer(this, 'caseReviewApexController', 'sumbitForStateReversal', (function (result) {
            if (result.isSuccessful) {
                helper.showToast(
                    this,
                    'Success!',
                    'Task T121 \u2013 State Reversal Request is created on Case Review ' +
                        result.objectData.recordName + ' and assigned to ' + result.objectData.userName + '.',
                    'success',
                    'dismissible'
                );
                this.doCancel();
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
            }
        }).bind(this), JSON.stringify(params));
    }

    // Submit to Reviewee

    handleSubmitToReviewee() {
        caseReviewModal.open({
            'showHeader': true,
            'modalHeader': 'Submit to Reviewee',
            'buttons': [
                { 'label': 'Complete', 'Id': 'Complete', 'variant': 'brand' }
            ],
            'lwcToImport': 'c/submitToRevieweePopup',
            'size': 'medium'
        }).then((result) => {
            if (result) {
                let type = result.evtType;
                if (type == 'Complete') {
                    let payload = result.payload;
                    this.revieweeId = payload.revieweeId;
                    this.submitToReviewee();
                } else {
                    this.doCancel();
                }
            } else {
                this.doCancel();
            }
        });
    }

    submitToReviewee() {
        let params = { 'revieweeId': this.revieweeId, 'recordId': this.recordId };
        helper.callServer(this, 'caseReviewApexController', 'submitToReviewee', (function (result) {
            if (result.isSuccessful) {
                helper.showToast(
                    this,
                    'Success!',
                    'Task T118 \u2013 Case Review Complete is created on Case ' +
                        result.objectData.caseNumber + ' and assigned to ' + result.objectData.userName + '.',
                    'success',
                    'dismissible'
                );
                helper.redirectToRecord(this, this.recordId);
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
            }
        }).bind(this), JSON.stringify(params));
    }

    // Cancel / Refresh

    doCancel() {
        this.dispatchEvent(new RefreshEvent());
    }
}