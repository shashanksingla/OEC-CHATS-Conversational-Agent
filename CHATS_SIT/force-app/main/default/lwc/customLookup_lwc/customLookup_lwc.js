import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';

const DELAY = 500;

export default class CustomLookup_lwc extends LightningElement {
    // ═══════════════════════════════════════════════════════════════════════════
    // TRACKED STATE
    // ═══════════════════════════════════════════════════════════════════════════
    @track recordsList;
    @track selectedRecord = {};
    @track _selectedRecordId;
    @track _customErrorMessage;

    // ═══════════════════════════════════════════════════════════════════════════
    // INTERNAL STATE
    // ═══════════════════════════════════════════════════════════════════════════
    showSpinner;
    Message;
    error;
    showList;
    preventClosingOfSerachPanel;
    valid = true;
    searchDelayTimeout;

    // ═══════════════════════════════════════════════════════════════════════════
    // PUBLIC API PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════════
    @api helpText;
    @api label;
    @api required;
    @api selectedIconName;
    @api placeholder = 'search..';
    @api objectApiName;
    @api searchString = "";
    @api searchField = 'Name';
    @api hideRecentRecords;
    @api enableError;
    @api hideError;
    @api isDisabled = false;
    @api uniqueKey = '1';
    @api filter = '';
    @api
    get customErrorMessage() {
        return this._customErrorMessage;
    }
    set customErrorMessage(value) {
        const previousValue = this._customErrorMessage;
        this._customErrorMessage = value;
        if (value !== previousValue) {
            this.reportValidity();
        }
    }
    @api
    get selectedRecordId() {
        return this._selectedRecordId;
    }
    set selectedRecordId(value) {
        const previousValue = this._selectedRecordId;
        this._selectedRecordId = value;
        if (value !== previousValue) {
            if (value) {
                this.getRecordByParent();
            } else {
                this.selectedRecord = {};
                this.Message = '';
                this.searchString = '';
                this.recordsList = undefined;
                this.showList = false;
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PUBLIC API METHODS
    // ═══════════════════════════════════════════════════════════════════════════
    @api
    clearSelectedValue() {
        this.handleCommit();
    }

    @api
    reportValidity() {
        this.valid = true;
        const searchCmp = this.template.querySelector(".c_customLookup");
        if (this.customErrorMessage) {
            this.valid = false;
            if (searchCmp) {
                searchCmp.setCustomValidity(this.customErrorMessage);
                searchCmp.reportValidity();
            }
        } else if (!this.isValueSelected) {
            if (this.required && Object.keys(this.selectedRecord).length === 0) {
                this.valid = false;
                if (searchCmp && !this.hideError) {
                    searchCmp.setCustomValidity('Please provide a value.');
                    searchCmp.reportValidity();
                }
            } else if (searchCmp) {
                searchCmp.setCustomValidity('');
                searchCmp.reportValidity();
            }
        }


        return this.valid;
    }

    @api
    checkValidity() {
        return this.valid;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LIFECYCLE HOOKS
    // ═══════════════════════════════════════════════════════════════════════════
    connectedCallback() {
        if (this.selectedRecordId) {
            this.getRecordByParent();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // COMPUTED PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════════
    get selectedRecordName() {
        return this.selectedRecord?.[this.searchField];
    }

    get resultCss() {
        return this.recordsList || this.Message
            ? 'slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid'
            : 'slds-hide';
    }

    get selectedInputClass() {
        return 'slds-combobox__form-element ' +
            (this.selectedIconName
                ? ' slds-input-has-icon slds-input-has-icon_left-right '
                : 'slds-input-has-icon slds-input-has-icon_right');
    }

    get isValueSelected() {
        if (!this.selectedRecord || typeof this.selectedRecord !== 'object') {
            return false;
        }
        return Object.keys(this.selectedRecord).length > 0;
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // APEX CALLOUTS
    // ═══════════════════════════════════════════════════════════════════════════
    getRecordByParent() {
        const params = {
            'parentRecordId': this.selectedRecordId,
            'ObjectName': this.objectApiName
        };

        helper.callServer(this, 'customLookupController_Lwc', 'fetchRecordFromParentRecordId', ((response) => {
            if (response.status === 'OK') {
                const storeResponse = response.objectData.record || {};

                if (storeResponse.length === 0) {
                    this.Message = 'No Result Found...';
                } else {
                    this.selectedRecord = storeResponse;
                    this.Message = '';
                }
                storeResponse.showVal = storeResponse[this.searchField];
                this.recordsList = JSON.parse(JSON.stringify([storeResponse]));
            }
        }), JSON.stringify(params));
    }

    searchHelper(getInputkeyWord) {
        let params;
        if (getInputkeyWord && getInputkeyWord.length > 0) {
            params = {
                'searchKeyWord': getInputkeyWord,
                'ObjectName': this.objectApiName,
                'searchField': this.searchField,
                ...(this.filter ? { 'filter': this.filter } : {})
            };
            helper.callServer(this, 'customLookupController_Lwc', 'fetchLookUpValues', ((response) => {
                if (response.status === 'OK') {
                    const storeResponse = response.objectData.records || [];

                    this.Message = storeResponse.length === 0 ? 'No Result Found...' : '';
                    storeResponse.forEach(val => val.showVal = val[this.searchField]);
                    this.recordsList = JSON.parse(JSON.stringify(storeResponse));
                    this.showList = true;
                }
                this.showSpinner = false;
            }), JSON.stringify(params));
        } else if (!this.hideRecentRecords) {
            params = {
                'ObjectName': this.objectApiName,
                ...(this.filter ? { 'filter': this.filter } : {})
            };

            helper.callServer(this, 'customLookupController_Lwc', 'fetchRecentLookUpValues', ((response) => {
                if (response.status === 'OK') {
                    const storeResponse = response.objectData.records || [];

                    if (storeResponse.length === 0) {
                        this.Message = 'No Result Found...';
                    } else {
                        this.Message = '';
                        storeResponse.forEach(val => val.showVal = val[this.searchField]);
                        this.recordsList = JSON.parse(JSON.stringify(storeResponse));
                    }
                    this.showList = true;
                }
                this.showSpinner = false;
            }), JSON.stringify(params));
        } else {
            this.Message = '';
            this.showList = false;
            this.showSpinner = false;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════════
    handleChange(event) {
        if (this.isDisabled) return;

        let searchTerm = event.target.value;

        if (this.searchField && this.searchField === 'Service_Period_Dates__c') {
            searchTerm = searchTerm.replace(/\b0/g, '');
        }

        this.searchString = searchTerm;
        this.showSpinner = true;
        // Clear any existing search timeout to implement debouncing
        window.clearTimeout(this.searchDelayTimeout);

        // Debounce: Only trigger search after user stops typing for DELAY ms
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.searchDelayTimeout = setTimeout(() => {
            this.searchHelper(this.searchString);
        }, DELAY);

        event.stopPropagation();
        event.preventDefault();
        Promise.resolve().then(() => this.reportValidity());
    }

    showoptions(evt) {
        if (this.isDisabled) return;

        this.showList = false;
        this.searchString = evt.target.value;
        this.showSpinner = true;
        this.searchHelper(this.searchString);
    }

    handleDivClick() {
        this.preventClosingOfSerachPanel = true;
    }

    handleCommit() {
        this.selectedRecordId = '';
        this.selectedRecord = {};
        this.Message = '';
        this.searchString = '';
        this.recordsList = undefined;
        this.showList = false;
        Promise.resolve().then(() => this.reportValidity());
        this.fireEvent();
    }

    handleSelect(event) {
        event.preventDefault();
        event.stopPropagation();
        this.preventClosingOfSerachPanel = true;

        const selId = event.currentTarget.dataset.id;
        const selectedRecord = this.recordsList?.filter(val => val.Id === selId)[0] || {};

        this.selectedRecord = JSON.parse(JSON.stringify(selectedRecord));
        this.selectedRecordId = selId;
        this.searchString = "";
        this.recordsList = [];
        this.showList = false;
        this._customErrorMessage = '';
        Promise.resolve().then(() => this.reportValidity());
        this.fireEvent();
    }

    handleInputBlur() {
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            if (!this.preventClosingOfSerachPanel) {
                this.recordsList = [];
                this.showList = false;
                if (!this.selectedRecord.Id) {
                    Promise.resolve().then(() => this.reportValidity());
                }
            }
            this.preventClosingOfSerachPanel = false;
        }, DELAY);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UTILITY METHODS
    // ═══════════════════════════════════════════════════════════════════════════
    fireEvent() {
        const selectedEvent = new CustomEvent('valueselected', {
            detail: {
                'record': this.selectedRecord,
                'objName': this.objectApiName,
                'fieldName': this.searchField,
                'uniqueKey': this.uniqueKey
            }
        });
        this.dispatchEvent(selectedEvent);
    }
}