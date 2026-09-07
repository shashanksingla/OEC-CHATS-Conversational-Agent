import { label } from 'c/labelUtility';

//_______________Adjustment Flow Helper - Single Export Object_______________//

// ─── Tab Configuration ─────────────────────────────────────────────────────────
const TAB_NAMES = ['Adjustment Information', 'Adjustment Summary'];
const TAB_TITLES = { 1: 'Adjustment Information', 2: 'Adjustment Summary' };
const TAB_INFO = {
    1: 'Step 1 of 2 — Enter and confirm the Adjustment information',
    2: 'Step 2 of 2 — Review the adjustment details entered, revise any entry before saving or finalizing the adjustment details.'
};

// ═══════════════════════════════════════════════════════════════════════════════
// FUNCTION IMPLEMENTATIONS
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Checks if a value is null, undefined, or empty string.
 */
function isEmpty(value) {
    return value === null || value === undefined || value === '';
}

/**
 * Formats an array of message strings into objects with Id and message properties.
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

/**
 * Builds an adjustment record object for upsert operations.
 */
function getAdjustmentRecord(adjustment) {
    return {
        sobjectType: 'T_ADJMT__c',
        attributes: { type: 'T_ADJMT__c' },
        Id: adjustment.Id,
        CDE_TYPE_CLSFN__c: adjustment.CDE_TYPE_CLSFN__c,
        IND_ORD_COURT_ADJMT__c: adjustment.IND_ORD_COURT_ADJMT__c,
        CDE_REASON__c: adjustment.CDE_REASON__c,
        Recovery_Initiative__c: adjustment.Recovery_Initiative__c,
        CDE_EDIT_REASON__c: adjustment.CDE_EDIT_REASON__c
    };
}

/**
 * Builds an address record object for upsert operations.
 */
function getAddressRecord(address) {
    return {
        sobjectType: 'T_ADJMT_ADDR__c',
        attributes: { type: 'T_ADJMT_ADDR__c' },
        Id: address.Id || null,
        IDN_ADJMT__c: address.IDN_ADJMT__c,
        ADR_LINE_1__c: address.ADR_LINE_1__c,
        ADR_LINE_2__c: address.ADR_LINE_2__c,
        ADR_CITY__c: address.ADR_CITY__c,
        ADR_STATE__c: address.ADR_STATE__c,
        ADR_ZIP_MAIN__c: address.ADR_ZIP_MAIN__c,
        ADR_ZIP_EXTN__c: address.ADR_ZIP_EXTN__c
    };
}

// ─── Data Transformation Functions ─────────────────────────────────────────────

function determineIsSubPayment(adjustment) {
    if (!adjustment) {
        return false;
    }
    const adjustmentAgainst = adjustment.CDE_AGNST_ADJMT__c || '';
    if (adjustmentAgainst) {
        return adjustmentAgainst === 'Sub-Payment';
    }
    // Fallback to RecordType if CDE_AGNST_ADJMT__c is not set
    const devName = (adjustment.RecordType && adjustment.RecordType.DeveloperName) || '';
    return devName.toLowerCase().indexOf('non') === -1;
}

/**
 * Determines if ART fees should be disabled.
 * @param {Object} adjustment - The adjustment record
 * @returns {boolean} - True if ART fees should be disabled
 */
function shouldDisableARTFees(adjustment) {
    if (!adjustment) {
        return false;
    }
    return !isEmpty(adjustment.IDN_CASE__c) && adjustment.CDE_TYPE_ADJMT__c === 'Recovery';
}

/**
 * Sets address fields based on adjustment data.
 * Mirrors Aura helper.setAddressFields logic.
 * @param {Object} objectData - The init data from server
 * @param {string} recordId - The adjustment record ID
 * @returns {Object} - Object containing address and responsiblePartiesAddressList
 */
