import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';

/**
 * Converts an array of message strings to the format expected by pageMessages_lwc.
 * @param {string[]} messages - Array of message strings
 * @returns {Object[]} - Array of objects with Id and message keys
 */
function formatMessages(messages) {
    if (!messages || messages.length === 0) {
        return [];
    }
    return messages.map((msg, index) => ({
        Id: 'error-' + Date.now() + '-' + index,
        message: msg
    }));
}

export default class AdjustmentFlow_AdjustmentEntry_lwc extends LightningElement {

    // ─── @api properties ────────────────────────────────────────────────────────
    @api selectedSubPayment;

    // adjustment -> fallback {}
    @track _adjustment = {};
    @api
    get adjustment() {
        return this._adjustment;
    }
    set adjustment(value) {
        if (value !== null && value !== undefined) {
            this._adjustment = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustment = {};
        }
    }

    // subPaymentDetails -> fallback []
    @track _subPaymentDetails = [];
    @api
    get subPaymentDetails() {
        return this._subPaymentDetails;
    }
    set subPaymentDetails(value) {
        if (value !== null && value !== undefined) {
            this._subPaymentDetails = JSON.parse(JSON.stringify(value));
        } else {
            this._subPaymentDetails = [];
        }
    }

    // existAdjWrap -> fallback {}
    @track _existAdjWrap = {};
    @api
    get existAdjWrap() {
        return this._existAdjWrap;
    }
    set existAdjWrap(value) {
        if (value !== null && value !== undefined) {
            this._existAdjWrap = JSON.parse(JSON.stringify(value));
        } else {
            this._existAdjWrap = {};
        }
    }

    // adjustmentDetailList -> fallback []
    @track _adjustmentDetailList = [];
    @api
    get adjustmentDetailList() {
        return this._adjustmentDetailList;
    }
    set adjustmentDetailList(value) {
        if (value !== null && value !== undefined) {
            this._adjustmentDetailList = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustmentDetailList = [];
        }
    }

    // adjustmentDetailsMap1 -> fallback {}
    @track _adjustmentDetailsMap1 = {};
    @api
    get adjustmentDetailsMap1() {
        return this._adjustmentDetailsMap1;
    }
    set adjustmentDetailsMap1(value) {
        if (value !== null && value !== undefined) {
            this._adjustmentDetailsMap1 = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustmentDetailsMap1 = {};
        }
    }

    // careLevelOptionsMap -> fallback {}
    @track _careLevelOptionsMap = {};
    @api
    get careLevelOptionsMap() {
        return this._careLevelOptionsMap;
    }
    set careLevelOptionsMap(value) {
        if (value !== null && value !== undefined) {
            this._careLevelOptionsMap = JSON.parse(JSON.stringify(value));
        } else {
            this._careLevelOptionsMap = {};
        }
    }

    // careUnitTypeOptionsMap -> fallback {}
    @track _careUnitTypeOptionsMap = {};
    @api
    get careUnitTypeOptionsMap() {
        return this._careUnitTypeOptionsMap;
    }
    set careUnitTypeOptionsMap(value) {
        if (value !== null && value !== undefined) {
            this._careUnitTypeOptionsMap = JSON.parse(JSON.stringify(value));
        } else {
            this._careUnitTypeOptionsMap = {};
        }
    }

    // rateTypeOptionsMap -> fallback {}
    @track _rateTypeOptionsMap = {};
    @api
    get rateTypeOptionsMap() {
        return this._rateTypeOptionsMap;
    }
    set rateTypeOptionsMap(value) {
        if (value !== null && value !== undefined) {
            this._rateTypeOptionsMap = JSON.parse(JSON.stringify(value));
        } else {
            this._rateTypeOptionsMap = {};
        }
    }

    // rateTypeOptionsCareDateMap -> fallback {}
    @track _rateTypeOptionsCareDateMap = {};
    @api
    get rateTypeOptionsCareDateMap() {
        return this._rateTypeOptionsCareDateMap;
    }
    set rateTypeOptionsCareDateMap(value) {
        if (value !== null && value !== undefined) {
            this._rateTypeOptionsCareDateMap = JSON.parse(JSON.stringify(value));
        } else {
            this._rateTypeOptionsCareDateMap = {};
        }
    }

    // adjustDetailMap -> fallback {}
    @track _adjustDetailMap = {};
    @api
    get adjustDetailMap() {
        return this._adjustDetailMap;
    }
    set adjustDetailMap(value) {
        if (value !== null && value !== undefined) {
            this._adjustDetailMap = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustDetailMap = {};
        }
    }

