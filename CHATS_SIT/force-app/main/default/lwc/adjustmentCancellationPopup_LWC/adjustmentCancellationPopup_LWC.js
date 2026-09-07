import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export default class AdjustmentCancellationPopup_LWC extends NavigationMixin(LightningElement) {
    @api recordId;

    connectedCallback() {
        this.navigateToCreateRecord();
    }


    navigateToCreateRecord() {
        const defaultValues = encodeDefaultFieldValues({
            IDN_ADJMT_CANCEL__c: this.recordId
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'T_ADJMT_CANCL_NOTES__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues
            }
        });
    }
}