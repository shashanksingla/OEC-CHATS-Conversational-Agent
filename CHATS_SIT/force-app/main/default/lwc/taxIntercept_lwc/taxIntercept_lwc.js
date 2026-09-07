import { LightningElement, track } from 'lwc';
import { helper } from 'c/generic_Utilities';

export default class TaxIntercept_lwc extends LightningElement {
    // Reactive properties that need tracking
    @track searchWrapper = {};
    @track searchResults = [];
    @track selectedRecord = {};
    @track showDetailsModal = false;
    @track removeReason;

    // Non-tracked reactive properties (modern LWC doesn't require @track for primitives)
    searchResultCount = 0;
    mouseStart;
    oldWidth;
    sortField = 'Name';
    sortAsc = true;
    removeAccess = false;
    removeAccessSingle = false;
    taxYearOptions = [];
    userCounty = [];
    isAdmin = false;
    showSpinner = false;
    pageMessages = [];
    messageType;
    fieldValidationErrors = [];

    // Table columns configuration for lightning-datatable
    get columns() {
        return [
            {
                label: 'Intercept ID',
                fieldName: 'Name',
                type: 'customHyperlink',
                typeAttributes: {
                    recordId: { fieldName: 'Id' },
                    rowId: { fieldName: 'rowIndex' },
                    value: { fieldName: 'Name' }
                },
                sortable: true,
                hideDefaultActions: true
            },
            {
                label: 'Intercept Status',
                fieldName: 'Intercept_Status__c',
                type: 'textWithTooltip',
                sortable: true,
                hideDefaultActions: true
            },
            {
                label: 'County',
                fieldName: 'County_Name_Text__c',
                type: 'textWithTooltip',
                sortable: true,
                hideDefaultActions: true
            },
            {
                label: 'Case ID',
                fieldName: 'Case_Name_Number__c',
                type: 'textWithTooltip',
                sortable: true,
                hideDefaultActions: true
            },
            {
                label: 'Provider ID',
                fieldName: 'Provider_Name_Number__c',
                type: 'textWithTooltip',
                sortable: true,
                hideDefaultActions: true
            },
            {
                label: 'Name',
                fieldName: 'Name__c',
                type: 'textWithTooltip',
                sortable: true,
                hideDefaultActions: true
            },
            {
                label: 'Recovery Reason',
                fieldName: 'Recovery_Reason__c',
                type: 'textWithTooltip',
                typeAttributes: {
                    value: { fieldName: 'Recovery_Reason__c' }
                },
                sortable: true,
                hideDefaultActions: true
            },
            {
                label: 'Classification',
                fieldName: 'Classification__c',
                type: 'textWithTooltip',
                typeAttributes: {
                    value: { fieldName: 'Classification__c' }
                },
                sortable: true,
                hideDefaultActions: true
            },
            {
                label: 'Last Payment Date',
                fieldName: 'Last_Payment_Date__c',
                type: 'date',
                typeAttributes: {
                    day: 'numeric',
                    month: 'numeric',
                    year: 'numeric'
                },
                sortable: true,
                hideDefaultActions: true
            },
            {
                label: 'Outstanding Balance',
                fieldName: 'Current_Balance__c',
                type: 'currency',
                typeAttributes: {
                    currencyCode: 'USD'
                },
                sortable: true,
                cellAttributes: { alignment: 'left' },
                hideDefaultActions: true
            }
        ];
    }

    // Memoized getters for performance
    get hasSearchResults() {
        return this.searchResults?.length > 0;
    }

    get sortDirection() {
        return this.sortAsc ? 'asc' : 'desc';
    }

    get matchingInfoAdj() {
        return { primaryField: { fieldPath: 'Name', mode: 'contains' } };
    }

    get matchingInfoCase() {
        return { primaryField: { fieldPath: 'Name', mode: 'contains' } };
    }

    get matchingInfoProvider() {
        return { primaryField: { fieldPath: 'Name', mode: 'contains' } };
    }

    // Lifecycle hooks
    connectedCallback() {
        document.title = "State Tax Intercept"; // Browser tab title
        this.initSearchWrapper();
        this.setTaxYear();
    }

    // Initialize search wrapper
    initSearchWrapper() {
        this.searchWrapper = JSON.parse(JSON.stringify({
            taxRecord: { sobjectType: 'Tax_Intercept__c' },
            selectedCounty: [],
            recoveryReason: []
        }));
    }

