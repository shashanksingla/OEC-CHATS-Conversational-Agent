import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import adjustment_error_otherRecoveries from '@salesforce/label/c.adjustment_error_otherRecoveries';

export default class AdjustmentFlow_AdjustmentInformation_lwc extends LightningElement {

    // ─── Labels ──────────────────────────────────────────────────────────────────
    label = {
        adjustment_error_otherRecoveries
    };

    // ─── @api Properties (primitives — no getter/setter needed) ─────────────────

    @api recordId;
    @api isEditableAddress = false;
    @api pageMode = 'view';
    @api isCurrentPageValid = false;
    @api messageType = '';

    // ─── Internal @track State (mutable copies of @api inputs) ──────────────────

    @track _adjustment = {
        sObjectType: 'T_ADJMT__c',
        attributes: { type: 'T_ADJMT__c' },
        CDE_AGNST_ADJMT__c: '',
        IDN_PROVR__c: '',
        IDN_CASE__c: '',
        Recovery_Initiative__c: ''
    };
    @track _address = {};
    @track _responsiblePartyList = [];
    @track _responsibleParties = [];
    @track _responsiblePartiesAddressList = [];
    @track _responsiblePartiesAddressListClone = [];
    @track _adjustmentReasonOptions = [];
    @track _recordError = [];
    @track _selectedLookUpRecord = {};
    @track _pageMessages = [];
    @track showClassificationTypeModal = false;

    // ─── Loop Prevention Flags ──────────────────────────────────────────────────
    _isParentSettingValue = false;
    _lastFiredAdjustment = null;
    _lastFiredAddress = null;
    _lastFiredResponsiblePartyListLength = null;

    // ─── @api Getter / Setter Pairs ──────────────────────────────────────────────

    /**
     * adjustment – deep-copies incoming value into internal state so mutations
     * never touch the parent-owned reference.
     */
    @api
    get adjustment() {
        return this._adjustment;
    }
    set adjustment(value) {
        this._isParentSettingValue = true;
        try {
            // Use JSON deep copy to ensure full reactivity for nested properties
            this._adjustment = value
                ? JSON.parse(JSON.stringify(value))
                : {
                    sObjectType: 'T_ADJMT__c',
                    attributes: { type: 'T_ADJMT__c' },
                    CDE_AGNST_ADJMT__c: '',
                    IDN_PROVR__c: '',
                    IDN_CASE__c: '',
                    Recovery_Initiative__c: ''
                };
        } finally {
            this._isParentSettingValue = false;
        }
    }

    /**
     * address – deep-copies incoming value into internal state.
     */
    @api
    get address() {
        return this._address;
    }
    set address(value) {
        this._isParentSettingValue = true;
        try {
            // Use JSON deep copy to ensure full reactivity for nested properties
            // Return empty object instead of null to prevent template errors when accessing properties
            this._address = value ? JSON.parse(JSON.stringify(value)) : {};
        } finally {
            this._isParentSettingValue = false;
        }
    }

    /**
     * responsiblePartyList – deep-copies incoming array into internal state.
     */
    @api
    get responsiblePartyList() {
        return this._responsiblePartyList;
    }
    set responsiblePartyList(value) {
        this._isParentSettingValue = true;
        try {
            // Use JSON deep copy to ensure full reactivity for nested properties
            this._responsiblePartyList = value ? JSON.parse(JSON.stringify(value)) : [];
        } finally {
            this._isParentSettingValue = false;
        }
    }
    /**
     * responsibleParties – deep-copies incoming array into internal state.
     */
    @api
    get responsibleParties() {
        return this._responsibleParties;
    }
    set responsibleParties(value) {
        this._responsibleParties = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : [];
    }

    /**
     * responsiblePartiesAddressList – deep-copies incoming array into internal state.
     */
    @api
    get responsiblePartiesAddressList() {
        return this._responsiblePartiesAddressList;
    }
    set responsiblePartiesAddressList(value) {
        this._responsiblePartiesAddressList = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : [];
    }

