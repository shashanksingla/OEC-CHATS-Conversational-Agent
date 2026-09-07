import { LightningElement, api, track } from 'lwc';
import fetchPicklist from '@salesforce/apex/APXInputPicklistCtrl.getPicklistValues';
import getPicklistValues from '@salesforce/apex/dynamicPicklistApexController.getPicklistValues';
import { helper } from 'c/generic_Utilities';


export default class multiSelectCombobox extends LightningElement {

    // Internal tracked values for reactivity
    @track _options_internal;
    @track _hiddenValues_internal;
    @track _value;
    @track _optionData = [];
    @track _searchString;
    @track _message;
    @track _inputPlaceHolder = 'Select an Option';
    @track _showDropdown = false;
    @track _showSpinner = false;
    @track _allOptions = [];
    @track _valueLabel; // for readonly picklist
    @track _selectedValue; // for checkbox picklist - internal tracking
    @track _isReset = false; // Flag to skip reportValidity during reset (matches V1 isReset)
    @api alreadyHasValues;
    @api label;
    @api minChar = 2;
    @api disabled = false;
    @api object;
    @api field;
    @api showNone;
    @api multiSelect;
    @api required;
    @api behaviorType = 'multiselectWithSearch';
    @api methodName;
    @api picklistType;
    @api userRestriction;
    @api valueColName;
    @api keyColName;
    @api fieldName; //for dynamic picklist
    @api makeNoAsDefault = false; //for checkbox picklist
    @api width;
    @api labelBold;
    @api fieldLevelErrorMessage;
    @api customErrorMessage = '';
    @api uniqueKey = '1';

    // ==== NEW FEATURES FROM AURA inputPicklist ====
    @api labelClass = ''; // CSS class for label styling
    @api hideLabel = false; // Option to hide the label
    @api showSelect = false; // Show "--Select--" instead of "--None--"
    @api matchWithLabel = false; // Match value with label instead of value field - when true, incoming value is a label, match by label but store API value
    @api hideSpinner = false; // Hide spinner component
    @api needFocus = false; // Auto-focus on validation failure

    // Internal state variables (not tracked - primitives are reactive by default in modern LWC)
    _oldValue;
    _valid;
    _rendered = false;
    _isSettingPicklistValues = false; // Flag to prevent infinite loop
    _mustValues = [];
    _mainStyle;
    _hasSharedUpdatesOnce = false; // Flag to track if shareUpdates has been called once post-load for matchWithLabel
    _isUserAction = false; // Flag to track if current action is from user interaction

    // ============== GETTER/SETTERS FOR @api PROPERTIES ==============

