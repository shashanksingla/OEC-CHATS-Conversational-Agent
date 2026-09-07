import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';
import AdjustmentDetailEditModal from 'c/adjustmentFlow_SubPayment_AddAdjDetailFlow_Modal_lwc';

export default class AdjustmentDetailRow_lwc extends LightningElement {

    // ─── @api properties (read-only / no internal state needed) ─────────────────
    @api currentTabNumber;
    @api rateTypeOptions;
    @api careUnitTypeOptions;
    @api careLevelOptions;
    @api adjustmentDetailList;
    @api careUnitTypeOptionsMap;
    @api careLevelOptionsMap;
    @api rateTypeOptionsMap;
    @api childCurrentUtilization;
    @api rowIndex;
    @api disabledARTFees;
    @api pageMode = 'view';
    @api slotCntcheckbox = false;
    @api activeARTFeeRecords = [];
    @api subPaymentDetail;
    @api selectedSubPayment;

    // ─── Internal @track state ───────────────────────────────────────────────────
    @track _adjustment = null;
    @track _adjustmentDtlWarp = null;
    @track _adjustmentDtlWarpArr = [];
    @track _adjustDetailMap = null;
    @track rateTypeOptionsCareDateMap = {};

    // ─── @api getter/setter: adjustment ─────────────────────────────────────────
    @api
    get adjustment() {
        return this._adjustment;
    }
    set adjustment(value) {
        if (value !== null && value !== undefined) {
            this._adjustment = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustment = null;
        }
    }

    // ─── @api getter/setter: adjustmentDtlWarp ──────────────────────────────────
    @api
    get adjustmentDtlWarp() {
        return this._adjustmentDtlWarp;
    }
    set adjustmentDtlWarp(value) {
        if (value !== null && value !== undefined) {
            this._adjustmentDtlWarp = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustmentDtlWarp = null;
        }
    }

    // ─── @api getter/setter: adjustmentDtlWarpArr ───────────────────────────────
    @api
    get adjustmentDtlWarpArr() {
        return this._adjustmentDtlWarpArr;
    }
    set adjustmentDtlWarpArr(value) {
        if (value !== null && value !== undefined) {
            this._adjustmentDtlWarpArr = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustmentDtlWarpArr = [];
        }
    }

    // ─── @api getter/setter: adjustDetailMap ────────────────────────────────────
    @api
    get adjustDetailMap() {
        return this._adjustDetailMap;
    }
    set adjustDetailMap(value) {
        if (value !== null && value !== undefined) {
            this._adjustDetailMap = JSON.parse(JSON.stringify(value));
        } else {
            this._adjustDetailMap = null;
        }
    }

    // ─── @track properties ──────────────────────────────────────────────────────
    @track selectedMenuItemValue;
    @track adjustmentEntryEditMode = false;
    @track showDeleteModal = false;
    @track deleteConfirmMessage = 'Are You Sure?';

    // ─── Spinner / error state ───────────────────────────────────────────────────
    @track showSpinner = false;
    @track error;

    // ─── Getters ─────────────────────────────────────────────────────────────────

    /**
     * Returns true when the component is in view-only mode.
     */
    get isViewMode() {
        return this.pageMode === 'view';
    }

    /**
     * Show the action menu only when NOT in view mode (or adjustment is absent).
     * Hides the menu when adjustment exists AND pageMode is 'view'.
     */
    get showActionMenu() {
        return !(this._adjustment && this.pageMode === 'view');
    }

    /**
     * Show the Case Name column when the adjustment has a Provider ID set.
     */
    get showCaseColumn() {
        return !this._isEmpty(this._adjustment && this._adjustment.IDN_PROVR__c);
    }

    /**
     * Show Provider Name and Facility Name columns when the adjustment has a Case ID set.
     */
    get showProviderColumns() {
        return !this._isEmpty(this._adjustment && this._adjustment.IDN_CASE__c);
    }

    // ─── Null-safe display getters for deep idn_auth__r relationship chain ────────
    // Aura's expression engine performs safe null traversal automatically (returns ''
    // when any hop is null). LWC evaluates the same chain via JavaScript property
    // access, which throws TypeError when idn_auth__r is null — as happens for
    // vacant-slot-contract sub-payments (idn_auth__c = null → idn_auth__r = null).
    // These getters replicate Aura's safe-traversal behaviour using optional chaining.

    /**
     * Case Name from the sub-payment auth relationship.
     * Returns '' when idn_auth__r is null (e.g. vacant slot contract).
     */
    get caseNameDisplay() {
        return this._adjustmentDtlWarp?.subPaymentDetails?.idn_pmt_sub__r?.idn_auth__r?.IDN_CASE__r?.Name || '';
    }

