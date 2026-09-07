import { LightningElement, api, track } from 'lwc';
import { abs_helper } from 'c/abstract_Component';

export default class AdjustmentFlow_AdjustmentSummary_lwc extends LightningElement {

    // ─── @api properties (read-only / primitive / no internal mutation needed) ──
    @api recordId;
    @api currentTabNumber;
    @api individualObj;
    @api adjustmentEntryEditMode;
    @api subPaymentDetail;
    @api rateTypeOptions;
    @api disabledARTFees = false;
    @api pageMode = 'view';
    @api slotCntcheckbox = false;
    @api activeARTFeeRecords = [];

    // ─── Loop Prevention Flags ──────────────────────────────────────────────────
    // These flags prevent infinite loops in two-way binding scenarios where:
    // 1. Parent sets @api property → setter fires
    // 2. Setter calculates and fires event → parent updates state
    // 3. Parent re-sets @api property → LOOP
    // By tracking when we're in a "parent-initiated" context, we skip firing events.
    _isParentSettingValue = false;
    _lastFiredAdjustmentAmount = null;
    _lastFiredAdjustmentDtlWarpLength = null;
    _lastFiredAdjustDetailMapKeys = null;

    // ─── Internal @track state (mutable copies of @api inputs) ─────────────────
    @track _adjustmentObj;
    @track _adjustmentDtlWarp = [];
    @track _adjustDetailMap;
    @track _rateTypeOptionsMap;
    @track _selectedSubPayment;
    @track _careUnitTypeOptions;
    @track _careLevelOptions;
    @track _careUnitTypeOptionsMap;
    @track _careLevelOptionsMap;
    @track _childCurrentUtilization;

    // ─── @api getters/setters ───────────────────────────────────────────────────

    @api
    get adjustmentObj() {
        return this._adjustmentObj;
    }
    set adjustmentObj(value) {
        this._adjustmentObj = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : null;
    }

    @api
    get adjustmentDtlWarp() {
        return this._adjustmentDtlWarp;
    }
    set adjustmentDtlWarp(value) {
        // Set flag to indicate parent is setting value - prevents event loop
        this._isParentSettingValue = true;
        try {
            this._adjustmentDtlWarp = (value !== null && value !== undefined)
                ? JSON.parse(JSON.stringify(value))
                : [];
            // Recalculate total when data changes from parent
            // Note: _calculateTotalAmount will NOT fire events because _isParentSettingValue is true
            if (this._adjustmentDtlWarp && this._adjustmentDtlWarp.length > 0) {
                this._calculateTotalAmount(this._adjustmentDtlWarp);
            }
        } finally {
            this._isParentSettingValue = false;
        }
    }

    @api
    get adjustDetailMap() {
        return this._adjustDetailMap;
    }
    set adjustDetailMap(value) {
        this._adjustDetailMap = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : null;
    }

    @api
    get rateTypeOptionsMap() {
        return this._rateTypeOptionsMap;
    }
    set rateTypeOptionsMap(value) {
        this._rateTypeOptionsMap = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : null;
    }

    @api
    get selectedSubPayment() {
        return this._selectedSubPayment;
    }
    set selectedSubPayment(value) {
        this._selectedSubPayment = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : null;
    }

    @api
    get careUnitTypeOptions() {
        return this._careUnitTypeOptions;
    }
    set careUnitTypeOptions(value) {
        this._careUnitTypeOptions = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : null;
    }

    @api
    get careLevelOptions() {
        return this._careLevelOptions;
    }
    set careLevelOptions(value) {
        this._careLevelOptions = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : null;
    }

    @api
    get careUnitTypeOptionsMap() {
        return this._careUnitTypeOptionsMap;
    }
    set careUnitTypeOptionsMap(value) {
        this._careUnitTypeOptionsMap = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : null;
    }

    @api
    get careLevelOptionsMap() {
        return this._careLevelOptionsMap;
    }
    set careLevelOptionsMap(value) {
        this._careLevelOptionsMap = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : null;
    }

    @api
    get childCurrentUtilization() {
        return this._childCurrentUtilization;
    }
    set childCurrentUtilization(value) {
        this._childCurrentUtilization = (value !== null && value !== undefined)
            ? JSON.parse(JSON.stringify(value))
            : null;
    }

