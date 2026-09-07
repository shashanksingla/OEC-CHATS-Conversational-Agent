import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class TeenParentEducationForm_lwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api clientId; // Client ID passed from Aura component
    
    @track isLoading = false;
    @track error;
    @track selectedTrainingType = '';


    renderedCallback() {
        // Set the client ID field value if creating a new record
        if (this.clientId && !this.recordId) {
            const clientField = this.template.querySelector('lightning-input-field[field-name="IDN_CLIENT__c"]');
            if (clientField) {
                // For lightning-input-field, we can set the value directly
                clientField.value = this.clientId;
            }
        }
    }

    get recordTitle() {
        return this.recordId ? 'Teen Parent Education' : 'New Teen Parent Education';
    }

    get isSudSelected() {
        return this.selectedTrainingType === 'SUD';
    }

    get isSudDisabled(){
        return !this.isSudSelected;
    }

    // Handle Training or Education Type field change
    handleTrainingTypeChange(event) {
        this.selectedTrainingType = event.target.value;
        
        if (this.selectedTrainingType === 'SUD') {
            // Set Verified and How Verified fields for SUD 
                this.setSudVerificationFields();
        } else {
            this.clearSudFields();
        }
    }

    // Set verification fields for SUD
    setSudVerificationFields() {
        // Set Verified to "Written Verification" (V)
        const verifiedField = this.template.querySelector('lightning-input-field[data-field="verified"]');
        if (verifiedField) {
            verifiedField.value = 'V';
        }
        
        // Set How Verified to "Self Attestation" (SA)
        const howVerifiedField = this.template.querySelector('lightning-input-field[data-field="howVerified"]');
        if (howVerifiedField) {
            howVerifiedField.value = 'SA';
        }      
    }

    clearSudFields() {
        if (!this.recordId) {
            const sudFields = [
                'verified', 'howVerified'
            ];
            
            sudFields.forEach(fieldName => {
                const field = this.template.querySelector(`lightning-input-field[data-field="${fieldName}"]`);
                if (field) {
                    field.value = '';
                }
            });
        }
    }

    handleLoad(event) {
        this.isLoading = false;
        this.error = null;
        
        // Initialize selectedTrainingType from loaded record
        if (event.detail && event.detail.records) {
            const record = event.detail.records[Object.keys(event.detail.records)[0]];
            if (record && record.fields && record.fields.CDE_TYPE_SCHOOL__c) {
                this.selectedTrainingType = record.fields.CDE_TYPE_SCHOOL__c.value;                
            }
        }
    }

    handleSuccess(event) {
        const recordId = event.detail.id;        
        this.showToast('Success', 'Teen Parent Education record saved successfully', 'success');
        
        if (!this.recordId) {
            this.navigateToRecord(recordId);
        }
        if (this.recordId) {
            this.navigateToRecord(this.recordId);
        }
    }

    handleError(event) {
        this.error = event.detail.message || 'An error occurred while saving the record';
        this.showToast('Error', this.error, 'error');
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('refresh'));
        if (this.recordId) {
            this.navigateToRecord(this.recordId);
        } else {
            window.history.back(); 
        }
    }


    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'T_INDIV_EDUC__c',
                actionName: 'view'
            }
        });
    }
}