    /**
     * Provider Name from the sub-payment auth relationship.
     * Returns '' when idn_auth__r is null.
     */
    get providerNameDisplay() {
        return this._adjustmentDtlWarp?.subPaymentDetails?.idn_pmt_sub__r?.idn_auth__r?.IDN_PROVR__r?.Name || '';
    }

    /**
     * Facility Name from the sub-payment auth relationship.
     * Returns '' when idn_auth__r is null.
     */
    get facilityNameDisplay() {
        return this._adjustmentDtlWarp?.subPaymentDetails?.idn_pmt_sub__r?.idn_auth__r?.NAM_FACILITY__c || '';
    }

    /**
     * Child First Name from the sub-payment auth relationship.
     * Returns '' when idn_auth__r is null.
     */
    get childFirstNameDisplay() {
        return this._adjustmentDtlWarp?.subPaymentDetails?.idn_pmt_sub__r?.idn_auth__r?.NAM_FIRST__c || '';
    }

    /**
     * Child Last Name from the sub-payment auth relationship.
     * Returns '' when idn_auth__r is null.
     */
    get childLastNameDisplay() {
        return this._adjustmentDtlWarp?.subPaymentDetails?.idn_pmt_sub__r?.idn_auth__r?.NAM_LAST__c || '';
    }

    /**
     * Returns the edit menu item value with record ID prefix.
     */
    get editMenuItemValue() {
        if (this._adjustmentDtlWarp && this._adjustmentDtlWarp.ajustmentDetails && this._adjustmentDtlWarp.ajustmentDetails.Id) {
            return this._adjustmentDtlWarp.ajustmentDetails.Id + '_edit';
        }
        return '_edit';
    }

    /**
     * Returns the delete menu item value with record ID prefix.
     */
    get deleteMenuItemValue() {
        if (this._adjustmentDtlWarp && this._adjustmentDtlWarp.ajustmentDetails && this._adjustmentDtlWarp.ajustmentDetails.Id) {
            return this._adjustmentDtlWarp.ajustmentDetails.Id + '_delete';
        }
        return '_delete';
    }

    /**
     * Returns the adjusted amount to display.
     * If AMT_DETAIL_ADJMT__c !== 0 AND adjustment type is 'Recovery', display as negative.
     * Otherwise display as-is.
     */
    get adjustedAmountDisplay() {
        if (!this._adjustmentDtlWarp || !this._adjustmentDtlWarp.ajustmentDetails) {
            return null;
        }
        const adjDetails = this._adjustmentDtlWarp.ajustmentDetails;
        const amount = adjDetails.AMT_DETAIL_ADJMT__c;

        if (
            amount !== 0 &&
            this._adjustment &&
            this._adjustment.CDE_TYPE_ADJMT__c === 'Recovery'
        ) {
            return amount !== undefined && amount !== null ? -Math.abs(amount) : null;
        }
        return amount !== undefined && amount !== null ? amount : null;
    }

    // ─── RESPONSIVE & ADA: DYNAMIC COLUMN INDICES ────────────────────────────────

    /**
     * Returns the aria-colindex for Provider Name column (accounting for dynamic Case column).
     */
    get providerNameColIndex() {
        return this.showCaseColumn ? 2 : 1;
    }

    /**
     * Returns the aria-colindex for Facility Name column.
     */
    get facilityNameColIndex() {
        return this.showCaseColumn ? 3 : 2;
    }

    /**
     * Returns the aria-colindex for Child First Name column.
     */
    get childFirstNameColIndex() {
        let colIndex = this.showCaseColumn ? 4 : 3;
        if (this.showProviderColumns) {
            // Provider + Facility take 2 slots
            colIndex = this.showCaseColumn ? 6 : 5;
        }
        return colIndex;
    }

    /**
     * Returns the aria-colindex for Child Last Name column.
     */
    get childLastNameColIndex() {
        return this.childFirstNameColIndex + 1;
    }

    /**
     * Returns the aria-colindex for Care Date column.
     */
    get careDateColIndex() {
        return this.childFirstNameColIndex + 2;
    }

    /**
     * Returns the aria-colindex for Unit Care Expected column.
     */
    get unitCareExpectedColIndex() {
        return this.childFirstNameColIndex + 3;
    }

    /**
     * Returns the aria-colindex for Unit Type column.
     */
    get unitTypeColIndex() {
        return this.childFirstNameColIndex + 4;
    }

    /**
     * Returns the aria-colindex for Unit Care Actual column.
     */
    get unitCareActualColIndex() {
        return this.childFirstNameColIndex + 5;
    }

    /**
     * Returns the aria-colindex for Time Traditional column.
     */
    get timeTraditionalColIndex() {
        return this.childFirstNameColIndex + 6;
    }