function processAddressFields(objectData, recordId) {
    let address = { sobjectType: 'T_ADJMT_ADDR__c', attributes: { type: 'T_ADJMT_ADDR__c' } };
    let responsiblePartiesAddressListClone = objectData.addressList || [];
    let responsiblePartiesAddressList = objectData.responsiblePartiesAddressList || [];

    // Check if adjustment has existing address records
    // Adjustment__r is a relationship query result with { totalSize, done, records: [...] }
    if (objectData.adjustment && objectData.adjustment.Adjustment__r &&
        objectData.adjustment.Adjustment__r.records &&
        objectData.adjustment.Adjustment__r.records.length > 0) {
        // Use existing address from adjustment
        address = objectData.adjustment.Adjustment__r.records[0];
    } else {
        // Populate address from case or provider
        if (objectData.adjustment && !isEmpty(objectData.adjustment.IDN_CASE__c)) {
            // Case-based adjustment - get address from case
            if (objectData.caseRec && objectData.caseRec.T_SBSD_CASE3__r && objectData.caseRec.T_SBSD_CASE3__r[0]) {
                const caseAddr = objectData.caseRec.T_SBSD_CASE3__r[0];
                address.ADR_LINE_1__c = caseAddr.ADR_LINE_1__c;
                address.ADR_LINE_2__c = caseAddr.ADR_LINE_2__c;
                address.ADR_CITY__c = caseAddr.ADR_CITY__c;
                address.ADR_STATE__c = caseAddr.ADR_STATE__c;
                if (caseAddr.ADR_ZIP_MAIN__c != null && caseAddr.ADR_ZIP_MAIN__c !== undefined) {
                    address.ADR_ZIP_MAIN__c = String(caseAddr.ADR_ZIP_MAIN__c);
                }
                if (caseAddr.ADR_ZIP_EXTN__c != null && caseAddr.ADR_ZIP_EXTN__c !== undefined) {
                    address.ADR_ZIP_EXTN__c = String(caseAddr.ADR_ZIP_EXTN__c);
                }

                // Also update responsible parties address list
                if (responsiblePartiesAddressListClone && responsiblePartiesAddressListClone.length > 0) {
                    for (let i = 0; i < responsiblePartiesAddressListClone.length; i++) {
                        responsiblePartiesAddressListClone[i].ADR_LINE_1__c = caseAddr.ADR_LINE_1__c;
                        responsiblePartiesAddressListClone[i].ADR_LINE_2__c = caseAddr.ADR_LINE_2__c;
                        responsiblePartiesAddressListClone[i].ADR_CITY__c = caseAddr.ADR_CITY__c;
                        responsiblePartiesAddressListClone[i].ADR_STATE__c = caseAddr.ADR_STATE__c;
                        if (caseAddr.ADR_ZIP_MAIN__c != null && caseAddr.ADR_ZIP_MAIN__c !== undefined) {
                            responsiblePartiesAddressListClone[i].ADR_ZIP_MAIN__c = String(caseAddr.ADR_ZIP_MAIN__c);
                        }
                        if (caseAddr.ADR_ZIP_EXTN__c != null && caseAddr.ADR_ZIP_EXTN__c !== undefined) {
                            responsiblePartiesAddressListClone[i].ADR_ZIP_EXTN__c = String(caseAddr.ADR_ZIP_EXTN__c);
                        }
                    }
                }
            }
        } else if (objectData.adjustment && !isEmpty(objectData.adjustment.IDN_PROVR__c)) {
            // Provider-based adjustment - get address from provider
            if (objectData.adjustment.IDN_PROVR__r) {
                const provAddr = objectData.adjustment.IDN_PROVR__r;
                address.ADR_LINE_1__c = provAddr.ADR_LINE1_MLNG__c;
                address.ADR_CITY__c = provAddr.ADR_CITY_MLNG__c;
                address.ADR_STATE__c = provAddr.ADR_STATE_MLNG__c;
                address.ADR_ZIP_MAIN__c = provAddr.ADR_ZIP_MLNG__c;

                // Also update responsible parties address list
                if (responsiblePartiesAddressListClone && responsiblePartiesAddressListClone.length > 0) {
                    for (let i = 0; i < responsiblePartiesAddressListClone.length; i++) {
                        responsiblePartiesAddressListClone[i].ADR_LINE_1__c = provAddr.ADR_LINE1_MLNG__c;
                        responsiblePartiesAddressListClone[i].ADR_CITY__c = provAddr.ADR_CITY_MLNG__c;
                        responsiblePartiesAddressListClone[i].ADR_STATE__c = provAddr.ADR_STATE_MLNG__c;
                        responsiblePartiesAddressListClone[i].ADR_ZIP_MAIN__c = provAddr.ADR_ZIP_MLNG__c;
                    }
                }
            }
        }
        // Set adjustment ID on address
        address.IDN_ADJMT__c = recordId;
    }

    return {
        address,
        responsiblePartiesAddressList,
        responsiblePartiesAddressListClone
    };
}

