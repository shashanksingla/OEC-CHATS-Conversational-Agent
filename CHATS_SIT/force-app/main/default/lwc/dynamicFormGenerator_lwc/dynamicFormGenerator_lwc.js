import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

export default class DynamicFormGenerator_lwc extends LightningElement {
    @api fieldLabel;
    @api fieldType;
    @api fieldAPIName;
    @api fieldValue;
    @api required = false;
    @api referenceFieldDetails;
    @api parentObjectName;
    @api objectName;
    @api fieldUtilityPicklistFieldName = '';
    @api sOb;
    @api usePlainValue = false;
    @api selectedLookUpRecord = {};    
    @track _readOnly = false;    
    @api 
    get readOnly() {
        return this._readOnly;
    }    
    set readOnly(value) {
        const oldValue = this._readOnly;
        this._readOnly = value;
        if (oldValue !== value && this.initLoaded) {
            setTimeout(() => {
                this.initLoaded = false;
                setTimeout(() => {
                    this.initLoaded = true;
                }, 10);
            }, 10);
        }
    }    
    @track initLoaded = false;
    @track picklistOptions = [];
    @track objectInfo;
    @track lookupValue;
    @track lookupRecordName;

    connectedCallback() {
        this.doInit();
    }

    renderedCallback() {
        if (this.sOb && this.fieldAPIName) {
            const newValue = this.sOb[this.fieldAPIName];
            if (newValue !== this.fieldValue) {
                this.updateFieldValue();
            }
        }
    }

    doInit() {
        this.updateFieldValue();
        this.initLoaded = true;
    }

    updateFieldValue() {
        if (this.sOb && this.fieldAPIName) {
            this.fieldValue = this.sOb[this.fieldAPIName];
            if (this.isReferenceField) {
                this.lookupValue = this.fieldValue;
            }
        }
    }

    @api
    refreshFieldValue() {
        this.updateFieldValue();
    }

    get isStringField() {
        return this.fieldType === 'STRING';
    }
    get isDoubleField() {
        return this.fieldType === 'DOUBLE';
    }
    get isEmailField() {
        return this.fieldType === 'EMAIL';
    }
    get isPhoneField() {
        return this.fieldType === 'PHONE';
    }
    get isPicklistField() {
        return this.fieldType === 'PICKLIST';
    }
    get isBooleanField() {
        return this.fieldType === 'BOOLEAN';
    }
    get isReferenceField() {
        return this.fieldType === 'REFERENCE';
    }
    get isTextareaField() {
        return this.fieldType === 'TEXTAREA';
    }
    get isDateField() {
        return this.fieldType === 'DATE';
    }
    get isMultiPicklistField() {
        return this.fieldType === 'MULTIPICKLIST';
    }
    get checkboxValue() {
        return this.fieldValue === 'true' || this.fieldValue === true;
    }
    get picklistObject(){
        return (this.fieldUtilityPicklistFieldName == '' || this.fieldUtilityPicklistFieldName == undefined) ? this.objectName : 'Field_Utility__c';
    }
    get picklistField() {
        return (this.fieldUtilityPicklistFieldName == '' || this.fieldUtilityPicklistFieldName == undefined) ? this.fieldAPIName : this.fieldUtilityPicklistFieldName;
    }

    handleFieldChange(event) {
        this.fieldValue = event.target.value;
        this.updateSObject();
        event.stopPropagation();
    }

    handleCheckboxChange(event) {
        this.fieldValue = event.detail.value;
        this.updateSObject();
        event.stopPropagation();
    }

    handleLookupSelection(event) {
        this.selectedLookUpRecord = event.detail.record;
        this.fieldValue = event.detail.record.Id;
        this.updateSObject();
        event.stopPropagation();
    }

    handlePicklistChange(event){
        this.fieldValue = event.detail.payload.value;
        this.updateSObject();
        event.stopPropagation();
    }

    updateSObject() {
        if (this.sOb && this.fieldAPIName) {
            this.sOb = { ...this.sOb, [this.fieldAPIName]: this.fieldValue };
            this.dispatchEvent(new CustomEvent('sobupdate', { detail: {record: this.sOb }}));

        }
    }

    @api
    validateAndSetData() {
        if (this.readOnly) {
            return true;
        }
        this.updateSObject();
        
        const inputField = this.template.querySelector('.input-field') || 
                          this.template.querySelector('[data-id="input-field"]');        
        if (inputField) {
            if (inputField.reportValidity) {
                inputField.reportValidity();
                return inputField.checkValidity();
            }
            return true;
        }
        const lookupField = this.template.querySelector('c-custom-lookup_lwc');
        if (lookupField) {
            return lookupField.reportValidity();
        }
        const picklistField = this.template.querySelector('c-multiselect-combobox');
        if (picklistField) {
            picklistField.reportValidity();
            return picklistField.checkValidity();
        }
        return true;
    }

    get displayValue() {
        if (this.fieldType === 'BOOLEAN') {
            return this.fieldValue === 'true' || this.fieldValue === true ? 'Yes' : 'No';
        }
        if (this.fieldType === 'REFERENCE') {
            if (this.lookupRecordName) {
                return this.lookupRecordName;
            }
            if (this.selectedLookUpRecord && this.selectedLookUpRecord.Name) {
                return this.selectedLookUpRecord.Name;
            }
        }
        return this.fieldValue;
    }
}