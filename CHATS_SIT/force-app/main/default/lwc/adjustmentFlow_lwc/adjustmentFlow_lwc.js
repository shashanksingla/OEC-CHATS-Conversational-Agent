import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { helper } from 'c/generic_Utilities';
import { label } from 'c/labelUtility';
import { abs_helper } from 'c/abstract_Component';
import AdjustmentNoteModal from 'c/adjustmentNoteOverride_Modal_lwc';
import AddAdjDetailFlowModal from 'c/adjustmentFlow_SubPayment_AddAdjDetailFlow_Modal_lwc';
import { adjustmentFlowHelper as hlp } from './adjustmentFlowHelper_lwc';

const { TAB_NAMES, TAB_TITLES, TAB_INFO, isEmpty, formatMessages, getAdjustmentRecord, getAddressRecord,
    determineIsSubPayment, shouldDisableARTFees, processAddressFields, processResponsibleParties,
    buildAdjustmentReasonOptions, validateRecoveryAdjustment, updateReasonToLabel, getButtonVisibility,
    extractErrorMessage, buildFinalizedAdjustment, buildFinalizedAdjustmentDetails, buildDraftAdjustment,
    buildRecordsToDelete, isNewRecordType, processAdjDetailModalResult, processAdjNoteModalResult,
    checkSummaryDataChanges, hasAmountChanged, validateAdjustmentDetailsExist } = hlp;

export default class AdjustmentFlow_lwc extends NavigationMixin(LightningElement) {

    // ══════════════════════════════════════════════════════════════════════════
    // @API PROPERTIES
    // ══════════════════════════════════════════════════════════════════════════
    @api recordId;
    @api pageMode = 'view';

    // ══════════════════════════════════════════════════════════════════════════
    // @TRACK PROPERTIES
    // ══════════════════════════════════════════════════════════════════════════

    // Spinner and initialization
    @track showSpinner = false;
    @track initLoaded = false;

    // Tab navigation
    @track _currentTabNumber = 1;
    saveState = '';

    // Tab visibility flags
    @track isTab1 = true;
    @track isTab2SubPayment = false;
    @track isTab2NonSubPayment = false;

    // Navigation button state
    @track _showCancel = true;
    @track _showSaveAsDraft = false;
    @track _showAddAdjDetail = false;
    @track _finishLabel = 'Finalize Adjustment';

    // Page validation and state
    @track doNextEnabled = true;
    @track isCurrentPageValid = false;

    // Page messaging and error handling
    @track _pageMessages = [];
    @track _messageType = '';
    @track _fieldValidationErrors = [];
    @track _missingPageMessages = [];

    // Adjustment data (Tab 1)
    @track adjustment = { sobjectType: 'T_ADJMT__c', attributes: { type: 'T_ADJMT__c' } };
    @track address = { sobjectType: 'T_ADJMT_ADDR__c', attributes: { type: 'T_ADJMT_ADDR__c' } };
    @track adjustmentReasonOptions = [];
    @track responsibleParties = [];
    @track responsiblePartyList = [];
    @track responsiblePartiesAddressList = [];
    @track responsiblePartiesAddressListClone = [];
    @track isEditableAddress = false;
    @track recordError = [];
    @track responsiblePartyObj = { sobjectType: 'T_ADJMT_RESPBL_PARTY__c', attributes: { type: 'T_ADJMT_RESPBL_PARTY__c' } };

    // Summary and Tab 2 data (Sub-Payment flow)
    @track adjustmentDtlWarp = [];
    @track adjustmentDetailLst = [];
    @track individualObj;
    @track adjustmentEntryEditMode = false;
    @track rateTypeOptions = [];
    @track rateTypeOptionsMap = {};
    @track rateTypeOptionsCareDateMap = {};
    @track careUnitTypeOptionsMap = {};
    @track careLevelOptionsMap = {};
    @track careUnitTypeOptions = [];
    @track careLevelOptions = [];
    @track slotCntcheckbox = false;
    @track adjustDetailMap = {};
    @track childCurrentUtilization;
    @track disabledARTFees = false;
    @track isSubPayment = false;
    @track authId = '';
    @track authorizationAssocIndiv = '';

    // Non Sub-Payment flow
    @track nonAdjustmentDetailObj = [];
    @track nonAdjustmentDetail = { sobjectType: 'T_NON_ADJMT_DETAIL__c', attributes: { type: 'T_NON_ADJMT_DETAIL__c' } };
    @track hasNonAdjDetailError = false;

    // Additional flags
    @track doNextIncrement = false;
    @track isRefresh = true;

    // Modal visibility flags
    @track showCancelModal = false;
    @track showFinishModal = false;
    @track showSaveAsDraftModal = false;
    @track showAdjNoteModal = false;

    // ══════════════════════════════════════════════════════════════════════════
    // GETTER / SETTER PROPERTIES
    // ══════════════════════════════════════════════════════════════════════════

    // Tab Number
    get currentTabNumber() {
        return this._currentTabNumber;
    }

    set currentTabNumber(value) {
        this._currentTabNumber = value;
        this.updateTabState();
    }

    // Tab Title
    get currentTabTitle() {
        return TAB_TITLES[this._currentTabNumber] || '';
    }

    // Tab Info
    get currentTabInfo() {
        return TAB_INFO[this._currentTabNumber] || '';
    }

