import { LightningElement, api, track } from 'lwc';
import { abs_helper } from 'c/abstract_Component';

export default class AdjustmentAddressLwc extends LightningElement {

    // ═══════════════════════════════════════════════════════════════════════════
    // @api PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════════

    @api pageMode = 'view';
    @api provEditableAddress = false;

    // ═══════════════════════════════════════════════════════════════════════════
    // @track PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════════

    @track _adjustment = {};
    @track _address = {};
    @track zipExtErrorMessage = '';

    // ═══════════════════════════════════════════════════════════════════════════
    // PRIVATE PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════════

    _isParentSettingValue = false;
    _lastFiredAddressKey = null;

    // ═══════════════════════════════════════════════════════════════════════════
    // GETTERS / SETTERS
    // ═══════════════════════════════════════════════════════════════════════════

    @api
    get adjustment() {
        return this._adjustment;
    }
    set adjustment(value) {
        // Guard: only deep-copy when value is non-null/undefined; otherwise fall back to {}
        if (value !== null && value !== undefined) {
            this._adjustment = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustment = {};
        }
    }

    @api
    get address() {
        return this._address;
    }
    set address(value) {
        this._isParentSettingValue = true;
        try {
            // Guard: only deep-copy when value is a non-null object; otherwise fall back to {}
            if (value !== null && value !== undefined && typeof value === 'object') {
                this._address = JSON.parse(JSON.stringify(value));
            } else {
                this._address = {};
            }
        } finally {
            this._isParentSettingValue = false;
        }
    }

    get isViewMode() {
        return this.pageMode === 'view' && !this.provEditableAddress;
    }

    get isEditMode() {
        return !this.isViewMode;
    }
    
    connectedCallback() {
        this.divideZipCode();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PUBLIC METHODS (@api)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Called by parent to validate this page.
     * @returns {boolean} True if validations pass
     */
    @api
    validateCurrentPage() {
        const pageValid = abs_helper.validateCurrentPage(this);
        const customValid = this.checkCustomValidations();
        return pageValid && customValid;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Handle changes to standard text input fields.
     * @param {Event} event - Input change event
     */
    handleAddressChange(event) {
        const field = event?.target?.dataset?.field;
        const value = event?.target?.value;

        // Validate that field is a non-empty string before using it as a key
        if (!field || typeof field !== 'string' || field.trim() === '') {
            console.warn('handleAddressChange: missing or invalid data-field attribute on target element');
            return;
        }

        this._address = { ...this._address, [field]: value };
        this.fireAddressChange();
    }

    /**
     * Handle State picklist change (c-multiselect-combobox).
     * @param {CustomEvent} event - Select event from multiselect combobox
     */
    handleStateChange(event) {
        let value;
        if (event.detail && event.detail.payload && event.detail.payload.value !== undefined) {
            // Standard multiselectCombobox event structure
            value = event.detail.payload.value;
        } else if (event.detail && event.detail.value !== undefined) {
            // Fallback for direct value structure
            value = event.detail.value;
        } else {
            // Last resort fallback
            value = event.detail;
        }
        this._address = { ...this._address, ADR_STATE__c: value };
        this.fireAddressChange();
    }

    /**
     * Zip code blur handler – split zip if needed.
     */
    handleZipBlur() {
        this.divideZipCode();
        this.fireAddressChange();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Splits zip code into main (5 digits) and extension (4 digits).
     */
    divideZipCode() {
        const address = this._address;
        if (!address) {
            return;
        }

        // Null-safe reads: default to empty string so .includes() is always safe
        let zipCode = (address.ADR_ZIP_MAIN__c != null) ? String(address.ADR_ZIP_MAIN__c) : '';
        let zipCodeExt = (address.ADR_ZIP_EXTN__c != null) ? String(address.ADR_ZIP_EXTN__c) : '';

        // Remove hyphens and special characters
        if (zipCode && zipCode.includes('-')) {
            zipCode = zipCode.toLowerCase().replace(/[\W_]+/g, '');
        }
        if (zipCodeExt && zipCodeExt.includes('-')) {
            zipCodeExt = zipCodeExt.toLowerCase().replace(/[\W_]+/g, '');
        }

        if (zipCode && zipCode.length > 5) {
            // Split: first 5 to main, rest to extension (only if extension is empty)
            if (!zipCodeExt || zipCodeExt.length === 0) {
                zipCodeExt = zipCode.substring(5, zipCode.length);
            }
            zipCode = zipCode.substring(0, 5);
        } else if (zipCode && zipCode.length === 5) {
            // Set extension to '0000' if empty
            if (!zipCodeExt || zipCodeExt.length === 0) {
                zipCodeExt = '0000';
            }
        }

        this._address = {
            ...this._address,
            ADR_ZIP_MAIN__c: zipCode || null,
            ADR_ZIP_EXTN__c: zipCodeExt || null
        };
    }

    /**
     * Validates custom business rules for the address.
     * @returns {boolean} True if validations pass
     */
    checkCustomValidations() {
        const address = this._address;
        if (address) {
            const zipCodeExt = address.ADR_ZIP_EXTN__c;
            if (zipCodeExt && zipCodeExt.length > 4) {
                this.zipExtErrorMessage = 'Zip Code(Extn) cannot be greater than 4 characters';
                return false;
            } else {
                this.zipExtErrorMessage = '';
                return true;
            }
        }
        return true;
    }

    /**
     * Fires addresschange event to notify parent of address updates.
     */
    fireAddressChange() {
        if (this._isParentSettingValue) return;

        const currentKey = this._address ? JSON.stringify(this._address) : '';
        if (this._lastFiredAddressKey === currentKey) return;

        this._lastFiredAddressKey = currentKey;
        this.dispatchEvent(
            new CustomEvent('addresschange', {
                detail: { address: this._address }
            })
        );
    }
}