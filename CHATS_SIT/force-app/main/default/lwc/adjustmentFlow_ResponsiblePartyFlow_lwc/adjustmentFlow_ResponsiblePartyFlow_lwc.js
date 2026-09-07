import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';

export default class AdjustmentFlow_ResponsiblePartyFlow_lwc extends LightningElement {

    informParentCmp;
    // ─── @api backing fields ────────────────────────────────────────────────────
    @track _adjustment = {};
    @track _responsiblePartyObj = {};

    // ─── @api properties ───────────────────────────────────────────────────────
    @api
    get adjustment() {
        return this._adjustment;
    }
    set adjustment(value) {
        let oldVal = this._adjustment.CDE_TYPE_CLSFN__c;
        if (value !== null && value !== undefined) {
            this._adjustment = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustment = {};
        }
        if (value?.CDE_TYPE_CLSFN__c != oldVal) {
            this.validateCurrentPage();
        }
    }
    @api
    get responsiblePartyObj() {
        return this._responsiblePartyObj;
    }
    set responsiblePartyObj(value) {
        this._isParentSettingValue = true;
        try {
            if (value !== null && value !== undefined) {
                this._responsiblePartyObj = JSON.parse(JSON.stringify(value));
            } else {
                this._responsiblePartyObj = {};
            }
        } finally {
            this._isParentSettingValue = false;
        }
    }

    @api pageMode = 'view';

    // ─── @track properties ─────────────────────────────────────────────────────
    @track IPVRecordId;
    @track IPVRecord;
    @track ipvErrorMessage;
    @track showSpinner = false;
    @track error;

    // ─── Loop Prevention Flags ──────────────────────────────────────────────────
    _isParentSettingValue = false;
    _lastFiredKey = null;
    _lastFiredSelectedRec = null;
    _lastErrorMessage;

    // ─── Getters ────────────────────────────────────────────────────────────────

    get isViewMode() {
        return this.pageMode == 'view';
    }
    get IPVName() {
        return this._responsiblePartyObj.IPV_Info__c ? this._responsiblePartyObj.IPV_Info__r.Name : '';
    }
    get isFraud() {
        return this._adjustment.CDE_TYPE_CLSFN__c == '1';
    }
    get isRecoveryCase() {
        return this._adjustment.CDE_TYPE_ADJMT__c == 'Recovery' && this._adjustment.IDN_CASE__c != undefined && this._adjustment.IDN_CASE__c != ''
    }
    get ipvRequired() {
        return this._responsiblePartyObj?.Selected__c && this.isRecoveryCase && this.isFraud;
    }

    connectedCallback() {
        this.IPVRecordId = this._responsiblePartyObj.IPV_Info__c;
    }
    // ─── Event Handlers ─────────────────────────────────────────────────────────

    /**
     * Handles checkbox change for responsible party selection.
     * Toggles Selected__c on the responsiblePartyObj and fires the createrespparty event.
     */
    handleCheckboxChange(event) {
        const checked = event.target.checked;
        // Use _responsiblePartyObj (backing field) for internal mutations to respect LWC one-way data flow
        const updatedObj = JSON.parse(JSON.stringify(Object.assign({}, this._responsiblePartyObj, { Selected__c: checked })));
        this._responsiblePartyObj = updatedObj;
        this.handleRespLevelUpdatesChange();
    }

    /**
     * Handles IPV lookup record selection change.
     * Updates IPV_Info__c on the responsiblePartyObj and triggers server-side validation.
     */
    handleIPVLookupChange(event) {
        const selectedRecord = event.detail ? event.detail.record : {};
        this._responsiblePartyObj = {
            ...this._responsiblePartyObj,
            IPV_Info__c: ''
        };
        if (selectedRecord && selectedRecord.Id) {
            this.IPVRecordId = selectedRecord.Id;
        } else {
            this.IPVRecordId = '';
            this.IPVRecord = {};
        }
        this.handleRespLevelUpdatesChange();

    }
    handleRespLevelUpdatesChange() {
        this.ipvErrorMessage = '';
        if (this._responsiblePartyObj.Selected__c) {
            // Validate IPV requirement immediately if classification is Fraud/IPV and no IPV selected
            if (this.isFraud && !this.IPVRecordId) {
                this.ipvErrorMessage = 'Investigation Record ID is a required field when Classification Type is Fraud/IPV.';
                this.informParentCmp = true;
            } else {
                if (this.isRecoveryCase) {
                    if (this.IPVRecordId) {
                        this.getIPVRecord(this.IPVRecordId);
                    } else {
                        this.informParentCmp = true;
                    }
                }
            }
        } else {
            this.informParentCmp = true;
        }
        if (this.informParentCmp) {
            this.fireEvent(this._responsiblePartyObj?.Selected__c, this._responsiblePartyObj);
        }
    }

