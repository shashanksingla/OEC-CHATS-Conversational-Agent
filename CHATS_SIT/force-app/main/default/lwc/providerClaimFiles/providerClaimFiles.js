import { LightningElement, api, track, wire } from 'lwc';
import { helper } from 'c/generic_Utilities';


import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
export default class ProviderClaimFiles extends LightningElement {
    @api recordId;
    error;
    @track
    claimFileWrapper;
    @api
    showSpinner;
    @wire(getRelatedListRecords, {
        parentRecordId: "$recordId", relatedListId: 'Manual_Claim_Files__r',
        fields: ['Manual_Claim_File__c.Title__c', 'Manual_Claim_File__c.File_Identifier__c', 'Manual_Claim_File__c.File_Extension__c'],
    })
    const({ error, data }) {
        if (data) {
            this.claimFileWrapper = data.records;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.claimFileWrapper = undefined;
        }
    }
    handleFileClick(evt) {
        let fileId = evt.target.dataset.id;
        let record = this.claimFileWrapper.filter(val => val.id == fileId)[0];
        let fileName = record.fields.Title__c.value;
        let params = { 'fileIdentifier': record.fields.File_Identifier__c.value, 'fileName': fileName };
        helper.callServer(this, 'ClaimInboxScreenCtrl', 'getFileDownloadUrl', (function (result) {
            if (result.isSuccessful) {
                if (result.objectData) {
                    if (result.objectData.downloadUrl) {
                        window.open(result.objectData.downloadUrl, '_blank');
                    }
                }
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', '');
            }
        }).bind(this), JSON.stringify(params));
    }
}