    /**
     * responsiblePartiesAddressListClone – deep-copies incoming array into internal state.
     */
    @api
    get responsiblePartiesAddressListClone() {
        return this._responsiblePartiesAddressListClone;
    }
    set responsiblePartiesAddressListClone(value) {
        this._responsiblePartiesAddressListClone = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : [];
    }

    /**
     * adjustmentReasonOptions – deep-copies incoming array into internal state.
     */
    @api
    get adjustmentReasonOptions() {
        return this._adjustmentReasonOptions;
    }
    set adjustmentReasonOptions(value) {
        this._adjustmentReasonOptions = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : [];
    }

    /**
     * recordError – deep-copies incoming array into internal state.
     */
    @api
    get recordError() {
        return this._recordError;
    }
    set recordError(value) {
        this._recordError = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : [];
    }

    /**
     * selectedLookUpRecord – deep-copies incoming object into internal state.
     */
    @api
    get selectedLookUpRecord() {
        return this._selectedLookUpRecord;
    }
    set selectedLookUpRecord(value) {
        this._selectedLookUpRecord = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : {};
    }

    /**
     * pageMessages – deep-copies incoming array into internal state.
     */
    @api
    get pageMessages() {
        return this._pageMessages;
    }
    set pageMessages(value) {
        this._pageMessages = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : [];
    }

    // ─── Computed Properties (Getters) ───────────────────────────────────────────

    /**
     * Returns true when the component is in view mode.
     */
    get isViewMode() {
        return this.pageMode === 'view';
    }

    /**
     * Returns true when the adjustment type is 'Recovery'.
     */
    get isRecoveryType() {
        return this._adjustment?.CDE_TYPE_ADJMT__c === 'Recovery';
    }

    /**
     * Returns true when adjustment is Recovery type AND has a case ID.
     */
    get isRecoveryWithCase() {
        return this.isRecoveryType && this._adjustment?.IDN_CASE__c;
    }

    /**
     * Returns true when there is more than one adjustment reason option
     * (i.e., the section should be shown).
     */
    get showAdjustmentReasonSection() {
        return this._adjustmentReasonOptions?.length !== 1;
    }

    /**
     * Returns true when Reason for Edit field is required
     * (status is 'Calculation Complete').
     */
    get isReasonForEditRequired() {
        return this._adjustment?.CDE_STATUS_ADJMT__c === 'Calculation Complete';
    }

    /**
     * Mirrors Aura parent expression:
     *   provEditableAddress="{!(v.adjustment.CDE_STATUS_ADJMT__c=='Calculation Complete')}"
     * When the adjustment status is 'Calculation Complete', the address section remains
     * editable even while pageMode is 'view'.
     */
    get isProvEditableAddress() {
        return this._adjustment?.CDE_STATUS_ADJMT__c === 'Calculation Complete';
    }

    /**
     * Returns true when Recovery Initiative field is required
     * (classification type is '1').
     */
    get isRecoveryInitiativeRequired() {
        return this._adjustment?.CDE_TYPE_CLSFN__c === '1';
    }

    // ─── Public API Methods ───────────────────────────────────────────────────────

