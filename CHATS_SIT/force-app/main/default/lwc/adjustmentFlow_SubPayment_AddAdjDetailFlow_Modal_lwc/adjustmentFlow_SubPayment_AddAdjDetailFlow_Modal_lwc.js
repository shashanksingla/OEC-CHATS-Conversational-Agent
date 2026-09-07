import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import { label } from 'c/labelUtility';

export default class AdjustmentFlow_SubPayment_AddAdjDetailFlow_Modal_lwc extends LightningModal {

    // ─── @api properties (passed from parent) ────────────────────────────────────

    // Primitive @api properties
    @api disabledARTFees = false;
    @api slotCntcheckbox = false;
    @api editMode = false;

    // Tab 1 specific primitive properties
    @api authId;
    @api caseId;
    @api slotCntId;
    @api searchBySlotCntId = false;
    @api paymentObjId;
    @api subPaymentObj_NAM_FIRST;
    @api servicePeriodObj_DTE_BEGIN_EFFV;
    @api subPaymentObj_Id;
    @api subPaymentObj_NAM_LAST;
    @api servicePeriodObj_DTE_END_EFFV;

    // ─── @track backing fields for object/array @api properties ─────────────────
    @track _adjustment = {};
    @track _subPaymentDetails = [];
    @track _existAdjWrap = {};
    @track _rateTypeOptions = [];
    @track _careUnitTypeOptions = [];
    @track _careLevelOptions = [];
    @track _adjustmentDetailList = [];
    @track _rateTypeOptionsCareDateMap = {};
    @track _careLevelOptionsMap = {};
    @track _careUnitTypeOptionsMap = {};
    @track _rateTypeOptionsMap = {};
    @track _adjustDetailMap = {};
    @track _childCurrentUtilization = {};
    @track _selectedSubPayment = null;
    @track _activeARTFeeRecords = [];

    // ─── @api getter/setter pairs for object/array properties ───────────────────

    @api
    get adjustment() { return this._adjustment; }
    set adjustment(value) {
        this._adjustment = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : {};
    }

    @api
    get subPaymentDetails() { return this._subPaymentDetails; }
    set subPaymentDetails(value) {
        this._subPaymentDetails = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : [];
    }

    @api
    get existAdjWrap() { return this._existAdjWrap; }
    set existAdjWrap(value) {
        this._existAdjWrap = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : {};
    }

    @api
    get rateTypeOptions() { return this._rateTypeOptions; }
    set rateTypeOptions(value) {
        this._rateTypeOptions = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : [];
    }

    @api
    get careUnitTypeOptions() { return this._careUnitTypeOptions; }
    set careUnitTypeOptions(value) {
        this._careUnitTypeOptions = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : [];
    }

    @api
    get careLevelOptions() { return this._careLevelOptions; }
    set careLevelOptions(value) {
        this._careLevelOptions = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : [];
    }

    @api
    get adjustmentDetailList() { return this._adjustmentDetailList; }
    set adjustmentDetailList(value) {
        this._adjustmentDetailList = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : [];
    }

    @api
    get rateTypeOptionsCareDateMap() { return this._rateTypeOptionsCareDateMap; }
    set rateTypeOptionsCareDateMap(value) {
        this._rateTypeOptionsCareDateMap = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : {};
    }

    @api
    get careLevelOptionsMap() { return this._careLevelOptionsMap; }
    set careLevelOptionsMap(value) {
        this._careLevelOptionsMap = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : {};
    }

    @api
    get careUnitTypeOptionsMap() { return this._careUnitTypeOptionsMap; }
    set careUnitTypeOptionsMap(value) {
        this._careUnitTypeOptionsMap = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : {};
    }

    @api
    get rateTypeOptionsMap() { return this._rateTypeOptionsMap; }
    set rateTypeOptionsMap(value) {
        this._rateTypeOptionsMap = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : {};
    }

    @api
    get adjustDetailMap() { return this._adjustDetailMap; }
    set adjustDetailMap(value) {
        this._adjustDetailMap = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : {};
    }

    @api
    get childCurrentUtilization() { return this._childCurrentUtilization; }
    set childCurrentUtilization(value) {
        this._childCurrentUtilization = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : {};
    }

    @api
    get selectedSubPayment() { return this._selectedSubPayment; }
    set selectedSubPayment(value) {
        this._selectedSubPayment = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : null;
    }

    @api
    get activeARTFeeRecords() { return this._activeARTFeeRecords; }
    set activeARTFeeRecords(value) {
        this._activeARTFeeRecords = (value !== null && value !== undefined) ? JSON.parse(JSON.stringify(value)) : [];
    }

    // ─── @track properties ───────────────────────────────────────────────────────
    @track currentTabNumber = 1;
    @track pageMessages = [];
    @track messageType = null;
    @track showSpinner = false;
    @track calculateBtnClicked = false;
    @track adjustmentDetailsMap = {};
    @track adjustmentDetailsARTFeeMap = {};
    @track isARTFeeCalculated = false;
    @track isARTFeeChanged = false;
    @track isFirstCalculate = false;
    @track adjustmentDetailsMapClone = {};
    @track adjustDetailMapClone = {};
    @track totalPaidAmount = '0';
    @track oldAdjustedAmount = 0;
    @track isOldAdjustedAmountSet = false;
    @track subPaymentSearchLst = [];
    @track errorMessageText = '';
    @track showARTFeeConfirmModal = false;
    @track showCancelConfirmModal = false;
    @track showPreviousConfirmModal = false;
    @track _pendingSaveAction = null; // 'save' or 'saveAndNew'
    @track _isCalculating = false; // true while the calculate server call is in-flight; guards calculateBtnClicked reset