/**
 * Processes responsible parties from adjustment data.
 * Mirrors Aura helper.setResponsibleParties logic.
 * @param {Object} objectData - The init data from server
 * @param {Object} adjustment - The adjustment record
 * @param {string} pageMode - Current page mode (view/edit/create)
 * @returns {Object} - Object containing responsibleParties, responsiblePartyList
 */
function processResponsibleParties(objectData, adjustment, pageMode) {
    const responsibleParties = objectData.responsibleParties || [];
    const responsiblePartyList = objectData.responsiblePartyList || [];
    const responsiblePartyObj = { sobjectType: 'T_ADJMT_RESPBL_PARTY__c' };

    // Check if adjustment has existing responsible party records
    if (objectData.adjustment && objectData.adjustment.Adjustent5__r) {
        objectData.adjustment.Adjustent5__r.records.forEach((existingResponsibleParty) => {
            const partyObj = { ...responsiblePartyObj };

            if (pageMode === 'view' && !isEmpty(existingResponsibleParty.IDN_CLIENT__c)) {
                // View mode - use name for display
                partyObj.IDN_CLIENT__c = existingResponsibleParty.IDN_CLIENT__c;
                partyObj.IDN_ADJMT__c = adjustment.Id;
                if (existingResponsibleParty.IDN_CLIENT__r) {
                    partyObj.Responsible_Party_Name__c =
                        existingResponsibleParty.IDN_CLIENT__r.NAM_LAST__c + ', ' +
                        existingResponsibleParty.IDN_CLIENT__r.NAM_FIRST__c;
                }
            } else {
                // Edit mode - use ID for selection
                partyObj.IDN_CLIENT__c = existingResponsibleParty.IDN_CLIENT__c;
                partyObj.IDN_ADJMT__c = adjustment.Id;
                if (existingResponsibleParty.IDN_CLIENT__r) {
                    partyObj.Responsible_Party_Name__c =
                        existingResponsibleParty.IDN_CLIENT__r.NAM_LAST__c + ', ' +
                        existingResponsibleParty.IDN_CLIENT__r.NAM_FIRST__c;
                }
            }
        });
    }

    return {
        responsibleParties,
        responsiblePartyList
    };
}

/**
 * Builds adjustment reason options based on adjustment type and context.
 * Mirrors Aura helper.setAdjustmentReasonOptions logic.
 * @param {Object} adjustment - The adjustment record
 * @returns {Object[]} - Array of picklist options
 */