    /**
     * Validates all child components and this component's fields.
     * Equivalent to callValidateCurrentPage / handleValidateCurrentPage in Aura.
     * @returns {boolean}
     */
    @api
    callValidateCurrentPage() {
        let resultFromAdjustmentAddress = true;
        let resultFromAdjustmentResponsibleParty = true;
        let resultFromAdjustmentResponsiblePartyAddr = true;

        // 1. Validate adjustmentAddress child if present
        const adjustmentAddressCmp = this.template.querySelector('[data-id="adjustmentAddress"]');
        if (adjustmentAddressCmp) {
            resultFromAdjustmentAddress = adjustmentAddressCmp.validateCurrentPage();
        }
        // 2. Validate this component's own fields via abs_helper
        const resultFromThisComponent = abs_helper.validateCurrentPage(this);

        // 3. Validate adjustmentResponsibleParty if Recovery type with case
        if (this.isRecoveryWithCase) {
            const childRows = this.template.querySelectorAll('c-adjustment-flow_-responsible-party-flow_lwc');
            if (childRows) {


                childRows.forEach(row => {
                    let childValidity = row.validateCurrentPage();
                    console.log('childValidity' + childValidity);
                    if (!childValidity) {
                        resultFromAdjustmentResponsibleParty = false;
                    }
                });
            }
            // 4. Validate each adjustmentAddressRespParty child (can be an array)
            const adjustmentAddressRespPartyCmps = this.template.querySelectorAll('[data-id="adjustmentAddressRespParty"]');
            if (adjustmentAddressRespPartyCmps && adjustmentAddressRespPartyCmps.length > 0) {
                adjustmentAddressRespPartyCmps.forEach(cmp => {
                    const validSoFar = cmp.validateCurrentPage();
                    if (!validSoFar) {
                        resultFromAdjustmentResponsiblePartyAddr = false;
                    }
                });
            }
            // Delegate validation to each child row component
        }

        return (
            resultFromAdjustmentAddress &&
            resultFromAdjustmentResponsibleParty &&
            resultFromThisComponent &&
            resultFromAdjustmentResponsiblePartyAddr
        );
    }
    connectedCallback() {
        this._updateResponsiblePartiesAddressList();
    }
    checkCustomValidations() {
        if (this.isRecoveryWithCase && this._adjustment && this._adjustment.RecordType &&
            this._adjustment.RecordType.DeveloperName !== 'Finalized') {

            const hasSelected = this.responsiblePartyList &&
                this.responsiblePartyList.some(party => party.Selected__c === true);
            if (!hasSelected) {
                helper.showToast(
                    this,
                    'Error',
                    'At least one checkbox must be checked before proceeding to the next screen.',
                    'error',
                    'dismissible'
                );
                return false;
            }
        }
        return true;
    }
    // ─── Event Handlers ──────────────────────────────────────────────────────────

    /**
     * Handles the change event from the Classification Type picklist.
     * Updates the adjustment object and delegates to validateClassificationType logic.
     * @param {CustomEvent} event
     */
    handleClassificationTypeChange(event) {
        const newValue = event.detail?.payload?.value ?? event.detail?.value;
        if (newValue !== undefined) {
            this._adjustment = { ...this._adjustment, CDE_TYPE_CLSFN__c: newValue };
            this._fireAdjustmentChange();
        }
        this._validateClassificationType(event);
    }

    /**
     * Handles the change event from the Court Ordered Adjustment picklist.
     * Updates the adjustment object and fires change event to parent.
     * @param {CustomEvent} event
     */
    handleCourtOrderedAdjustmentChange(event) {
        const newValue = event.detail?.payload?.value ?? event.detail?.value;
        if (newValue !== undefined) {
            this._adjustment = { ...this._adjustment, IND_ORD_COURT_ADJMT__c: newValue };
            this._fireAdjustmentChange();
        }
    }

    /**
     * Handles the change event from the Recovery Initiative picklist.
     * Updates the adjustment object and fires change event to parent.
     * @param {CustomEvent} event
     */
    handleRecoveryInitiativeChange(event) {
        const newValue = event.detail?.payload?.value ?? event.detail?.value;
        if (newValue !== undefined) {
            this._adjustment = { ...this._adjustment, Recovery_Initiative__c: newValue };
            this._fireAdjustmentChange();
        }
    }

    /**
     * Handles the change event from the Adjustment Reason multiselect picklist.
     * Updates the adjustment object and fires change event to parent.
     * @param {CustomEvent} event
     */
    handleAdjustmentReasonChange(event) {
        const newValue = event.detail?.payload?.value ?? event.detail?.value;
        if (newValue !== undefined) {
            this._adjustment = { ...this._adjustment, CDE_REASON__c: newValue };
            this._fireAdjustmentChange();
        }
    }

    /**
     * Handles the change event from the Reason for Edit picklist.
     * Updates the adjustment object and triggers modal validation logic.
     * @param {CustomEvent} event
     */
    handleReasonForEditChange(event) {
        const newValue = event.detail?.payload?.value ?? event.detail?.value;
        console.log('pick' + JSON.stringify(event.detail));
        if (newValue !== undefined) {
            this._adjustment = { ...this._adjustment, CDE_EDIT_REASON__c: newValue };
            this._fireAdjustmentChange();
        }
        this._validateClassificationType(event);
    }

