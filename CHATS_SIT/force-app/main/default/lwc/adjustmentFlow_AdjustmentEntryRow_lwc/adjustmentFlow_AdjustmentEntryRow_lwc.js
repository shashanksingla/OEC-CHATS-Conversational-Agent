import { LightningElement, api, track } from 'lwc';

const DEFAULT_ADJUSTMENT_DETAIL = {
    sobjectType: 'T_ADJMT_DETAIL__c',
    NBR_HOURS_AUTH_ADJD__c: 2,
    CDE_TYPE_RATE_ADJD__c: '',
    CDE_TYPE_UNIT_ADJD__c: '',
    CDE_CARE_LEVEL_ADJD__c: '',
    NBR_HOURS_ATTND_ADJD__c: 2,
    AMT_PAID_RATE_ADJD__c: 12,
    IND_OVERRIDE__c: false,
    AMT_DETAIL_ADJMT__c: 0,
    NBR_HOURS_AUTH_ORIG__c: 0,
    NBR_HOURS_ATNDT_ORIG__c: 0,
    AMT_PAID_RATE_ORIG__c: 0,
    Adjustment_Initiated__c: false,
    Activity_Fee_Paid__c: 0,
    Registration_Fee_Paid__c: 0,
    Transportation_Fee_Paid__c: 0
};

const DEFAULT_ADJUSTMENT_DETAIL_TEMP = {
    sobjectType: 'T_ADJMT_DETAIL__c',
    NBR_HOURS_AUTH_ADJD__c: 2,
    CDE_TYPE_RATE_ADJD__c: '',
    CDE_TYPE_UNIT_ADJD__c: '',
    CDE_CARE_LEVEL_ADJD__c: '',
    NBR_HOURS_ATTND_ADJD__c: 2,
    AMT_PAID_RATE_ADJD__c: 12,
    IND_OVERRIDE__c: false,
    AMT_DETAIL_ADJMT__c: 0,
    NBR_HOURS_AUTH_ORIG__c: 0,
    NBR_HOURS_ATNDT_ORIG__c: 0,
    AMT_PAID_RATE_ORIG__c: 0,
    Activity_Fee_Paid__c: 0,
    Registration_Fee_Paid__c: 0,
    Transportation_Fee_Paid__c: 0,
    Adjustment_Initiated__c: false
};

const DISABLE_CARE_LEVEL_RATE_TYPES = ['13', '19', '25'];

export default class AdjustmentFlow_AdjustmentEntryRow_lwc extends LightningElement {

    // ─── @track backing fields for @api getter/setter properties ────────────────
    @track _adjustment = {};
    @track _subPaymentDetail = {};
    @track _existAdjWrap = {};
    @track _adjustmentDetailList = [];
    @track _careLevelOptionsMap = {};
    @track _careUnitTypeOptionsMap = {};
    @track _rateTypeOptionsCareDateMap = {};
    @track _rateTypeOptionsMap = {};
    @track _adjustDetailMap = {};
    @track _adjustmentDetailsARTFeeMap = {};
    @track _careUnitTypeOptions = [];
    @track _careLevelOptions = [];
    // Backing field for rateTypeOptions (must NOT be @api — conflicts with getter)
    @track _rateTypeOptions;

    // ─── @api properties ────────────────────────────────────────────────────────

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

    @api
    get subPaymentDetail() {
        return this._subPaymentDetail;
    }
    set subPaymentDetail(value) {
        if (value !== null && value !== undefined) {
            this._subPaymentDetail = JSON.parse(JSON.stringify(value));
        } else {
            this._subPaymentDetail = {};
        }
    }

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