    // ─── @api Public Methods ─────────────────────────────────────────────────────

    /**
     * Validates the current page/row.
     * Returns true if valid, false otherwise.
     * Called by parent component (adjustmentResponsibleParty_lwc) during flow navigation.
     */
    @api
    validateCurrentPage() {
        return abs_helper.validateCurrentPage(this);
    }

    // ─── Private Helper Methods ──────────────────────────────────────────────────

    /**
     * Validates IPV Record requirement.
     * IPV_Info__c is required when IPVRecordReq is true and the party is selected.
     * Also validates that the IPV Record's Individual_ID__c matches IDN_CLIENT__c.
     */
    checkCustomValidations() {
        let valid = true;
        this.ipvErrorMessage = '';

        if (this.ipvRequired) {
            if (!this._responsiblePartyObj.IPV_Info__c) {
                valid = false;
                this.ipvErrorMessage = 'Investigation Record ID is a required field when Classification Type is Fraud/IPV.';
            }
        }
        if (this.IPVRecord) {
            const ipvIndividualId = this.IPVRecord.Individual_ID__c;
            const clientId = this._responsiblePartyObj.IDN_CLIENT__c;
            if (ipvIndividualId && clientId && String(ipvIndividualId) !== String(clientId) && this._responsiblePartyObj.Selected__c) {
                this.ipvErrorMessage = 'Investigation Record ID is not associated with the individual selected.  Please verify and update the record ID.';
                valid = false;
            }
        }
        return valid;
    }

    /**
     * Fires the 'createrespparty' custom event with the current state.
     */
    fireEvent(selectedRec, responsiblePartyObj) {
        if (this._isParentSettingValue) return;
        this.showSpinner = true;
        this.dispatchEvent(new CustomEvent('createrespparty', {
            detail: {
                selectedRec: selectedRec,
                responsiblePartyObj: responsiblePartyObj,
                key: responsiblePartyObj?.IDN_CLIENT__c,
                IPVRecordId: this.IPVRecordId
            },
            bubbles: true,
            composed: true
        }));
        this.informParentCmp = false;
        this.showSpinner = false;
        this.validateCurrentPage();
    }

    /**
     * Server call: AdjustmentFlowApxCtrl.getSelectedIPVRecord
     * Validates the selected IPV record against the responsible party's client ID.
     */
    getIPVRecord(ipvRecordId) {
        const params = { IPVRecordId: ipvRecordId };
        helper.callServer(this, 'AdjustmentFlowApxCtrl', 'getSelectedIPVRecord', (function (result) {
            if (result && result.isSuccessful && result.objectData && result.objectData.IPVRecord) {
                this.IPVRecord = result.objectData.IPVRecord;
                // Validate client ID match
                const ipvIndividualId = this.IPVRecord.Individual_ID__c;
                const clientId = this._responsiblePartyObj ? this._responsiblePartyObj.IDN_CLIENT__c : '';
                //console.log('clientId' + clientId + ' -- ' + ipvIndividualId);
                if (ipvIndividualId && clientId && String(ipvIndividualId) !== String(clientId)) {
                    this.ipvErrorMessage = 'Investigation Record ID is not associated with the individual selected.  Please verify and update the record ID.';
                } else {
                    // Use _responsiblePartyObj (backing field) for internal mutations
                    const updatedObj = JSON.parse(JSON.stringify(Object.assign({}, this._responsiblePartyObj, { IPV_Info__c: ipvRecordId })));
                    this._responsiblePartyObj = updatedObj;
                    this.ipvErrorMessage = '';
                }
            } else {
                this.IPVRecord = {};
                this.ipvErrorMessage = 'Investigation Record ID is not associated with the individual selected.  Please verify and update the record ID.';
            }
            this.fireEvent(this._responsiblePartyObj?.Selected__c, this._responsiblePartyObj);
        }).bind(this), JSON.stringify(params));
    }
}