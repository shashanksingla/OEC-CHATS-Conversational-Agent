import { LightningElement, track, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import DYNATRACE_JS from '@salesforce/resourceUrl/Dynatrace_JSv1';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import { label } from 'c/labelUtility';
// Using helper for Apex calls instead of direct imports

export default class IncomeCalculator_lwc extends LightningElement {
    visualforceUrl = '/apex/sample';
    // Properties from Aura component
    @track currentTabNumber = 1;
    @track countySelected;
    @track familySize;
    @track noOfChildReqCare;
    @track index;
    @track incomeType = { SObjectType: 'T_INDIV_OTHER_INCOME__c', CDE_SOURCE_INCOME__c: '' };
    @track amount;
    @track frequency = { SObjectType: 'T_EMPLMT_INCOME__c', CDE_FREQ_PAY_ESTMD__c: '' };
    @track hoursPerWeek;
    @track incomeRows = [];
    @track annualIncome = '00.00';
    @track monthlyIncome = '00.00';
    @track fpg;
    @track incomeCelling;
    pfChangeEffective;
    @track c1;
    @track c2;
    @track recordId;
    @track fullTimeFee = '00.00';
    @track partTimeFee = '00.00';
    @track fullTimeFeeDiscounted = '00.00';
    @track partTimeFeeDiscounted = '00.00';
    @track fbgIncome = '00.00';
    @track countyMaxIncome = '00.00';
    @track SMI = '00.00';
    @track baseParentFee = '00.00';
    @track addOnFee = '00.00';
    @track pageMessages;
    @track messageType;
    @track showSpinner = false;
    _dynatraceLoaded = false;

    // Getters
    get isFirstTab() {
        return this.currentTabNumber === 1;
    }

    // Lifecycle hooks
    connectedCallback() {
        let today = new Date();
        this.pfChangeEffective = today >= new Date(label.Parent_Fee_Formula_Change);
        this.initializeIncomeRows();
        this.getFPGValuesFromServer();
    }

    renderedCallback() {
        if (this._dynatraceLoaded) return;
        this._dynatraceLoaded = true;
        Promise.resolve(loadScript(this, DYNATRACE_JS))
            .then(() => {
                console.log('Dynatrace_JSv1 loaded');
            })
            .catch(() => {
                // Dynatrace may throw during LWC Locker Service eval — script still initializes
                console.warn('Dynatrace_JSv1 loaded with warnings (Locker Service eval restriction)');
            });
    }

    // Initialize income rows with unique IDs
    initializeIncomeRows() {
        const defaultRow = {
            CDE_SOURCE_INCOME__c: '',
            empNumber: '',
            amount: '',
            CDE_FREQ_PAY_ESTMD__c: '',
            hoursPerWeek: '',
            fedMinWageMet: ''
        };
        this.incomeRows = null;
        let incomeRows = [];
        for (let i = 0; i < 12; i++) {
            incomeRows.push({
                ...JSON.parse(JSON.stringify(defaultRow)),
                uniqueId: 'row-' + i
            });
        }
        this.incomeRows = JSON.parse(JSON.stringify(incomeRows));
    }
    handleIncomeRows(event) {
        if (event.detail) {
            this.incomeRows[event.detail.index] = event.detail.incomeRow;
        }
    }
    // Consolidated event handler for all input changes
    handleInputChange(event) {
        // Handle multiselect-combobox changes
        if (event.detail && event.detail.callingContext === 'User_Owner_County__c') {
            this.countySelected = event.detail.payload.value;
        }
        // Handle income row changes
        else if (event.detail && event.detail.incomeRow) {
            const updatedRow = event.detail.incomeRow;
            const index = this.incomeRows.findIndex(row => row.uniqueId === updatedRow.uniqueId);
            if (index !== -1) {
                // Create a new array with the updated row to maintain reactivity
                const updatedRows = [...this.incomeRows];
                updatedRows[index] = updatedRow;
                this.incomeRows = updatedRows;
            }
        }
        // Handle standard lightning-input changes
        else if (event.target) {
            const fieldName = event.target.name;
            const fieldValue = event.target.value;

            if (fieldName === 'familySize') {
                this.familySize = fieldValue;
            } else if (fieldName === 'noOfChildReqCare') {
                this.noOfChildReqCare = fieldValue;
            }
        }
    }

    // Button click handlers
    addIncomeRow() {
        const defaultRow = {
            CDE_SOURCE_INCOME__c: '',
            empNumber: '',
            amount: '',
            CDE_FREQ_PAY_ESTMD__c: '',
            hoursPerWeek: '',
            fedMinWageMet: '',
            uniqueId: 'row-' + this.incomeRows.length
        };
        this.incomeRows = [...this.incomeRows, defaultRow];
    }

    clearFields() {
        this.familySize = 0;
        this.initializeIncomeRows();
        this.annualIncome = '0';
        this.monthlyIncome = '0';
        this.fpg = '0';
        this.incomeCelling = '0';
        this.fullTimeFee = '0';
        this.partTimeFee = '0';
        this.fullTimeFeeDiscounted = '0';
        this.partTimeFeeDiscounted = '0';
        this.fbgIncome = '0';
        this.countyMaxIncome = '0';
        this.SMI = '0';
        this.baseParentFee = '0';
        this.addOnFee = '0';
        this.template.querySelector('c-multiselect-combobox').clearSelectedValue();
        this.noOfChildReqCare = 0;
    }

    calculateIncome() {
        if (this.validateInputs()) {
            this.calculateTotalIncome();
        }
    }

    // Validation
    validateInputs() {
        this.pageMessages = null;

        // Use abstract helper to validate the current page (standard inputs)
        let allValid = abs_helper.validateCurrentPage(this);

        // Check if at least one income row is populated
        let anyRowPopulated = false;
        this.incomeRows.forEach(incomeRow => {
            if (incomeRow.CDE_SOURCE_INCOME__c || incomeRow.amount || incomeRow.CDE_FREQ_PAY_ESTMD__c) {
                anyRowPopulated = true;
            }
        });

        if (!anyRowPopulated) {
            this.pageMessages = [{ 'Id': 0, 'message': label.INCOME_TOOL_AT_LEAST_ONE_ROW_REQ }];
            this.messageType = 'error';
            allValid = false;
        }

        // Validate the income row component (now a single component containing all rows)
        const incomeRowComponent = this.template.querySelector('c-income-row_lwc');
        if (incomeRowComponent && incomeRowComponent.validateMe) {
            allValid = incomeRowComponent.validateMe() && allValid;
        }
        return allValid;
    }

    // Server calls
    getFPGValuesFromServer() {
        this.showSpinner = true;
        helper.callServer(this, 'IncomeCalculatorApxCtrl', 'getFPGValues', (function (response) {
            if (response.isSuccessful) {
                this.c1 = response.objectData.c1;
                this.c2 = response.objectData.c2;
            }
            this.showSpinner = false;
        }).bind(this), JSON.stringify({}));
    }

    getCountyDataFromServer() {
        if (!this.countySelected) return;
        this.showSpinner = true;
        helper.callServer(this, 'IncomeCalculatorApxCtrl', 'getCountyData', (function (response) {
            if (response.isSuccessful && response.objectData && response.objectData.data) {
                this.incomeCelling = response.objectData.data.ELIGIBILITY_Q1_1__c;
            }
            this.showSpinner = false;
        }).bind(this), JSON.stringify({ 'county': this.countySelected }));
    }

    fullParentFeeCalculation(annualIncome, fpg) {
        this.showSpinner = true;
        let params = JSON.stringify({
            'annualIncome': annualIncome,
            'inputFPG': fpg,
            'noOfChildReq': this.noOfChildReqCare,
            'county': this.countySelected,
            'familySize': this.familySize
        });
        helper.callServer(this, 'IncomeCalculatorApxCtrl', 'parentFeeDataAll', (function (response) {
            if (response.isSuccessful && response.objectData) {
                const fullTimeFee = parseFloat(response.objectData.fullTimeFee);
                const partTimeFee = parseFloat(response.objectData.partTimeFee);
                this.fullTimeFee = fullTimeFee.toFixed(2);
                this.partTimeFee = partTimeFee.toFixed(2);
                this.baseParentFee = response.objectData.baseParentFee;
                this.addOnFee = response.objectData.addOnFee;
                this.SMI = response.objectData.SMIPercent;
                this.fullTimeFeeDiscounted = Math.floor(response.objectData.fullTimeFee * 0.8);
                this.partTimeFeeDiscounted = Math.floor(response.objectData.partTimeFee * 0.8);
                this.fbgIncome = response.objectData.FPIGPercent;
                this.countyMaxIncome = response.objectData.countyMaxIncome;
                this.getCountyDataFromServer();
            }
            this.showSpinner = false;
        }).bind(this), params);
    }

    // Income calculation logic
    calculateTotalIncome() {
        this.showSpinner = true;
        let annualIncome = 0;
        let annualIncome1 = 0;
        let annualIncome2 = 0;
        let annualIncome3 = 0;
        let annualIncome4 = 0;
        let annualIncome5 = 0;
        let annualIncome6 = 0;
        let annualIncome7 = 0;
        let annualIncome8 = 0;
        let annualIncome9 = 0;
        let annualIncome10 = 0;
        let fpg = 0;
        const familySizeValue = this.familySize;
        const c1 = this.c1;
        const c2 = this.c2;

        // Check if there are employment type incomes
        let hasEmploymentType = false;
        const empNumCountMap = new Map();
        const empNumIncomeMap = new Map();
        const empNumAvgIncomeMap = new Map();
        const empNumHourMap = new Map();
        const fedMinWageMap = new Map();

        this.incomeRows.forEach(ir => {
            if (ir.amount != null && ir.amount !== "" && ir.amount > 0) {
                let empNumberTemp = ir.empNumber;
                // Adding condition for One Time Payment
                if ((ir.CDE_SOURCE_INCOME__c !== "E" && ir.CDE_SOURCE_INCOME__c !== "S") || ir.CDE_FREQ_PAY_ESTMD__c === 'ONE') {
                    empNumberTemp = ""; // Emp # are ignored for non 'Employment' and 'Self Emp' income types
                }
                if (empNumCountMap.has(empNumberTemp)) {
                    empNumCountMap.set(empNumberTemp, empNumCountMap.get(empNumberTemp) + 1);
                } else {
                    empNumCountMap.set(empNumberTemp, 1);
                }
                if (ir.CDE_SOURCE_INCOME__c === "E" || ir.CDE_SOURCE_INCOME__c === "S") {
                    hasEmploymentType = true;
                }
            }
        });

        if (hasEmploymentType) {
            this.incomeRows.forEach(ir => {
                if (ir.amount != null && ir.amount !== "" && ir.amount > 0) {
                    // Calculating per row annual income based on frequency
                    let rowAnnualIncome = 0;
                    const amount = parseFloat(ir.amount);
                    const hoursPerWeek = parseFloat(ir.hoursPerWeek);

                    switch (ir.CDE_FREQ_PAY_ESTMD__c) {
                        case 'HLY':
                            rowAnnualIncome = ((amount * hoursPerWeek) * 4.33) * 12;
                            break;
                        case 'WKY':
                            rowAnnualIncome = (4.33 * amount) * 12;
                            break;
                        case 'E2W':
                            rowAnnualIncome = (4.33 * (amount / 2)) * 12;
                            break;
                        case '2PM':
                            rowAnnualIncome = 24 * amount;
                            break;
                        case 'MON':
                            rowAnnualIncome = 12 * amount;
                            break;
                        case 'E2M':
                            rowAnnualIncome = 6 * amount;
                            break;
                        case 'QRT':
                            rowAnnualIncome = 4 * amount;
                            break;
                        case '2PY':
                            rowAnnualIncome = 2 * amount;
                            break;
                        case '1PY':
                        case 'ONE':
                            rowAnnualIncome = amount;
                            break;
                    }

                    // Creating Map of Emp # as key and total week hours for that Emp # as value
                    if ((ir.CDE_SOURCE_INCOME__c === "E" || ir.CDE_SOURCE_INCOME__c === "S") && ir.CDE_FREQ_PAY_ESTMD__c !== 'ONE') {
                        if (empNumHourMap.has(ir.empNumber)) {
                            empNumHourMap.set(ir.empNumber, empNumHourMap.get(ir.empNumber) + hoursPerWeek);
                        } else {
                            empNumHourMap.set(ir.empNumber, hoursPerWeek);
                        }
                    }

                    // Creating Map of Emp # as key and total annual income for that Emp # as value
                    let empNumberTemp = ir.empNumber;
                    if ((ir.CDE_SOURCE_INCOME__c !== "E" && ir.CDE_SOURCE_INCOME__c !== "S") || ir.CDE_FREQ_PAY_ESTMD__c === 'ONE') {
                        empNumberTemp = "";
                    }
                    if (empNumIncomeMap.has(empNumberTemp)) {
                        empNumIncomeMap.set(empNumberTemp, empNumIncomeMap.get(empNumberTemp) + rowAnnualIncome);
                    } else {
                        empNumIncomeMap.set(empNumberTemp, rowAnnualIncome);
                    }
                }
            });

            // Calculating the average of annual income per emp # and total income
            empNumIncomeMap.forEach((value, key) => {
                if (key) {
                    empNumAvgIncomeMap.set(key, value / empNumCountMap.get(key));
                    annualIncome += value / empNumCountMap.get(key);
                } else {
                    annualIncome += value;
                }
            });

            // Calculating the fed min wage for each emp #
            empNumHourMap.forEach((value, key) => {
                const avgHour = value / empNumCountMap.get(key);
                fedMinWageMap.set(key, (avgHour * 7.25 * 4.33 * 12).toFixed(2));
            });

            // Comparing fed min wage with income and setting Yes/No in UI
            const updatedIncomeRows = this.incomeRows.map(ir => {
                const updatedRow = { ...ir };
                updatedRow.fedMinWageMet = '';
                if (updatedRow.CDE_SOURCE_INCOME__c === "E" || updatedRow.CDE_SOURCE_INCOME__c === "S") {
                    if (empNumAvgIncomeMap.get(updatedRow.empNumber) >= fedMinWageMap.get(updatedRow.empNumber)) {
                        updatedRow.fedMinWageMet = 'Yes';
                    } else {
                        updatedRow.fedMinWageMet = 'No';
                    }
                }
                return updatedRow;
            });
            this.incomeRows = updatedIncomeRows;
        } else {
            // If no 'Employment' or 'Self Emp' type are present then simply calculate income per row and add into total
            this.incomeRows.forEach(incomeRow => {
                if (!incomeRow.amount) return;

                const amount = parseFloat(incomeRow.amount);
                const hoursPerWeek = parseFloat(incomeRow.hoursPerWeek);

                switch (incomeRow.CDE_FREQ_PAY_ESTMD__c) {
                    case 'HLY':
                        annualIncome1 += ((amount * hoursPerWeek) * 4.33) * 12;
                        break;
                    case 'WKY':
                        annualIncome2 += (4.33 * amount) * 12;
                        break;
                    case 'E2W':
                        annualIncome3 += (4.33 * (amount / 2)) * 12;
                        break;
                    case '2PM':
                        annualIncome4 += 24 * amount;
                        break;
                    case 'MON':
                        annualIncome5 += 12 * amount;
                        break;
                    case 'E2M':
                        annualIncome6 += 6 * amount;
                        break;
                    case 'QRT':
                        annualIncome7 += 4 * amount;
                        break;
                    case '2PY':
                        annualIncome8 += 2 * amount;
                        break;
                    case '1PY':
                        annualIncome9 += amount;
                        break;
                    case 'ONE':
                        annualIncome10 += amount;
                        break;
                }
            });
            annualIncome = annualIncome1 + annualIncome2 + annualIncome3 + annualIncome4 + annualIncome5 +
                annualIncome6 + annualIncome7 + annualIncome8 + annualIncome9 + annualIncome10;
        }

        // Clearing fedMinWageMet column in UI for non-employment rows
        const updatedIncomeRows = this.incomeRows.map(ir => {
            const updatedRow = { ...ir };
            if (updatedRow.CDE_SOURCE_INCOME__c !== "E" && updatedRow.CDE_SOURCE_INCOME__c !== "S") {
                updatedRow.fedMinWageMet = '';
            }
            return updatedRow;
        });
        this.incomeRows = updatedIncomeRows;

        // Calculate FPG
        fpg = (annualIncome / (c1 + ((familySizeValue - 1) * c2))) * 100;
        if (this.pfChangeEffective) {
            fpg = Math.trunc(fpg * 1000) / 1000;
        }
        this.annualIncome = annualIncome.toFixed(2);
        this.monthlyIncome = (annualIncome / 12).toFixed(2);
        this.fpg = fpg.toFixed(3);
        // Calculate parent fee
        this.showSpinner = false;
        this.fullParentFeeCalculation(annualIncome, this.fpg);
    }
}