    // ─── @track properties ─────────────────────────────────────────────────────
    @track sortField;
    @track sortAsc = true;
    @track showSpinner = false;

    // ─── Lifecycle ──────────────────────────────────────────────────────────────

    connectedCallback() {
        this._doInit();
    }

    // ─── Getters ────────────────────────────────────────────────────────────────

    /**
     * Returns true when Provider ID is populated (show Case ID column in table)
     */
    get showCaseIdColumn() {
        return this._adjustmentObj && this._adjustmentObj.IDN_PROVR__c;
    }

    /**
     * Returns true when Case ID is populated (show Provider columns in table)
     */
    get showProviderColumns() {
        return this._adjustmentObj && this._adjustmentObj.IDN_CASE__c;
    }

    /**
     * Returns true when adjustment exists and pageMode is not 'view' (show action column)
     */
    get showActionColumn() {
        return !(this._adjustmentObj && this.pageMode === 'view');
    }

    /**
     * Returns the adjustment amount formatted for display.
     * For Recovery type with non-zero amount, returns negative value.
     */
    get adjustmentAmountDisplay() {
        if (!this._adjustmentObj) return 0;
        const amount = this._adjustmentObj.AMT_ADJMT__c || 0;
        if (amount !== 0 && this._adjustmentObj.CDE_TYPE_ADJMT__c === 'Recovery') {
            return -amount;
        }
        return amount;
    }

    /**
     * Returns the primary caretaker name formatted as "FirstName, LastName"
     */
    get primaryCaretakerName() {
        if (this.individualObj && this.individualObj.NAM_FIRST__c && this.individualObj.NAM_LAST__c) {
            return `${this.individualObj.NAM_FIRST__c}, ${this.individualObj.NAM_LAST__c}`;
        }
        return '';
    }

    /**
     * Returns true if there are adjustment detail wrappers to display
     */
    get hasAdjustmentDetails() {
        return this._adjustmentDtlWarp && this._adjustmentDtlWarp.length > 0;
    }

    // ─── Sort Icon Getters ──────────────────────────────────────────────────────

    get sortIconProviderID() {
        return this._getSortIcon('subPaymentDetails.idn_pmt_sub__r.idn_auth__r.IDN_PROVR__r.Name');
    }
    get sortIconProviderName() {
        return this._getSortIcon('subPaymentDetails.idn_pmt_sub__r.idn_auth__r.NAM_FACILITY__c');
    }
    get sortIconCaseID() {
        return this._getSortIcon('subPaymentDetails.idn_pmt_sub__r.idn_auth__r.IDN_CASE__r.Name');
    }
    get sortIconChildFirstName() {
        return this._getSortIcon('subPaymentDetails.idn_pmt_sub__r.idn_auth__r.NAM_FIRST__c');
    }
    get sortIconChildLastName() {
        return this._getSortIcon('subPaymentDetails.idn_pmt_sub__r.idn_auth__r.NAM_LAST__c');
    }
    get sortIconCareDate() {
        return this._getSortIcon('subPaymentDetails.dte_care__c');
    }
    get sortIconAuthorizedHours() {
        return this._getSortIcon('subPaymentDetails.cde_unit_care_exptd__c');
    }
    get sortIconAuthorizedRateType() {
        return this._getSortIcon('subPaymentDetails.cde_type_unit_care__c');
    }
    get sortIconAttendedHours() {
        return this._getSortIcon('subPaymentDetails.cde_unit_care_actual__c');
    }
    get sortIconUnitPaid() {
        return this._getSortIcon('subPaymentDetails.cde_time_trdnl__c');
    }
    get sortIconRatePaid() {
        return this._getSortIcon('subPaymentDetails.amt_rate__c');
    }
    get sortIconParentFee() {
        return this._getSortIcon('subPaymentDetails.amt_copay__c');
    }
    get sortIconAmountPaid() {
        return this._getSortIcon('subPaymentDetails.amt_total__c');
    }
    get sortIconAdjustedAuthHours() {
        return this._getSortIcon('ajustmentDetails.NBR_HOURS_AUTH_ADJD__c');
    }
    get sortIconAdjustedAttendedHours() {
        return this._getSortIcon('ajustmentDetails.NBR_HOURS_ATTND_ADJD__c');
    }
    get sortIconAdjustedRateType() {
        return this._getSortIcon('ajustmentDetails.CDE_TYPE_RATE_ADJD__c');
    }
    get sortIconAdjustedRatePaid() {
        return this._getSortIcon('ajustmentDetails.AMT_PAID_RATE_ADJD__c');
    }
    get sortIconAdjustedAmount() {
        return this._getSortIcon('ajustmentDetails.AMT_DETAIL_ADJMT__c');
    }

