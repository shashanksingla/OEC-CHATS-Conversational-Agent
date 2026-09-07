import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class AuthEncumTerminatedFlowLwc extends NavigationMixin(LightningElement) {    
    @track selectedMonth;
    @track selectedYear;
    @track months = [];

    @api recordId;

    connectedCallback() {
        this.initializeDefaults();
    }

    initializeDefaults() {
        const today = new Date();
        this.selectedMonth = String(today.getMonth());
        this.selectedYear = today.getFullYear();
        
        this.months = [
            { value: '0', label: 'January' },
            { value: '1', label: 'February' },
            { value: '2', label: 'March' },
            { value: '3', label: 'April' },
            { value: '4', label: 'May' },
            { value: '5', label: 'June' },
            { value: '6', label: 'July' },
            { value: '7', label: 'August' },
            { value: '8', label: 'September' },
            { value: '9', label: 'October' },
            { value: '10', label: 'November' },
            { value: '11', label: 'December' }
        ];
    }

    handleMonthChange(event) {
        this.selectedMonth = event.detail.value;
    }

    handleYearChange(event) {
        this.selectedYear = event.detail.value;
    }

    handleViewClick() {
        const allValid = this.validateInputs();
        
        if (allValid) {
            const childComponent = this.template.querySelector('c-auth-encumbrance-related-list_-l-w-c');
            if (childComponent) {
                childComponent.getAuthEncumb(this.selectedMonth, this.selectedYear);
            }
        }
    }

    validateInputs() {
        const inputFields = this.template.querySelectorAll('lightning-combobox, lightning-input');
        let allValid = true;
        
        inputFields.forEach(inputField => {
            if (!inputField.checkValidity()) {
                inputField.reportValidity();
                allValid = false;
            }
        });
        
        return allValid;
    }

    handleCancelClick() {
        this.navigateToRecord();
    }

    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }
}