    // Tab Names
    get tabNames() {
        return TAB_NAMES;
    }

    // Finish Label
    get finishLabel() {
        return this._finishLabel;
    }

    set finishLabel(value) {
        this._finishLabel = value;
    }

    // Cancel Label
    get cancelLabel() {
        return 'Cancel';
    }

    // Previous Label
    get previousLabel() {
        return 'Previous';
    }

    // Show Cancel Button
    get showCancel() {
        return this._showCancel;
    }

    // Show Custom Button 1
    get showSaveAsDraft() {
        return this._showSaveAsDraft;
    }

    // Add Adjustment Detail Label
    get addAdjDetailLabel() {
        return 'Add Adjustment Detail';
    }

    // Show Custom Button 2
    get showAddAdjDetail() {
        return this._showAddAdjDetail;
    }

    // Save as Draft Label
    get saveAsDraftLabel() {
        return 'Save as Draft';
    }

    // Is Recovery Type
    get isRecoveryType() {
        return this.adjustment?.CDE_TYPE_ADJMT__c === 'Recovery';
    }

    // Is Recovery with Case
    get isRecoveryWithCase() {
        return this.isRecoveryType && this.adjustment?.IDN_CASE__c;
    }

    // Page Messages
    get pageMessages() {
        return this._pageMessages;
    }

    set pageMessages(value) {
        this._pageMessages = value || [];
        if (this._pageMessages && this._pageMessages.length > 0 && this._messageType === 'error') {
            this.showSpinner = false;
        }
    }

    // Message Type
    get messageType() {
        if (this._messageType) {
            return this._messageType;
        }
        return this._pageMessages && this._pageMessages.length > 0 ? 'error' : '';
    }

    set messageType(value) {
        this._messageType = value || '';
        if (value === 'error') {
            this.showSpinner = false;
        }
    }

    // Field Validation Errors
    get fieldValidationErrors() {
        return this._fieldValidationErrors;
    }

    set fieldValidationErrors(value) {
        this._fieldValidationErrors = value || [];
    }

    // Missing Page Messages
    get missingPageMessages() {
        return this._missingPageMessages;
    }

    set missingPageMessages(value) {
        this._missingPageMessages = value || [];
    }

    // Modal Messages
    get cancelAdjustment() {
       // return 'Are you sure you want to cancel? Any unsaved changes will be lost.';
       return label.FMFlow_CancelAdjustmentMessage;
    }

    get finishMsg() {
        return 'Finalize Adjustment?';
    }

    get saveAsDraftMsg() {
        return 'Proceed with Save as Draft';
    }

    get adjNoteMsg() {
        return 'Adjustment cannot be finalized without an adjustment note. Please create an Adjustment Note.';
    }

    // ══════════════════════════════════════════════════════════════════════════
    // MAIN FUNCTIONS - LIFECYCLE & INITIALIZATION
    // ══════════════════════════════════════════════════════════════════════════
    connectedCallback() {
        this.doInit();
    }