    // ─── Private Methods ────────────────────────────────────────────────────────

    /**
     * Initialization logic - fetches picklist options and calculates total amount
     */
    _doInit() {
        // Fetch picklist options
        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'getPicklistOptions',
            (response) => {
                if (response.objectData) {
                    if (response.objectData.careUnitTypeOptions) {
                        this._careUnitTypeOptions = response.objectData.careUnitTypeOptions;
                    }
                    if (response.objectData.careUnitTypeOptionsMap) {
                        this._careUnitTypeOptionsMap = response.objectData.careUnitTypeOptionsMap;
                    }
                    if (response.objectData.careLevelOptions) {
                        this._careLevelOptions = response.objectData.careLevelOptions;
                    }
                    if (response.objectData.careLevelOptionsMap) {
                        this._careLevelOptionsMap = response.objectData.careLevelOptionsMap;
                    }
                }
            },
            null,
            null
        );

        // Calculate total amount if adjustment details exist
        if (this._adjustmentDtlWarp && this._adjustmentDtlWarp.length > 0) {
            this._calculateTotalAmount(this._adjustmentDtlWarp);
        } else {
            this._setAdjustmentAmount(0);
        }
    }

    /**
     * Calculates total adjustment amount from all detail wrappers
     */
    _calculateTotalAmount(adjustmentDtlWarp) {
        let totalAmount = 0;
        for (let i = 0; i < adjustmentDtlWarp.length; i++) {
            if (adjustmentDtlWarp[i].ajustmentDetails && adjustmentDtlWarp[i].ajustmentDetails.AMT_DETAIL_ADJMT__c) {
                totalAmount = totalAmount + parseFloat(adjustmentDtlWarp[i].ajustmentDetails.AMT_DETAIL_ADJMT__c);
            }
        }
        this._setAdjustmentAmount(totalAmount);
    }

    /**
     * Sets the adjustment amount on the internal _adjustmentObj and fires event to parent.
     * LOOP PREVENTION: Only fires event if:
     * 1. Not in a parent-initiated setter context (_isParentSettingValue is false)
     * 2. The amount has actually changed from the last fired value
     */
    _setAdjustmentAmount(amount) {
        if (this._adjustmentObj) {
            // Update internal state to trigger reactivity using deep copy
            const updated = JSON.parse(JSON.stringify(this._adjustmentObj));
            updated.AMT_ADJMT__c = amount;
            this._adjustmentObj = updated;

            // LOOP PREVENTION: Skip firing event if parent is setting value
            // This prevents: parent sets adjustmentDtlWarp → setter calculates → fires event → parent updates → LOOP
            if (this._isParentSettingValue) {
                return;
            }

            // LOOP PREVENTION: Only fire event if amount actually changed
            if (this._lastFiredAdjustmentAmount !== amount) {
                this._lastFiredAdjustmentAmount = amount;
                this._fireAdjustmentObjChange();
            }
        }
    }

    /**
     * Fires adjustmentobjchange event to sync with parent (LWC two-way binding).
     * LOOP PREVENTION: This method should only be called after guards have been checked.
     */
    _fireAdjustmentObjChange() {
        this.dispatchEvent(
            new CustomEvent('adjustmentobjchange', {
                detail: { adjustmentObj: this._adjustmentObj }
            })
        );
    }

    /**
     * Returns the sort icon name based on current sort state
     */
    _getSortIcon(fieldName) {
        if (this.sortField === fieldName) {
            return this.sortAsc ? 'utility:arrowup' : 'utility:arrowdown';
        }
        return null;
    }

    /**
     * Gets nested field value from object using dot notation path
     */
    _fieldValue(object, fieldPath) {
        let result = object;
        fieldPath.forEach(function (field) {
            if (result) {
                result = result[field];
            }
        });
        return result;
    }

    /**
     * Sorts the _adjustmentDtlWarp array by the specified field
     */
    _sortBy(fieldId) {
        const field = fieldId;
        const sortField = fieldId;
        const records = this._adjustmentDtlWarp ? JSON.parse(JSON.stringify(this._adjustmentDtlWarp)) : [];
        const dummyRecordArray = [];
        const sortedRecord = [];
        const fieldPath = field.split(/\./);
        const fieldValue = this._fieldValue.bind(this);

        // dummyRecord will possess all objects from all records
        for (let i = 0; i < records.length; i++) {
            dummyRecordArray[i] = JSON.parse(JSON.stringify(records[i]));
            // Additional attribute 'parentIndex' is added to keep track of actual index
            dummyRecordArray[i].parentIndex = i;
        }

        // Toggle sort direction if same field, otherwise default to ascending
        const newSortAsc = sortField !== this.sortField || !this.sortAsc;

        // Sort dummyRecord Array
        dummyRecordArray.sort(function (a, b) {
            const aValue = fieldValue(a, fieldPath);
            const bValue = fieldValue(b, fieldPath);
            const t1 = aValue === bValue;
            const t2 = (!aValue && bValue) || (aValue < bValue);
            return t1 ? 0 : (newSortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });

        for (let i = 0; i < records.length; i++) {
            sortedRecord.push(records[dummyRecordArray[i].parentIndex]);
        }

        this.sortAsc = newSortAsc;
        this.sortField = fieldId;
        this._adjustmentDtlWarp = sortedRecord;
    }

    // ─── Event Handlers ─────────────────────────────────────────────────────────

    /**
     * Handles column header click for sorting
     */
    handleSortByColumn(event) {
        const dataToSort = this._adjustmentDtlWarp;
        if (dataToSort != null && dataToSort !== undefined) {
            const idToSort = event.currentTarget.dataset.id;
            if (idToSort !== undefined && idToSort !== '') {
                this._sortBy(idToSort);
            }
        }
    }

    /**
     * Handles the adjustmentDetailSummary event from child components
     * This is the LWC equivalent of the Aura application event handler
     */
    @api
    handleAdjustmentDetailSummaryEvent(eventData) {
        const adjustmentAmount = eventData.adjustmentAmount;
        const subPaymentDetail = eventData.subPaymentDetail;
        const rateTypeOptions = eventData.rateTypeOptions;
        const selectedSubPayment = eventData.selectedSubPayment;
        const adjustmentDtlWarp = eventData.adjustmentDtlWarp;
        const adjustDetailMap = eventData.adjustDetailMap;

        this._adjustmentDtlWarp = (adjustmentDtlWarp !== null && adjustmentDtlWarp !== undefined)
            ? JSON.parse(JSON.stringify(adjustmentDtlWarp))
            : [];
        this._rateTypeOptionsMap = (rateTypeOptions !== null && rateTypeOptions !== undefined)
            ? JSON.parse(JSON.stringify(rateTypeOptions))
            : null;
        this._selectedSubPayment = (selectedSubPayment !== null && selectedSubPayment !== undefined)
            ? JSON.parse(JSON.stringify(selectedSubPayment))
            : null;

        if (adjustDetailMap) {
            this._adjustDetailMap = JSON.parse(JSON.stringify(adjustDetailMap));
        }

        // Fetch updated adjustment details map and current utilization
        if (this._adjustmentObj && this._adjustmentObj.Id) {
            this._fetchAdjustmentDetailsMap(this._adjustmentObj.Id);
            this._fetchCurrentUtilization(this._adjustmentObj.Id);
        }
    }

    /**
     * Fetches the adjustment details map from server
     */
    _fetchAdjustmentDetailsMap(adjustmentId) {
        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'getAdjustmentDetailsMap',
            (response) => {
                if (response) {
                    this._adjustDetailMap = response;
                }
            },
            JSON.stringify({ adjustmentId: adjustmentId }),
            null
        );
    }

    /**
     * Fetches the current utilization record from server
     */
    _fetchCurrentUtilization(adjustmentId) {
        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'getCurrentUtilizationRecord',
            (response) => {
                if (response.objectData && response.objectData.currentUtilizationMap) {
                    this._childCurrentUtilization = response.objectData.currentUtilizationMap;
                }
            },
            JSON.stringify({ adjustmentId: adjustmentId }),
            null
        );
    }

    /**
     * Handles changes to _adjustmentDtlWarp - recalculates total amount
     * This is the LWC equivalent of the Aura change handler
     */
    @api
    updateTotalAmount() {
        if (this._adjustmentDtlWarp && this._adjustmentDtlWarp.length > 0) {
            this._calculateTotalAmount(this._adjustmentDtlWarp);
        } else {
            this._setAdjustmentAmount(0);
        }
    }

    /**
     * Handles the adjustmentdetailsummary event from the modal
     */
    handleAdjustmentDetailSummary(event) {
        const detail = event.detail;
        if (detail) {
            this.handleAdjustmentDetailSummaryEvent(detail);
        }
    }

    /**
     * Handles the adjustdetailmapchange event from adjustmentDetailRow_lwc.
     * This event is fired when the adjustDetailMap is updated (e.g., during ART Fee merge or edit).
     * @param {CustomEvent} event - event.detail contains the updated adjustDetailMap
     */
    handleAdjustDetailMapChange(event) {
        if (event && event.detail) {
            // Update internal adjustDetailMap
            this._adjustDetailMap = (event.detail !== null && event.detail !== undefined)
                ? JSON.parse(JSON.stringify(event.detail))
                : null;

            // Bubble the event to parent (adjustmentFlow_lwc)
            this.dispatchEvent(new CustomEvent('adjustdetailmapchange', {
                detail: this._adjustDetailMap,
                bubbles: true,
                composed: true
            }));
        }
    }

    /**
     * Handles the createadjustdetails event from adjustmentDetailRow_lwc.
     * This event is fired when a row is edited or deleted.
     * 
     * Event detail structures from adjustmentDetailRow_lwc:
     * 
     * 1. Edit action (after modal save):
     *    { action, adjustmentDtlWarp (array), adjustmentAmount, subPaymentDetail, 
     *      rateTypeOptions, selectedSubPayment, adjustDetailMap }
     * 
     * 2. Delete action:
     *    { adjustmentDtlWarpArr (filtered array), adjustDetailMap }
     * 
     * 3. Edit request (to open modal - bubbled to parent):
     *    { existAdjWrap (single wrapper with ajustmentDetails.Id) }
     * 
     * @param {CustomEvent} event - event.detail contains updated data
     */
    handleCreateAdjustDetails(event) {
        const detail = event.detail || {};

        // CASE 1: Check if this is an edit request to open the modal
        // The existAdjWrap property is set when we need to bubble to parent to open modal
        // Also check if detail itself is a wrapper (fallback for direct wrapper dispatch)
        const existAdjWrap = detail.existAdjWrap;
        const isDirectWrapper = !existAdjWrap && detail.ajustmentDetails && detail.ajustmentDetails.Id;

        if (existAdjWrap || isDirectWrapper) {
            const wrapperToEdit = existAdjWrap || detail;
            // This is an edit request - bubble the event to parent to open the modal
            this.dispatchEvent(new CustomEvent('createadjustdetails', {
                detail: { existAdjWrap: wrapperToEdit },
                bubbles: true,
                composed: true
            }));
            return;
        }

        // CASE 2: Handle delete action - adjustmentDtlWarpArr is the updated array after deletion
        if (detail.adjustmentDtlWarpArr) {
            this._adjustmentDtlWarp = JSON.parse(JSON.stringify(detail.adjustmentDtlWarpArr));
        }

        // CASE 3: Handle edit/save action from modal - adjustmentDtlWarp is the updated data
        if (detail.adjustmentDtlWarp && !detail.adjustmentDtlWarpArr) {
            const updatedWrap = detail.adjustmentDtlWarp;
            if (Array.isArray(updatedWrap)) {
                // If it's an array, replace the entire list
                this._adjustmentDtlWarp = JSON.parse(JSON.stringify(updatedWrap));
            } else if (updatedWrap && updatedWrap.ajustmentDetails && updatedWrap.ajustmentDetails.Id) {
                // If it's a single wrapper, find and update it in the array
                const index = this._adjustmentDtlWarp.findIndex(
                    wrap => wrap.ajustmentDetails && wrap.ajustmentDetails.Id === updatedWrap.ajustmentDetails.Id
                );
                if (index !== -1) {
                    const updatedList = JSON.parse(JSON.stringify(this._adjustmentDtlWarp));
                    updatedList[index] = JSON.parse(JSON.stringify(updatedWrap));
                    this._adjustmentDtlWarp = updatedList;
                } else {
                    // New item - add to the list
                    const updatedList = JSON.parse(JSON.stringify(this._adjustmentDtlWarp));
                    updatedList.push(JSON.parse(JSON.stringify(updatedWrap)));
                    this._adjustmentDtlWarp = updatedList;
                }
            }
        }

        // Update adjustDetailMap if provided
        if (detail.adjustDetailMap) {
            this._adjustDetailMap = JSON.parse(JSON.stringify(detail.adjustDetailMap));
        }

        // Update rateTypeOptions if provided
        if (detail.rateTypeOptions) {
            this._rateTypeOptionsMap = (typeof detail.rateTypeOptions === 'object')
                ? JSON.parse(JSON.stringify(detail.rateTypeOptions))
                : detail.rateTypeOptions;
        }

        // Update selectedSubPayment if provided
        if (detail.selectedSubPayment !== undefined) {
            this._selectedSubPayment = (detail.selectedSubPayment !== null && detail.selectedSubPayment !== undefined)
                ? JSON.parse(JSON.stringify(detail.selectedSubPayment))
                : null;
        }

        // Recalculate total amount
        if (this._adjustmentDtlWarp && this._adjustmentDtlWarp.length > 0) {
            this._calculateTotalAmount(this._adjustmentDtlWarp);
        } else {
            this._setAdjustmentAmount(0);
        }

        // Fire event to parent for two-way binding
        this._fireAdjustmentDetailSummary();
    }

    // ══════════════════════════════════════════════════════════════════════════
    // TWO-WAY BINDING EVENT DISPATCHERS
    // In Aura, child attribute changes auto-sync to parent via two-way binding.
    // In LWC, we must explicitly dispatch events so parent can update its state.
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * Dispatches adjustmentdetailsummary event to sync adjustment details with parent.
     * Call this whenever _adjustmentDtlWarp or _adjustDetailMap is modified.
     * LOOP PREVENTION: Only fires if data has actually changed from last fired values.
     */
    _fireAdjustmentDetailSummary() {
        // LOOP PREVENTION: Skip if parent is setting values
        if (this._isParentSettingValue) {
            return;
        }

        // LOOP PREVENTION: Check if data has actually changed
        const currentLength = this._adjustmentDtlWarp ? this._adjustmentDtlWarp.length : 0;
        const currentMapKeys = this._adjustDetailMap ? Object.keys(this._adjustDetailMap).sort().join(',') : '';

        // Only fire if something actually changed
        const lengthChanged = this._lastFiredAdjustmentDtlWarpLength !== currentLength;
        const mapChanged = this._lastFiredAdjustDetailMapKeys !== currentMapKeys;

        if (lengthChanged || mapChanged) {
            this._lastFiredAdjustmentDtlWarpLength = currentLength;
            this._lastFiredAdjustDetailMapKeys = currentMapKeys;

            this.dispatchEvent(new CustomEvent('adjustmentdetailsummary', {
                detail: {
                    adjustmentDtlWarp: this._adjustmentDtlWarp,
                    adjustDetailMap: this._adjustDetailMap,
                    adjustmentAmount: this._adjustmentObj?.AMT_ADJMT__c || 0
                },
                bubbles: true,
                composed: true
            }));
        }
    }

    /**
     * Handles delete action for an adjustment detail row.
     * Removes the detail from the list and recalculates total.
     * @param {CustomEvent} event - event.detail contains the index or id to delete
     */
    handleDeleteAdjustmentDetail(event) {
        const indexToDelete = event.detail?.index;
        const idToDelete = event.detail?.id;

        if (indexToDelete !== undefined && indexToDelete >= 0) {
            this._adjustmentDtlWarp = this._adjustmentDtlWarp.filter((_, idx) => idx !== indexToDelete);
        } else if (idToDelete) {
            this._adjustmentDtlWarp = this._adjustmentDtlWarp.filter(
                wrap => wrap.ajustmentDetails?.Id !== idToDelete
            );
        }

        // Recalculate total and notify parent
        this._calculateTotalAmount(this._adjustmentDtlWarp);
        this._fireAdjustmentDetailSummary();
    }

    /**
     * Handles edit action for an adjustment detail row.
     * Sets the component into edit mode for the specified detail.
     * @param {CustomEvent} event - event.detail contains the detail to edit
     */
    handleEditAdjustmentDetail(event) {
        const detailToEdit = event.detail?.adjustmentDetail;
        const index = event.detail?.index;

        if (detailToEdit || index !== undefined) {
            this.adjustmentEntryEditMode = true;
            // Additional edit logic can be added here
        }
    }

    /**
     * Handles save action after editing an adjustment detail.
     * Updates the detail in the list and recalculates total.
     * @param {CustomEvent} event - event.detail contains the updated detail
     */
    handleSaveAdjustmentDetail(event) {
        const updatedDetail = event.detail?.adjustmentDetail;
        const index = event.detail?.index;

        if (updatedDetail && index !== undefined && index >= 0) {
            const updatedList = JSON.parse(JSON.stringify(this._adjustmentDtlWarp));
            const updatedItem = JSON.parse(JSON.stringify(updatedList[index]));
            updatedItem.ajustmentDetails = JSON.parse(JSON.stringify(updatedDetail));
            updatedList[index] = updatedItem;
            this._adjustmentDtlWarp = updatedList;
        }

        this.adjustmentEntryEditMode = false;
        this._calculateTotalAmount(this._adjustmentDtlWarp);
        this._fireAdjustmentDetailSummary();
    }

    /**
     * Handles cancel action during edit mode.
     * Exits edit mode without saving changes.
     */
    handleCancelEdit() {
        this.adjustmentEntryEditMode = false;
    }

    /**
     * Handles the addition of a new adjustment detail from the modal.
     * Adds the new detail to the list and recalculates total.
     * @param {CustomEvent} event - event.detail contains the new detail wrapper
     */
    handleAddAdjustmentDetail(event) {
        const newDetailWrapper = event.detail?.adjustmentDetailWrapper;

        if (newDetailWrapper) {
            const updatedList = JSON.parse(JSON.stringify(this._adjustmentDtlWarp));
            updatedList.push(JSON.parse(JSON.stringify(newDetailWrapper)));
            this._adjustmentDtlWarp = updatedList;
            this._calculateTotalAmount(this._adjustmentDtlWarp);
            this._fireAdjustmentDetailSummary();
        }
    }

    /**
     * Handles changes to individual adjustment detail fields.
     * Updates the specific field and recalculates total if amount changed.
     * @param {CustomEvent} event - event.detail contains index, fieldName, and value
     */
    handleAdjustmentDetailFieldChange(event) {
        const { index, fieldName, value } = event.detail || {};

        if (index !== undefined && fieldName && this._adjustmentDtlWarp[index]) {
            const updatedList = JSON.parse(JSON.stringify(this._adjustmentDtlWarp));
            const updatedItem = JSON.parse(JSON.stringify(updatedList[index]));
            const updatedAjustmentDetails = JSON.parse(JSON.stringify(updatedItem.ajustmentDetails || {}));
            updatedAjustmentDetails[fieldName] = value;
            updatedItem.ajustmentDetails = updatedAjustmentDetails;
            updatedList[index] = updatedItem;
            this._adjustmentDtlWarp = updatedList;

            // Recalculate if amount field changed
            if (fieldName === 'AMT_DETAIL_ADJMT__c') {
                this._calculateTotalAmount(this._adjustmentDtlWarp);
            }
            this._fireAdjustmentDetailSummary();
        }
    }

    /**
     * Public API method to refresh the adjustment details from server.
     * Called by parent when data needs to be reloaded.
     */
    @api
    refreshAdjustmentDetails() {
        if (this._adjustmentObj && this._adjustmentObj.Id) {
            this._fetchAdjustmentDetailsMap(this._adjustmentObj.Id);
            this._fetchCurrentUtilization(this._adjustmentObj.Id);
        }
    }

    /**
     * Public API method to refresh data - alias for refreshAdjustmentDetails.
     * Called by parent component after modal operations.
     */
    @api
    refreshData() {
        this.refreshAdjustmentDetails();
    }
}