import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import SUBMITTED from "@salesforce/schema/Provider_Review__c.IsSubmitted__c";
import REVIEW_STATUS from "@salesforce/schema/Provider_Review__c.Review_Status__c";
import COUNTY_NAME from "@salesforce/schema/Provider_Review__c.Provider_Fiscal_Agreement__r.CDE_COUNTY__r.Name";
import REVIEWEE from "@salesforce/schema/Provider_Review__c.Reviewee__c";
import Id from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import T234_DESC from '@salesforce/label/c.Task_T234_Description';
import { helper } from 'c/generic_Utilities';
import { RefreshEvent } from 'lightning/refresh';


import providerReviewModal from 'c/providerReviewModal';
export default class ProviderReviewActions extends NavigationMixin(LightningElement) {
    @api recordId;
    @api showSpinner;
    @api actionMode;
    taskComment;
    revieweeId;
    userId = Id;
    isAccessible;
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [SUBMITTED, COUNTY_NAME, REVIEW_STATUS, REVIEWEE],
    }) provReview;
    connectedCallback() {
        if (this.isDetail) {
            this.checkRecordAccess();

        }
        window.addEventListener('popstate', () => {
            window.removeEventListener("popstate", () => { }, false);
            window.location.reload();

        });
    }
    disconnectedCallback() {
        window.removeEventListener("popstate", () => { }, false);
    }

    get isDetail() {
        return this.actionMode == 'recordDetail';
    }
    get isAction() {
        return this.actionMode == 'recordActions';
    }
    get Is_Submitted() {
        return getFieldValue(this.provReview.data, SUBMITTED);
    }
    get Is_Draft() {
        return getFieldValue(this.provReview.data, REVIEW_STATUS) === '1';
    }
    get isReviewee() {
        return getFieldValue(this.provReview.data, REVIEWEE) === this.userId;
    }
    checkRecordAccess() {
        let params = { 'recordId': this.recordId };
        helper.callServer(this, 'providerReviewApexController', 'checkRecordAccess', (function (result) {
            if (result.isSuccessful) {
                this.isAccessible = true;
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', '');
                this.isAccessible = false;
                if (result.objectData.parentFARecord) {
                    helper.redirectToRecord(this, result.objectData.parentFARecord);
                } else {
                    window.history.back();
                }
            }
        }).bind(this), JSON.stringify(params));
    }

    handleButtonClick(evt) {
        if (evt.target.dataset.name == 'delete') {
            this.checkDeleteFirst();
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
    checkDeleteFirst() {
        providerReviewModal.open({
            'modalContent': 'Are you sure you want to delete this?',
            'buttons': [{ 'label': 'No', 'Id': 'No', 'variant': 'brand' },
            { 'label': 'Yes', 'Id': 'Yes', 'variant': 'neutral' }],
            'size': 'medium'
        }).then((result) => {
            if (result) {
                let type = result.evtType;
                if (type == 'No') {
                    this.doCancel();
                } else if (type == 'Yes') {
                    this.handleDelete();
                } else if (type == undefined) {
                    this.doCancel();
                }
            } else {
                this.doCancel();
            }
        });

    }
    handleSubmitToReviewee() {
        providerReviewModal.open({
            'showHeader': true,
            'modalHeader': 'Submit to Reviewee',
            'buttons': [{ 'label': 'Complete', 'Id': 'Complete', 'variant': 'brand' }],
            'lwcToImport': 'c/submitToRevieweePopup',
            'size': 'medium'
        }).then((result) => {
            if (result) {
                let type = result.evtType;
                if (type == 'Complete') {
                    let payload = result.payload;
                    this.revieweeId = payload.revieweeId;
                    this.submitToReviewee();
                } else if (type == undefined) {
                    this.doCancel();
                }
            } else {
                this.doCancel();
            }
        });
    }
    submitToReviewee() {
        let params = { 'revieweeId': this.revieweeId, 'recordId': this.recordId };
        helper.callServer(this, 'providerReviewApexController', 'submitToReviewee', (function (result) {
            if (result.isSuccessful) {
                helper.showToast(this, 'Success!', 'Task T231 - Provider Review Complete is created on Provider ' + result.objectData.provNumber + ' and assigned to ' + result.objectData.userName + '.', 'success', '');
                window.reload();
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', '');
            }
        }).bind(this), JSON.stringify(params));
    }
    handleStateReversal() {
        let countyName = getFieldValue(this.provReview.data, COUNTY_NAME);
        let descr = T234_DESC;
        this.taskComment = descr.replace('{!countyName}', countyName);
        providerReviewModal.open({
            'taskComment': this.taskComment,
            'buttons': [{ 'label': 'Complete', 'Id': 'Complete', 'variant': 'brand' }],
            'lwcToImport': 'c/stateReversalPopup',
            'size': 'small'
        }).then((result) => {
            if (result) {
                let type = result.evtType;
                if (type == 'Complete') {
                    let payload = result.payload;
                    this.taskComment = payload.taskComment;
                    this.sendStateReversal();
                } else if (type == undefined) {
                    this.doCancel();
                }
            } else {
                this.doCancel();
            }
        });
    }
    sendStateReversal() {
        let params = { 'recordId': this.recordId, 'taskComment': this.taskComment };
        helper.callServer(this, 'providerReviewApexController', 'sumbitForStateReversal', (function (result) {
            if (result.isSuccessful) {
                helper.showToast(this, 'Success!', 'Task T234 – State Reversal Request is created on Provider Review ' + result.objectData.recordName + ' and assigned to ' + result.objectData.userName + '.', 'success', '');
                this.doCancel();
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', '');
            }
        }).bind(this), JSON.stringify(params));
    }
    doCancel() {
        this.dispatchEvent(new RefreshEvent());
    }
    handleDelete() {
        let params = { 'recordId': this.recordId };
        helper.callServer(this, 'providerReviewApexController', 'deleteProviderReviewButton', (function (result) {
            if (result.isSuccessful) {
                helper.showToast(this, 'Success!', 'Record was successfully deleted!', 'success', '');
                helper.redirectToRecord(this, result.objectData.parentFARecord);
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', '');
            }
        }).bind(this), JSON.stringify(params));

    }
    handleView() {
        let params = { 'recordId': this.recordId, 'screenMode': 'VIEW', 'isDelete': false, 'fetchAllData': false };
        helper.callServer(this, 'providerReviewApexController', 'checkEligibility', (function (result) {
            if (result.isSuccessful) {
                helper.callServer(this, 'providerReviewApexController', 'getVFBaseURL', (function (result1) {
                    if (result1.isSuccessful) {
                        if (result1.objectData) {
                            var hosturl = result1.objectData.sfUrl;
                            window.open(hosturl + "/apex/providerReviewFlow_generatePDF?recordId=" + this.recordId, '_blank');
                        }
                    } else {
                        helper.showToast(this, 'Error!', result1.errorMessage, 'error', '');
                    }
                }).bind(this), undefined);
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', '');
            }
        }).bind(this), JSON.stringify(params));
    }
    handleReview() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__providerReviewFlow',
            },
            state: {
                'c__recordId': this.recordId,
                'c__screenMode': 'EDIT'
            },
        });
    }
}