function buildAdjustmentReasonOptions(adjustment) {
    if (!adjustment) {
        return [{ value: null, label: '--None--', selected: false }];
    }

    const adjustmentReasonOptions = [{ value: null, label: '--None--', selected: false }];
    const reason = adjustment.CDE_REASON__c || '';
    const hasProvider = !isEmpty(adjustment.IDN_PROVR__c);
    const hasCase = !isEmpty(adjustment.IDN_CASE__c);
    const adjType = adjustment.CDE_TYPE_ADJMT__c;

    // Helper function to check if reason is selected
    // Checks for both value and label match, and handles semicolon-separated multi-select values
    const isSelected = (value, label) => {
        if (!reason) return false;
        // Check exact match for single value
        if (reason === label || reason === value) return true;
        // Check if reason contains the label or value (for multi-select scenarios)
        if (reason.includes(label) || reason.includes(value)) return true;
        return false;
    };

    if (!isEmpty(reason)) {
        // Existing reason - show options based on context with selection
        if (hasProvider && adjType === 'Claim') {
            adjustmentReasonOptions.push({ value: '24', label: 'Care provided-not paid automatically', selected: isSelected('24', 'Care provided-not paid automatically') });
            adjustmentReasonOptions.push({ value: '25', label: 'Care provided-payment rate type change', selected: isSelected('25', 'Care provided-payment rate type change') });
            adjustmentReasonOptions.push({ value: '26', label: 'ART Fees', selected: isSelected('26', 'ART Fees') });
            adjustmentReasonOptions.push({ value: '28', label: 'Care paid at incorrect rate/rate type', selected: isSelected('28', 'Care paid at incorrect rate/rate type') });
            adjustmentReasonOptions.push({ value: '31', label: 'Parent fee adjustment', selected: isSelected('31', 'Parent fee adjustment') });
        } else if (hasProvider && adjType === 'Recovery') {
            adjustmentReasonOptions.push({ value: '14', label: 'Fraud (Refer To Court Decision Or Consent Agreement)', selected: isSelected('14', 'Fraud (Refer To Court Decision Or Consent Agreement)') });
            if (reason.includes('Tax Intercept') || reason.includes('21')) {
                adjustmentReasonOptions.push({ value: '21', label: 'Tax Intercept', selected: isSelected('21', 'Tax Intercept') });
            }
            adjustmentReasonOptions.push({ value: '25', label: 'Care provided-payment rate type change', selected: isSelected('25', 'Care provided-payment rate type change') });
            adjustmentReasonOptions.push({ value: '26', label: 'ART Fees', selected: isSelected('26', 'ART Fees') });
            adjustmentReasonOptions.push({ value: '27', label: 'Care Not Provided', selected: isSelected('27', 'Care Not Provided') });
            adjustmentReasonOptions.push({ value: '28', label: 'Care paid at incorrect rate/rate type', selected: isSelected('28', 'Care paid at incorrect rate/rate type') });
            adjustmentReasonOptions.push({ value: '30', label: 'License Closed/Suspended', selected: isSelected('30', 'License Closed/Suspended') });
            adjustmentReasonOptions.push({ value: '31', label: 'Parent fee adjustment', selected: isSelected('31', 'Parent fee adjustment') });
        } else if (hasCase && adjType === 'Recovery') {
            adjustmentReasonOptions.push({ value: '1', label: 'Household Ineligible Due to Income Exceeding 85% SMI', selected: isSelected('1', 'Household Ineligible Due to Income Exceeding 85% SMI') });
            if (reason.includes('Incorrectly Reported Household Composition') || reason.includes('7')) {
                adjustmentReasonOptions.push({ value: '7', label: 'Incorrectly Reported Household Composition', selected: isSelected('7', 'Incorrectly Reported Household Composition') });
            }
            if (reason.includes('Incorrectly Reported Earned Income') || reason.includes('8')) {
                adjustmentReasonOptions.push({ value: '8', label: 'Incorrectly Reported Earned Income', selected: isSelected('8', 'Incorrectly Reported Earned Income') });
            }
            if (reason.includes('Incorrectly Reported Unearned Income') || reason.includes('9')) {
                adjustmentReasonOptions.push({ value: '9', label: 'Incorrectly Reported Unearned Income', selected: isSelected('9', 'Incorrectly Reported Unearned Income') });
            }
            adjustmentReasonOptions.push({ value: '10', label: 'Interim Benefits Were Issued While Awaiting A Hearing', selected: isSelected('10', 'Interim Benefits Were Issued While Awaiting A Hearing') });
            if (reason.includes('Other Household Error') || reason.includes('11')) {
                adjustmentReasonOptions.push({ value: '11', label: 'Other Household Error', selected: isSelected('11', 'Other Household Error') });
            }
            adjustmentReasonOptions.push({ value: '13', label: 'Intentional Program Violation/Fraud', selected: isSelected('13', 'Intentional Program Violation/Fraud') });
            if (reason.includes('Fraud (Refer To Court Decision Or Consent Agreement)') || reason.includes('14')) {
                adjustmentReasonOptions.push({ value: '14', label: 'Fraud (Refer To Court Decision Or Consent Agreement)', selected: isSelected('14', 'Fraud (Refer To Court Decision Or Consent Agreement)') });
            }
            if (reason.includes('Client Recovery/Parental Fee') || reason.includes('15')) {
                adjustmentReasonOptions.push({ value: '15', label: 'Client Recovery/Parental Fee', selected: isSelected('15', 'Client Recovery/Parental Fee') });
            }
            if (reason.includes('Tax Intercept') || reason.includes('21')) {
                adjustmentReasonOptions.push({ value: '21', label: 'Tax Intercept', selected: isSelected('21', 'Tax Intercept') });
            }
            adjustmentReasonOptions.push({ value: '22', label: 'Client Failed to accurately report Eligible Activity', selected: isSelected('22', 'Client Failed to accurately report Eligible Activity') });
            adjustmentReasonOptions.push({ value: '32', label: 'Client Failed to accurately report HH comp', selected: isSelected('32', 'Client Failed to accurately report HH comp') });
            adjustmentReasonOptions.push({ value: '33', label: 'Client Failed to accurately report income', selected: isSelected('33', 'Client Failed to accurately report income') });
            adjustmentReasonOptions.push({ value: '34', label: 'Client Failed to accurately report residency', selected: isSelected('34', 'Client Failed to accurately report residency') });
            adjustmentReasonOptions.push({ value: '35', label: 'Client falsely reported expenses', selected: isSelected('35', 'Client falsely reported expenses') });
            adjustmentReasonOptions.push({ value: '36', label: 'Client falsely reported income', selected: isSelected('36', 'Client falsely reported income') });
            adjustmentReasonOptions.push({ value: '37', label: 'Client falsely reported eligibility information', selected: isSelected('37', 'Client falsely reported eligibility information') });
        }
    } else {
        // No existing reason - show all options for context
        if (hasProvider && adjType === 'Claim') {
            adjustmentReasonOptions.push({ value: '24', label: 'Care provided-not paid automatically', selected: false });
            adjustmentReasonOptions.push({ value: '25', label: 'Care provided-payment rate type change', selected: false });
            adjustmentReasonOptions.push({ value: '26', label: 'ART Fees', selected: false });
            adjustmentReasonOptions.push({ value: '28', label: 'Care paid at incorrect rate/rate type', selected: false });
            adjustmentReasonOptions.push({ value: '31', label: 'Parent fee adjustment', selected: false });
        } else if (hasProvider && adjType === 'Recovery') {
            adjustmentReasonOptions.push({ value: '14', label: 'Fraud (Refer To Court Decision Or Consent Agreement)', selected: false });
            adjustmentReasonOptions.push({ value: '25', label: 'Care provided-payment rate type change', selected: false });
            adjustmentReasonOptions.push({ value: '26', label: 'ART Fees', selected: false });
            adjustmentReasonOptions.push({ value: '27', label: 'Care Not Provided', selected: false });
            adjustmentReasonOptions.push({ value: '28', label: 'Care paid at incorrect rate/rate type', selected: false });
            adjustmentReasonOptions.push({ value: '30', label: 'License Closed/Suspended', selected: false });
            adjustmentReasonOptions.push({ value: '31', label: 'Parent fee adjustment', selected: false });
        } else if (hasCase && adjType === 'Recovery') {
            adjustmentReasonOptions.push({ value: '1', label: 'Household Ineligible Due to Income Exceeding 85% SMI', selected: false });
            adjustmentReasonOptions.push({ value: '10', label: 'Interim Benefits Were Issued While Awaiting A Hearing', selected: false });
            adjustmentReasonOptions.push({ value: '13', label: 'Intentional Program Violation/Fraud', selected: false });
            adjustmentReasonOptions.push({ value: '22', label: 'Client Failed to accurately report Eligible Activity', selected: false });
            adjustmentReasonOptions.push({ value: '32', label: 'Client Failed to accurately report HH comp', selected: false });
            adjustmentReasonOptions.push({ value: '33', label: 'Client Failed to accurately report income', selected: false });
            adjustmentReasonOptions.push({ value: '34', label: 'Client Failed to accurately report residency', selected: false });
            adjustmentReasonOptions.push({ value: '35', label: 'Client falsely reported expenses', selected: false });
            adjustmentReasonOptions.push({ value: '36', label: 'Client falsely reported income', selected: false });
            adjustmentReasonOptions.push({ value: '37', label: 'Client falsely reported eligibility information', selected: false });
        }
    }
    //console.log('adjustmentReasonOptions' + JSON.stringify(adjustmentReasonOptions));
    return adjustmentReasonOptions;
}

