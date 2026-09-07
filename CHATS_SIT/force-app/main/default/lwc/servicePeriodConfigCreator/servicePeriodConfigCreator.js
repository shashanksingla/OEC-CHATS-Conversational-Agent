import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { helper } from 'c/generic_Utilities';

export default class ServicePeriodConfigCreator extends LightningElement {
    @track existingConfig = {};
    @track isLoading = false;
    @track periodStartDate;
    disableEdit = true;
    // Component lifecycle hook - called when component is inserted into DOM
    connectedCallback() {
        this.loadExistingConfiguration();
    }

    // Getter for form validity
    get isFormValid() {
        return /*this.existingConfig.Payment_Calculation_Day__c &&*/ this.existingConfig.Payment_Release_Day__c && //modified for CCCAP-14743 
            this.existingConfig.Service_Period_Frequency__c && this.existingConfig.Future_Payment__c;
    }

    // Getter for form disabled state
    get isFormDisabled() {
        return !this.isFormValid || this.isLoading;
    }
    handlePickselect(event) {
        var payload = event.detail.payload;
        var payloadType = event.detail.payloadType;
        if (payloadType === 'uni-select') {
            if (event.detail.callingContext == 'Service_Period_Config__c_Payment_Release_Day__c') {
                this.existingConfig.Payment_Release_Day__c = payload.value;
            } else if (event.detail.callingContext == 'Service_Period_Config__c_Service_Period_Frequency__c') {
                this.existingConfig.Service_Period_Frequency__c = payload.value;
            } /*else if (event.detail.callingContext == 'Service_Period_Config__c_Payment_Calculation_Day__c') { // commented for CCCAP-14743 
                this.existingConfig.Payment_Calculation_Day__c = payload.value;
            }*/ else if(event.detail.callingContext == 'Service_Period_Config__c_Future_Payment__c'){
                this.existingConfig.Future_Payment__c = payload.value;
            }
        }
    }
    get configUrl(){
        return '/'+this.existingConfig.Id;
    }
    // Handle form submission
    handleSave() {
        if (!this.isFormValid) {
            this.showToast('Error', 'Please fill in all required fields.', 'error');
            return;
        }

        this.isLoading = true;
        let params = {
            'configData': JSON.stringify(this.existingConfig)
        };
        this.disableEdit = true;
        helper.callServer(this, 'ServicePeriodConfigController', 'upsertServicePeriodConfig', (function (result) {
            if (result.isSuccessful) {
                this.showToast('Success', 'Service Period Config saved successfully!', 'success');
                this.isLoading = false;
                this.disableEdit = false;
                // Reload the configuration to get the updated record
                this.loadExistingConfiguration();
            } else {
                this.showToast('Error', result.errorMessage || 'An error occurred while saving the record.', 'error');
                this.isLoading = false;
                this.disableEdit = false;
            }
        }).bind(this), JSON.stringify(params));
    }

    // Load existing configuration data
    loadExistingConfiguration() {
        this.isLoading = true;
        helper.callServer(this, 'ServicePeriodConfigController', 'getExistingServicePeriodConfig', (function (result) {
            if (result.isSuccessful && result.objectData) {
                this.disableEdit = false;
                if (result.objectData.existingConfig) {
                    const existingConfig = result.objectData.existingConfig;
                    this.existingConfig = JSON.parse(JSON.stringify(existingConfig));
                }
                if (result.objectData.periodStartDate) {
                    this.periodStartDate = result.objectData.periodStartDate;
                }
            } else {
                this.showToast('Error', result.errorMessage, 'error');
                this.isLoading = false;
                this.disableEdit = false;
            }
            this.isLoading = false;
        }).bind(this), JSON.stringify({}));
    }
    // Show toast message
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}