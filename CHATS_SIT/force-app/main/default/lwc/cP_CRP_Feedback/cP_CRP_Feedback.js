import { LightningElement, api, track } from 'lwc';
import feedbackModal from 'c/feedbackModal';
import { helper } from 'c/generic_Utilities';


export default class cP_CRP_Feedback extends LightningElement {

    @api
    recordId
    @api loadpopup
    buttons = [];
    @api userFlow;
    @api feedbackButtonLabel;
    @track
    isApprover;
    isFeedbackVisible = true;
    @api
    isCPFlow = false;
    connectedCallback() {
        this.buttons = [];
        this.buttons = [{ 'label': 'Close', 'Id': 'close', 'variant': 'neutral' }]
        this.checkInit();

    }
    get showButton() {
        return (!this.isApprover && !this.loadpopup && this.isFeedbackVisible);
    }
    checkInit() {
        let params = { 'recordId': this.recordId, 'isCPFlow': this.isCPFlow };
        helper.callServer(this, 'CompareCP_CRP_lwc', 'initLoad', (function (result) {
            if (result.isSuccessful) {
                if (result.objectData) {
                    this.isApprover = result.objectData.isApprover;
                    this.isFeedbackVisible = result.objectData.isFeedbackVisible;
                    if (this.isApprover) {
                        this.feedbackButtonLabel = 'Feedback';
                    } else {
                        this.feedbackButtonLabel = 'Revisions Needed';
                    }
                    if (this.loadpopup) {
                        this.showFeedback();
                    }
                }
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', '');
            }
        }).bind(this), JSON.stringify(params));
    }
    showFeedback() {
        feedbackModal.open({
            recordId: this.recordId,
            size: 'large',
            'buttons': this.buttons,
            'header': this.feedbackButtonLabel,
            'showHeader': true,
            'isCPFlow': this.isCPFlow
        }).then((result) => {
            if (result) {
                let type = result.evtType;
            } else {

            }
            const valueChangeEvent = new CustomEvent("closeModal", {});
            this.dispatchEvent(valueChangeEvent);
        });
    }
}