        if (this.artFeeFlag) {
            const key = this.adjustmentDetailId;
            const map = this._adjustmentDetailsARTFeeMap;
            if (key && map && Object.prototype.hasOwnProperty.call(map, key)) {
                const initiated = !!map[key].Adjustment_Initiated__c;
                this.adjustmentDetail = {
                    ...this.adjustmentDetail,
                    Adjustment_Initiated__c: initiated
                };
                this.adjustmentDetailTemp = {
                    ...this.adjustmentDetailTemp,
                    Adjustment_Initiated__c: initiated
                };
            }
        }
    }

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

    /**
     * FIX 2: @api getter/setter pattern for rateTypeOptions.
     * - The @api decorator is on the getter ONLY (no separate @api _rateTypeOptions property).
     * - The backing field @track _rateTypeOptions is declared above in the properties section.
     * - The setter deep-copies arrays/objects via JSON.parse(JSON.stringify()) to guarantee
     *   LWC reactivity when the parent passes a new reference.
     * - The getter falls back through localRateTypeOptions → _rateTypeOptions → [] so callers
     *   always receive an array, never null/undefined.
     */
    @api
    get rateTypeOptions() {
        return this.localRateTypeOptions || this._rateTypeOptions || [];
    }
    set rateTypeOptions(value) {
        if (value !== null && value !== undefined) {
            this._rateTypeOptions = JSON.parse(JSON.stringify(value));
        } else {
            this._rateTypeOptions = [];
        }
    }

    // ─── Simple @api properties (primitives / flags) ─────────────────────────────
    @api artFeeFlag = false;
    @api adjustmentDetailId;
    @api childCurrentUtilization;
    @api slotCntcheckbox = false;
    @api disabledARTFees;
    @api selectedSubPayment;
    @api selectedAdjustmentDetailRec;

    // ─── @track properties ──────────────────────────────────────────────────────
    @track adjustmentDetail = { ...DEFAULT_ADJUSTMENT_DETAIL };
    @track adjustmentDetailTemp = { ...DEFAULT_ADJUSTMENT_DETAIL_TEMP };
    @track existingAdj = {};
    @track disableCareLevel = false;
    @track localRateTypeOptions;

    // ─── Lifecycle ──────────────────────────────────────────────────────────────

    connectedCallback() {
        this._doInit();
    }

    // ─── Private: doInit logic ───────────────────────────────────────────────────

    _doInit() {
        const subPaymentDetail = this.subPaymentDetail ? { ...this.subPaymentDetail } : {};
        let adjustmentDetail = { ...this.adjustmentDetail };

        // Resolve rate type options keyed by care date map
        if (this.rateTypeOptionsCareDateMap != null) {
            this.localRateTypeOptions = this.rateTypeOptionsCareDateMap[subPaymentDetail.ExternalId];
        } else {
            // FIX 3: Null + length guard before spreading this.rateTypeOptions to avoid
            // "Cannot spread null/undefined" runtime errors.
            this.localRateTypeOptions = (this.rateTypeOptions && this.rateTypeOptions.length > 0)
                ? [...this.rateTypeOptions]
                : [];
        }

        const adjustmentDetailList = this.adjustmentDetailList;

        if (!adjustmentDetailList || adjustmentDetailList.length === 0) {
            // No existing adjustment — initialise from subPaymentDetail
            adjustmentDetail.NBR_HOURS_AUTH_ADJD__c = 0;
            adjustmentDetail.NBR_HOURS_ATTND_ADJD__c = 0;
            adjustmentDetail.IND_OVERRIDE__c = false;

            if (!subPaymentDetail.amt_rate__c) {
                subPaymentDetail.amt_rate__c = 0;
            }

            adjustmentDetail.AMT_PAID_RATE_ADJD__c = 0;
            adjustmentDetail.AMT_DETAIL_ADJMT__c = 0;

            if (this.localRateTypeOptions && this.localRateTypeOptions.length > 0) {
                adjustmentDetail.CDE_TYPE_RATE_ADJD__c = subPaymentDetail.cde_type_unit_care__c;
            }

            if (this.slotCntcheckbox === true) {
                adjustmentDetail.CDE_TYPE_UNIT_ADJD__c = subPaymentDetail.cde_time_trdnl__c || '';
                adjustmentDetail.CDE_CARE_LEVEL_ADJD__c = subPaymentDetail.cde_level_care__c || '';
            }

            // Resolve display labels for read-only display columns.
            // The server returns cde_type_unit_care__c and cde_time_trdnl__c as API codes for
            // new rows (no existing adjustment). displayRateType / displayUnitPaid getters
            // handle the translation at render time — no need to mutate subPaymentDetail here.
            // We only need to translate cde_level_care__c since it's rendered directly
            // (no computed getter for it).
            const careLevelOptionsMap = this.careLevelOptionsMap;
            if (careLevelOptionsMap != null) {
                const levelLabel = careLevelOptionsMap[subPaymentDetail.cde_level_care__c];
                if (levelLabel !== undefined && levelLabel !== null && levelLabel !== '') {
                    subPaymentDetail.cde_level_care__c = levelLabel;
                }
            }

            this.adjustmentDetail = { ...adjustmentDetail };
        } else {
            const rateTypeOptionsMap = this.rateTypeOptionsMap;
            const rateTypeOptions    = this.localRateTypeOptions || this._rateTypeOptions || [];

            // Build { labelString → apiCode } from whichever source has data
            const labelToCode = {};
            if (Array.isArray(rateTypeOptionsMap) && rateTypeOptionsMap.length > 0) {
                // Shape A: array of { label, value }
                rateTypeOptionsMap.forEach(opt => {
                    if (opt && opt.label !== undefined && opt.value !== undefined) {
                        labelToCode[opt.label] = opt.value;
                    }
                });
            } else if (rateTypeOptionsMap && typeof rateTypeOptionsMap === 'object'
                    && Object.keys(rateTypeOptionsMap).length > 0) {
                // Shape B: { key → { label, value } }
                Object.keys(rateTypeOptionsMap).forEach(key => {
                    const entry = rateTypeOptionsMap[key];
                    if (entry && entry.label !== undefined && entry.value !== undefined) {
                        labelToCode[entry.label] = entry.value;
                    }
                });
            }
            // Also scan localRateTypeOptions / _rateTypeOptions (the combobox options array)
            // as a fallback — these always have the correct { label, value } pairs
            if (Object.keys(labelToCode).length === 0 && rateTypeOptions.length > 0) {
                rateTypeOptions.forEach(opt => {
                    if (opt && opt.label !== undefined && opt.value !== undefined) {
                        labelToCode[opt.label] = opt.value;
                    }
                });
            }

            const existingDetail = { ...adjustmentDetailList[0] };
            if (existingDetail.CDE_TYPE_RATE_ADJD__c && Object.keys(labelToCode).length > 0) {
                const savedLabel  = existingDetail.CDE_TYPE_RATE_ADJD__c;
                const matchedCode = labelToCode[savedLabel];
                if (matchedCode !== undefined && matchedCode !== null) {
                    existingDetail.CDE_TYPE_RATE_ADJD__c = matchedCode;
                }
            }

            // Calculate adjustment amount
            if (subPaymentDetail.amt_slot_paid__c != null) {
                existingDetail.AMT_DETAIL_ADJMT__c = existingDetail.AMT_PAID_RATE_ADJD__c - subPaymentDetail.amt_slot_paid__c;
            } else {
                existingDetail.AMT_DETAIL_ADJMT__c = existingDetail.AMT_PAID_RATE_ADJD__c - subPaymentDetail.amt_rate__c;
            }
            if (!existingDetail.CDE_TYPE_RATE_ADJD__c && subPaymentDetail.cde_type_unit_care__c) {
                existingDetail.CDE_TYPE_RATE_ADJD__c = subPaymentDetail.cde_type_unit_care__c;
            }

            // Apply care level disable logic
            const rateType = existingDetail.CDE_TYPE_RATE_ADJD__c;
            this.disableCareLevel = DISABLE_CARE_LEVEL_RATE_TYPES.includes(rateType);

            this.adjustmentDetail = { ...existingDetail };
            this.adjustmentDetailTemp = { ...existingDetail };
        }
        const existAdjWrap = this.existAdjWrap || {};
        const existAdjFromWrap = existAdjWrap[subPaymentDetail.ExternalId];
        const existAdjFromList = (adjustmentDetailList && adjustmentDetailList.length > 0)
            ? adjustmentDetailList[0]
            : null;
        this.existingAdj = existAdjFromWrap || existAdjFromList || {};

        // Fire initial event to register in parent map
        this._fireEvent();
    }

    // ─── Private: fire createadjustdetails event ─────────────────────────────────

    _fireEvent() {
        const subPaymentDetail = this.subPaymentDetail || {};
        const event = new CustomEvent('createadjustdetails', {
            bubbles: true,
            composed: true,
            detail: {
                adjustmentDetailObj: { ...this.adjustmentDetail },
                key: subPaymentDetail.ExternalId,
                adjustmentDetailTemp: { ...this.adjustmentDetailTemp },
                isARTFee: this.artFeeFlag
            }
        });
        this.dispatchEvent(event);
    }

    // ─── Public API ──────────────────────────────────────────────────────────────

    /**
     * Validates all input fields including custom child components.
     * Called by parent via component reference (equivalent to aura:method validateEachRow).
     * Validates:
     * - lightning-input elements
     * - c-multiselect-combobox custom components
     * @returns {boolean} true if all fields are valid, false otherwise
     */
    @api
    validateEachRow() {
        let validity = true;

        // Validate lightning-input elements
        const inputs = this.template.querySelectorAll('lightning-input');
        inputs.forEach(input => {
            input.reportValidity();
            if (!input.checkValidity()) {
                validity = false;
            }
        });

        // Validate c-multiselect-combobox custom components
        const multiselectComboboxes = this.template.querySelectorAll('c-multiselect-combobox');
        multiselectComboboxes.forEach(combobox => {
            if (combobox && typeof combobox.reportValidity === 'function') {
                combobox.reportValidity();
            }
            if (combobox && typeof combobox.checkValidity === 'function') {
                if (!combobox.checkValidity()) {
                    validity = false;
                }
            }
        });

        return validity;
    }

    // ─── Event Handlers ──────────────────────────────────────────────────────────

    /**
     * Handles the selection checkbox change (Adjustment_Initiated__c).
     * Toggles the flag on both adjustmentDetail and adjustmentDetailTemp, then fires event.
     */
    handleCheckboxChange(event) {
        const checked = event.target.checked;
        this.adjustmentDetail = {
            ...this.adjustmentDetail,
            Adjustment_Initiated__c: checked
        };
        this.adjustmentDetailTemp = {
            ...this.adjustmentDetailTemp,
            Adjustment_Initiated__c: checked
        };
        this._fireEvent();
    }

    /**
     * Handles dropdown (select) changes for rateType, careUnit, careLevel.
     * Applies care level disable logic when rate type is 13, 19, or 25.
     * Updated to handle c-multiselect-combobox event structure:
     * - event.detail.payload.value (standard multiselectCombobox)
     * - event.detail.value (fallback)
     * - event.target.value (legacy fallback)
     */
    handleSelectChange(event) {
        const fieldName = event.target.dataset.field;

        // Handle c-multiselect-combobox event structure
        let value;
        if (event.detail && event.detail.payload && event.detail.payload.value !== undefined) {
            // Standard multiselectCombobox event structure
            value = event.detail.payload.value;
        } else if (event.detail && event.detail.value !== undefined) {
            // Fallback for direct value structure
            value = event.detail.value;
        } else {
            // Legacy fallback
            value = event.target.value;
        }

        this.adjustmentDetail = {
            ...this.adjustmentDetail,
            [fieldName]: value
        };

        // Apply care level disable logic for slot contract mode
        if (this.slotCntcheckbox === true && fieldName === 'CDE_TYPE_RATE_ADJD__c') {
            if (DISABLE_CARE_LEVEL_RATE_TYPES.includes(value)) {
                if (this.adjustmentDetail.CDE_CARE_LEVEL_ADJD__c !== '8') {
                    this.adjustmentDetail = {
                        ...this.adjustmentDetail,
                        CDE_CARE_LEVEL_ADJD__c: '8'
                    };
                }
                this.disableCareLevel = true;
            } else {
                this.disableCareLevel = false;
            }
        }

        this._fireEvent();
    }

    /**
     * Handles currency / number input changes (e.g. AMT_PAID_RATE_ADJD__c, NBR_HOURS_AUTH_ADJD__c, etc.).
     */
    handleAmountChange(event) {
        const fieldName = event.target.dataset.field;
        const value = parseFloat(event.detail.value);

        const artFeeFields = ['Activity_Fee_Paid__c', 'Registration_Fee_Paid__c', 'Transportation_Fee_Paid__c'];
        if (artFeeFields.includes(fieldName)) {
            this.adjustmentDetailTemp = {
                ...this.adjustmentDetailTemp,
                [fieldName]: isNaN(value) ? 0 : value
            };
        } else {
            this.adjustmentDetail = {
                ...this.adjustmentDetail,
                [fieldName]: isNaN(value) ? 0 : value
            };
        }

        this._fireEvent();
    }

    /**
     * Handles the override checkbox change (IND_OVERRIDE__c).
     */
    handleOverrideChange(event) {
        const checked = event.target.checked;
        this.adjustmentDetail = {
            ...this.adjustmentDetail,
            IND_OVERRIDE__c: checked
        };
        this._fireEvent();
    }

    /**
     * Handles the calculate amount paid event.
     * Updates AMT_PAID_RATE_ADJD__c and recalculates AMT_DETAIL_ADJMT__c.
     * Equivalent to handlecalculateAmountPaid in the Aura controller.
     * 
     * In LWC, this is exposed as @api method so the parent can call it directly
     * (replacing the Aura application event pattern).
     * 
     * @param {Object} adjustmentDetailsMapUpdated - Map of adjustment details keyed by ExternalId
     */
    @api
    handleCalculateAmountPaid(adjustmentDetailsMapUpdated) {
        const subPaymentDetail = this.subPaymentDetail || {};
        let adjustmentDetail = { ...this.adjustmentDetail };

        // Handle both direct object parameter and event-style parameter for backward compatibility
        const updatedMap = (adjustmentDetailsMapUpdated && typeof adjustmentDetailsMapUpdated === 'object' && !adjustmentDetailsMapUpdated.detail)
            ? adjustmentDetailsMapUpdated
            : (adjustmentDetailsMapUpdated && adjustmentDetailsMapUpdated.detail ? adjustmentDetailsMapUpdated.detail.adjustmentDetailsMapUpdated : {});

        if (adjustmentDetail.Adjustment_Initiated__c === true) {
            const adjustmentDetailsMap = updatedMap || {};

            // Update AMT_PAID_RATE_ADJD__c from the map
            for (const key in adjustmentDetailsMapUpdated) {
                if (Object.prototype.hasOwnProperty.call(adjustmentDetailsMapUpdated, key)) {
                    if (subPaymentDetail.ExternalId === key) {
                        adjustmentDetail.AMT_PAID_RATE_ADJD__c = adjustmentDetailsMapUpdated[key].AMT_PAID_RATE_ADJD__c;
                    }
                }
            }

            if (adjustmentDetail.AMT_PAID_RATE_ADJD__c != null && adjustmentDetail.AMT_PAID_RATE_ADJD__c !== '') {
                const amtRate = this.slotCntcheckbox === true
                    ? subPaymentDetail.amt_slot_paid__c
                    : subPaymentDetail.amt_rate__c;

                const paidRate = parseFloat(adjustmentDetail.AMT_PAID_RATE_ADJD__c) || 0;
                const baseRate = parseFloat(amtRate) || 0;

                adjustmentDetail.AMT_DETAIL_ADJMT__c = paidRate > baseRate
                    ? paidRate - baseRate
                    : baseRate - paidRate;

                // Add ART fees to adjustment amount
                for (const key in adjustmentDetailsMapUpdated) {
                    if (Object.prototype.hasOwnProperty.call(adjustmentDetailsMapUpdated, key)) {
                        if (subPaymentDetail.ExternalId === key) {
                            const artFeeAmount =
                                parseFloat(adjustmentDetailsMapUpdated[key].Activity_Fee_Paid__c || 0) +
                                parseFloat(adjustmentDetailsMapUpdated[key].Registration_Fee_Paid__c || 0) +
                                parseFloat(adjustmentDetailsMapUpdated[key].Transportation_Fee_Paid__c || 0);
                            adjustmentDetail.AMT_DETAIL_ADJMT__c = artFeeAmount + adjustmentDetail.AMT_DETAIL_ADJMT__c;
                        }
                    }
                }
            }
        } else {
            // Reset all editable fields when not initiated
            adjustmentDetail.AMT_DETAIL_ADJMT__c = 0;
            adjustmentDetail.AMT_PAID_RATE_ADJD__c = 0;
            adjustmentDetail.NBR_HOURS_AUTH_ADJD__c = 0;
            adjustmentDetail.NBR_HOURS_ATTND_ADJD__c = 0;
            adjustmentDetail.IND_OVERRIDE__c = false;
        }

        this.adjustmentDetail = { ...adjustmentDetail };

        // Fire event to notify parent of the updated adjustmentDetail
        // This is critical for LWC since there's no automatic two-way binding like in Aura
        this._fireEvent();
    }

    // ─── Getters ─────────────────────────────────────────────────────────────────

    /**
     * Returns true when the row is a regular (non-ART) adjustment row.
     */
    get isMainRow() {
        return !this.artFeeFlag;
    }

    /**
     * Returns true when the row is an ART Fee row.
     */
    get isARTFeeRow() {
        return this.artFeeFlag === true;
    }

    /**
     * Returns true when the sub payment already has an existing adjustment (ind_adjmt__c === 'Y').
     */
    get isExistingAdj() {
        return this.subPaymentDetail && this.subPaymentDetail.ind_adjmt__c === 'Y';
    }

    /**
     * Returns true when the override rate input should be shown (IND_OVERRIDE__c is true).
     */
    get showOverrideInput() {
        return this.adjustmentDetail && this.adjustmentDetail.IND_OVERRIDE__c === true;
    }

    /**
     * Returns true when all inputs should be disabled (Adjustment_Initiated__c is false).
     */
    get isInputDisabled() {
        return !(this.adjustmentDetail && this.adjustmentDetail.Adjustment_Initiated__c);
    }

    /**
     * Returns true when the care level dropdown should be disabled.
     */
    get isCareLevelDisabled() {
        return this.isInputDisabled || this.disableCareLevel;
    }

    /**
     * Returns the display label for Authorized Rate Type (cde_type_unit_care__c).
     * Translates the API code to a human-readable label using rateTypeOptionsMap at render time.
     * rateTypeOptionsMap structure from server: { apiCode → labelString }
     * e.g. { "1": "Regular", "13": "Part-time" }
     * If the value is already a label (pre-translated by server for existing adj rows),
     * the lookup returns undefined and the original value is returned unchanged.
     */
    get displayRateType() {
        const code = this._subPaymentDetail && this._subPaymentDetail.cde_type_unit_care__c;
        if (!code) return code;
        const label = this._rateTypeOptionsMap && this._rateTypeOptionsMap[code];
        return (label !== undefined && label !== null && label !== '') ? label : code;
    }

    /**
     * Returns the 0-36 months enrollment payment indicator value.
     * Mirrors the Aura original: {! if(empty(v.subPaymentDetail.ind_0_36_months_enroll_pmt__c), 'N', v.subPaymentDetail.ind_0_36_months_enroll_pmt__c)}
     * Defaults to 'N' when the field is null/undefined/empty on the external object record,
     * which happens on records where the upstream batch/Heroku sync has not set the field.
     */
    get enrollmentPaymentIndicator() {
        const val = this._subPaymentDetail && this._subPaymentDetail.ind_0_36_months_enroll_pmt__c;
        return (val !== null && val !== undefined && val !== '') ? val : 'N';
    }

    /**
     * Returns the display label for Unit Paid (cde_time_trdnl__c).
     * Translates the API code to a human-readable label using careUnitTypeOptionsMap at render time.
     * careUnitTypeOptionsMap structure from server: { apiCode → labelString }
     * e.g. { "3": "Daily", "1": "Hourly" }
     * If the value is already a label (pre-translated by server for existing adj rows),
     * the lookup returns undefined and the original value is returned unchanged.
     */
    get displayUnitPaid() {
        const code = this._subPaymentDetail && this._subPaymentDetail.cde_time_trdnl__c;
        if (!code) return code;
        const label = this._careUnitTypeOptionsMap && this._careUnitTypeOptionsMap[code];
        return (label !== undefined && label !== null && label !== '') ? label : code;
    }

    /**
     * Returns the display label for Care Level Paid (cde_level_care__c) in slot contract mode.
     * Translates the API code to a human-readable label using careLevelOptionsMap at render time.
     * careLevelOptionsMap structure from server: { apiCode → labelString }
     * e.g. { "5": "24-30 Months" }
     */
    get displayCareLevelPaid() {
        const code = this._subPaymentDetail && this._subPaymentDetail.cde_level_care__c;
        if (!code) return code;
        const label = this._careLevelOptionsMap && this._careLevelOptionsMap[code];
        return (label !== undefined && label !== null && label !== '') ? label : code;
    }

    /**
     * Returns the display label for Rate Type Paid (cde_type_unit_care__c) in slot contract mode.
     * Reuses rateTypeOptionsMap — same map used by displayRateType for the regular mode column.
     * rateTypeOptionsMap structure from server: { apiCode → labelString }
     * e.g. { "1": "Regular" }
     */
    get displayRateTypePaid() {
        const code = this._subPaymentDetail && this._subPaymentDetail.cde_type_unit_care__c;
        if (!code) return code;
        const label = this._rateTypeOptionsMap && this._rateTypeOptionsMap[code];
        return (label !== undefined && label !== null && label !== '') ? label : code;
    }

    /**
     * Returns the display label for Adjusted Rate Type (CDE_TYPE_RATE_ADJD__c) on existing-adj
     * read-only rows in slot contract mode.
     * rateTypeOptionsMap structure from server: { apiCode → labelString }
     */
    get displayExistingAdjRateType() {
        const val = this.existingAdj && this.existingAdj.CDE_TYPE_RATE_ADJD__c;
        if (!val) return val;
        const label = this._rateTypeOptionsMap && this._rateTypeOptionsMap[val];
        return (label !== undefined && label !== null && label !== '') ? label : val;
    }

    // ─── Safe auth-relationship getters (guard against null idn_auth__r on vacant slot rows) ───
    // Aura used Apex-level null coalescing. In LWC, template bindings crash on null
    // intermediate objects. Use optional chaining in JS getters and bind to these
    // instead of the raw deep-access paths in the template. (CCCAP-7579)

    /**
     * Case ID (IDN_CASE__r.Name) — null for vacant slot sub-payments.
     */
    get authCaseName() {
        return this._subPaymentDetail?.idn_pmt_sub__r?.idn_auth__r?.IDN_CASE__r?.Name || '';
    }

    /**
     * Provider Name (IDN_PROVR__r.Name) — null for vacant slot sub-payments.
     */
    get authProviderName() {
        return this._subPaymentDetail?.idn_pmt_sub__r?.idn_auth__r?.IDN_PROVR__r?.Name || '';
    }

    /**
     * Child First Name (NAM_FIRST__c) — null for vacant slot sub-payments.
     */
    get authFirstName() {
        return this._subPaymentDetail?.idn_pmt_sub__r?.idn_auth__r?.NAM_FIRST__c || '';
    }

    /**
     * Child Last Name (NAM_LAST__c) — null for vacant slot sub-payments.
     */
    get authLastName() {
        return this._subPaymentDetail?.idn_pmt_sub__r?.idn_auth__r?.NAM_LAST__c || '';
    }
}