    // adjustmentDetailsARTFeeMap -> fallback {}
    @track _adjustmentDetailsARTFeeMap = {};
    @api
    get adjustmentDetailsARTFeeMap() {
        return this._adjustmentDetailsARTFeeMap;
    }
    set adjustmentDetailsARTFeeMap(value) {
        if (value !== null && value !== undefined) {
            this._adjustmentDetailsARTFeeMap = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustmentDetailsARTFeeMap = {};
        }
    }

    // childCurrentUtilization -> fallback {}
    @track _childCurrentUtilization = {};
    @api
    get childCurrentUtilization() {
        return this._childCurrentUtilization;
    }
    set childCurrentUtilization(value) {
        if (value !== null && value !== undefined) {
            this._childCurrentUtilization = JSON.parse(JSON.stringify(value));
        } else {
            this._childCurrentUtilization = {};
        }
    }

    // rateTypeOptions -> fallback []
    @track _rateTypeOptions = [];
    @api
    get rateTypeOptions() {
        return this._rateTypeOptions;
    }
    set rateTypeOptions(value) {
        if (value !== null && value !== undefined) {
            this._rateTypeOptions = JSON.parse(JSON.stringify(value));
        } else {
            this._rateTypeOptions = [];
        }
    }

    // careUnitTypeOptions -> fallback []
    @track _careUnitTypeOptions = [];
    @api
    get careUnitTypeOptions() {
        return this._careUnitTypeOptions;
    }
    set careUnitTypeOptions(value) {
        if (value !== null && value !== undefined) {
            this._careUnitTypeOptions = JSON.parse(JSON.stringify(value));
        } else {
            this._careUnitTypeOptions = [];
        }
    }

    // careLevelOptions -> fallback []
    @track _careLevelOptions = [];
    @api
    get careLevelOptions() {
        return this._careLevelOptions;
    }
    set careLevelOptions(value) {
        if (value !== null && value !== undefined) {
            this._careLevelOptions = JSON.parse(JSON.stringify(value));
        } else {
            this._careLevelOptions = [];
        }
    }

    // selectedAdjustmentDetailRec -> fallback null
    @track _selectedAdjustmentDetailRec = null;
    @api
    get selectedAdjustmentDetailRec() {
        return this._selectedAdjustmentDetailRec;
    }
    set selectedAdjustmentDetailRec(value) {
        if (value !== null && value !== undefined) {
            this._selectedAdjustmentDetailRec = JSON.parse(JSON.stringify(value));
        } else {
            this._selectedAdjustmentDetailRec = null;
        }
    }

    // Primitive @api properties (kept as simple @api)
    @api slotCntcheckbox = false;
    @api disabledARTFees = false;

    // ─── @track properties ──────────────────────────────────────────────────────
    @track ARTFeeFlag = false;
    @track pageMessages = [];
    @track messageType = null;
    @track fieldValidationErrors = [];

    // ─── Lifecycle ──────────────────────────────────────────────────────────────

    connectedCallback() {
        const adjustmentDetailList = this.adjustmentDetailList;
        if (adjustmentDetailList && adjustmentDetailList.length > 0) {
            const rec = adjustmentDetailList[0];
            if (
                rec.IDN_DETAIL_PMT_SUB__r &&
                rec.IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r &&
                rec.IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_slot_contract__c != null &&
                rec.IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_auth__c == null
            ) {
                this.slotCntcheckbox = true;
            }
        }
    }

    // ─── Getters ─────────────────────────────────────────────────────────────────

    /**
     * Show ART Fees table when disabledARTFees is false and slotCntcheckbox is false.
     */
    get showARTFeesTable() {
        return !this.disabledARTFees && !this.slotCntcheckbox;
    }

    /**
     * Returns boolean true for use in template bindings that require a boolean true value.
     * Used to pass ARTFeeFlag={booleanTrue} to child row components in the ART Fees table.
     */
    get booleanTrue() {
        return true;
    }

    /**
     * Returns a copy of subPaymentDetails with each item augmented with a unique artFeeKey.
     * This prevents LWC virtual DOM key collisions between the main table and the ART Fees table,
     * which both iterate the same subPaymentDetails array.
     * The artFeeKey is the ExternalId suffixed with '-art' (e.g. "EXT-001-art").
     */
    get artFeeSubPaymentDetails() {
        const details = this._subPaymentDetails;
        if (!details || details.length === 0) {
            return [];
        }
        return details.map(item => ({
            ...item,
            artFeeKey: (item.ExternalId || '') + '-art'
        }));
    }