    // ─── Getters ─────────────────────────────────────────────────────────────────

    // Used by lightning-modal-header (the modal window title bar)
    get tabHeaderName() {
        if (this.editMode) {
            return 'Adjustment Detail Edit';
        }
        return 'Adjustment Entry';
    }

    // Used by the card's inner <h1>
    // In edit mode, always shows 'Sub Payment Selection' (the step the user came from)
    // In normal flow, follows the tab number
    get cardHeaderName() {
        if (this.editMode) {
            return 'Sub Payment Selection';
        }
        return this.currentTabNumber === 1 ? 'Sub Payment Selection' : 'Sub Payment Details';
    }

    // Used by the card's inner <p> subtitle
    // In edit mode, always shows the sub payment description (context for the adjustment being edited)
    // In normal flow, only shown on Tab 1
    get cardHeaderTitle() {
        if (this.editMode) {
            return 'Select a sub payment record for the child and service period which the adjustment is applied for.';
        }
        return this.currentTabNumber === 1
            ? 'Select a sub payment record for the child and service period which the adjustment is applied for.'
            : '';
    }

    // Kept for backwards compatibility — not used in template directly
    get tabHeaderTitle() {
        return this.cardHeaderTitle;
    }

    get isTab1() {
        return this.currentTabNumber === 1;
    }

    get isTab2() {
        return this.currentTabNumber === 2;
    }

    get showNextBtn() {
        return this.currentTabNumber === 1;
    }

    get showPreviousBtn() {
        return this.currentTabNumber === 2;
    }

    get showCalculateBtn() {
        return this.currentTabNumber === 2;
    }

    get showSaveAndNewBtn() {
        // In edit mode (editing an existing row), Save And New is not shown —
        // mirrors Aura where showCustomButton defaults to false when opened from adjustmentDetailRow
        return this.currentTabNumber === 2 && !this.editMode;
    }

    get showFinishBtn() {
        return this.currentTabNumber === 2;
    }

    get hasPageMessages() {
        return this.pageMessages && this.pageMessages.length > 0;
    }

    // ─── Lifecycle ───────────────────────────────────────────────────────────────

    connectedCallback() {
        // If editMode is true, start at Tab 2 and initialize adjustmentDetailsMap
        if (this.editMode) {
            this.currentTabNumber = 2;
        }

        // Initialize adjustmentDetailsMap from adjustDetailMap if provided
        if (this.adjustDetailMap && Object.keys(this.adjustDetailMap).length > 0) {
            const map = {};
            for (const p in this.adjustDetailMap) {
                if (this.adjustDetailMap[p] && this.adjustDetailMap[p][0]) {
                    map[p] = this.adjustDetailMap[p][0];
                }
            }
            this.adjustmentDetailsMap = map;
        }

        // Set error message text for search limit
        this.errorMessageText = 'Over ' + (label.Subpayment_Search_Limit || '200') + ' records have been returned, please refine the search criteria';
    }

    // ─── Event Handlers ──────────────────────────────────────────────────────────

