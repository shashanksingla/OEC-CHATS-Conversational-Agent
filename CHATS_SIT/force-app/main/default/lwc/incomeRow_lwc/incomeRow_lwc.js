import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';

export default class IncomeRow extends LightningElement {
    _incomeRows = [];
    @api
    get incomeRows() {
        return this._incomeRows;
    }
    set incomeRows(value) {
        this._incomeRows = (value || []).map(row => this._addComputedProps(row));
    }

    _addComputedProps(row) {
        return {
            ...row,
            'isHoursRequired': row.CDE_SOURCE_INCOME__c === 'E' || row.CDE_SOURCE_INCOME__c === 'S' || row.CDE_FREQ_PAY_ESTMD__c === 'HLY',
            'isSourceOrFrequencyRequired': row.CDE_SOURCE_INCOME__c != '' || row.CDE_FREQ_PAY_ESTMD__c != '',
            'isEmpNumberRequired': row.CDE_SOURCE_INCOME__c === 'E' || row.CDE_SOURCE_INCOME__c === 'S'
        };
    }
    empNumberOptions = [];
    freqOptions = [];

    connectedCallback() {
        this.setEmpNumberOptions();
    }

    get localRows() {
        return (this._incomeRows || []).map(row => this._addComputedProps(row));
    }

    isHoursRequired(row) {
        return row.CDE_SOURCE_INCOME__c === 'E' || row.CDE_SOURCE_INCOME__c === 'S' || row.CDE_FREQ_PAY_ESTMD__c === 'HLY';
    }

    isSourceOrFrequencyRequired(row) {
        return row.CDE_SOURCE_INCOME__c != '' || row.CDE_FREQ_PAY_ESTMD__c != '';
    }

    isEmpNumberRequired(row) {
        return row.CDE_SOURCE_INCOME__c === 'E' || row.CDE_SOURCE_INCOME__c === 'S';
    }
    /**
     * Sets the employment number options
     */
    setEmpNumberOptions() {
        this.empNumberOptions = [
            { label: "--None--", value: "" },
            { label: "1", value: "1" },
            { label: "2", value: "2" },
            { label: "3", value: "3" },
            { label: "4", value: "4" },
            { label: "5", value: "5" },
            { label: "6", value: "6" },
            { label: "7", value: "7" },
            { label: "8", value: "8" },
            { label: "9", value: "9" },
            { label: "10", value: "10" },
            { label: "11", value: "11" },
            { label: "12", value: "12" }
        ];
    }

    /**
     * Sets the frequency options
     */
    setFreqOptions() {
        this.freqOptions = [
            { label: "--None-", value: "" },
            { label: 'Twice per Month', value: "2PM" },
            { label: 'Once a Year', value: "1PY" },
            { label: 'Twice a Year', value: "2PY" },
            { label: 'Every Other Month', value: "E2M" },
            { label: 'Every Two Weeks', value: "E2W" },
            { label: 'Hourly', value: "HLY" },
            { label: 'Monthly', value: "MON" },
            { label: 'One Time Only', value: "ONE" },
            { label: 'Quarterly', value: "QRT" },
            { label: 'Weekly', value: "WKY" }
        ];
    }


    /**
     * Consolidated handler for all input changes
     */
    handleFieldChange(event) {
        // Find the row being modified using for:each index
        const rowElement = event.target.closest('tr');
        if (!rowElement) return;

        // Get the index from the row's dataset (set in template)
        const rowIndex = parseInt(rowElement.dataset.index, 10);
        if (isNaN(rowIndex) || rowIndex < 0 || rowIndex >= this._incomeRows.length) return;

        // Work directly with the tracked array
        let updatedRow = { ...this._incomeRows[rowIndex] };
        // Handle multiselect-combobox which has a different event structure
        if (event.detail && event.detail.callingContext === 'T_INDIV_OTHER_INCOME__c_CDE_SOURCE_INCOME__c') {
            updatedRow.CDE_SOURCE_INCOME__c = event.detail.payload.value;
        } else if (event.detail && event.detail.callingContext === 'T_EMPLMT_INCOME__c_CDE_FREQ_PAY_ESTMD__c') {
            updatedRow.CDE_FREQ_PAY_ESTMD__c = event.detail.payload.value;
        } else {
            // Handle standard lightning components
            const fieldName = event.target.name;
            const fieldValue = event.detail.value;
            switch (fieldName) {
                case 'empNumber':
                    updatedRow.empNumber = fieldValue;
                    break;
                case 'incomeSource':
                    updatedRow.CDE_SOURCE_INCOME__c = fieldValue;
                    break;
                case 'amount':
                    updatedRow.amount = fieldValue;
                    break;
            }
        }
        // Recompute computed properties before updating
        updatedRow = this._addComputedProps(updatedRow);
        this.updateRowAndDispatchEvent(rowIndex, updatedRow);
    }

    /**
     * Updates a row in the incomeRows array and dispatches a change event
     */
    updateRowAndDispatchEvent(rowIndex, updatedRow) {
        // Update the tracked array directly
        let _incomeRows = this._incomeRows;
        _incomeRows[rowIndex] = updatedRow;
        this._incomeRows = JSON.parse(JSON.stringify(_incomeRows));
        // Dispatch the change event with the updated row
        const changeEvent = new CustomEvent('incomerowchange', {
            detail: { 'incomeRow': updatedRow, 'index': rowIndex }
        });
        this.dispatchEvent(changeEvent);
    }

    /**
     * Rounds off the hours to 2 decimal places
     */
    roundOffHours(event) {
        const rowElement = event.target.closest('tr');
        if (!rowElement) return;

        // Get the index from the row's dataset (set in template)
        const rowIndex = parseInt(rowElement.dataset.index, 10);
        let updatedRow = { ...this._incomeRows[rowIndex] };
        if (event.target.value) {
            const roundedHours = parseFloat(event.target.value).toFixed(2);
            updatedRow.hoursPerWeek = roundedHours;
        }
        updatedRow = this._addComputedProps(updatedRow);
        this.updateRowAndDispatchEvent(rowIndex, updatedRow);
    }

    /**
     * Validates the input fields in the component
     * @returns {Boolean} - True if all fields are valid, false otherwise
     */
    @api
    validateMe() {
        // Use abstract helper to validate the current page (standard inputs)
        let allValid = abs_helper.validateCurrentPage(this);

        // Check each row for custom validations
        this.incomeRows.forEach(row => {
            // Only validate rows that have some data entered
            if (row.CDE_SOURCE_INCOME__c || row.amount || row.CDE_FREQ_PAY_ESTMD__c) {
                // Check if employment number is required
                if (row.isEmpNumberRequired && !row.empNumber) {
                    allValid = false;
                }

                // Check if hours per week is required
                if (row.isHoursRequired && !row.hoursPerWeek) {
                    allValid = false;
                }

                // Check if amount is required
                if (row.isSourceOrFrequencyRequired && !row.amount) {
                    allValid = false;
                }
            }
        });
        return allValid;
    }

    /**
     * Custom validations check - used by abs_helper.validateCurrentPage
     */
    checkCustomValidations() {
        return true; // Basic implementation, main validations handled in validateMe
    }
}