// ─── Validation Functions ──────────────────────────────────────────────────────

/**
 * Validates recovery adjustment based on discovery date and amount.
 * @param {Object} adjustment - The adjustment record
 * @returns {Object} - { isValid: boolean, errorMessage: string|null }
 */
function validateRecoveryAdjustment(adjustment) {
    const discoveryDate = adjustment.DTE_DISCV_ADJMT_ORIG__c;
    const amount = Math.abs(adjustment.AMT_ADJMT__c || 0);

    if (amount < 50 && discoveryDate) {
        const discovery = new Date(discoveryDate);
        const today = new Date();
        const monthsDiff = (today.getFullYear() - discovery.getFullYear()) * 12 +
            (today.getMonth() - discovery.getMonth());

        if (monthsDiff > 12) {
            return {
                isValid: false,
                errorMessage: label.adjustment_error_discoveryDate
            };
        }
    }
    return { isValid: true, errorMessage: null };
}

/**
 * Updates reason picklist to use labels instead of values.
 * @param {Object} adjustment - The adjustment record
 * @param {Object[]} adjustmentReasonOptions - The reason options array
 * @returns {Object} - Updated adjustment with CDE_REASON__c set to labels
 */
function updateReasonToLabel(adjustment, adjustmentReasonOptions) {
    if (adjustmentReasonOptions && adjustmentReasonOptions.length > 0) {
        const selectedLabels = adjustmentReasonOptions
            .filter(opt => opt.selected)
            .map(opt => opt.label)
            .join(';');

        return {
            ...adjustment,
            CDE_REASON__c: selectedLabels
        };
    }
    return adjustment;
}