    /**
     * Handles the 'yes' event from the confirmation modal (OK button clicked).
     * Hides the classification type modal.
     */
    confirmOK() {
        this.showClassificationTypeModal = false;
    }

    /**
     * Handles the 'no' event from the confirmation modal (modal closed/cancelled).
     * Hides the classification type modal.
     */
    handleModalClose() {
        this.showClassificationTypeModal = false;
    }

    // ─── Private Helpers ─────────────────────────────────────────────────────────

    /**
     * Validates whether the Classification Type change should trigger the
     * confirmation modal. Shows modal if:
     *   - Adjustment type is 'Recovery'
     *   - Old value is NOT 'Other Recoveries'
     *   - New value IS '5'
     * @param {CustomEvent} event - event with oldValue and value (or detail.oldValue / detail.value)
     */
    _validateClassificationType(event) {
        const oldValue = event.detail?.payload?.oldValue ?? event.detail?.oldValue;
        const newValue = event.detail?.payload?.value ?? event.detail?.value;
        
        if (
            this._adjustment?.CDE_TYPE_ADJMT__c === 'Recovery' && ((oldValue &&
            oldValue !== 'Other Recoveries' &&
            newValue === '5') || (oldValue=='' && newValue==='5'))
        ) {
            this.showClassificationTypeModal = true;
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // TWO-WAY BINDING EVENT DISPATCHERS
    // In Aura, child attribute changes auto-sync to parent via two-way binding.
    // In LWC, we must explicitly dispatch events so parent can update its state.
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * Dispatches adjustmentchange event to sync adjustment object with parent.
     * Call this whenever the adjustment object is modified.
     */
    _fireAdjustmentChange() {
        if (this._isParentSettingValue) return;
        const currentKey = this._adjustment ? JSON.stringify({

            CDE_TYPE_CLSFN__c: this._adjustment.CDE_TYPE_CLSFN__c,
            IND_ORD_COURT_ADJMT__c: this._adjustment.IND_ORD_COURT_ADJMT__c,
            Recovery_Initiative__c: this._adjustment.Recovery_Initiative__c,
            CDE_REASON__c: this._adjustment.CDE_REASON__c,
            CDE_EDIT_REASON__c: this._adjustment.CDE_EDIT_REASON__c,
            CDE_INIT_RECOVERY__c: this._adjustment.CDE_INIT_RECOVERY__c,
            CDE_REASON_ADJMT__c: this._adjustment.CDE_REASON_ADJMT__c,
            TXT_REASON_EDIT__c: this._adjustment.TXT_REASON_EDIT__c
        }) : '';
        console.log('currentKey' + JSON.stringify(currentKey));
        if (this._lastFiredAdjustment === currentKey) return;
        this._lastFiredAdjustment = currentKey;
        this.dispatchEvent(new CustomEvent('adjustmentchange', { detail: { adjustment: this._adjustment }, bubbles: true, composed: true }));
    }

    /**
     * Dispatches addresschange event to sync address object with parent.
     * Call this whenever the address object is modified.
     */
    _fireAddressChange() {
        if (this._isParentSettingValue) return;
        const currentKey = this._address ? JSON.stringify(this._address) : '';
        if (this._lastFiredAddress === currentKey) return;
        this._lastFiredAddress = currentKey;
        this.dispatchEvent(new CustomEvent('addresschange', { detail: { address: this._address }, bubbles: true, composed: true }));
    }

    /**
     * Dispatches responsiblepartylistchange event to sync responsible party list with parent.
     * Call this whenever the _responsiblePartyList or _responsiblePartiesAddressList is modified.
     */
    _lastFiredResponsiblePartyList = [];
    _lastFiredResponsiblePartyAddList = [];

    _fireResponsiblePartyListChange() {
        if (this._isParentSettingValue) return;
        // LOOP PREVENTION: Check if data has actually changed
        const currentpartyList = JSON.stringify(this._responsiblePartyList);
        const currentpartyAddList = JSON.stringify(this._responsiblePartiesAddressList);

        // Only fire if something actually changed
        const respListUpdated = this._lastFiredResponsiblePartyList !== currentpartyList;
        const addListUpdated = this._lastFiredResponsiblePartyAddList !== currentpartyAddList;
        if (respListUpdated || addListUpdated) {
            this._lastFiredResponsiblePartyList = currentpartyList;
            this._lastFiredResponsiblePartyAddList = currentpartyAddList;

            this.dispatchEvent(
                new CustomEvent('responsiblepartylistchange', {
                    detail: {
                        responsiblePartyList: this._responsiblePartyList,
                        responsiblePartiesAddressList: this._responsiblePartiesAddressList
                    }
                })
            );
        }
    }
    // ══════════════════════════════════════════════════════════════════════════
    // FIELD CHANGE HANDLERS (for two-way binding)
    // ══════════════════════════════════════════════════════════════════════════
    handleCreateRespParties(event) {
        event.stopPropagation();
        //console.log('handleCreateRespParties ' + JSON.stringify(event.detail));
        const { selectedRec, responsiblePartyObj, key } = event.detail;
        let responsiblePartyList = this._responsiblePartyList;
        let indice = responsiblePartyList.findIndex(val => val.IDN_CLIENT__c == responsiblePartyObj.IDN_CLIENT__c);
        if (indice > -1) {
            responsiblePartyList[indice] = responsiblePartyObj;
            this._responsiblePartyList = JSON.parse(JSON.stringify(responsiblePartyList));
            // Deep copy existing map to maintain reactivity
            // Filter responsiblePartiesAddressList based on respPartyMap (match Aura handleAddRespParties logic)
            this._updateResponsiblePartiesAddressList();

            this._fireResponsiblePartyListChange();
        }

    }

    /**
     * Updates responsiblePartiesAddressList based on respPartyMap.
     * Filters addresses to only include those whose Responsible_Party_Client_Id__c
     * exists in the respPartyMap.
     * @param {string} mapkey - The client ID key that triggered the change
     * @param {boolean} selectedRec - Whether the responsible party is selected
     * @param {Object} respPartyMap - The current responsible party map
     */
    _updateResponsiblePartiesAddressList() {
        const respPartyMap = Object.fromEntries(this._responsiblePartyList.map(obj => [obj.IDN_CLIENT__c, obj]));
        console.log('respPartyMap' + JSON.stringify(respPartyMap));
        const respAddrMaster = this._responsiblePartiesAddressListClone || [];
        let responsiblePartiesAddressListTemp = [];
        try {
            if (respPartyMap && Object.keys(respPartyMap).length > 0) {
                // If respPartyMap is not empty, filter the address list
                if (respAddrMaster.length > 0) {
                    for (let i = 0; i < respAddrMaster.length; i++) {
                        // Check if this address's client ID exists in the respPartyMap
                        if (respPartyMap.hasOwnProperty(respAddrMaster[i].Responsible_Party_Client_Id__c)) {
                            if (respPartyMap[respAddrMaster[i].Responsible_Party_Client_Id__c].Selected__c) {
                                responsiblePartiesAddressListTemp.push(respAddrMaster[i]);
                            }
                        }
                    }
                }
            }
            this._responsiblePartiesAddressList = JSON.parse(JSON.stringify(responsiblePartiesAddressListTemp));
        } catch (err) {
            console.log('err', err.message);
        }
        console.log('_responsiblePartiesAddressList' + JSON.stringify(this._responsiblePartiesAddressList));
    }

    /**
     * Handles address change event from adjustmentAddress child component.
     * @param {CustomEvent} event - event.detail contains updated address
     */
    handleAddressUpdate(event) {
        // CRITICAL: Stop propagation to prevent duplicate handling at grandparent level.
        // This component handles the event and fires a new 'addresschange' event.
        event.stopPropagation();

        if (event.detail?.address) {
            this._address = JSON.parse(JSON.stringify({ ...this._address, ...event.detail.address }));
            this._fireAddressChange();
        }
    }

    /**
     * Handles responsible party address change from adjustmentAddressRespParty child.
     * @param {CustomEvent} event - event.detail contains updated address data
     */
    handleRespPartyAddressUpdate(event) {
        // CRITICAL: Stop propagation to prevent duplicate handling at grandparent level.
        // This component handles the event and fires a new 'respaddresschange' event.
        event.stopPropagation();
        let respAddrList = this._responsiblePartiesAddressList;
        let updatedAddress = event.detail.respAddress;
        // BUG FIX: Use Responsible_Party_Client_Id__c as the lookup key instead of Id.
        // When address records are NEW (not yet saved), Id is null on all entries — matching
        // by Id would always resolve to the first null-Id row, overwriting the wrong record
        // and causing duplicate inserts in upsertResponsiblePartiesAddress on the Apex side.
        // Responsible_Party_Client_Id__c is always populated and unique per party, matching
        // how Aura identified rows via its two-way attribute binding on v.responsiblePartiesAddressList[i].
        let indice = respAddrList.findIndex(
            val => val.Responsible_Party_Client_Id__c === updatedAddress.Responsible_Party_Client_Id__c
        );
        if (indice > -1) {
            respAddrList[indice] = updatedAddress;
            this._responsiblePartiesAddressList = JSON.parse(JSON.stringify(respAddrList));
            this._fireResponsiblePartyListChange();
        }
    }

    /**
     * Public API method to validate the current page.
     * Alias for callValidateCurrentPage for compatibility.
     * @returns {boolean}
     */
    @api
    validateCurrentPage() {
        return this.callValidateCurrentPage();
    }

    /**
     * Public API method: returns the current responsible parties address list
     * with ADR_STATE__c read directly from each rendered State combobox.
     *
     * Called by the parent (adjustmentFlow_lwc) immediately before
     * upsertRespAddressList to ensure the correct API values are saved.
     *
     * Background: the address clone is seeded from the server which returns
     * toLabel(ADR_STATE__c) = 'Colorado'. The State combobox converts this to
     * the API value ('CO') asynchronously after fetchPicklist completes. If the
     * user clicks Next before that async call returns, _responsiblePartiesAddressList
     * still holds 'Colorado'. Each rendered c-adjustment-address-resp-party_lwc
     * exposes getAddressWithConvertedState() which reads the combobox's current
     * internal _value (always the API value once options load) bypassing the race.
     * Falls back to _responsiblePartiesAddressList if no components are rendered.
     *
     * @returns {Array} Address list with ADR_STATE__c as API values
     */
    @api
    getResponsiblePartiesAddressList() {
        // Start from the internal list as the source of truth for all fields and ordering.
        // Only patch ADR_STATE__c by reading from each rendered card's State combobox.
        // This avoids DOM-order vs list-order mismatches and duplicate-ID issues caused
        // by building a new list from querySelectorAll results.
        const base = this._responsiblePartiesAddressList
            ? JSON.parse(JSON.stringify(this._responsiblePartiesAddressList))
            : [];

        if (base.length === 0) {
            return base;
        }

        // Build a map of clientId → converted state value from rendered cards.
        // querySelectorAll returns only rendered cards — if key={addressObj.Id} caused
        // LWC to skip some items, we simply won't patch those (they keep the base value).
        const stateByClientId = {};
        const addrCards = this.template.querySelectorAll('[data-id="adjustmentAddressRespParty"]');
        if (addrCards && addrCards.length > 0) {
            addrCards.forEach(card => {
                if (typeof card.getAddressWithConvertedState === 'function') {
                    const addr = card.getAddressWithConvertedState();
                    if (addr && addr.Responsible_Party_Client_Id__c && addr.ADR_STATE__c) {
                        stateByClientId[addr.Responsible_Party_Client_Id__c] = addr.ADR_STATE__c;
                    }
                }
            });
        }

        // Patch ADR_STATE__c only where a converted (non-empty) value was found.
        base.forEach(addr => {
            const converted = stateByClientId[addr.Responsible_Party_Client_Id__c];
            if (converted) {
                addr.ADR_STATE__c = converted;
            }
        });

        return base;
    }
}