    // Set tax year options and default value - Optimized to avoid unnecessary JSON parsing
    setTaxYear() {
        const today = new Date();
        const currentYear = today.getFullYear();
        const taxYearOptions = [];

        for (let i = 2021; i <= currentYear; i++) {
            taxYearOptions.push({ 'label': i.toString(), 'value': i.toString() });
        }

        this.taxYearOptions = taxYearOptions;
        if (this.searchWrapper.taxRecord) {
            this.searchWrapper.taxRecord.Tax_Year__c = currentYear.toString();
        }
    }

    handleComboboxUpdates(event) {
        if (event.detail.callingContext == 'User_Owner_County__c') {
            this.searchWrapper.selectedCounty = event.detail.payload.value;
        } else if (event.detail.callingContext == 'Tax_Intercept__c_Recovery_Reason__c') {
            this.searchWrapper.recoveryReason = event.detail.payload.value;
        } else if (event.detail.callingContext == 'Tax_Intercept__c_Classification__c') {
            this.searchWrapper.taxRecord.Classification__c = event.detail.payload.value;
        } else if (event.detail.callingContext == 'Tax_Intercept__c_Type__c') {
            this.searchWrapper.taxRecord.Type__c = event.detail.payload.value;
        }
    }
    handleInputChange(event) {
        const { name, value } = event.target;
        if (this.searchWrapper.taxRecord) {
            this.searchWrapper.taxRecord[name] = value;
        }
    }
    handleLookupSelection(event) {
        const inputName = event.target.name;
        const recordId = event.detail.recordId;

        // Using a mapping object for cleaner code
        const fieldMapping = {
            'AdjustmentId': 'Adjustment__c',
            'CaseId': 'Case__c',
            'ProviderId': 'Provider__c'
        };

        if (fieldMapping[inputName] && this.searchWrapper.taxRecord) {
            this.searchWrapper.taxRecord[fieldMapping[inputName]] = recordId;
        }
    }

    // Clear search filters and results
    clearScreen() {
        this.showSpinner = true;
        // Store the current tax year before resetting
        const currentTaxYear = this.searchWrapper.taxRecord?.Tax_Year__c;
        // Initialize search wrapper (resets all fields)
        this.initSearchWrapper();

        // Restore tax year if it was set
        if (currentTaxYear && this.searchWrapper.taxRecord) {
            this.searchWrapper.taxRecord.Tax_Year__c = currentTaxYear;
        }
        // Clear all multiselect combobox components
        const multiselectComboboxes = this.template.querySelectorAll('c-multiselect-combobox');
        if (multiselectComboboxes) {
            multiselectComboboxes.forEach(combobox => {
                if (combobox && typeof combobox.clearSelectedValue === 'function') {
                    combobox.clearSelectedValue();
                }
            });
        }
        // Clear all lightning-record-picker components
        const recordPickers = this.template.querySelectorAll('lightning-record-picker');
        if (recordPickers) {
            recordPickers.forEach(picker => {
                if (picker) {
                    picker.clearSelection();
                }
            });
        }
        this.searchResults = [];
        this.searchResultCount = 0;
        this.setTaxYear();
        this.showSpinner = false;
    }

    // Search for tax intercepts - Optimized with better error handling
    search() {
        if (!this.validateRequiredFields()) {
            return;
        }

        this.showSpinner = true;
        this.searchResults = [];
        this.searchResultCount = 0;
        let requestPayload = JSON.parse(JSON.stringify(this.searchWrapper));
        if (requestPayload.selectedCounty != '') {
            requestPayload.selectedCounty = requestPayload.selectedCounty.split(';').filter(val => val != '');
        } else {
            requestPayload.selectedCounty = [];
        }
        if (requestPayload.recoveryReason != '') {
            requestPayload.recoveryReason = requestPayload.recoveryReason.split(';').filter(val => val != '');
        } else {
            requestPayload.recoveryReason = [];
        }
        const params = {
            searchWrapperString: requestPayload
        };
        helper.callServer(
            this,
            'TaxInterceptApexController',
            'searchTaxIntercepts',
            this.handleSearchResponse.bind(this),
            JSON.stringify(params)
        );
    }

