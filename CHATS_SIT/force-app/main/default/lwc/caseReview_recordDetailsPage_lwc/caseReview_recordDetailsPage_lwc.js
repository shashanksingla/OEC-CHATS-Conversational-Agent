import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { helper } from 'c/generic_Utilities';

export default class CaseReview_recordDetailsPage_lwc extends NavigationMixin(LightningElement) {

    @api recordId;
    showSpinner = false;
    isAccessible = false;

    connectedCallback() {
        this.doInit();
    }

    doInit() {
        this.showSpinner = true;
        let params = { recordId: this.recordId };
        helper.callServer(this, 'caseReviewApexController', 'checkRecordAccess', (function (response) {
            if (response && response.isSuccessful) {
                this.showSpinner = false;
                this.isAccessible = true;
            } else {
                helper.showToast(this, 'Error!', response.errorMessage, 'error', 'sticky');
                this.showSpinner = false;
                this.isAccessible = false;
                if (response.objectData && response.objectData.caseId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: response.objectData.caseId,
                            actionName: 'view'
                        }
                    });
                } else {
                    window.history.back();
                }
            }
        }).bind(this), JSON.stringify(params));
    }
}