    /**
     * Returns the aria-colindex for Rate Amount column.
     */
    get rateAmountColIndex() {
        return this.childFirstNameColIndex + 7;
    }

    /**
     * Returns the aria-colindex for Copay Amount column.
     */
    get copayAmountColIndex() {
        return this.childFirstNameColIndex + 8;
    }

    /**
     * Returns the aria-colindex for Total Amount column.
     */
    get totalAmountColIndex() {
        return this.childFirstNameColIndex + 9;
    }

    /**
     * Returns the aria-colindex for Authorized Hours Adjusted column.
     */
    get authHoursAdjustedColIndex() {
        return this.childFirstNameColIndex + 10;
    }

    /**
     * Returns the aria-colindex for Attended Hours Adjusted column.
     */
    get attendedHoursAdjustedColIndex() {
        return this.childFirstNameColIndex + 11;
    }

    /**
     * Returns the aria-colindex for Rate Type Adjusted column.
     */
    get rateTypeAdjustedColIndex() {
        return this.childFirstNameColIndex + 12;
    }

    /**
     * Returns the aria-colindex for Rate Paid Adjusted column.
     */
    get ratePaidAdjustedColIndex() {
        return this.childFirstNameColIndex + 13;
    }

    /**
     * Returns the aria-colindex for Adjusted Amount column.
     */
    get adjustedAmountColIndex() {
        return this.childFirstNameColIndex + 14;
    }

    /**
     * Returns the aria-colindex for Action column.
     */
    get actionColIndex() {
        return this.childFirstNameColIndex + 15;
    }

    // ─── Lifecycle ───────────────────────────────────────────────────────────────

    connectedCallback() {
        // Initialisation logic (mirrors Aura init handler)
        this.deleteConfirmMessage = 'Are You Sure?';
    }

    // ─── Event Handlers ──────────────────────────────────────────────────────────

    /**
     * Handles selection from the action menu.
     * Menu item values follow the pattern "{Id}_edit" or "{Id}_delete".
     * Mirrors Aura handleMenuSelect which:
     * 1. Calls getRateTypeMap to get rate type options for the care date
     * 2. Opens adjustmentFlow_SubPayment_AddAdjDetailFlow modal for edit
     * 3. Shows delete confirmation modal for delete
     */
    handleMenuSelect(event) {
        const selectedValue = event.detail.value;
        this.selectedMenuItemValue = selectedValue;

        if (!selectedValue) {
            return;
        }

        // Null check on selectedValue before calling .split()
        const selectedAction = selectedValue && selectedValue.includes('_') ? selectedValue.split('_')[1] : null;
        const selectedId = selectedValue && selectedValue.includes('_') ? selectedValue.split('_')[0] : null;

        // Get the adjustment detail wrapper for the current row
        const adjustmentDetailWrapper = this._adjustmentDtlWarpArr;
        const rowIndex = this.rowIndex;

        if (!adjustmentDetailWrapper || rowIndex === undefined || rowIndex === null) {
            return;
        }

        const subPaymentDetails = [];
        const adjustmentDetails = [];

        // Get sub payment and adjustment details for the current row
        if (adjustmentDetailWrapper[rowIndex]) {
            adjustmentDetails.push(adjustmentDetailWrapper[rowIndex].ajustmentDetails);
            subPaymentDetails.push(adjustmentDetailWrapper[rowIndex].subPaymentDetails);
        }

        if (selectedAction === 'edit') {
            // First call getRateTypeMap to get rate type options for the care date
            this.showSpinner = true;

            const params = {
                subPaymentDetail: subPaymentDetails[0],
                adjustmentDetail: adjustmentDetails[0]
            };

            helper.callServer(
                this,
                'AdjustmentFlowApxCtrl',
                'getRateTypeMap',
                (function (response) {
                    this.showSpinner = false;

                    let rateTypeOptionsCareDateMap = {};
                    if (response && response.objectData && response.objectData.rateTypeOptionsCareDateMap) {
                        rateTypeOptionsCareDateMap = response.objectData.rateTypeOptionsCareDateMap;
                    }
                    this.rateTypeOptionsCareDateMap = rateTypeOptionsCareDateMap;

                    // Now open the modal
                    this.adjustmentEntryEditMode = true;
                    this._openEditModal(subPaymentDetails, adjustmentDetails, rateTypeOptionsCareDateMap);
                }).bind(this),
                JSON.stringify(params)
            );

        } else if (selectedAction === 'delete') {
            // Delete action - show confirmation modal
            this.showDeleteModal = true;
        }
    }