    /**
     * value - The selected value(s). For multiSelect, values are semicolon-separated.
     * Uses internal _value with getter/setter to ensure reactivity when parent updates.
     */

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        const oldVal = this._value;
        this._value = val;
        // Only re-process if value actually changed, component is rendered, 
        // and we're not already inside setPicklistValues (to avoid infinite loop)
        if (this._rendered && oldVal !== val && !this._isSettingPicklistValues) {
            this.setPicklistValues();
        }
    }
    /**
     * options - The picklist options array. Each option should have {label, value}.
     * When set from parent, triggers re-initialization if component is already rendered.
     */
    @api
    get options() {
        return this._options_internal;
    }
    set options(items) {
        const oldOptions = this._options_internal || [];
        this._options_internal = items || [];

        // Only re-init if options actually changed and component is rendered
        if (this._rendered && JSON.stringify(oldOptions) !== JSON.stringify(items)) {
            this.initActions();
        }
    }

    /**
     * hiddenValues - Array of values to hide from the picklist.
     * When set from parent, triggers re-initialization if component is already rendered.
     */
    @api
    get hiddenValues() {
        return this._hiddenValues_internal;
    }
    set hiddenValues(items) {
        const oldHidden = this._hiddenValues_internal || [];
        this._hiddenValues_internal = items || [];
        // Only re-init if hiddenValues actually changed and component is rendered
        if (this._rendered && JSON.stringify(oldHidden) !== JSON.stringify(items)) {
            this.initActions();
        }
    }

    /**
     * mustValues - Array of values that must always be selected (cannot be deselected).
     */
    @api
    get mustValues() {
        return this._mustValues;
    }
    set mustValues(items) {
        const oldMustVals = this._mustValues || [];
        this._mustValues = items || [];
        if (this._rendered && JSON.stringify(oldMustVals) !== JSON.stringify(items)) {
            this.setPicklistValues();
        }
    }

    /**
     * selectedValue - For checkbox picklist behavior type, the selected 'yes'/'no' value.
     */
    @api
    get selectedValue() {
        return this._selectedValue;
    }
    set selectedValue(val) {
        this._selectedValue = val;
    }

    // ============== COMPUTED GETTERS FOR TEMPLATE ==============

    get optionData() {
        return this._optionData || [];
    }

    get searchString() {
        return this._searchString;
    }

    get message() {
        return this._message;
    }

    get inputPlaceHolder() {
        return this._inputPlaceHolder;
    }

    get showDropdown() {
        return this._showDropdown;
    }

    get valueLabel() {
        return this._valueLabel;
    }

    get mainStyle() {
        return this._mainStyle;
    }

    get labelStyle() {
        return this.labelBold ? 'font-weight:bold;' : '';
    }

    get computedLabelClass() {
        let baseClass = 'slds-form-element__label';
        return this.labelClass ? `${baseClass} ${this.labelClass}` : baseClass;
    }

    get shouldShowLabel() {
        return this.label && !this.hideLabel;
    }

    get isPicklist() {
        return this.behaviorType == 'picklist';
    }

    get isCheckbox() {
        return this.behaviorType == 'checkbox';
    }

    get isDynamic() {
        return this.behaviorType == 'dynamic';
    }

    get isCheckboxPicklist() {
        return this.behaviorType == 'checkboxPicklist';
    }

    get isReadOnly() {
        return this.behaviorType == 'readonly';
    }

    get isRadioGroup() {
        return this.behaviorType == 'radioGroup';
    }

    get isDisabled() {
        return this.disabled || !this._optionData || this._optionData.length == 0;
    }

    get arevaluesSelected() {
        return this.multiSelect && this._optionData && this._optionData.findIndex(val => val.selected == true) > -1;
    }

    get selectedItems() {
        if (!this._optionData) {
            return [];
        }
        // Create deep copy to avoid mutation
        const optionDataCopy = JSON.parse(JSON.stringify(this._optionData));
        return optionDataCopy.filter(val => val.selected == true) || [];
    }

    // ============== LIFECYCLE HOOKS ==============

    connectedCallback() {
        this.initActions();
    }

    renderedCallback() {
        this._rendered = true;
    }

    // ============== PUBLIC API METHODS ==============

    @api
    clearSelectedValue() {
        this._isReset = true;
        this._value = '';
        // Safely update optionData
        if (this._optionData && this._optionData.length > 0) {
            const updatedOptions = this._optionData.map(opt => ({
                ...opt,
                selected: false
            }));
            this._optionData = updatedOptions;
        }
        if (this.multiSelect) {
            this._inputPlaceHolder = this.showNone ? '-- None --' : '0 Option(s) Selected';
        } else {
            this._inputPlaceHolder = 'Select an Option';
        }
        this._searchString = '';
        this.shareUpdates();
        this._isReset = false;
    }

    @api
    reportValidity() {
        const searchCmp = this.template.querySelector(".c_multiCombobox");
        if (!searchCmp) {
            this._valid = true;
            return;
        }
        let fieldLevelErrorMessage = this.fieldLevelErrorMessage;
        if (!fieldLevelErrorMessage) {
            fieldLevelErrorMessage = this.multiSelect ? 'Please select at least one option.' : 'Please enter a value';
        }
        this._valid = true;
        const currentValue = this._value;
        // Safely convert to string for split operations
        const currentValueStr = this.normalizeValueToString(currentValue);

        if (this.required && !this.isCheckbox && (
            (this.multiSelect && currentValueStr.split(';').filter(item => item.trim() !== '').length == 0) ||
            (!this.multiSelect && !this.isCheckboxPicklist && !currentValue)
        )) {
            searchCmp.setCustomValidity(fieldLevelErrorMessage);
            this._valid = false;
        } else if (this.required && this.isCheckbox && (
            (this.multiSelect && String(currentValue).split(',').filter(item => item.trim() !== '').length == 0) ||
            (!this.multiSelect && !this.isCheckboxPicklist && !currentValue)
        )) {
            searchCmp.setCustomValidity(fieldLevelErrorMessage);
            this._valid = false;
        } else if (this.required && this.isCheckboxPicklist && (this._selectedValue == '' || this._selectedValue == null)) {
            searchCmp.setCustomValidity(fieldLevelErrorMessage);
            this._valid = false;
        } else {
            searchCmp.setCustomValidity("");
        }

        if (this.customErrorMessage) {
            searchCmp.setCustomValidity(this.customErrorMessage);
            this._valid = false;
        }
        searchCmp.reportValidity();
    }

    @api
    checkValidity() {
        return this._valid;
    }

    @api
    focus() {
        const inputElement = this.template.querySelector('.c_multiCombobox');
        if (inputElement && typeof inputElement.focus == 'function') {
            inputElement.focus();
        }
    }

    @api
    showHelpMessageIfInvalid() {
        this.reportValidity();
        if (!this._valid && this.needFocus) {
            this.focus();
        }
        return { valid: this._valid };
    }

    // ============== INITIALIZATION ==============

    initActions() {
        if (this.isCheckboxPicklist) {
            this._options_internal = [
                { label: 'No', value: 'no' },
                { label: 'Yes', value: 'yes' }
            ];
        }
        if (this.alreadyHasValues) {
            this.setPicklistValues();
        } else {
            this.fetchPicklistValues();
        }
        this._mainStyle = 'width:' + this.width;
    }

    // ============== PICKLIST FETCHING ==============

    fetchPicklistValues() {
        this._showSpinner = true;

        if (this.isDynamic) {
            let picklistMap = {};
            if (this.picklistType == "GlobalPicklist") {
                picklistMap = { 'objectName': this.object, 'fieldName': this.field };
                this.getDynamicPicklistValues(picklistMap);
            } else if (this.picklistType == "TableFetchPicklist") {
                picklistMap = {
                    'keyColName': this.keyColName,
                    'keyValueName': this.valueColName,
                    'method': this.methodName,
                    'userRestriction': this.userRestriction
                };
                this.getDynamicPicklistValues(picklistMap);
            }
        } else if (this.isCheckboxPicklist) {
            this._showSpinner = false;
            this.setPicklistValues();
        } else {
            fetchPicklist({ 'obj': this.object, 'fld': this.field })
                .then(result => {
                    this._showSpinner = false;
                    if (result) {
                        this.processPicklistResult(result);
                    }
                })
                .catch(error => {
                    this._showSpinner = false;
                    helper.showToast(this, 'Error!', error.message, 'error', '');
                });
        }
    }

    getDynamicPicklistValues(keyParams) {
        getPicklistValues({ 'picklistType': this.picklistType, 'keyParams': keyParams })
            .then(result => {
                this._showSpinner = false;
                if (result) {
                    this.processPicklistResult(result);
                }
            })
            .catch(error => {
                this._showSpinner = false;
                helper.showToast(this, 'Error!', error.message, 'error', '');
            });
    }

    /**
     * Common method to process picklist results from both fetch methods.
     * Ensures consistent handling of options, mustValues, hiddenValues, and matchWithLabel.
     */
    processPicklistResult(result) {
        const options_internal = [];
        // Store all options before filtering
        this._allOptions = JSON.parse(JSON.stringify(result));

        const mustVals = this._mustValues || [];
        const hiddenVals = this._hiddenValues_internal || [];

        result.forEach(element => {
            element.optionClass = 'slds-listbox__option';
            element.required = mustVals.includes(element.value);
            if (element.required) {
                element.optionClass = 'no_pointer slds-listbox__option';
            }
            if (!hiddenVals.includes(element.value)) {
                options_internal.push(element);
            }
        });

        // Handle default values
        const defaultValues = result.filter(val => val.isDefaultValue).map(val => val.value);
        if (!this._value && defaultValues.length > 0) {
            this._value = defaultValues.join(';');
        }

        // Set options_internal BEFORE matchWithLabel check so findValueByLabel can use it
        this._options_internal = options_internal;
        this.setPicklistValues();
    }

    // ============== CORE VALUE PROCESSING ==============

    /**
     * Main method to synchronize internal state with the current value.
     * Updates optionData, inputPlaceHolder, searchString based on _value.
     */
    setPicklistValues() {
        // Set flag to prevent infinite loop when we modify _value at the end
        this._isSettingPicklistValues = true;

        try {
            this._showDropdown = false;
            let valueSet = [];

            // Handle checkboxPicklist behavior
            if (this.isCheckboxPicklist) {
                if (!this._value && this.makeNoAsDefault == true) {
                    this._selectedValue = 'no';
                } else {
                    this._selectedValue = (this._value == true || this._value == 'true') ? 'yes' : 'no';
                }
                valueSet = this._selectedValue ? this._selectedValue.split(';') : [];
            }
            // Handle readonly behavior
            else if (this.isReadOnly) {
                if (this._options_internal && this._options_internal.length > 0) {
                    if (this._value == null || this._value == undefined) {
                        const defaultOption = this._options_internal.find(v => v.isDefaultValue);
                        this._value = defaultOption ? defaultOption.value : null;
                    }
                    const matchedOption = this._options_internal.find(element => element.value == this._value);
                    this._valueLabel = matchedOption ? matchedOption.label : '';
                }
                return; // Early return for readonly
            }
            // Handle standard behavior
            else {
                const normalizedValue = this.normalizeValueToString(this._value);
                valueSet = normalizedValue ? normalizedValue.split(';') : [];
            }

            // Create deep copy of options to avoid mutation
            let optionData = this._options_internal ? JSON.parse(JSON.stringify(this._options_internal)) : [];

            // When matchWithLabel is true, convert incoming label values to API values
            // This handles the case where parent passes labels (e.g., "Care Not Provided") 
            // but we need to match and store API values
            if (this.matchWithLabel && valueSet.length > 0 && optionData.length > 0) {
                valueSet = valueSet.map(val => {
                    // Check if val is already an API value (exists in options)
                    const existsAsValue = optionData.some(opt => opt.value == val);
                    if (existsAsValue) {
                        return val; // Already an API value, keep it
                    }
                    // Try to find by label match
                    const matchedByLabel = optionData.find(
                        opt => opt.label && opt.label.toLowerCase() == val.toLowerCase()
                    );
                    return matchedByLabel ? matchedByLabel.value : val;
                }).filter(val => val); // Remove empty values
            }

            // Merge mustValues into valueSet
            const mustVals = this._mustValues || [];
            valueSet = [...new Set([...valueSet, ...mustVals])];

            let searchString = '';
            let count = 0;
            const hiddenVals = this._hiddenValues_internal || [];

            // Process each option
            let i = 0;
            while (i < optionData.length) {
                const optionItr = optionData[i];

                if (!hiddenVals.includes(optionItr.value)) {
                    optionItr.optionClass = 'slds-listbox__option';
                    optionItr.iconClass = 'slds-m-around_xx-small';
                    optionItr.isVisible = true; // Default to visible

                    if (mustVals.includes(optionItr.value)) {
                        optionItr.required = true;
                        optionItr.optionClass = 'no_pointer slds-listbox__option';
                        optionItr.iconClass = 'slds-m-around_xx-small removeCross';
                    }

                    if (this.multiSelect) {
                        optionItr.selected = valueSet.includes(optionItr.value);
                        if (optionItr.selected) {
                            count++;
                        }
                    } else {
                        if (optionItr.value == valueSet[0]) {
                            searchString = optionItr.label;
                            optionItr.selected = true;
                            count++;
                        } else {
                            optionItr.selected = false;
                        }
                    }
                    i++;
                } else {
                    optionData.splice(i, 1);
                }
            }

            // Update placeholder and searchString
            if (this.multiSelect) {
                this._inputPlaceHolder = (count == 0 && this.showNone) ? '-- None --' : count + ' Option(s) Selected';
            } else {
                this._inputPlaceHolder = searchString || 'Select an Option';
                this._searchString = searchString;
            }

            if (count == 0) {
                this._searchString = '';
            }

            // Add showSelect or showNone option at the beginning
            if (this.showSelect) {
                optionData.unshift({
                    'label': '--Select--',
                    'value': '',
                    'isVisible': true
                });
            } else if (this.showNone) {
                optionData.unshift({
                    'label': '--None--',
                    'value': '',
                    'isVisible': true
                });
            }

            // Update optionData (triggers reactivity)
            this._optionData = optionData;

            // Update _value to normalized form (joined valueSet)
            this._value = valueSet.join(';');
        } finally {
            // Always reset the flag
            this._isSettingPicklistValues = false;
        }
        // Handle matchWithLabel: convert label to value if needed
        if (this.matchWithLabel) {
            if (this._value) {
                this._value = this.findValueByLabel(this._value);
            }
            // For matchWithLabel, call shareUpdates ONCE post-load (not during user actions)
            // This notifies parent of the converted value after initial load
            if (!this._hasSharedUpdatesOnce && !this._isUserAction) {
                this._hasSharedUpdatesOnce = true;
                this.shareUpdates();
            }
        }
    }

    // ============== EVENT HANDLERS ==============

    filterOptions(event) {
        this._searchString = event.target.value;

        if (this._searchString && this._searchString.length > 0) {
            this._message = '';

            if (this._searchString.length >= this.minChar) {
                let noMatch = true;
                // Create new array to trigger reactivity
                const updatedOptions = this._optionData.map(option => {
                    const labelMatch = option.label && option.label.toLowerCase().trim().includes(this._searchString.toLowerCase().trim());
                    const valueMatch = option.value && option.value.toLowerCase().trim().includes(this._searchString.toLowerCase().trim());
                    const isVisible = labelMatch || valueMatch;

                    if (isVisible) {
                        noMatch = false;
                    }

                    return {
                        ...option,
                        isVisible: isVisible
                    };
                });

                this._optionData = updatedOptions;

                if (noMatch) {
                    this._message = "No results found for '" + this._searchString + "'";
                }
            }
            this._showDropdown = true;
        } else {
            this._showDropdown = false;
        }
    }

    handleSelect(event) {
        this._oldValue = this._value;
        this._isUserAction = true; // Mark as user action to prevent double shareUpdates

        if (this.isPicklist || this.isDynamic || this.isRadioGroup) {
            this._value = event.detail.value;
            this.setPicklistValues();
            this.shareUpdates();
        } else if (this.isCheckboxPicklist) {
            this._selectedValue = event.detail.value;
            this._value = (this._selectedValue == 'yes');
            this.shareUpdates();
        } else if (this.isCheckbox) {
            this._value = event.detail.value;
            const valueSet = this.value.toString().split(',');

            // Create new array to trigger reactivity
            const updatedOptions = this._optionData.map(option => ({
                ...option,
                selected: valueSet.includes(option.value)
            }));
            this._optionData = updatedOptions;
            this.reportValidity();
        }

        this._isUserAction = false; // Reset flag after action completes
    }

    selectItem(event) {
        this._isUserAction = true; // Mark as user action
        const selectedVal = event.currentTarget.dataset.id;

        // Create deep copy to avoid mutation
        let options_internal = this._optionData ? JSON.parse(JSON.stringify(this._optionData)) : [];

        if (selectedVal) {
            const index = options_internal.findIndex(val => val.value == selectedVal);

            if (index == -1) {
                return; // Option not found
            }

            if (this.multiSelect) {
                options_internal[index].selected = !options_internal[index].selected;

                const normalizedValue = this.normalizeValueToString(this._value);
                let valueSet = normalizedValue ? normalizedValue.split(';') : [];
                if (valueSet.includes(selectedVal)) {
                    valueSet = valueSet.filter(val => val !== selectedVal);
                } else {
                    valueSet.push(options_internal[index].value);
                }
                this._value = valueSet.join(';');
            } else {
                // Single select - update all options
                options_internal = options_internal.map(opt => ({
                    ...opt,
                    selected: opt.value == selectedVal
                }));
                this._value = selectedVal;
                this._searchString = options_internal[index].label;
            }

            this._optionData = options_internal;

            const count = options_internal.filter(val => val.selected == true).length;

            if (this.multiSelect) {
                this._inputPlaceHolder = (count == 0 && this.showNone) ? '-- None --' : count + ' Option(s) Selected';
                event.preventDefault();
            } else {
                this._showDropdown = false;
            }

            if (count == 0) {
                this._searchString = '';
            }
        } else {
            // Clear selection (e.g., --None-- selected)
            options_internal = options_internal.map(opt => ({
                ...opt,
                selected: false
            }));
            this._optionData = options_internal;
            this._searchString = '';
            this._value = '';
        }

        this.reportValidity();
    }

    showOptions() {
        if (this.disabled == false && this._options_internal) {
            this._message = '';
            this._searchString = '';
            this._inputPlaceHolder = 'Type to search...';

            // Create new array with all options visible
            const updatedOptions = this._optionData.map(opt => ({
                ...opt,
                isVisible: true
            }));

            if (updatedOptions.length > 0) {
                this._showDropdown = true;
            }
            this._optionData = updatedOptions;
        }
    }

    blurEvent() {
        const count = this._optionData ? this._optionData.filter(val => val.selected == true).length : 0;
        this._showDropdown = false;

        if (this.multiSelect) {
            this._inputPlaceHolder = (count == 0 && this.showNone) ? '-- None --' : count + ' Option(s) Selected';
        } else {
            const matchedOption = this._optionData ? this._optionData.find(val => val.value == this._value) : null;
            if (matchedOption) {
                this._inputPlaceHolder = matchedOption.label;
                this._searchString = matchedOption.label;
            }
        }

        if (count == 0) {
            this._searchString = '';
        }

        // For multiselect with matchWithLabel, blurEvent is the final event that fires
        // shareUpdates should only be called here (not in selectItem) to avoid double calls
        this.shareUpdates();
        this._isUserAction = false; // Reset flag after blur completes
    }

    handleItemRemove(evt) {
        this._isUserAction = true; // Mark as user action
        const removedValue = evt.target.dataset.name;

        if (!this._optionData) {
            return;
        }

        // Create deep copy
        const optionData = JSON.parse(JSON.stringify(this._optionData));
        const optionIndex = optionData.findIndex(val => val.value == removedValue);

        if (optionIndex !== -1 && optionData[optionIndex] && !optionData[optionIndex].required) {
            optionData[optionIndex].selected = false;
            this._optionData = optionData;

            const normalizedValue = this.normalizeValueToString(this._value);
            let valueSet = normalizedValue ? normalizedValue.split(';').filter(val => val != removedValue) : [];
            this._value = valueSet.join(';');
        }
        this.blurEvent();
    }

    // ============== HELPER METHODS ==============

    /**
     * Dispatches events to notify parent components of value changes.
     * MATCHES ORIGINAL V1 BEHAVIOR:
     * - Called ONLY from user interactions: clearSelectedValue(), handleSelect(), blurEvent()
     * - NOT called from setPicklistValues() or getter/setters
     * - Dispatches 'valuechange' for checkboxPicklist, 'select' for all others
     */
    shareUpdates() {
        //console.log('fired from here');
        if (this.isCheckboxPicklist) {
            // Original V1 event structure for checkboxPicklist
            const valueChangeEvent = new CustomEvent('valuechange', {
                detail: {
                    'value': this._value,
                    'oldValue': this._oldValue,
                    'field': this.field,
                    'fieldName': this.fieldName,
                    'object': this.object,
                    'selectedValue': this._selectedValue,
                    'uniqueKey': this.uniqueKey
                }
            });
            this.dispatchEvent(valueChangeEvent);
        } else {
            // Original V1 event structure for all other behavior types
            let callingContext = '';
            if (this.isDynamic) {
                callingContext = this.fieldName;
            } else {
                callingContext = this.object + '_' + this.field;
            }
            this.dispatchEvent(new CustomEvent('select', {
                detail: {
                    'payloadType': this.multiSelect == true ? 'multi-select' : 'uni-select',
                    'callingContext': callingContext,
                    'field': this.field,
                    'fieldName': this.fieldName,
                    'object': this.object,
                    'matchWithLabel': this.matchWithLabel,
                    'uniqueKey': this.uniqueKey,
                    'payload': {
                        'value': this._value,
                        'oldValue': this._oldValue
                    }
                },
                bubbles: true,
                composed: true
            }));
        }
        // Match V1 behavior: skip reportValidity during reset
        if (!this._isReset) {
            this.reportValidity();
        }
    }

    /**
     * Normalizes the value to a string for safe split operations.
     * Handles arrays (joins with semicolon), null/undefined (returns empty string),
     * and other types (converts to string).
     * @param {*} val - The value to normalize
     * @returns {String} A string representation safe for split operations
     */
    normalizeValueToString(val) {
        if (val == null || val == undefined) {
            return '';
        }
        if (Array.isArray(val)) {
            return val.join(';');
        }
        if (typeof val === 'string') {
            return val;
        }
        // For booleans, numbers, or other types
        return String(val);
    }

    /**
     * Finds the actual value for a given label when matchWithLabel is enabled.
     * @param {String} labelToMatch - The label to search for
     * @returns {String} The corresponding value, or the original label if not found
     */
    /**
     * Converts label(s) to API value(s) when matchWithLabel is enabled.
     * Handles both single values and semicolon-separated multiple values.
     * @param {String} labelOrLabels - Single label or semicolon-separated labels
     * @returns {String} Corresponding API value(s), semicolon-separated if multiple
     */
    findValueByLabel(labelOrLabels) {
        if (!this._options_internal || !labelOrLabels) {
            return labelOrLabels;
        }

        // Split by semicolon to handle multiple values
        let labels = labelOrLabels.split(';').filter(l => l.trim() !== '');

        let values = labels.map(label => {
            // First check if it's already an API value
            let existsAsValue = this._options_internal.some(opt => opt.value == label);
            if (existsAsValue) return label;

            // Try to find by label match (case-insensitive)
            let matchedOption = this._options_internal.find(
                opt => opt.label && opt.label.toLowerCase() == label.toLowerCase()
            );
            return matchedOption ? matchedOption.value : label;
        });

        return values.join(';');
    }
}