// ─── Button Visibility Logic ───────────────────────────────────────────────────

/**
 * Determines button visibility based on current tab and mode.
 * @param {number} currentTabNumber - Current tab (1 or 2)
 * @param {string} pageMode - Current page mode (view/edit/create)
 * @param {Object} adjustment - The adjustment record
 * @returns {Object} - { showCancel, showSaveAsDraft, showAddAdjDetail }
 */
function getButtonVisibility(currentTabNumber, pageMode, adjustment) {
    let showCancel = true;
    let showSaveAsDraft = false;
    let showAddAdjDetail = false;
    let finishLabel;

    if (pageMode === 'edit' || pageMode === 'create') {
        if (currentTabNumber === 1) {
            showCancel = true;
            showSaveAsDraft = false;
            showAddAdjDetail = false;
        } else if (currentTabNumber === 2) {
            showAddAdjDetail = true; // Add Adjustment Detail

            // Hide Save as Draft for Recovery + Calculation Complete
            const isRecoveryCalcComplete =
                adjustment.CDE_TYPE_ADJMT__c === 'Recovery' &&
                adjustment.CDE_STATUS_ADJMT__c === 'Calculation Complete';
            showSaveAsDraft = !isRecoveryCalcComplete;
        }
    } else {
        // View mode - hide all custom buttons
        showCancel = currentTabNumber === 1;
        showSaveAsDraft = false;
        showAddAdjDetail = false;
        finishLabel = 'Finish';

    }

    return { showCancel, showSaveAsDraft, showAddAdjDetail, finishLabel };
}

// ─── Error Handling ────────────────────────────────────────────────────────────

/**
 * Extracts error message from various error formats.
 */
function extractErrorMessage(error) {
    if (!error) {
        return 'An unexpected error occurred.';
    }
    if (error.message) {
        return error.message;
    }
    if (error.body && error.body.message) {
        return error.body.message;
    }
    return 'An unexpected error occurred.';
}

// ─── Finalization Helpers ─────────────────────────────────────────────────────

/**
 * Builds the adjustment object for finalization.
 */
function buildFinalizedAdjustment(adjustment, recordTypeId, isRecoveryType, pageMode, outstandingRecoveryBalance) {
    const adjustmentToSave = {
        Id: adjustment.Id,
        sobjectType: 'T_ADJMT__c',
        RecordTypeId: recordTypeId,
        attributes: { type: 'T_ADJMT__c' },
        CDE_STATUS_ADJMT__c: '2',
        AMT_ADJMT__c: adjustment.AMT_ADJMT__c  // Aura explicitly saves AMT_ADJMT__c during finalization
    };

    if (isRecoveryType) {
        if (adjustment.CDE_STATUS_ADJMT__c === 'Calculation Complete' && pageMode === 'edit') {
            adjustmentToSave.CHK_CR206ForceTrigger__c = true;
        }
        const currentDevName = adjustment.RecordType ? adjustment.RecordType.DeveloperName : '';
        if (currentDevName !== 'Finalized') {
            adjustmentToSave.DTE_EFFV_RECOVERY__c = new Date().toISOString().split('T')[0];
        }
        // Aura uses the server-calculated outstandingRecoveryBalance from getRecordTypeId response
        // If not provided, fall back to the current adjustment field value.
        adjustmentToSave.Outstanding_Recovery_Balance__c = (outstandingRecoveryBalance != null)
            ? outstandingRecoveryBalance
            : adjustment.Outstanding_Recovery_Balance__c;
    }

    return adjustmentToSave;
}

/**
 * Builds array of finalized adjustment details.
 */
function buildFinalizedAdjustmentDetails(adjustmentDtlWarp) {
    const updatedDetails = [];
    if (adjustmentDtlWarp && adjustmentDtlWarp.length > 0) {
        adjustmentDtlWarp.forEach(wrap => {
            if (wrap.ajustmentDetails) {
                updatedDetails.push({
                    ...wrap.ajustmentDetails,
                    sobjectType: 'T_ADJMT_DETAIL__c',
                    attributes: { type: 'T_ADJMT_DETAIL__c' },
                    CDE_STATUS_ADJMT__c: '2'
                });
            }
        });
    }
    return updatedDetails;
}

/**
 * Builds the adjustment object for saving as draft.
 */
