import { LightningElement, api, wire } from 'lwc';
import { helper } from 'c/generic_Utilities';
import { CurrentPageReference } from 'lightning/navigation';
import getClaimsData from '@salesforce/apex/ClaimInboxScreenCtrl.getClaimsData';
import { NavigationMixin } from 'lightning/navigation';

export default class ProviderClaimScreen extends NavigationMixin(LightningElement) {
    @api recordId;
    @api claim;
    @api claimDetails;
    showSpinner;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && currentPageReference.state.c__recordId) {
            this.claim = undefined;
            this.claimDetails = undefined;
            this.showSpinner = true;
            this.recordId = currentPageReference.state.c__recordId;
        }
    }

    @wire(getClaimsData, { 'recordId': '$recordId' })
    wiredClaimsData({ error, data }) {
        if (data) {
           if (data.isSuccessful) {
                if (data.objectData) {
                    if (data.objectData.claimData) {
                        this.claim = data.objectData.claimData;
                        this.claimDetails = data.objectData.claimDetails;
                    }
                }
            } else {
                helper.showToast(this, 'Error!', data.errorMessage, 'error', 'dismissible');
            }
            this.showSpinner = false;
        } else if (error) {
            helper.showToast(this, 'Error!',error.body.message, 'error', 'dismissible');
            this.showSpinner = false;
            window.history.back();
        }
    }
    handlePrint() {
        window.print();
    }
    goBack() {
        helper.redirectToCustomTab(this,'Provider_Claim_Inbox');
    }
}