    /**
     * Opens the Adjustment Detail Edit modal using LightningModal.
     */
    async _openEditModal(subPaymentDetails, adjustmentDetails, rateTypeOptionsCareDateMap) {
        try {
            const result = await AdjustmentDetailEditModal.open({
                size: 'large',
                // Pass all required properties to the modal
                adjustment: this._adjustment,
                subPaymentDetails: subPaymentDetails,
                rateTypeOptions: this.rateTypeOptions,
                careUnitTypeOptions: this.careUnitTypeOptions,
                careLevelOptions: this.careLevelOptions,
                adjustmentDetailList: adjustmentDetails,
                rateTypeOptionsCareDateMap: rateTypeOptionsCareDateMap,
                careLevelOptionsMap: this.careLevelOptionsMap,
                careUnitTypeOptionsMap: this.careUnitTypeOptionsMap,
                rateTypeOptionsMap: this.rateTypeOptionsMap || this.rateTypeOptions,
                adjustDetailMap: this._adjustDetailMap,
                childCurrentUtilization: this.childCurrentUtilization,
                disabledARTFees: this.disabledARTFees,
                slotCntcheckbox: this.slotCntcheckbox,
                activeARTFeeRecords: this.activeARTFeeRecords,
                selectedSubPayment: '',
                // Edit mode flag - starts at Tab 2 when editing from row
                editMode: true
            });

            // Handle modal result - check for cancel/close actions
            // Modal returns { action: 'cancel' } on cancel button click
            // Modal returns null/undefined when closed via X button or escape key
            if (result) {
                if (result.action === 'cancel') {
                    // User cancelled the modal - stay on current page, no action needed
                    console.log('Adjustment Detail Edit modal cancelled by user');
                } else {
                    // Fire event to parent with updated data
                    const updateEvent = new CustomEvent('createadjustdetails', {
                        detail: {
                            action: result.action,
                            adjustmentDtlWarp: result.adjustmentDtlWarp,
                            adjustmentAmount: result.adjustmentAmount,
                            subPaymentDetail: result.subPaymentDetail,
                            rateTypeOptions: result.rateTypeOptions,
                            selectedSubPayment: result.selectedSubPayment,
                            adjustDetailMap: result.adjustDetailMap
                        }
                    });
                    this.dispatchEvent(updateEvent);
                }
            }
            // If result is null/undefined (modal closed via X button), stay on current page
            // Do NOT fire any events - user should remain on the current view

            this.adjustmentEntryEditMode = false;
        } catch (error) {
            console.error('Error opening edit modal:', error);
            this.adjustmentEntryEditMode = false;
        }
    }

    /**
     * Handles confirmation of the delete action.
     * Calls AdjustmentFlowApxCtrl.deleteRecords on the server,
     * then fires 'createadjustdetails' with updated lists.
     */
    handleDeleteConfirm() {
        if (!this.selectedMenuItemValue) {
            return;
        }

        // Extract the record Id from the menu value pattern "{Id}_delete"
        const selectedId = this.selectedMenuItemValue.replace('_delete', '');

        const params = {
            deleteObjects: [
                {
                    attributes: { type: 'T_ADJMT_DETAIL__c' },
                    Id: selectedId
                }
            ]
        };

        helper.callServer(
            this,
            'GenericDataSaverApxCtrl',
            'deleteRecords',
            (function (result) {
                if (result && result.isSuccessful) {
                    // Remove the deleted entry from the wrapper arrays/maps
                    const updatedArr = (this._adjustmentDtlWarpArr || []).filter(
                        (item) =>
                            item &&
                            item.ajustmentDetails &&
                            item.ajustmentDetails.Id !== selectedId
                    );

                    const updatedMap = JSON.parse(JSON.stringify(this._adjustDetailMap || {}));
                    for (const key in updatedMap) {
                        const entries = updatedMap[key];
                        if (Array.isArray(entries) && entries.some(e => e && e.Id === selectedId)) {
                            delete updatedMap[key];
                            break;
                        }
                    }

                    // Notify parent
                    const deleteEvent = new CustomEvent('createadjustdetails', {
                        detail: {
                            adjustmentDtlWarpArr: updatedArr,
                            adjustDetailMap: updatedMap
                        }
                    });
                    this.dispatchEvent(deleteEvent);
                }
                this.showDeleteModal = false;
                this.selectedMenuItemValue = null;
            }).bind(this),
            JSON.stringify(params)
        );
    }

    /**
     * Handles cancellation of the delete confirmation modal.
     */
    handleDeleteCancel() {
        this.showDeleteModal = false;
        this.selectedMenuItemValue = null;
    }

    // ─── Private helpers ─────────────────────────────────────────────────────────

    /**
     * Returns true when the value is null, undefined, or an empty string.
     * Mirrors the isEmpty utility used in column visibility logic.
     */
    _isEmpty(value) {
        return value === null || value === undefined || value === '';
    }
}