    /**
     * Show Case ID column when IDN_PROVR__c is populated on the adjustment.
     */
    get showCaseIdColumn() {
        return this.adjustment && this.adjustment.IDN_PROVR__c;
    }

    /**
     * Show Provider ID column when IDN_CASE__c is populated on the adjustment.
     */
    get showProviderIdColumn() {
        return this.adjustment && this.adjustment.IDN_CASE__c;
    }

    /**
     * Returns true when there are page messages to display.
     */
    get hasPageMessages() {
        return this.pageMessages && this.pageMessages.length > 0;
    }

    // ─── Public API ──────────────────────────────────────────────────────────────

    /**
     * Validates all child rows and returns a boolean.
     * Equivalent to callValidateCurrentPage / handleValidateCurrentPage in Aura.
     * @returns {boolean}
     */
    @api
    validateCurrentPage() {
        return this._checkCustomValidations();
    }

    /**
     * Propagates the calculated amount data to all child row components.
     * This replaces the Aura application event pattern (calculateAmountRateEvent).
     * Called by the grandparent (Modal) after the server calculation completes.
     * 
     * @param {Object} adjustmentDetailsMapUpdated - Map of adjustment details keyed by ExternalId
     */
    @api
    propagateCalculateAmountPaid(adjustmentDetailsMapUpdated) {
        const rowComponents = this.template.querySelectorAll('c-adjustment-flow_-adjustment-entry-row_lwc');
        if (rowComponents && rowComponents.length > 0) {
            rowComponents.forEach(row => {
                if (row && typeof row.handleCalculateAmountPaid === 'function') {
                    row.handleCalculateAmountPaid(adjustmentDetailsMapUpdated);
                }
            });
        }
    }

    // ─── Private: validation logic ───────────────────────────────────────────────

