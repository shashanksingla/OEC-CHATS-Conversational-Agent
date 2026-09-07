import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

export default class LookupRedirect_lwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api screenFrom;
    @api objectApiName;
    
    recordName;
    error;
    _recordIdValue;

    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Compact'], modes: ['View'] })
    wiredRecord({ error, data }) {
        if (data) {
            if(data.fields.FirstName && data.fields.LastName){
                this.recordName = data.fields.FirstName.value + ' ' + data.fields.LastName.value;
            }else{
                this.recordName = data.fields.Name?.value || data.fields.Subject?.value || data.fields.Title?.value || this.recordId;
            }
            this.error = undefined;
        } else if (error) {
            this.error = this.reduceErrors(error);
            this.recordName = undefined;
        }
    }

    get hasRecordId() {
        return this.recordId && this.recordId.length > 0;
    }

    get recordUrl() {
        return `/lightning/r/${this.recordId}/view`;
    }

    get isViewParentFee() {
        return this.screenFrom === 'ViewParentFee';
    }

    handleNavigateToRecord(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        return errors
            .filter(error => !!error)
            .map(error => {
                if (Array.isArray(error.body)) {
                    return error.body.map(e => e.message);
                } else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                } else if (typeof error.message === 'string') {
                    return error.message;
                }
                return error.statusText || 'Unknown error';
            })
            .join(', ');
    }
}