function buildDraftAdjustment(adjustmentId, recordTypeId) {
    return {
        Id: adjustmentId,
        sobjectType: 'T_ADJMT__c',
        attributes: { type: 'T_ADJMT__c' },
        RecordTypeId: recordTypeId
    };
}

// ─── Cancellation Helpers ─────────────────────────────────────────────────────

/**
 * Builds array of records to delete during cancellation.
 */
function buildRecordsToDelete(address, adjustmentDtlWarp, nonAdjustmentDetailObj) {
    const recordsToDelete = [];

    if (address && address.Id) {
        recordsToDelete.push({
            Id: address.Id,
            sobjectType: 'T_ADJMT_ADDR__c',
            attributes: { type: 'T_ADJMT_ADDR__c' }
        });
    }

    if (adjustmentDtlWarp && adjustmentDtlWarp.length > 0) {
        adjustmentDtlWarp.forEach(wrap => {
            if (wrap.ajustmentDetails && wrap.ajustmentDetails.Id) {
                recordsToDelete.push({
                    Id: wrap.ajustmentDetails.Id,
                    sobjectType: 'T_ADJMT_DETAIL__c',
                    attributes: { type: 'T_ADJMT_DETAIL__c' }
                });
            }
        });
    }

    if (nonAdjustmentDetailObj && nonAdjustmentDetailObj.length > 0) {
        nonAdjustmentDetailObj.forEach(detail => {
            if (detail.Id) {
                recordsToDelete.push({
                    Id: detail.Id,
                    sobjectType: 'T_NON_ADJMT_DETAIL__c',
                    attributes: { type: 'T_NON_ADJMT_DETAIL__c' }
                });
            }
        });
    }

    return recordsToDelete;
}

/**
 * Determines if record is New type (for cancellation logic).
 */
function isNewRecordType(adjustment) {
    const currentDevName = adjustment?.RecordType?.DeveloperName || '';
    return currentDevName === 'New';
}

// ─── Modal Result Processing Helpers ──────────────────────────────────────────

/**
 * Processes the result from Add/Edit Adjustment Detail modal.
 * Mirrors Aura confirmFinishHlp / confirmDoSaveAndNewHlp which fire the
 * adjustmentDetailSummaryEvent regardless of whether adjustmentDtlWarp is
 * populated — the server may return null/empty on the first save.
 */
function processAdjDetailModalResult(result) {
    if (!result || result.action === 'cancel') {
        return null;
    }

    // Do NOT gate on adjustmentDtlWarp — it can be null/empty on a first save
    // and the parent still needs to update its state (adjustDetailMap, AMT_ADJMT__c).
    const updates = {
        // Preserve null so the caller can distinguish "not yet populated" from "empty list"
        adjustmentDtlWarp: result.adjustmentDtlWarp !== undefined
            ? (result.adjustmentDtlWarp ? [...result.adjustmentDtlWarp] : [])
            : undefined
    };

    if (result.adjustDetailMap) {
        updates.adjustDetailMap = { ...result.adjustDetailMap };
    }

    if (result.adjustmentAmount !== undefined) {
        updates.adjustmentAmount = result.adjustmentAmount;
    }

    updates.shouldSaveAndNew = result.action === 'saveAndNew';

    return updates;
}

/**
 * Processes the result from Adjustment Note modal.
 */
function processAdjNoteModalResult(result) {
    if (!result) {
        return { action: 'closed' };
    }

    const evtType = result.evtType;
    if (evtType === 'save') {
        return { action: 'saved', showSuccess: true };
    }
    if (evtType === 'close') {
        return { action: 'cancelled' };
    }

    return { action: 'unknown' };
}

// ─── Loop Prevention Helpers ──────────────────────────────────────────────────

/**
 * Checks if adjustment amount has changed (loop prevention).
 */
function hasAmountChanged(currentAmount, newAmount) {
    return currentAmount !== newAmount;
}

/**
 * Checks if adjustment detail summary data has changed (loop prevention).
 */