    /**
     * Handle search event from adjustmentFlow_SelectSubPayment_lwc
     */
    handleSearch(event) {
        const searchParams = event.detail || {};
        this.subPaymentSearchLst = [];

        // Determine whether this search is a Vacant Slot Contract search and
        // persist it on this.slotCntcheckbox so that Tab 2 receives the correct
        // column set when the user clicks Next.
        const isSlotSearch = searchParams.searchBySlotCntId !== undefined
            ? searchParams.searchBySlotCntId
            : this.slotCntcheckbox;
        this.slotCntcheckbox = isSlotSearch;

        const params = {
            paymentObjId: searchParams.paymentObjId || this.paymentObjId,
            subPaymentObjId: searchParams.subPaymentObjId || this.subPaymentObj_Id,
            subPaymentObjNAMFIRST: searchParams.subPaymentObjNAMFIRST || this.subPaymentObj_NAM_FIRST,
            servicePeriodObjDTEBEGINEFFV: searchParams.servicePeriodObjDTEBEGINEFFV || this.servicePeriodObj_DTE_BEGIN_EFFV,
            subPaymentObjNAMLAST: searchParams.subPaymentObjNAMLAST || this.subPaymentObj_NAM_LAST,
            servicePeriodObjDTEENDEFFV: searchParams.servicePeriodObjDTEENDEFFV || this.servicePeriodObj_DTE_END_EFFV,
            adjustmentInfo: this.adjustment,
            selectedAuthId: searchParams.authId || this.authId,
            selectedCaseId: searchParams.caseId || this.caseId,
            selectedSlotCntId: searchParams.slotCntId || this.slotCntId,
            slotCntcheckbox: isSlotSearch
        };

        this.showSpinner = true;
        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'doSearchSubPayment',
            (response) => {
                this.showSpinner = false;
                let newResult = response.objectData?.SubpaymentSearchResults || [];

                if (isSlotSearch && this.adjustment?.CDE_COUNTY__c) {
                    newResult = newResult.filter(x => x.slotCountySFID === this.adjustment.CDE_COUNTY__c);
                }

                this.subPaymentSearchLst = newResult;
            },
            JSON.stringify(params),
            null
        );
    }

    /**
     * Handle sub payment selection from child component
     */
    handleSubPaymentSelection(event) {
        this.selectedSubPayment = event.detail?.selectedSubPayment || event.detail;
    }

    /**
     * Handle Next button - moves from Tab 1 to Tab 2
     */
    handleNext() {
        if (this.currentTabNumber === 1) {
            this.adjustmentDetailsMap = {};

            if (this.selectedSubPayment) {
                this.showSpinner = true;

                const params = {
                    subPaymentId: this.selectedSubPayment.subPymtId,
                    selectedSubPayment: JSON.stringify(this.selectedSubPayment),
                    adjustmentInfo: this.adjustment
                };

                abs_helper.callServerAndHandleError(
                    this,
                    'AdjustmentFlowApxCtrl',
                    'doSearchSubPaymentDetails',
                    (response) => {
                        this.showSpinner = false;

                        if (response.objectData) {
                            if (response.objectData.subPaymentDetails) {
                                this.subPaymentDetails = response.objectData.subPaymentDetails;
                            }
                            if (response.objectData.existAdjWrap) {
                                this.existAdjWrap = response.objectData.existAdjWrap;
                            }
                            if (response.objectData.rateTypeOptions) {
                                this.rateTypeOptions = response.objectData.rateTypeOptions;
                            }
                            if (response.objectData.rateTypeOptionsMap) {
                                this.rateTypeOptionsMap = response.objectData.rateTypeOptionsMap;
                            }
                            if (response.objectData.currentUtilizationMap) {
                                this.childCurrentUtilization = response.objectData.currentUtilizationMap;
                            }
                            if (response.objectData.careUnitTypeOptions) {
                                this.careUnitTypeOptions = response.objectData.careUnitTypeOptions;
                            }
                            if (response.objectData.careUnitTypeOptionsMap) {
                                this.careUnitTypeOptionsMap = response.objectData.careUnitTypeOptionsMap;
                            }
                            if (response.objectData.careLevelOptions) {
                                this.careLevelOptions = response.objectData.careLevelOptions;
                            }
                            if (response.objectData.careLevelOptionsMap) {
                                this.careLevelOptionsMap = response.objectData.careLevelOptionsMap;
                            }
                            if (response.objectData.rateTypeOptionsCareDateMap) {
                                this.rateTypeOptionsCareDateMap = response.objectData.rateTypeOptionsCareDateMap;
                            }
                            if (response.objectData.activeARTFeeRecords) {
                                this.activeARTFeeRecords = response.objectData.activeARTFeeRecords;
                            }
                            if (response.objectData.error) {
                                this.pageMessages = [{ id: 'error', message: response.objectData.error }];
                                this.messageType = 'error';
                            }
                        }

                        this.currentTabNumber = 2;
                    },
                    JSON.stringify(params),
                    null
                );
            } else {
                this.pageMessages = [{ id: 'error-select', message: 'Please select sub payment record' }];
                this.messageType = 'error';
            }
        }
    }

    /**
     * Handle Previous button - moves from Tab 2 to Tab 1.
     * Mirrors Aura doPrevious: shows a "values will not be saved" confirmation before going back.
     * In editMode Previous acts as Cancel — shows "Are You Sure?" confirmation instead.
     */
    handlePrevious() {
            // Normal Tab 2 → Tab 1 flow — warn the user data will be lost
            this.showPreviousConfirmModal = true;
        
    }

    /**
     * Previous confirmation modal — Yes button.
     * Mirrors Aura confirmPrevious: reset Tab 2 state and go back to Tab 1.
     */
    handlePreviousConfirmYes() {
        this.showPreviousConfirmModal = false;
        this._resetTab2State();
        this.currentTabNumber = 1;
    }

    /**
     * Previous confirmation modal — No button.
     * User chose to stay on Tab 2 — dismiss the confirmation.
     */
    handlePreviousConfirmNo() {
        this.showPreviousConfirmModal = false;
    }

    /**
     * Handle Cancel button.
     * Mirrors Aura doCancel: shows "Are You Sure?" confirmation before closing the modal.
     */
    handleCancel() {
        this.showCancelConfirmModal = true;
    }

    /**
     * Cancel confirmation modal — Yes button.
     * Mirrors Aura confirmCancel: closes the modal overlay.
     */
    handleCancelConfirmYes() {
        this.showCancelConfirmModal = false;
        this.close({ action: 'cancel' });
    }

    /**
     * Cancel confirmation modal — No button.
     * User chose to stay — dismiss the confirmation.
     */
    handleCancelConfirmNo() {
        this.showCancelConfirmModal = false;
    }

    /**
     * Handle Calculate button click
     */
    handleCalculate() {
        this.pageMessages = [];
        this.messageType = null;
        this.isARTFeeChanged = false;

        // Clone maps for comparison on first calculate
        if (!this.isFirstCalculate) {
            if (this.adjustmentDetailsMap && Object.keys(this.adjustmentDetailsMap).length > 0 &&
                this.adjustmentDetailsARTFeeMap && Object.keys(this.adjustmentDetailsARTFeeMap).length > 0) {
                this.adjustmentDetailsMapClone = JSON.parse(JSON.stringify(this.adjustmentDetailsMap));
            }
            if (this.adjustDetailMap && Object.keys(this.adjustDetailMap).length > 0) {
                if (Object.keys(this.adjustmentDetailsMap).length === 0) {
                    const map2 = {};
                    for (const p in this.adjustDetailMap) {
                        if (this.adjustDetailMap[p] && this.adjustDetailMap[p][0]) {
                            map2[p] = this.adjustDetailMap[p][0];
                        }
                    }
                    this.adjustmentDetailsMapClone = JSON.parse(JSON.stringify(map2));
                }
                this.adjustDetailMapClone = JSON.parse(JSON.stringify(this.adjustDetailMap));
            }
            this.isFirstCalculate = true;
        }

        // Merge ART Fee data into adjustmentDetailsMap
        this._mergeARTFeeData();

        // Validate ART Fee restrictions
        if (!this._validateARTFeeRestriction()) {
            return;
        }

        // Build wrappers for calculation
        const wrappers = this._buildCalculationWrappers();

        // Call server to calculate
        this._isCalculating = true;
        this.showSpinner = true;
        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'calculateAdjustDetail',
            (response) => {
                this.showSpinner = false;

                if (response.objectData) {
                    if (response.objectData.adjustmentDetailUpdated) {
                        this.adjustmentDetailList = response.objectData.adjustmentDetailUpdated;
                    }
                    if (response.objectData.totalPaidAmount) {
                        this.totalPaidAmount = response.objectData.totalPaidAmount;
                    }
                    if (response.objectData.listToUpdated) {
                        // Merge server-returned updated rows into the map.
                        // The Apex calculateAdjustDetail only sets AMT_PAID_RATE_ADJD__c —
                        // it does NOT return ART fee fields. Replacing the entry wholesale
                        // would wipe out the ART fees that _mergeARTFeeData() already copied
                        // into adjustmentDetailsMap before the server call.
                        // Fix: preserve ART fee values when applying the server response by
                        // spreading the server object onto the existing entry (not replacing it).
                        const updatedList = response.objectData.listToUpdated;
                        const updatedMap = { ...this.adjustmentDetailsMap };
                        for (const p in updatedMap) {
                            for (let j = 0; j < updatedList.length; j++) {
                                if (updatedList[j].subPaymentDetails &&
                                    updatedList[j].subPaymentDetails.ExternalId === p) {
                                    // Preserve existing ART fee values and merge the server
                                    // response on top — server fields (AMT_PAID_RATE_ADJD__c etc.)
                                    // win, but ART fee fields absent from the server response
                                    // are kept from the pre-calculate merged map entry.
                                    updatedMap[p] = {
                                        ...updatedMap[p],
                                        ...updatedList[j].ajustmentDetails
                                    };
                                }
                            }
                        }
                        this.adjustmentDetailsMap = updatedMap;
                    }
                    this.calculateBtnClicked = true;

                    const entryComponent = this.template.querySelector('c-adjustment-flow_-adjustment-entry_lwc');
                    if (entryComponent && typeof entryComponent.propagateCalculateAmountPaid === 'function') {
                        entryComponent.propagateCalculateAmountPaid(this.adjustmentDetailsMap);
                    }
                }
                this._isCalculating = false;
            },
            JSON.stringify({
                selectedSubPayment: JSON.stringify(this.selectedSubPayment),
                adjustment: this.adjustment,
                subPaymentDetails: this.subPaymentDetails,
                adjustmentDetail: [],
                adjustmentWrap: JSON.stringify(wrappers)
            }),
            null
        );
    }

    /**
     * Handle Save button click
     */
    handleFinish() {
        if (!this.calculateBtnClicked) {
            this.pageMessages = [{ id: 'error-calc', message: 'Please click on Calculate before saving records.' }];
            this.messageType = 'error';
            return;
        }

        // Validate current page
        // adjustmentFlow_AdjustmentEntry_lwc exposes validateCurrentPage() (not callValidateCurrentPage)
        const entryComponent = this.template.querySelector('c-adjustment-flow_-adjustment-entry_lwc');
        let isValid = true;
        if (entryComponent && typeof entryComponent.validateCurrentPage === 'function') {
            isValid = entryComponent.validateCurrentPage();
        }

        // Additional validation for Recovery type
        if (this.adjustment && this.adjustment.CDE_TYPE_ADJMT__c === 'Recovery' && this.adjustmentDetailsMap) {
            for (const p in this.adjustmentDetailsMap) {
                if (this.adjustmentDetailsMap[p].Adjustment_Initiated__c) {
                    for (let j = 0; j < this.subPaymentDetails.length; j++) {
                        if (this.subPaymentDetails[j].ExternalId === p &&
                            this.subPaymentDetails[j].ind_adjmt__c !== 'Y') {
                            if (this.adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c < this.subPaymentDetails[j].amt_copay__c) {
                                this.pageMessages = [{ id: 'error-rate', message: 'Adjusted Rate Amount cannot be less than Parent Fee' }];
                                this.messageType = 'error';
                                isValid = false;
                                break;
                            }
                        }
                    }
                }
            }
        }

        if (isValid) {
            // Mirrors Aura doFinish: if ART fees changed, show confirmation before saving
            if (this.isARTFeeChanged) {
                this._pendingSaveAction = 'save';
                this.showARTFeeConfirmModal = true;
            } else {
                this._performSave(false);
            }
        }
    }

    /**
     * Handle Save And New button click
     */
    handleSaveAndNew() {
        if (!this.calculateBtnClicked) {
            this.pageMessages = [{ id: 'error-calc', message: 'Please click on Calculate before saving records.' }];
            this.messageType = 'error';
            return;
        }

        // Validate current page
        // adjustmentFlow_AdjustmentEntry_lwc exposes validateCurrentPage() (not callValidateCurrentPage)
        const entryComponent = this.template.querySelector('c-adjustment-flow_-adjustment-entry_lwc');
        let isValid = true;
        if (entryComponent && typeof entryComponent.validateCurrentPage === 'function') {
            isValid = entryComponent.validateCurrentPage();
        }

        // Additional validation for Recovery type
        if (this.adjustment && this.adjustment.CDE_TYPE_ADJMT__c === 'Recovery' && this.adjustmentDetailsMap) {
            for (const p in this.adjustmentDetailsMap) {
                if (this.adjustmentDetailsMap[p].Adjustment_Initiated__c) {
                    for (let j = 0; j < this.subPaymentDetails.length; j++) {
                        if (this.subPaymentDetails[j].ExternalId === p &&
                            this.subPaymentDetails[j].ind_adjmt__c !== 'Y') {
                            if (this.adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c < this.subPaymentDetails[j].amt_copay__c) {
                                this.pageMessages = [{ id: 'error-rate', message: 'Adjusted Rate Amount cannot be less than Parent Fee' }];
                                this.messageType = 'error';
                                isValid = false;
                                break;
                            }
                        }
                    }
                }
            }
        }

        if (isValid) {
            // Mirrors Aura doSaveAndNew: if ART fees changed, show confirmation before saving
            if (this.isARTFeeChanged) {
                this._pendingSaveAction = 'saveAndNew';
                this.showARTFeeConfirmModal = true;
            } else {
                this._performSave(true);
            }
        }
    }

    /**
     * Handle ART Fee confirmation modal — Yes button
     * Mirrors Aura confirmFinish / confirmDoSaveAndNew
     */
    handleARTFeeConfirmYes() {
        this.showARTFeeConfirmModal = false;
        const isSaveAndNew = this._pendingSaveAction === 'saveAndNew';
        this._pendingSaveAction = null;
        this._performSave(isSaveAndNew);
    }

    /**
     * Handle ART Fee confirmation modal — No button
     * User chose not to proceed — dismiss the confirmation and stay on the page
     */
    handleARTFeeConfirmNo() {
        this.showARTFeeConfirmModal = false;
        this._pendingSaveAction = null;
    }

    /**
     * Handle createAdjustDetails event from child component
     */
    handleCreateAdjustDetails(event) {
        const detail = event.detail;
        if (!detail) return;

        const adjustmentDetailObj = detail.adjustmentDetailObj;
        const adjustmentDetailTemp = detail.adjustmentDetailTemp;
        const mapkey = detail.key;
        const isARTFee = detail.isARTFee;

        if (!isARTFee) {
            // Update adjustmentDetailsMap
            const map = { ...this.adjustmentDetailsMap };
            map[mapkey] = adjustmentDetailObj;
            this.adjustmentDetailsMap = map;

            // Sync with ARTFeeMap if exists
            if (adjustmentDetailObj && this.adjustmentDetailsARTFeeMap &&
                this.adjustmentDetailsARTFeeMap[mapkey]) {
                const artMap = { ...this.adjustmentDetailsARTFeeMap };
                artMap[mapkey].Adjustment_Initiated__c = adjustmentDetailObj.Adjustment_Initiated__c;
                this.adjustmentDetailsARTFeeMap = artMap;
            }
        } else {
            // Update adjustmentDetailsARTFeeMap
            const mapARTFee = { ...this.adjustmentDetailsARTFeeMap };
            mapARTFee[mapkey] = adjustmentDetailTemp;
            this.adjustmentDetailsARTFeeMap = mapARTFee;
            this.isARTFeeCalculated = true;
        }

        // Only reset calculateBtnClicked when the user manually changes data,
        // NOT during the calculate server response propagation (_isCalculating = true).
        if (!this._isCalculating) {
            this.calculateBtnClicked = false;
        }
    }

    // ─── Private Methods ─────────────────────────────────────────────────────────

    /**
     * Resets all Tab 2 state back to defaults.
     * Called by handlePreviousConfirmYes before navigating back to Tab 1.
     * Mirrors Aura confirmPrevious which clears maps and resets adjustment lists.
     */
    _resetTab2State() {
        this.isARTFeeCalculated = false;
        this.isARTFeeChanged = false;
        this.isFirstCalculate = false;
        this._adjustmentDetailList = [];
        this.adjustmentDetailsMap = {};
        this.adjustmentDetailsARTFeeMap = {};
        this.adjustmentDetailsMapClone = {};
        this.adjustDetailMapClone = {};
        this._selectedSubPayment = null;
        this.pageMessages = [];
        this._subPaymentDetails = [];
        this.subPaymentSearchLst = [];
    }

    _mergeARTFeeData() {
        const rateTypeOptionsMap = this.rateTypeOptionsMap || {};
        const map = {};
        for (const p in rateTypeOptionsMap) {
            if (rateTypeOptionsMap[p].label) {
                map[rateTypeOptionsMap[p].label] = rateTypeOptionsMap[p].value;
            }
        }

        if (this.adjustmentDetailsMap && Object.keys(this.adjustmentDetailsMap).length > 0 &&
            this.adjustmentDetailsARTFeeMap && Object.keys(this.adjustmentDetailsARTFeeMap).length > 0) {

            const updatedMap = { ...this.adjustmentDetailsMap };

            for (const p in updatedMap) {
                // Always merge ART fee values if the ART fee map has an entry for this key.
                // if the ART row's checkbox sync was slightly delayed or the user only ticked
                // the main row checkbox (not the ART row), the merge was silently skipped and
                // ART fees never reached adjustmentDetailsMap — causing them to be dropped from
                // the database upsert. Merging unconditionally when the ART fee map entry exists
                // is safe: zero-valued ART fees do not affect the final AMT_DETAIL_ADJMT__c.
                if (this.adjustmentDetailsARTFeeMap[p]) {
                    // Check for ART Fee changes (for isARTFeeChanged confirmation dialog)
                    if (this.adjustmentDetailsMapClone && this.isFirstCalculate &&
                        this.adjustmentDetailsMapClone[p]) {

                        const artFee = this.adjustmentDetailsARTFeeMap[p];
                        const clone = this.adjustmentDetailsMapClone[p];

                        if (parseFloat(artFee.Transportation_Fee_Paid__c) !== parseFloat(clone.Transportation_Fee_Paid__c) ||
                            parseFloat(artFee.Registration_Fee_Paid__c) !== parseFloat(clone.Registration_Fee_Paid__c) ||
                            parseFloat(artFee.Activity_Fee_Paid__c) !== parseFloat(clone.Activity_Fee_Paid__c)) {
                            this.isARTFeeChanged = true;
                        }
                    }

                    // Merge ART Fee values unconditionally
                    updatedMap[p].Transportation_Fee_Paid__c = this.adjustmentDetailsARTFeeMap[p].Transportation_Fee_Paid__c;
                    updatedMap[p].Registration_Fee_Paid__c = this.adjustmentDetailsARTFeeMap[p].Registration_Fee_Paid__c;
                    updatedMap[p].Activity_Fee_Paid__c = this.adjustmentDetailsARTFeeMap[p].Activity_Fee_Paid__c;

                    if (this.adjustmentDetailsARTFeeMap[p].Adjustment_Initiated__c && !updatedMap[p].Adjustment_Initiated__c) {
                        updatedMap[p].Adjustment_Initiated__c = this.adjustmentDetailsARTFeeMap[p].Adjustment_Initiated__c;
                    }
                }
            }

            this.adjustmentDetailsMap = updatedMap;
        } else if (this.adjustDetailMap && Object.keys(this.adjustDetailMap).length > 0 &&
            Object.keys(this.adjustmentDetailsMap).length === 0 &&
            this.adjustmentDetailsARTFeeMap && Object.keys(this.adjustmentDetailsARTFeeMap).length > 0) {
            // Handle case where adjustmentDetailsMap is empty but adjustDetailMap has data
            const map1 = {};
            for (const p in this.adjustDetailMap) {
                if (this.adjustDetailMap[p] && this.adjustDetailMap[p][0] &&
                    this.adjustDetailMap[p][0].Adjustment_Initiated__c === true &&
                    this.adjustmentDetailsARTFeeMap[p]) {

                    // Check for ART Fee changes
                    if (this.adjustDetailMapClone && this.isFirstCalculate &&
                        this.adjustmentDetailsARTFeeMap[p] && this.adjustDetailMapClone[p] && this.adjustDetailMapClone[p][0]) {

                        const artFee = this.adjustmentDetailsARTFeeMap[p];
                        const clone = this.adjustDetailMapClone[p][0];

                        if (parseFloat(artFee.Transportation_Fee_Paid__c) !== parseFloat(clone.Transportation_Fee_Paid__c) ||
                            parseFloat(artFee.Registration_Fee_Paid__c) !== parseFloat(clone.Registration_Fee_Paid__c) ||
                            parseFloat(artFee.Activity_Fee_Paid__c) !== parseFloat(clone.Activity_Fee_Paid__c)) {
                            this.isARTFeeChanged = true;
                        }
                    }

                    // Deep copy to avoid mutating the @api property directly
                    // Update internal _adjustDetailMap instead of dispatching event
                    // (LightningModal events don't bubble to the programmatic opener)
                    const updatedAdjDetailMap = JSON.parse(JSON.stringify(this._adjustDetailMap));
                    updatedAdjDetailMap[p][0].Transportation_Fee_Paid__c = this.adjustmentDetailsARTFeeMap[p].Transportation_Fee_Paid__c;
                    updatedAdjDetailMap[p][0].Registration_Fee_Paid__c = this.adjustmentDetailsARTFeeMap[p].Registration_Fee_Paid__c;
                    updatedAdjDetailMap[p][0].Activity_Fee_Paid__c = this.adjustmentDetailsARTFeeMap[p].Activity_Fee_Paid__c;
                    updatedAdjDetailMap[p][0].Adjustment_Initiated__c = this.adjustmentDetailsARTFeeMap[p].Adjustment_Initiated__c;
                    // Update internal state - will be included in close result
                    this._adjustDetailMap = updatedAdjDetailMap;
                    map1[p] = updatedAdjDetailMap[p][0];
                }
            }
            this.adjustmentDetailsMap = map1;
        }
    }

    _validateARTFeeRestriction() {
        if (!this.adjustmentDetailsARTFeeMap || !this.subPaymentDetails || !this.activeARTFeeRecords) {
            return true;
        }

        const subPaymentDateMap = new Map();
        for (let i = 0; i < this.subPaymentDetails.length; i++) {
            subPaymentDateMap.set(this.subPaymentDetails[i].ExternalId, this.subPaymentDetails[i].dte_care__c);
        }

        let ARTFeeValidationSuccess = true;

        for (const j in this.adjustmentDetailsARTFeeMap) {
            if (this.adjustmentDetailsARTFeeMap[j].Adjustment_Initiated__c) {
                const careDateString = subPaymentDateMap.get(j);
                if (!careDateString) continue;

                const careDate = new Date(careDateString);
                const careMonth = careDate.getMonth() + 1;

                for (const k in this.activeARTFeeRecords) {
                    const record = this.activeARTFeeRecords[k];
                    if (!record.IDN_FISCAL_SCH__r) continue;

                    const beginDate = new Date(record.IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c);
                    const endDate = record.IDN_FISCAL_SCH__r.DTE_END_EFFV__c
                        ? new Date(record.IDN_FISCAL_SCH__r.DTE_END_EFFV__c)
                        : null;

                    if (careDate >= beginDate && (careDate <= endDate || endDate === null)) {
                        if (record.TXT_ACT_MONTH__c && record.TXT_ACT_MONTH__c.includes(careMonth) &&
                            this.adjustmentDetailsARTFeeMap[j].Activity_Fee_Paid__c > 0) {
                            ARTFeeValidationSuccess = false;
                        }
                        if (record.TXT_REG_MONTH__c && record.TXT_REG_MONTH__c.includes(careMonth) &&
                            this.adjustmentDetailsARTFeeMap[j].Registration_Fee_Paid__c > 0) {
                            ARTFeeValidationSuccess = false;
                        }
                        if (record.TXT_TRANS_MONTH__c && record.TXT_TRANS_MONTH__c.includes(careMonth) &&
                            this.adjustmentDetailsARTFeeMap[j].Transportation_Fee_Paid__c > 0) {
                            ARTFeeValidationSuccess = false;
                        }
                    }
                }
            }
        }

        if (!ARTFeeValidationSuccess) {
            this.pageMessages = [{ id: 'error-art', message: label.adjustment_error_ARTFee || 'ART Fee restriction violated.' }];
            this.messageType = 'error';
        }

        return ARTFeeValidationSuccess;
    }

    _buildCalculationWrappers() {
        const wrappers = [];
        let oldAdjustedAmount = 0;

        if (this.adjustmentDetailsMap) {
            for (const p in this.adjustmentDetailsMap) {
                if (this.adjustmentDetailsMap[p].Adjustment_Initiated__c) {
                    // Track old adjusted amount
                    if (this.adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c != null &&
                        this.adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c !== 'undefined') {
                        oldAdjustedAmount += this.adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c;
                    }

                    // Build wrapper for non-override records
                    for (let j = 0; j < this.subPaymentDetails.length; j++) {
                        if (this.subPaymentDetails[j].ExternalId === p) {
                            if (this.adjustmentDetailsMap[p].IND_OVERRIDE__c !== true) {
                                wrappers.push({
                                    subPaymentDetails: this.subPaymentDetails[j],
                                    ajustmentDetails: this.adjustmentDetailsMap[p]
                                });
                            }
                        }
                    }
                }
            }
        }

        if (!this.isOldAdjustedAmountSet) {
            this.oldAdjustedAmount = oldAdjustedAmount;
            this.isOldAdjustedAmountSet = true;
        }

        return wrappers;
    }

    _performSave(isSaveAndNew) {
        // Re-merge ART fee data immediately before building the save list.
        // _mergeARTFeeData() is called during Calculate, but if the user entered or changed
        // ART fees after clicking Calculate (without re-calculating), those values sit only
        // in adjustmentDetailsARTFeeMap and never reach adjustmentDetailsMap.
        // Calling it here guarantees ART fees are always present in adjustmentDetailsMap
        // at save time, matching Aura's behaviour where confirmFinishHlp reads ART fees
        // directly from adjustmentDetailsMap at the point of save.
        this._mergeARTFeeData();

        // _buildSaveList() recalculates AMT_DETAIL_ADJMT__c for each row via saveObj (a spread
        // copy) and merges all updated values back into this.adjustmentDetailsMap at the end.
        const sObjectList = this._buildSaveList();

        // adjustedAmountForGuard: matches Aura confirmFinishHlp which sums AMT_DETAIL_ADJMT__c
        // from ALL entries in adjustmentDetailsMap unconditionally — the Bug fix 3553 filter
        // (AMT_DETAIL_ADJMT__c > 0 && isAdjustedDetail) only controls what enters sObjectList,
        // not this sum. Summing only sObjectList excludes zero-amount and non-adjusted rows,
        // making newAdjAmount lower and falsely triggering the totalPaidAmount guard for
        // both Claims and Recoveries.
        let adjustedAmountForGuard = 0;
        for (const p in this.adjustmentDetailsMap) {
            const amt = this.adjustmentDetailsMap[p] && this.adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c;
            if (amt != null && amt !== undefined && amt !== 'undefined') {
                adjustedAmountForGuard += amt;
            }
        }

        let adjustedAmount = 0;
        for (const saveObj of sObjectList) {
            const amt = saveObj.AMT_DETAIL_ADJMT__c;
            if (amt != null && amt !== undefined && amt !== 'undefined') {
                adjustedAmount += amt;
            }
        }

        // Aura applies totalPaidAmount guard on Save (confirmFinishHlp) only.
        // SaveAndNew (confirmDoSaveAndNewHlp) skips this check and proceeds directly to upsert.
        if (!isSaveAndNew) {
            const currentAdjAmount = this.adjustment && this.adjustment.AMT_ADJMT__c ? this.adjustment.AMT_ADJMT__c : 0;
            const newAdjAmount = currentAdjAmount - Math.abs(this.oldAdjustedAmount) + adjustedAmountForGuard;
            const totalPaidAmount = parseFloat(this.totalPaidAmount);

            if (newAdjAmount < totalPaidAmount) {
                this.pageMessages = [{
                    id: 'error-total',
                    message: label.adjustment_error_totalPaidAmount + ' $' + totalPaidAmount.toFixed(2)
                }];
                this.messageType = 'error';
                return;
            }
        }

        this.showSpinner = true;
        abs_helper.callServerAndHandleError(
            this,
            'GenericDataSaverApxCtrl',
            'upsertRecords',
            (response) => {
                this.isARTFeeChanged = false;
                // Aura's confirmDoSaveAndNewHlp resets calculateBtnClicked to false after upsert.
                // Save (confirmFinishHlp) closes the modal so the reset is not needed there.
                if (isSaveAndNew) {
                    this.calculateBtnClicked = false;
                }

                if (response.isSuccessful) {
                    const adjustmentId = this.adjustment.Id;
                    abs_helper.callServerAndHandleError(
                        this,
                        'AdjustmentFlowApxCtrl',
                        'adjustmentDetails',
                        (detailResponse) => {
                            this.showSpinner = false;

                            const refreshedAdjDetailMap = detailResponse.objectData && detailResponse.objectData.adjustDetailMap ? detailResponse.objectData.adjustDetailMap : null;
                            const refreshedAdjDtlWarp = detailResponse.objectData && detailResponse.objectData.adjustmentDtlWarp ? detailResponse.objectData.adjustmentDtlWarp : null;

                            if (isSaveAndNew) {
                                this.close({
                                    action: 'saveAndNew',
                                    adjustmentDtlWarp: refreshedAdjDtlWarp,
                                    adjustmentAmount: adjustedAmount,
                                    subPaymentDetail: this.subPaymentDetails[0],
                                    rateTypeOptions: this.rateTypeOptionsMap,
                                    selectedSubPayment: this.selectedSubPayment,
                                    adjustDetailMap: refreshedAdjDetailMap
                                });
                            } else {
                                this.close({
                                    action: 'save',
                                    adjustmentDtlWarp: refreshedAdjDtlWarp,
                                    adjustmentAmount: adjustedAmount,
                                    subPaymentDetail: this.subPaymentDetails[0],
                                    rateTypeOptions: this.rateTypeOptionsMap,
                                    selectedSubPayment: this.selectedSubPayment,
                                    adjustDetailMap: refreshedAdjDetailMap
                                });
                            }
                        },
                        JSON.stringify({ adjustmentId: adjustmentId }),
                        null
                    );
                } else {
                    this.showSpinner = false;
                }
            },
            JSON.stringify({ lstSObject: sObjectList, isFinalStep: true }),
            null
        );
    }

    _buildSaveList() {
        const sObjectList = [];
        const updatedMap = {};

        if (this.adjustmentDetailsMap) {
            for (const p in this.adjustmentDetailsMap) {
                const saveObj = { ...this.adjustmentDetailsMap[p] };
                let isAdjustedDetail = false;

                for (let j = 0; j < this.subPaymentDetails.length; j++) {
                    const subPmt = this.subPaymentDetails[j];
                    if (subPmt.ExternalId === p &&
                        subPmt.ind_adjmt__c !== 'Y' &&
                        saveObj.Adjustment_Initiated__c === true) {

                        isAdjustedDetail = true;

                        const amtRate = subPmt.amt_rate__c === 'undefined' ? 0 : subPmt.amt_rate__c;
                        if (saveObj.AMT_PAID_RATE_ADJD__c === 'undefined' || saveObj.AMT_PAID_RATE_ADJD__c === undefined) {
                            saveObj.AMT_PAID_RATE_ADJD__c = 0;
                        }

                        saveObj.DTE_CARE__c = subPmt.dte_care__c;
                        saveObj.IDN_PROG_FNDG__c = subPmt.idn_prog_fndg__c;
                        saveObj.NBR_HOURS_ATNDT_ORIG__c = subPmt.cde_unit_care_actual__c;
                        saveObj.NBR_HOURS_AUTH_ORIG__c = subPmt.cde_unit_care_exptd__c;
                        saveObj.AMT_PAID_RATE_ORIG__c = amtRate;

                        const sub1 = parseFloat(saveObj.AMT_PAID_RATE_ADJD__c);
                        const sub2 = parseFloat(amtRate);
                        let calcResult = sub1 > sub2 ? sub1 - sub2 : sub2 - sub1;

                        const artFeeAmount =
                            parseFloat(saveObj.Activity_Fee_Paid__c || 0) +
                            parseFloat(saveObj.Registration_Fee_Paid__c || 0) +
                            parseFloat(saveObj.Transportation_Fee_Paid__c || 0);
                        saveObj.AMT_DETAIL_ADJMT__c = calcResult + artFeeAmount;
                    }
                }

                if (this.adjustDetailMap && this.adjustDetailMap[p] && this.adjustDetailMap[p][0]) {
                    saveObj.Id = this.adjustDetailMap[p][0].Id;
                }

                saveObj.IDN_ADJMT__c = this.adjustment.Id;
                saveObj.IDN_DETAIL_PMT_SUB__c = p;
                saveObj.sobjectType = 'T_ADJMT_DETAIL__c';
                saveObj.attributes = { type: 'T_ADJMT_DETAIL__c' };

                updatedMap[p] = saveObj;

                if (saveObj.AMT_DETAIL_ADJMT__c > 0 && isAdjustedDetail && saveObj.Adjustment_Initiated__c) {
                    sObjectList.push(saveObj);
                }
            }
            this.adjustmentDetailsMap = { ...this.adjustmentDetailsMap, ...updatedMap };
        }

        return sObjectList;
    }
}