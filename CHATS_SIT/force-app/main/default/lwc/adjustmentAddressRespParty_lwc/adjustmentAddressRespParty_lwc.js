import { LightningElement, api, track } from 'lwc';
import { abs_helper } from 'c/abstract_Component';

export default class AdjustmentAddressRespPartyLwc extends LightningElement {

    // ─── @api properties (migrated from Aura attributes) ───────────────────
    // adjustment is a mutable object – use @track so nested mutations are reactive
    @track _adjustment = {};

    @api
    get adjustment() {
        return this._adjustment;
    }
    set adjustment(value) {
        // Deep copy to ensure reactivity and avoid mutating parent's object
        if (value !== null && value !== undefined) {
            this._adjustment = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustment = {};
        }
    }

    @api pageMode = 'view';
    @api isEditableAddress = false;

    // address is a mutable object – use @track so nested mutations are reactive
    @track _address = {};
    
    @api
    get address() {
        return this._address;
    }
    set address(value) {
        // Deep copy to ensure reactivity and avoid mutating parent's object
        this._isParentSettingValue = true;
        try {
            this._address = value ? JSON.parse(JSON.stringify(value)) : {};
        } finally {
            this._isParentSettingValue = false;
        }
    }

    // ─── Lifecycle: connectedCallback (equivalent to Aura doInit) ───────────
    connectedCallback() {
        // Log for debugging (equivalent to Aura doInit console.log)
        console.log('resp addrs init' + JSON.stringify(this._address));
    }

    // ─── Computed mode getters ───────────────────────────────────────────────
    get isViewMode() {
        return this.pageMode === 'view' && !this.isEditableAddress;
    }

    get isEditMode() {
        return !this.isViewMode;
    }

    // ─── Zip extension error message (drives c-field-level-message_lwc) ─────
    @track zipExtErrorMessage = '';

    // ─── Loop Prevention Flags ──────────────────────────────────────────────────
    _isParentSettingValue = false;
    _lastFiredAddressKey = null;

    // ─── Public API method: called by parent to validate this page ──────────
    @api
    validateCurrentPage() {
        const pageValid = abs_helper.validateCurrentPage(this);
        const customValid = this.checkCustomValidations();
        return pageValid && customValid;
    }

    // ─── Handle changes to standard text input fields ────────────────────────
    handleAddressChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this._address = { ...this._address, [field]: value };
        this.fireAddressChange();
    }

    // ─── Handle State picklist change (c-multiselect-combobox) ──────────────
    // The multiselectCombobox fires 'select' event with detail: { payloadType, callingContext, payload: { value, oldValue } }
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

    // ─── Zip code blur handler – split zip if needed ─────────────────────────
    handleZipBlur() {
        this.divideZipCode();
        this.fireAddressChange();
    }

    // ─── divideZipCode (migrated from divideZipCodeHelper in Aura) ───────────
    divideZipCode() {
        const address = this._address;
        if (!address) {
            return;
        }

        let zipCode = address.ADR_ZIP_MAIN__c;
        let zipCodeExt = address.ADR_ZIP_EXTN__c;

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
            ADR_ZIP_MAIN__c: zipCode,
            ADR_ZIP_EXTN__c: zipCodeExt
        };
    }

    // ─── checkCustomValidations (migrated from Aura helper) ─────────────────
    checkCustomValidations() {
        const address = this._address;
        if (address) {
            const zipCodeExt = address.ADR_ZIP_EXTN__c;
            if (zipCodeExt && zipCodeExt.length > 4) {
                this.zipExtErrorMessage = 'Zip Code(Extn) cannot be greater than 4 characters';
                return false;
            }
            this.zipExtErrorMessage = '';
            return true;
        }
        return true;
    }

    /**
     * Public API method: returns the address object with ADR_STATE__c replaced
     * by the combobox's current internal value (the converted API value, e.g. 'CO').
     *
     * Called by the grandparent (adjustmentFlow_lwc) immediately before
     * upsertRespAddressList to ensure ADR_STATE__c is always an API value.
     *
     * Background: the address clone is seeded from the server which returns
     * toLabel(ADR_STATE__c) = 'Colorado'. The State combobox converts this to
     * the API value asynchronously after fetchPicklist completes. If the user
     * clicks Next before that async call returns, _address.ADR_STATE__c is still
     * 'Colorado'. Reading directly from the combobox here bypasses the async
     * race — the combobox's _value is always the API value once options load.
     *
     * @returns {Object} Deep copy of _address with ADR_STATE__c as API value
     */
    @api
    getAddressWithConvertedState() {
        const stateCmp = this.template.querySelector('[data-field="ADR_STATE__c"]');
        const stateValue = (stateCmp && stateCmp.value !== undefined && stateCmp.value !== null)
            ? stateCmp.value
            : this._address.ADR_STATE__c;
        return JSON.parse(JSON.stringify({ ...this._address, ADR_STATE__c: stateValue }));
    }

    // ─── Fire addresschange event to sync with parent (LWC two-way binding) ─
    // In Aura, child attribute changes auto-sync to parent. In LWC, we must
    // explicitly dispatch events so parent can update its own state.
    fireAddressChange() {
        if (this._isParentSettingValue) return;
        const currentKey = this._address ? JSON.stringify(this._address) : '';
        if (this._lastFiredAddressKey === currentKey) return;
        this._lastFiredAddressKey = currentKey;
        // BUG FIX: Ensure Responsible_Party_Client_Id__c is always present in the
        // fired payload. This field is a lookup (never rendered as an input), so it
        // can only exist on _address if it was set at init time and never overwritten.
        // Spread _address as-is — handleAddressChange already spreads INTO _address
        // (which retains the client ID from the initial address setter), so the field
        // is preserved throughout the edit lifecycle. This guard makes the intent
        // explicit and prevents accidental stripping in future refactors.
        const payload = { ...this._address };
        if (!payload.Responsible_Party_Client_Id__c && this._address.Responsible_Party_Client_Id__c) {
            payload.Responsible_Party_Client_Id__c = this._address.Responsible_Party_Client_Id__c;
        }
        this.dispatchEvent(
            new CustomEvent('respaddresschange', {
                detail: { respAddress: payload }
            })
        );
    }
}