function checkSummaryDataChanges(current, incoming) {
    const currentLength = current.adjustmentDtlWarp ? current.adjustmentDtlWarp.length : 0;
    const newLength = incoming.adjustmentDtlWarp ? incoming.adjustmentDtlWarp.length : 0;

    const currentMapKeys = current.adjustDetailMap ? Object.keys(current.adjustDetailMap).sort().join(',') : '';
    const newMapKeys = incoming.adjustDetailMap ? Object.keys(incoming.adjustDetailMap).sort().join(',') : '';

    const lengthChanged = currentLength !== newLength;
    const mapChanged = currentMapKeys !== newMapKeys;
    const amountChanged = incoming.adjustmentAmount !== undefined &&
        current.adjustment?.AMT_ADJMT__c !== incoming.adjustmentAmount;

    // Detect ART-fee-only changes: same row count but individual AMT_DETAIL_ADJMT__c values differ.
    // Without this check, adding ART fees to an existing row would pass through all other guards
    // silently (length unchanged, map keys unchanged, adjustmentAmount not in event detail)
    // and the summary table would keep stale per-row amounts.
    let wrapAmountChanged = false;
    if (!lengthChanged && incoming.adjustmentDtlWarp && current.adjustmentDtlWarp) {
        const currentTotal = current.adjustmentDtlWarp.reduce((sum, w) => {
            const amt = w && w.ajustmentDetails && w.ajustmentDetails.AMT_DETAIL_ADJMT__c;
            return sum + (amt ? parseFloat(amt) : 0);
        }, 0);
        const incomingTotal = incoming.adjustmentDtlWarp.reduce((sum, w) => {
            const amt = w && w.ajustmentDetails && w.ajustmentDetails.AMT_DETAIL_ADJMT__c;
            return sum + (amt ? parseFloat(amt) : 0);
        }, 0);
        wrapAmountChanged = currentTotal !== incomingTotal;
    }

    return {
        lengthChanged,
        mapChanged,
        amountChanged,
        wrapAmountChanged,
        anyChanged: lengthChanged || mapChanged || amountChanged || wrapAmountChanged
    };
}

// ─── Picklist Tracking Helpers ────────────────────────────────────────────────

/**
 * Generates a unique key for picklist field tracking.
 */
function generatePicklistFieldKey(eventDetail) {
    return `${eventDetail.object}_${eventDetail.field || eventDetail.fieldName}_${eventDetail.uniqueKey}`;
}

/**
 * Calculates expected picklist event count based on component visibility.
 */
function calculateExpectedPicklistEvents(config) {
    const {
        isViewMode,
        isRecoveryType,
        isRecoveryWithCase,
        showAdjustmentReasonSection,
        responsiblePartiesAddressListLength
    } = config;

    if (isViewMode) {
        return 0;
    }

    let count = 0;

    if (isRecoveryType) {
        count += 2; // CDE_TYPE_CLSFN__c and IND_ORD_COURT_ADJMT__c
    }

    if (showAdjustmentReasonSection) {
        count++; // CDE_REASON__c
    }

    if (showAdjustmentReasonSection && isRecoveryType) {
        count++; // CDE_EDIT_REASON__c
    }

    if (!isRecoveryWithCase) {
        count++; // ADR_STATE__c in adjustmentAddress
    }

    if (isRecoveryWithCase && responsiblePartiesAddressListLength > 0) {
        count += responsiblePartiesAddressListLength; // ADR_STATE__c per responsible party
    }

    return count;
}

// ─── Validation Helpers ───────────────────────────────────────────────────────

/**
 * Validates that adjustment details exist before finalization.
 */
function validateAdjustmentDetailsExist(adjustmentAgainst, adjustmentDtlWarp, nonAdjustmentDetailObj) {
    if (adjustmentAgainst === 'Sub-Payment') {
        return adjustmentDtlWarp != null && adjustmentDtlWarp !== undefined && adjustmentDtlWarp.length > 0;
    }
    if (adjustmentAgainst === 'Non Sub-Payment') {
        return nonAdjustmentDetailObj != null && nonAdjustmentDetailObj !== undefined;
    }
    return false;
}

// ─── Single Export Object ──────────────────────────────────────────────────────
export const adjustmentFlowHelper = {
    TAB_NAMES, TAB_TITLES, TAB_INFO,
    isEmpty, formatMessages, getAdjustmentRecord, getAddressRecord,
    determineIsSubPayment, shouldDisableARTFees, processAddressFields, processResponsibleParties,
    buildAdjustmentReasonOptions, validateRecoveryAdjustment, updateReasonToLabel, getButtonVisibility,
    extractErrorMessage, buildFinalizedAdjustment, buildFinalizedAdjustmentDetails,
    buildDraftAdjustment, buildRecordsToDelete, isNewRecordType,
    processAdjDetailModalResult, processAdjNoteModalResult, hasAmountChanged, checkSummaryDataChanges,
    generatePicklistFieldKey, calculateExpectedPicklistEvents, validateAdjustmentDetailsExist
};