    _checkCustomValidations() {
        let isValid = true;
        let isAllAdjusted = true;
        let atleastOneGreater = false;
        let atleastOneLesser = false;

        const adjustment = this.adjustment || {};
        const subPaymentDetail = this.subPaymentDetails || [];
        const adjustmentDetailsMap1 = this.adjustmentDetailsMap1 || {};
        const adjustmentDetailsARTFeeMap = this.adjustmentDetailsARTFeeMap || {};
        const childCurrentUtilization = this.childCurrentUtilization || {};

        this.pageMessages = [...[]];

        // Validate each child row
        const rowComponents = this.template.querySelectorAll('c-adjustment-flow_-adjustment-entry-row_lwc');
        if (rowComponents && rowComponents.length > 0) {
            rowComponents.forEach(row => {
                if (!row.validateEachRow()) {
                    isValid = false;
                }
            });
        }

        if (!isValid) {
            return false;
        }

        let activityError = false;
        let regisError = false;
        let transError = false;

        // ART fee utilization checks for Claim type
        if (
            adjustmentDetailsMap1 && Object.keys(adjustmentDetailsMap1).length > 0 &&
            childCurrentUtilization && Object.keys(childCurrentUtilization).length > 0 &&
            adjustment.CDE_TYPE_ADJMT__c === 'Claim'
        ) {
            for (const p in adjustmentDetailsMap1) {
                if (!Object.prototype.hasOwnProperty.call(adjustmentDetailsMap1, p)) continue;
                for (let i = 0; i < subPaymentDetail.length; i++) {
                    if (
                        subPaymentDetail[i].ExternalId === p &&
                        adjustmentDetailsMap1[p].Adjustment_Initiated__c === true
                    ) {
                        const authVal = subPaymentDetail[i].idn_pmt_sub__r &&
                            subPaymentDetail[i].idn_pmt_sub__r.idn_auth__r;
                        if (typeof authVal !== 'undefined' && authVal != null) {
                            const key = subPaymentDetail[i].idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r &&
                                subPaymentDetail[i].idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c;
                            if (key && childCurrentUtilization[key] && childCurrentUtilization[key].length > 0) {
                                const currentVal = childCurrentUtilization[key][0];
                                if (adjustmentDetailsMap1[p].Activity_Fee_Paid__c > currentVal.amt_act_remaining__c) {
                                    isValid = false;
                                    activityError = true;
                                    this.messageType = String('error');
                                }
                                if (adjustmentDetailsMap1[p].Registration_Fee_Paid__c > currentVal.amt_reg_remaining__c) {
                                    isValid = false;
                                    regisError = true;
                                    this.messageType = String('error');
                                }
                                if (adjustmentDetailsMap1[p].Transportation_Fee_Paid__c > currentVal.amt_trans_remaining__c) {
                                    isValid = false;
                                    transError = true;
                                    this.messageType = String('error');
                                }
                            }
                        }
                    }
                }
            }

            if (!isValid) {
                const msgs = [];
                if (activityError) {
                    msgs.push('Adjusted Activity Fee should be less than equals to child activity remaining amount.');
                }
                if (regisError) {
                    msgs.push('Adjusted Registration Fee should be less than equals to child Registration remaining amount.');
                }
                if (transError) {
                    msgs.push('Adjusted Transportation Fee should be less than equals to child Transportation remaining amount.');
                }
                this.pageMessages = formatMessages(msgs);
                return false;
            }
        }

        // Rate amount validation for Claim / Recovery
        if (adjustment.CDE_TYPE_ADJMT__c === 'Claim') {
            if (adjustmentDetailsMap1 && Object.keys(adjustmentDetailsMap1).length > 0) {
                for (const p in adjustmentDetailsMap1) {
                    if (!Object.prototype.hasOwnProperty.call(adjustmentDetailsMap1, p)) continue;
                    for (let i = 0; i < subPaymentDetail.length; i++) {
                        if (
                            subPaymentDetail[i].ExternalId === p &&
                            subPaymentDetail[i].ind_adjmt__c !== 'Y' &&
                            adjustmentDetailsMap1[p].Adjustment_Initiated__c === true
                        ) {
                            isAllAdjusted = false;
                            if (adjustmentDetailsMap1[p].AMT_PAID_RATE_ADJD__c > subPaymentDetail[i].amt_rate__c) {
                                atleastOneGreater = true;
                                isValid = true;
                            } else if (adjustmentDetailsMap1[p].AMT_PAID_RATE_ADJD__c === subPaymentDetail[i].amt_rate__c) {
                                isValid = true;
                            } else {
                                isValid = false;
                                this.messageType = String('error');
                                this.pageMessages = formatMessages(['Adjusted Rate Amount entered must be greater than Rate Paid for claims']);
                                return false;
                            }
                        }
                    }
                }
                if (isAllAdjusted) {
                    return true;
                } else if (isValid && atleastOneGreater) {
                    return true;
                } else {
                    if (this.pageMessages.length < 1) {
                        this.messageType = String('error');
                        this.pageMessages = formatMessages(['Adjusted Rate Amount entered must be greater than Rate Paid for claims']);
                    }
                    return false;
                }
            }
        } else if (adjustment.CDE_TYPE_ADJMT__c === 'Recovery') {
            for (const p in adjustmentDetailsMap1) {
                if (!Object.prototype.hasOwnProperty.call(adjustmentDetailsMap1, p)) continue;
                for (let i = 0; i < subPaymentDetail.length; i++) {
                    if (
                        subPaymentDetail[i].ExternalId === p &&
                        subPaymentDetail[i].ind_adjmt__c !== 'Y' &&
                        adjustmentDetailsMap1[p].Adjustment_Initiated__c === true
                    ) {
                        isAllAdjusted = false;
                        if (adjustmentDetailsMap1[p].AMT_PAID_RATE_ADJD__c < subPaymentDetail[i].amt_rate__c) {
                            atleastOneLesser = true;
                            isValid = true;
                        } else if (adjustmentDetailsMap1[p].AMT_PAID_RATE_ADJD__c === subPaymentDetail[i].amt_rate__c) {
                            isValid = true;
                        } else {
                            isValid = false;
                            this.messageType = String('error');
                            this.pageMessages = formatMessages(['Adjusted Rate Amount entered must be less than Rate Paid for recoveries']);
                            return false;
                        }
                    }
                }
            }
            if (isAllAdjusted) {
                return true;
            } else if (isValid && atleastOneLesser) {
                return true;
            } else {
                if (this.pageMessages.length < 1) {
                    this.messageType = String('error');
                    this.pageMessages = formatMessages(['Adjusted Rate Amount entered must be less than Rate Paid for recoveries']);
                }
                return false;
            }
        }

        return isValid;
    }

    // ─── Event Handlers ──────────────────────────────────────────────────────────

    /**
     * Handles field-level validation changes bubbled from child rows.
     */
    handleFieldLevelValidation() {
        const rowComponents = this.template.querySelectorAll('c-adjustment-flow_-adjustment-entry-row_lwc');
        if (rowComponents && rowComponents.length > 0) {
            rowComponents.forEach(row => {
                row.validateEachRow();
            });
        }
    }

}