    doInit() {
        if (!this.recordId) {
            this.initLoaded = true;
            return;
        }
        this.showSpinner = true;

        const params = { adjustmentId: this.recordId };

        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'doGetInitData',
            (function (result) {
                if (result.objectData) {
                    const data = result.objectData || {};
                    this.processInitData(data);
                    this.initLoaded = true;
                } else {
                    this._messageType = 'error';
                    this._pageMessages = formatMessages([
                        (result && result.errorMessage) ? result.errorMessage : 'Error fetching record type.'
                    ]);
                }
                this.showSpinner = false;
            }).bind(this),
            JSON.stringify(params),
            null
        );
    }

    processInitData(data) {
        if (data.adjustment) {
            this.adjustment = data.adjustment;
            this.isSubPayment = determineIsSubPayment(this.adjustment);
            this.disabledARTFees = shouldDisableARTFees(this.adjustment);
        }

        if (data.adjustDetailMap) {
            this.adjustDetailMap = data.adjustDetailMap;
        }

        if (data.currentUtilizationMap) {
            this.childCurrentUtilization = data.currentUtilizationMap;
        }

        if (data.isEditableAddress !== undefined) {
            this.isEditableAddress = data.isEditableAddress;
        }

        if (data.nonAdjustmentDetail) {
            this.nonAdjustmentDetailObj = data.nonAdjustmentDetail;
        }

        if (data.adjustmentDtlWarp) {
            this.adjustmentDtlWarp = data.adjustmentDtlWarp;
        }

        if (data.individualObj) {
            this.individualObj = data.individualObj;
        }

        if (data.rateTypeOptions) {
            this.rateTypeOptions = data.rateTypeOptions;
        }

        const addrCtx = processAddressFields(data, this.recordId);
        this.address = addrCtx.address;
        this.responsiblePartiesAddressList = addrCtx.responsiblePartiesAddressList;
        this.responsiblePartiesAddressListClone = addrCtx.responsiblePartiesAddressListClone;

        const respCtx = processResponsibleParties(data, this.adjustment, this.pageMode);
        this.responsibleParties = respCtx.responsibleParties;
        this.responsiblePartyList = respCtx.responsiblePartyList;

        if (data.careUnitTypeOptionsMap) {
            this.careUnitTypeOptionsMap = data.careUnitTypeOptionsMap;
        }

        if (data.careLevelOptionsMap) {
            this.careLevelOptionsMap = data.careLevelOptionsMap;
        }

        if (data.careUnitTypeOptions) {
            this.careUnitTypeOptions = data.careUnitTypeOptions;
        }

        if (data.careLevelOptions) {
            this.careLevelOptions = data.careLevelOptions;
        }

        if (data.adjustment && this.pageMode !== 'view') {
            this.adjustmentReasonOptions = buildAdjustmentReasonOptions(this.adjustment);
        }

        if (data.rateTypeOptionsMap) {
            this.rateTypeOptionsMap = data.rateTypeOptionsMap;
        }
        if (data.rateTypeOptionsCareDateMap) {
            this.rateTypeOptionsCareDateMap = data.rateTypeOptionsCareDateMap;
        }

        if (data.adjustmentDetailLst) {
            this.adjustmentDetailLst = data.adjustmentDetailLst;
        }

        if (data.nonAdjustmentDetailObj) {
            this.nonAdjustmentDetailObj = data.nonAdjustmentDetailObj;
        }

        this.updateTabState();
    }

    // ══════════════════════════════════════════════════════════════════════════
    // MAIN FUNCTIONS - TAB MANAGEMENT
    // ══════════════════════════════════════════════════════════════════════════
    updateTabState() {
        this.isTab1 = this._currentTabNumber == 1;
        this.isTab2SubPayment = this._currentTabNumber == 2 && this.isSubPayment;
        this.isTab2NonSubPayment = this._currentTabNumber == 2 && !this.isSubPayment;
        this.updateButtonVisibility();
    }

    updateButtonVisibility() {
        const vis = getButtonVisibility(this._currentTabNumber, this.pageMode, this.adjustment || {});
        this._showCancel = vis.showCancel;
        this._showSaveAsDraft = vis.showSaveAsDraft;
        this._showAddAdjDetail = vis.showAddAdjDetail;
        this._finishLabel = vis.finishLabel || this._finishLabel;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // MAIN FUNCTIONS - NAVIGATION HANDLERS
    // ══════════════════════════════════════════════════════════════════════════
    handleNext(event) {
        this._pageMessages = [];
        this._messageType = '';

        if (this._currentTabNumber === 1) {
            this.doNext();
        }
    }

    doNext() {
        this.showSpinner = true;
        this._pageMessages = [];
        this._messageType = '';

        if (this.pageMode === 'view') {
            if (this.isEditableAddress) {
                if (!isEmpty(this.adjustment.IDN_CASE__c)) {
                    this.upsertRespAddressList();
                    return;
                } else {
                    this._currentTabNumber = 2;
                    this.updateTabState();
                    this.showSpinner = false;
                    return;
                }
            } else if (this.adjustment.CDE_STATUS_ADJMT__c === 'Calculation Complete' && !isEmpty(this.adjustment.IDN_PROVR__c)) {
                const tab1Component = this.template.querySelector('c-adjustment-flow_-adjustment-information_lwc');
                let isValid = true;
                if (tab1Component && typeof tab1Component.validateCurrentPage === 'function') {
                    isValid = tab1Component.validateCurrentPage();
                }
                if (isValid) {
                    this.upsertAddressOnly();
                    return;
                } else {
                    this._messageType = 'error';
                    this._pageMessages = formatMessages([label.ERRORS_ON_THIS_PAGE]);
                    this.showSpinner = false;
                    return;
                }
            } else {
                this._currentTabNumber = 2;
                this.updateTabState();
                this.showSpinner = false;
                return;
            }
        }

        try {
            const tab1Component = this.template.querySelector('c-adjustment-flow_-adjustment-information_lwc');
            let isValid = true;
            if (tab1Component && typeof tab1Component.validateCurrentPage === 'function') {
                isValid = tab1Component.validateCurrentPage();
            }
            if (!isValid) {
                this._messageType = 'error';
                this._pageMessages = formatMessages([label.ERRORS_ON_THIS_PAGE]);
                this.showSpinner = false;
                return;
            }

            if (this.isRecoveryWithCase) {
                this.upsertAdj_Resp_RespAddress();
            } else {
                this.upsertAdj_Addr_Resp();
            }
        } catch (err) {
            console.log('err' + err.message);
        }
    }

    handlePrevious(event) {
        this._pageMessages = [];
        this._messageType = '';

        if (this._currentTabNumber === 2) {
            this.doPrevious();
        }
    }

    doPrevious() {
        this.showSpinner = true;

        if (this.responsiblePartiesAddressList && this.responsiblePartiesAddressList.length > 0) {
            this.doGetAddressAndGoBack();
        } else {
            this.adjustment = updateReasonToLabel(this.adjustment, this.adjustmentReasonOptions);
            this._currentTabNumber = 1;
            this.updateTabState();
            this.showSpinner = false;
        }
    }

    doGetAddressAndGoBack() {
        const params = { adjustmentId: this.recordId };
        this.showSpinner = true;
        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'doGetAddress',
            (function (result) {
                if (result.objectData) {
                    if (result.objectData.responsiblePartiesAddressList) {
                        this.responsiblePartiesAddressList = result.objectData.responsiblePartiesAddressList;
                        this.responsiblePartiesAddressListClone = JSON.parse(JSON.stringify(result.objectData.responsiblePartiesAddressList));
                    }
                    if (result.objectData.address) {
                        this.address = result.objectData.address;
                    }
                }

                this.adjustment = updateReasonToLabel(this.adjustment, this.adjustmentReasonOptions);
                this._currentTabNumber = 1;
                this.updateTabState();
                this.showSpinner = false;
            }).bind(this),
            JSON.stringify(params),
            null
        );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // MAIN FUNCTIONS - UPSERT OPERATIONS (Tab 1 Navigation)
    // ══════════════════════════════════════════════════════════════════════════
    upsertAdj_Resp_RespAddress() {
        const adjustmentRecord = getAdjustmentRecord(this.adjustment || {});
        const params = {
            lstSObject: [adjustmentRecord]
        };
        this.showSpinner = true;
        abs_helper.callServerAndHandleError(
            this,
            'GenericDataSaverApxCtrl',
            'upsertRecords',
            (function (result) {
                console.log('inside upsertAdj_Resp_RespAddress');
                this.showSpinner = false;
                this.upsertResponsibleParties(true);
            }).bind(this),
            JSON.stringify(params),
            null
        );
    }

    upsertAdj_Addr_Resp() {
        const adjustmentRecord = getAdjustmentRecord(this.adjustment || {});
        const addressToSave = getAddressRecord(this.address || {});
        const params = {
            lstSObject: [adjustmentRecord, addressToSave]
        };
        this.showSpinner = true;
        abs_helper.callServerAndHandleError(
            this,
            'GenericDataSaverApxCtrl',
            'upsertRecords',
            (function (result) {
                console.log('inside upsertAdj_Addr_Resp');
                console.log('result' + JSON.stringify(result));
                if (result.objectData && result.objectData.upsertedRecords) {
                    this.address = { ...this.address, ...result.objectData.upsertedRecords[1] };
                }
                this.showSpinner = false;
                this.upsertResponsibleParties(false);
            }).bind(this),
            JSON.stringify(params),
            null
        );
    }

    upsertResponsibleParties(insertAddress) {
        const params = {
            adjustmentId: this.recordId,
            responsiblePartyList: this.responsiblePartyList
        };
        console.log('inside upsertResponsibleParties');
        this.showSpinner = true;
        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'upsertResponsibleParties',
            (function (result) {
                this.showSpinner = false;
                if (insertAddress) {
                    if (this.responsiblePartiesAddressList && this.responsiblePartiesAddressList.length > 0) {
                        this.upsertRespAddressList();
                    } else {
                        this._currentTabNumber = 2;
                        this.updateTabState();
                    }
                } else {
                    this._currentTabNumber = 2;
                    this.updateTabState();
                }
            }).bind(this),
            JSON.stringify(params),
            null
        );
    }

    upsertRespAddressList() {
        // Always read the address list from the child component immediately before saving.
        // The parent's own responsiblePartiesAddressList copy is seeded from the server
        // response which contains raw label values for ADR_STATE__c (e.g. 'Colorado').
        // The conversion to API values ('CO') happens inside the child's State combobox
        // asynchronously and is reflected in the child's _responsiblePartiesAddressList
        // via handleRespPartyAddressUpdate. On the first IPV add the combobox may still
        // be fetching options, leaving stale label values in the parent copy. Pulling
        // from the child here guarantees we always save the converted API values.
        const tab1Component = this.template.querySelector('c-adjustment-flow_-adjustment-information_lwc');
        const addrListToSave = (tab1Component && typeof tab1Component.getResponsiblePartiesAddressList === 'function')
            ? tab1Component.getResponsiblePartiesAddressList()
            : this.responsiblePartiesAddressList;
        const params = {
            adjustmentId: this.recordId,
            responsiblePartiesAddressList: addrListToSave
        };
        this.showSpinner = true;

        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'upsertResponsiblePartiesAddress',
            (function (result) {
                console.log('inside upsertRespAddressList');
                this._currentTabNumber = 2;
                this.updateTabState();
                this.showSpinner = false;
            }).bind(this),
            JSON.stringify(params),
            null
        );
    }

    upsertAddressOnly() {
        const addressToSave = getAddressRecord(this.address || {});
        const params = {
            lstSObject: [addressToSave]
        };
        this.showSpinner = true;
        console.log('inside upsertAddressOnly');

        abs_helper.callServerAndHandleError(
            this,
            'GenericDataSaverApxCtrl',
            'upsertRecords',
            (function (result) {
                if (result.objectData && result.objectData.upsertedRecords && result.objectData.upsertedRecords[0]) {
                    this.address = { ...this.address, ...result.objectData.upsertedRecords[0] };
                }
                this._currentTabNumber = 2;
                this.updateTabState();
                this.showSpinner = false;
            }).bind(this),
            JSON.stringify(params),
            null
        );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // MAIN FUNCTIONS - ACTION BUTTON HANDLERS
    // ══════════════════════════════════════════════════════════════════════════
    handleFinish(event) {
        if (this.pageMode === 'view') {
            this.navigateToRecord(this.recordId);
            return;
        }

        if (this.isRecoveryType) {
            const { isValid, errorMessage } = validateRecoveryAdjustment(this.adjustment || {});
            if (!isValid) {
                this._pageMessages = formatMessages([errorMessage]);
                this._messageType = 'error';
                return;
            }
        }

        this.verifyAdjustmentNote('finish');
    }

    handleCancel(event) {
        this.pageMode!= 'view'? this.showCancelModal = true : this.handleConfirmCancel();
        //this.showCancelModal = true;
    }

    handleSaveAsDraft(event) {
        this.showSaveAsDraftModal = true;
    }

    handleSaveAndNew(event) {
        console.log('inside handleSaveAndNew');
        try {
            if (this._currentTabNumber === 2) {
                this.verifyAdjustmentNote('saveAndNew');
            }
        } catch (err) {
            console.log('err' + err.message);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // MAIN FUNCTIONS - VERIFICATION METHODS
    // ══════════════════════════════════════════════════════════════════════════
    verifyAdjustmentNote(action) {
        if (action == 'saveAndNew') {
            this.showSaveAsDraftModal = true;
        } else if (action == 'finish') {
            this.showSpinner = true;
            const params = { adjId: this.recordId };

            abs_helper.callServerAndHandleError(
                this,
                'AdjustmentFlowApxCtrl',
                'doVerifyAdjustmentNote',
                (function (result) {
                    if (result.objectData) {
                        if (result.objectData.noteFound) {
                            if (this.pageMode != 'view') {
                                const detailsExist = validateAdjustmentDetailsExist(
                                    this.adjustment?.CDE_AGNST_ADJMT__c,
                                    this.adjustmentDtlWarp,
                                    this.nonAdjustmentDetailObj
                                );
                                if (detailsExist) {
                                    this.showFinishModal = true;
                                } else {
                                    this._messageType = 'error';
                                    this._pageMessages = formatMessages(['Please add adjustment details before finalizing the adjustment.']);
                                }
                            } else {
                                this.navigateToRecord(this.recordId);
                            }
                        } else {
                            this.showAdjNoteModal = true;
                        }
                    } else {
                        this._messageType = 'error';
                        this._pageMessages = formatMessages([
                            (result && result.errorMessage) ? result.errorMessage : 'Error found in Adjustment Note.'
                        ]);
                    }
                    this.showSpinner = false;
                }).bind(this),
                JSON.stringify(params),
                null
            );
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // MAIN FUNCTIONS - CONFIRMATION MODAL HANDLERS
    // ══════════════════════════════════════════════════════════════════════════

    handleConfirmCancel() {
        this.showCancelModal = false;
        this.doCancel();
    }

    handleCloseCancelModal() {
        this.showCancelModal = false;
    }

    handleConfirmFinish() {
        this.showFinishModal = false;
        this.doFinish();
    }

    handleCloseFinishModal() {
        this.showFinishModal = false;
    }

    handleConfirmSaveAsDraft() {
        this.showSaveAsDraftModal = false;
        this.doSaveAsDraft();
    }

    handleCloseSaveAsDraftModal() {
        this.showSaveAsDraftModal = false;
    }

    handleConfirmAdjNote() {
        this.showAdjNoteModal = false;
        this.openAdjustmentNoteModal();
    }

    handleCloseAdjNoteModal() {
        this.showAdjNoteModal = false;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // MAIN FUNCTIONS - SAVE OPERATIONS
    // ══════════════════════════════════════════════════════════════════════════
    doFinish() {
        this.showSpinner = true;
        // Mirror Aura confirmFinish: getRecordTypeId for 'Finalized' record type.
        // Aura passes adjustmentAmount to getRecordTypeId and reads result.objectData.recordtypeId.
        const params = {
            recordTypeName: 'Finalized',
            parentObjectName: 'T_ADJMT__c',
            recordId: this.recordId,
            adjustmentAmount: this.adjustment.AMT_ADJMT__c
        };
        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'getRecordTypeId',
            (function (result) {
                this.showSpinner = false;
                if (result && result.isSuccessful && result.objectData) {
                    // Aura reads response.objectData.recordtypeId (lowercase 't')
                    const recordTypeId = result.objectData.recordtypeId || result.objectData;
                    // Aura reads outstandingRecoveryBalance from server response (CCCAP-6051).
                    // Server computes: AMT_ADJMT__c - getAdjustmentPaidAmount(recordId).
                    // Fall back to current adjustment value if server did not return one.
                    const outstandingRecoveryBalance = result.objectData.outstandingRecoveryBalance != null
                        ? result.objectData.outstandingRecoveryBalance
                        : this.adjustment.Outstanding_Recovery_Balance__c;
                    this.finalizeWithRecordType(recordTypeId, outstandingRecoveryBalance);
                } else {
                    this._messageType = 'error';
                    this._pageMessages = formatMessages([
                        (result && result.errorMessage) ? result.errorMessage : 'Error Finishing operation.'
                    ]);
                }
            }).bind(this),
            JSON.stringify(params),
            null
        );
    }

    finalizeWithRecordType(recordTypeId, outstandingRecoveryBalance) {
        // Mirror Aura confirmFinish step-by-step:
        // 1. upsertRecords([adjustmentObj]) — sets CDE_STATUS_ADJMT__c='2' on adjustment
        // 2a. Sub-Payment + has details: upsertRecords(adjObjUpdateList) — sets detail status='2'
        //     then subPaymentCallOut({adjustmentDtlList: adjObjUpdateList})
        // 2b. Sub-Payment + no details: subPaymentCallOut({adjustmentDtlList: []}) directly
        // 3.  Non Sub-Payment: upsertRecords(nonAdjObjUpdateList) then navigate
        const adjustmentToSave = buildFinalizedAdjustment(
            this.adjustment, recordTypeId, this.isRecoveryType, this.pageMode, outstandingRecoveryBalance
        );

        this.showSpinner = true;
        abs_helper.callServerAndHandleError(
            this,
            'GenericDataSaverApxCtrl',
            'upsertRecords',
            (function (result) {
                if (result && result.isSuccessful) {
                    if (this.isSubPayment) {
                        // Build adjustment detail update list — mirrors Aura's adjObjUpdateList
                        const adjustmentDtlWarp = this.adjustmentDtlWarp || [];
                        const adjObjUpdateList = [];

                        adjustmentDtlWarp.forEach(eachWrap => {
                            if (eachWrap && eachWrap.ajustmentDetails && eachWrap.ajustmentDetails.Id) {
                                adjObjUpdateList.push({
                                    sobjectType: 'T_ADJMT_DETAIL__c',
                                    attributes: { type: 'T_ADJMT_DETAIL__c' },
                                    Id: eachWrap.ajustmentDetails.Id,
                                    CDE_STATUS_DETAIL_ADJMT__c: '2',
                                    IDN_DETAIL_PMT_SUB__c: eachWrap.subPaymentDetails
                                        ? eachWrap.subPaymentDetails.ExternalId
                                        : null
                                });
                            }
                        });

                        if (adjObjUpdateList.length > 0) {
                            // Step 2a: upsert detail records first, then call out
                            abs_helper.callServerAndHandleError(
                                this,
                                'GenericDataSaverApxCtrl',
                                'upsertRecords',
                                (function (detailResult) {
                                    if (detailResult && detailResult.isSuccessful) {
                                        this.callSubPaymentCallOut(adjObjUpdateList);
                                    } else {
                                        this.showSpinner = false;
                                        this._messageType = 'error';
                                        this._pageMessages = formatMessages([
                                            (detailResult && detailResult.errorMessage) ? detailResult.errorMessage : 'Error finalizing adjustment details.'
                                        ]);
                                    }
                                }).bind(this),
                                JSON.stringify({ lstSObject: adjObjUpdateList }),
                                null
                            );
                        } else {
                            // Step 2b: no detail rows yet — call out directly
                            this.callSubPaymentCallOut([]);
                        }
                    } else {
                        // Non Sub-Payment: update detail status records then navigate
                        const nonAdjustmentDetailObj = this.nonAdjustmentDetailObj || [];
                        const nonAdjObjUpdateList = nonAdjustmentDetailObj
                            .filter(rec => rec && rec.Id)
                            .map(rec => ({
                                sobjectType: 'T_NON_ADJMT_DETAIL__c',
                                attributes: { type: 'T_NON_ADJMT_DETAIL__c' },
                                Id: rec.Id,
                                CDE_STATUS_DETAIL_ADJMT__c: '2'
                            }));

                        if (nonAdjObjUpdateList.length > 0) {
                            abs_helper.callServerAndHandleError(
                                this,
                                'GenericDataSaverApxCtrl',
                                'upsertRecords',
                                (function (nonAdjResult) {
                                    this.showSpinner = false;
                                    if (nonAdjResult && nonAdjResult.isSuccessful) {
                                        this.navigateToRecord(this.recordId);
                                    } else {
                                        this._messageType = 'error';
                                        this._pageMessages = formatMessages([
                                            (nonAdjResult && nonAdjResult.errorMessage) ? nonAdjResult.errorMessage : 'Error finalizing adjustment details.'
                                        ]);
                                    }
                                }).bind(this),
                                JSON.stringify({ lstSObject: nonAdjObjUpdateList }),
                                null
                            );
                        } else {
                            this.showSpinner = false;
                            this.navigateToRecord(this.recordId);
                        }
                    }
                } else {
                    this.showSpinner = false;
                    this._messageType = 'error';
                    this._pageMessages = formatMessages([
                        (result && result.errorMessage) ? result.errorMessage : 'Error finalizing adjustment.'
                    ]);
                }
            }).bind(this),
            JSON.stringify({ lstSObject: [adjustmentToSave] }),
            null
        );
    }

    callSubPaymentCallOut(adjObjUpdateList) {
        // Mirror Aura: pass adjustmentDtlList (the detail update list) to subPaymentCallOut.
        // Aura does NOT pass adjustmentId — it passes the list of detail records.
        this.showSpinner = true;
        abs_helper.callServerAndHandleError(
            this,
            'AdjustmentFlowApxCtrl',
            'subPaymentCallOut',
            (function (result) {
                this.showSpinner = false;
                if (result && result.isSuccessful) {
                    this.navigateToRecord(this.recordId);
                } else {
                    this._messageType = 'error';
                    this._pageMessages = formatMessages([
                        (result && result.errorMessage) ? result.errorMessage : 'Error Finishing operation.'
                    ]);
                }
            }).bind(this),
            JSON.stringify({ adjustmentDtlList: adjObjUpdateList || [] }),
            null
        );
    }

    doSaveAsDraft() {
        const params = {
            'recordTypeName': 'In Process',
            'parentObjectName': 'T_ADJMT__c',
            'recordId': '',
            'adjustmentAmount': this.adjustment.AMT_ADJMT__c
        };
        this.showSpinner = true;
        helper.callServer(
            this,
            'AdjustmentFlowApxCtrl',
            'getRecordTypeId',
            (function (result) {
                this.showSpinner = false;
                if (result && result.isSuccessful && result.objectData) {
                    const recordTypeId = result.objectData.recordtypeId;
                    this.saveAsDraftWithRecordType(recordTypeId);
                } else {
                    this._messageType = 'error';
                    this._pageMessages = formatMessages([
                        (result && result.errorMessage) ? result.errorMessage : 'Error fetching record type.'
                    ]);
                }
            }).bind(this),
            JSON.stringify(params)
        );
    }

    saveAsDraftWithRecordType(recordTypeId) {
        const adjustmentToSave = buildDraftAdjustment(this.adjustment.Id, recordTypeId);
        const params = {
            lstSObject: [adjustmentToSave]
        };
        this.showSpinner = true;
        helper.callServer(
            this,
            'GenericDataSaverApxCtrl',
            'upsertRecords',
            (function (result) {
                this.showSpinner = false;
                if (result && result.isSuccessful) {
                    this.navigateToRecord(this.recordId);
                } else {
                    this._messageType = 'error';
                    this._pageMessages = formatMessages([
                        (result && result.errorMessage) ? result.errorMessage : 'Error saving adjustment as draft.'
                    ]);
                }
            }).bind(this),
            JSON.stringify(params)
        );
    }

    doCancel() {
        this.showSpinner = true;
        if (isNewRecordType(this.adjustment)) {
            const recordsToDelete = buildRecordsToDelete(
                this.address, this.adjustmentDtlWarp, this.nonAdjustmentDetailObj
            );
            if (recordsToDelete.length > 0) {
                this.deleteRecordsAndNavigate(recordsToDelete);
            } else {
                this.navigateToRecord(this.recordId);
            }
        } else {
            this.navigateToRecord(this.recordId);
        }
    }

    deleteRecordsAndNavigate(records) {
        const params = {
            objectData: records
        };
        this.showSpinner = true;
        helper.callServer(
            this,
            'AdjustmentFlowApxCtrl',
            'doDeleteRecords',
            (function (result) {
                this.showSpinner = false;
                if (result.isSuccessful) {
                    this.navigateToRecord(this.recordId);
                } else {
                    this._messageType = 'error';
                    this._pageMessages = formatMessages([
                        (result && result.errorMessage) ? result.errorMessage : 'Error deleting records.'
                    ]);
                }
            }).bind(this),
            JSON.stringify(params)
        );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // MAIN FUNCTIONS - MODAL OPERATIONS
    // ══════════════════════════════════════════════════════════════════════════
    async openAdjDetailModal(editMode = false, existAdjWrap = null) {
        const modalParams = {
            size: 'large',
            adjustment: this.adjustment,
            adjustmentDetailList: this.adjustmentDetailLst,
            rateTypeOptions: this.rateTypeOptions,
            rateTypeOptionsMap: this.rateTypeOptionsMap,
            rateTypeOptionsCareDateMap: this.rateTypeOptionsCareDateMap,
            careUnitTypeOptionsMap: this.careUnitTypeOptionsMap,
            careLevelOptionsMap: this.careLevelOptionsMap,
            careUnitTypeOptions: this.careUnitTypeOptions,
            careLevelOptions: this.careLevelOptions,
            adjustDetailMap: this.adjustDetailMap,
            childCurrentUtilization: this.childCurrentUtilization,
            disabledARTFees: this.disabledARTFees,
            slotCntcheckbox: this.slotCntcheckbox,
            authId: this.authId,
            caseId: this.adjustment.IDN_CASE__c,
            editMode: editMode
        };

        if (editMode && existAdjWrap) {
            modalParams.existAdjWrap = existAdjWrap;
        }

        const result = await AddAdjDetailFlowModal.open(modalParams);
        const updates = processAdjDetailModalResult(result);

        if (updates) {
            // Always update adjustmentDtlWarp (may be null/empty on first save — that is valid)
            if (updates.adjustmentDtlWarp !== undefined) {
                this.adjustmentDtlWarp = updates.adjustmentDtlWarp || [];
            }
            if (updates.adjustDetailMap) {
                this.adjustDetailMap = updates.adjustDetailMap;
            }
            // Mirrors Aura's change handler on adjustmentDtlWarp → calculateTotalAmount:
            // sum ALL rows from the refreshed full list (not just the current session's amount)
            // so that AMT_ADJMT__c accumulates correctly across multiple modal sessions.
            const fullWrap = this.adjustmentDtlWarp;
            if (fullWrap && fullWrap.length > 0) {
                let totalAmount = 0;
                for (const wrap of fullWrap) {
                    if (wrap.ajustmentDetails && wrap.ajustmentDetails.AMT_DETAIL_ADJMT__c) {
                        totalAmount += parseFloat(wrap.ajustmentDetails.AMT_DETAIL_ADJMT__c);
                    }
                }
                this.adjustment = { ...this.adjustment, AMT_ADJMT__c: totalAmount };
            } else if (updates.adjustmentAmount !== undefined) {
                this.adjustment = { ...this.adjustment, AMT_ADJMT__c: updates.adjustmentAmount };
            }
            // Push refreshed wrap and updated adjustment directly to the summary component.
            // In Aura this happens via the adjustmentDetailSummaryEvent application event which
            // the summary component receives independently. In LWC there is no application-event
            // bus — we must push the new @api values down explicitly so the summary table rows
            // and the Adjustment Amount total both reflect ART fees immediately after save.
            // refreshData() is still called to reload adjustDetailMap and utilization from server.
            const summaryComponent = this.template.querySelector('c-adjustment-flow_-adjustment-summary_lwc');
            if (summaryComponent) {
                summaryComponent.adjustmentDtlWarp = this.adjustmentDtlWarp;
                summaryComponent.adjustmentObj = this.adjustment;
                if (updates.adjustDetailMap) {
                    summaryComponent.adjustDetailMap = this.adjustDetailMap;
                }
                if (typeof summaryComponent.refreshData === 'function') {
                    summaryComponent.refreshData();
                }
            }
            if (updates.shouldSaveAndNew) {
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => { this.openAdjDetailModal(false); }, 100);
            }
        }
    }

    openAdjustmentNoteModal() {
        AdjustmentNoteModal.open({
            size: 'large',
            recordId: this.recordId,
            objectApiName: 'T_ADJMT__c'
        }).then((result) => {
            const processed = processAdjNoteModalResult(result);
            if (processed.action === 'saved') {
                this._messageType = 'success';
                this._pageMessages = formatMessages(['Adjustment Note created successfully.']);
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => {
                    this._pageMessages = [];
                    this._messageType = '';
                }, 3000);
            }
        });
    }

    // ══════════════════════════════════════════════════════════════════════════
    // CHILD COMPONENT EVENT HANDLERS - TAB 1 (ADJUSTMENT INFORMATION)
    // ══════════════════════════════════════════════════════════════════════════

    handleAdjustmentChange(event) {
        if (event && event.detail) {
            if (event.detail.adjustment) {
                const incomingAdjustment = event.detail.adjustment;
                const oldReason = this.adjustment?.CDE_REASON__c;
                const newReason = incomingAdjustment.CDE_REASON__c;
                this.adjustment = { ...this.adjustment, ...incomingAdjustment };
                if (oldReason !== newReason && this.pageMode !== 'view') {
                    this.adjustmentReasonOptions = buildAdjustmentReasonOptions(this.adjustment);
                }
        }
        }
    }

    handleAddressChange(event) {
        if (event && event.detail) {
            if (event.detail.address) {
                this.address = { ...this.address, ...event.detail.address };
            }
        }
    }

    handleResponsiblePartyListChange(event) {
        console.log('inside handleResponsiblePartyListChange' + JSON.stringify(event.detail));
        if (event && event.detail) {
            if (event.detail.responsiblePartyList) {
                this.responsiblePartyList = JSON.parse(JSON.stringify(event.detail.responsiblePartyList));
            }
            if (event.detail.responsiblePartiesAddressList) {
                this.responsiblePartiesAddressList = JSON.parse(JSON.stringify(event.detail.responsiblePartiesAddressList));
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // CHILD COMPONENT EVENT HANDLERS - TAB 2 (ADJUSTMENT SUMMARY)
    // ══════════════════════════════════════════════════════════════════════════

    handleAdjustmentObjChange(event) {
        if (event && event.detail) {
            const incomingObj = event.detail.adjustmentObj || event.detail.adjustment;
            if (incomingObj) {
                if (!hasAmountChanged(this.adjustment?.AMT_ADJMT__c, incomingObj.AMT_ADJMT__c)) {
                    return;
                }
                this.adjustment = { ...this.adjustment, ...incomingObj };
            }
        }
    }

    handleAdjustmentDetailSummary(event) {
        if (event && event.detail) {
            const current = {
                adjustmentDtlWarp: this.adjustmentDtlWarp,
                adjustDetailMap: this.adjustDetailMap,
                adjustment: this.adjustment
            };
            const changes = checkSummaryDataChanges(current, event.detail);
            if (!changes.anyChanged) {
                return;
            }
            // wrapAmountChanged covers the ART-fee-only case: same row count but
            // per-row AMT_DETAIL_ADJMT__c values changed. Without this branch the parent's
            // adjustmentDtlWarp never gets the updated amounts and the summary stays stale.
            if (event.detail.adjustmentDtlWarp && (changes.lengthChanged || changes.wrapAmountChanged)) {
                this.adjustmentDtlWarp = [...event.detail.adjustmentDtlWarp];
            }
            if (event.detail.adjustDetailMap && changes.mapChanged) {
                this.adjustDetailMap = { ...event.detail.adjustDetailMap };
            }
            if (changes.amountChanged) {
                this.adjustment = {
                    ...this.adjustment,
                    AMT_ADJMT__c: event.detail.adjustmentAmount
                };
            }
        }
    }

    handleAdjustDetailMapChange(event) {
        if (event && event.detail) {
            this.adjustDetailMap = { ...event.detail };
        }
    }

    handleCreateAdjustDetails(event) {
        if (event && event.detail) {
            const existAdjWrap = event.detail.existAdjWrap || event.detail;
            if (existAdjWrap && existAdjWrap.ajustmentDetails && existAdjWrap.ajustmentDetails.Id) {
                this.openAdjDetailModal(true, existAdjWrap);
            } else {
                this.openAdjDetailModal(false);
            }
        } else {
            this.openAdjDetailModal(false);
        }
    }

    navigateToRecord(recordId) {
        if (!recordId) {
            window.history.back();
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    handleError(error) {
        console.error('Error:', error);
        const errorMessage = extractErrorMessage(error);
        this._messageType = 'error';
        this._pageMessages = formatMessages([errorMessage]);
    }
}