    // Separated callback for better organization and error handling
    handleSearchResponse(response) {
        this.showSpinner = false;

        if (!response || !response.objectData) {
            helper.showToast(this, 'Error!', 'Failed to retrieve search results.', 'error', 'dismissible');
            return;
        }

        const { taxInterceptList, recordCount, hasRemoveAccess, userCounty, isAdmin } = response.objectData;

        // Process data for datatable with URL field for row actions
        const processedData = this.processDataForDataTable(taxInterceptList || []);

        this.searchResults = processedData;
        this.searchResultCount = recordCount || 0;
        this.removeAccess = hasRemoveAccess || false;
        this.userCounty = userCounty || [];
        this.isAdmin = isAdmin || false;
        this.sortAsc = true;
        this.sortField = 'Name';

        if (this.searchResults.length === 0) {
            helper.showToast(this, 'Error!', 'No results found.', 'error', 'dismissible');
        }
    }

    // Process data for lightning-datatable
    processDataForDataTable(data) {
        return data.map((record, index) => {
            // Create a flattened copy of the record
            const processedRecord = { ...record };

            // Add row index as a data attribute for row selection
            processedRecord.rowIndex = index;

            return processedRecord;
        });
    }

    // Check if a column is the current sort field
    isCurrentSortField(fieldName) {
        return this.sortField === fieldName;
    }

    // Validate required fields
    validateRequiredFields() {
        if (!this.searchWrapper.selectedCounty?.length) {
            helper.showToast(this, 'Error!', 'Please select at least one County.', 'error', 'dismissible');
            return false;
        }
        return true;
    }

    // Handle hyperlink click event from custom component
    handleHyperlinkClick(event) {
        const { recordId, rowId, value } = event.detail;

        // Find the selected record using multiple fallback strategies
        let selectedRecord;

        // Strategy 1: Use recordId if available
        if (recordId) {
            selectedRecord = this.searchResults.find(record => record.Id === recordId);
        }

        // Strategy 2: Use rowId if available and recordId didn't work
        if (!selectedRecord && rowId !== undefined && rowId !== null) {
            selectedRecord = this.searchResults[rowId];
        }
        // Strategy 3: Use value as fallback
        if (!selectedRecord && value) {
            selectedRecord = this.searchResults.find(record => record.Name === value);
        }

        if (!selectedRecord) {
            console.error('Could not find selected record');
            return;
        }

        this.selectedRecord = selectedRecord;
        this.removeReason = selectedRecord.Remove_Reason__c;
        this.showDetailsModal = true;

        // Determine if user has remove access for this record
        const thisYear = new Date().getFullYear().toString();
        const hasCountyAccess = this.userCounty.includes(selectedRecord.County__r?.CDE_COUNTY__c?.toString()) ||
            this.userCounty.includes('66');

        this.removeAccessSingle = this.isAdmin ||
            (this.removeAccess && hasCountyAccess && thisYear === selectedRecord.Tax_Year__c);
    }

    // Handle details modal close
    handleModalClose() {
        this.showDetailsModal = false;
    }

    // Handle datatable sorting
    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;

        // Update sort field and direction
        this.sortField = fieldName;
        this.sortAsc = sortDirection === 'asc';

        // Sort the data
        const sortedData = [...this.searchResults].sort((a, b) => {
            let valueA = a[fieldName];
            let valueB = b[fieldName];

            // Handle null/undefined values
            if (!valueA && !valueB) return 0;
            if (!valueA) return this.sortAsc ? 1 : -1;
            if (!valueB) return this.sortAsc ? -1 : 1;

            // Compare based on data type
            if (typeof valueA === 'string') {
                return this.sortAsc ?
                    valueA.localeCompare(valueB) :
                    valueB.localeCompare(valueA);
            } else {
                return this.sortAsc ?
                    (valueA - valueB) :
                    (valueB - valueA);
            }
        });

        this.searchResults = [...sortedData]; // Create a new array to trigger reactivity
    }

    // Handle tax record update from child component
    handleTaxRecordUpdate(event) {
        const { taxRecord } = event.detail;

        // Update the selected record with the new data
        this.selectedRecord = { ...taxRecord };

        // Find and update the record in the search results
        const index = this.searchResults.findIndex(record => record.Id === taxRecord.Id);
        if (index !== -1) {
            this.searchResults = [
                ...this.searchResults.slice(0, index),
                { ...this.searchResults[index], ...taxRecord },
                ...this.searchResults.slice(index + 1)
            ];
        }
    }
}