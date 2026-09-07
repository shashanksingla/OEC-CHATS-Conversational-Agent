import { LightningElement, api, track } from 'lwc';
import { helper } from 'c/generic_Utilities';

const PAGE_SIZE = 50;

export default class AdjustmentFlow_SelectSubPayment_lwc extends LightningElement {

    // ─── @api properties ───────────────────────────────────────────────────────
    @track _paymentObjId = '';
    @api
    get paymentObjId() {
        return this._paymentObjId;
    }
    set paymentObjId(value) {
        this._paymentObjId = value != null ? value : '';
    }

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

    @track _authId = '';
    @api
    get authId() {
        return this._authId;
    }
    set authId(value) {
        this._authId = value != null ? value : '';
    }

    @track _slotCntId = '';
    @api
    get slotCntId() {
        return this._slotCntId;
    }
    set slotCntId(value) {
        this._slotCntId = value != null ? value : '';
    }

    @api slotCntcheckbox;
    @api errorMessageText;

    @track _caseId = '';
    @api
    get caseId() {
        return this._caseId;
    }
    set caseId(value) {
        this._caseId = value != null ? value : '';
    }

    @track _subPaymentObj_NAM_FIRST = '';
    @api
    get subPaymentObj_NAM_FIRST() {
        return this._subPaymentObj_NAM_FIRST;
    }
    set subPaymentObj_NAM_FIRST(value) {
        this._subPaymentObj_NAM_FIRST = value != null ? value : '';
    }

    @track _servicePeriodObj_DTE_BEGIN_EFFV = '';
    @api
    get servicePeriodObj_DTE_BEGIN_EFFV() {
        return this._servicePeriodObj_DTE_BEGIN_EFFV;
    }
    set servicePeriodObj_DTE_BEGIN_EFFV(value) {
        this._servicePeriodObj_DTE_BEGIN_EFFV = value != null ? value : '';
    }

    @track _subPaymentObj_Id = '';
    @api
    get subPaymentObj_Id() {
        return this._subPaymentObj_Id;
    }
    set subPaymentObj_Id(value) {
        this._subPaymentObj_Id = value != null ? value : '';
    }

    @track _subPaymentObj_NAM_LAST = '';
    @api
    get subPaymentObj_NAM_LAST() {
        return this._subPaymentObj_NAM_LAST;
    }
    set subPaymentObj_NAM_LAST(value) {
        this._subPaymentObj_NAM_LAST = value != null ? value : '';
    }

    @track _servicePeriodObj_DTE_END_EFFV = '';
    @api
    get servicePeriodObj_DTE_END_EFFV() {
        return this._servicePeriodObj_DTE_END_EFFV;
    }
    set servicePeriodObj_DTE_END_EFFV(value) {
        this._servicePeriodObj_DTE_END_EFFV = value != null ? value : '';
    }

    @track _subPaymentSearchLst = [];
    @api
    get subPaymentSearchLst() {
        return this._subPaymentSearchLst;
    }
    set subPaymentSearchLst(value) {
        let existingVal = JSON.stringify(this._subPaymentSearchLst);
        if (existingVal !== JSON.stringify(value)) {
            this._subPaymentSearchLst = JSON.parse(JSON.stringify(value));
            this.pagination();
        }
    }

    @track _selectedSubPayment = null;
    @api
    get selectedSubPayment() {
        return this._selectedSubPayment;
    }
    set selectedSubPayment(value) {
        if (value !== null && value !== undefined) {
            this._selectedSubPayment = JSON.parse(JSON.stringify(value));
        } else {
            this._selectedSubPayment = null;
        }
    }

    // ─── @track properties ─────────────────────────────────────────────────────
    @track searchByAuthId = false;
    @track searchBySlotCntId = false;
    @track searchByChilName = false;
    @track hasOnePage = true;
    @track currentPageNumber = 0;
    @track numberOfPages;
    @track subPaymentSearchLstPage = [];
    @track pageNavigated = false;

    @track showSpinner = false;
    @track error;

    // ADA Enhancements
    @track selectedRowId = null;
    @track resultsAnnouncementText = '';

    // ─── Getters ────────────────────────────────────────────────────────────────

    /**
     * Returns the maximum number of sub-payment search results to display.
     */
    get searchLimit() {
        return 500;
    }

    /**
     * Returns true when the results list exceeds the search limit.
     */
    get isOverLimit() {
        return this.subPaymentSearchLst && this.subPaymentSearchLst.length > this.searchLimit;
    }

    /**
     * Returns true when there are results to display.
     */
    get hasResults() {
        return this.subPaymentSearchLst && this.subPaymentSearchLst.length > 0;
    }

    /**
     * Returns true when the Slot Contract search option should be visible.
     * Mirrors the Aura condition: adjustment.IDN_PROVR__c != null && != ''
     */
    get showSlotContractOption() {
        return this.adjustment &&
            this.adjustment.IDN_PROVR__c != null &&
            this.adjustment.IDN_PROVR__c !== '';
    }

    /**
     * Returns the human-readable current page label (1-based).
     */
    get currentPageLabel() {
        return this.currentPageNumber + 1;
    }

    /**
     * Returns true when the Previous button should be disabled.
     */
    get isPreviousDisabled() {
        return this.currentPageNumber === 0;
    }

    /**
     * Returns true when the Next button should be disabled.
     */
    get isNextDisabled() {
        return (this.currentPageNumber + 1) === this.numberOfPages;
    }

    /**
     * Returns the total number of search results across all pages.
     * Used for aria-rowcount in the table.
     */
    get totalSearchResults() {
        return this.subPaymentSearchLst ? this.subPaymentSearchLst.length : 0;
    }

    /**
     * Returns the number of columns based on the view (slot vs case).
     * Used for aria-colcount in the table.
     */
    get tableColumnCount() {
        return this.slotCntcheckbox ? 8 : 12;
    }

    /**
     * Case ID field is enabled only when "Search By Case ID" mode is active.
     * Mirrors Aura: disabled="{!!v.searchByChilName}"
     */
    get isCaseIdDisabled() {
        return !this.searchByChilName;
    }

    /**
     * Authorization ID field is enabled only when "Search By Authorization ID" mode is active.
     * Mirrors Aura: disabled="{!!v.searchByAuthId}"
     */
    get isAuthIdDisabled() {
        return !this.searchByAuthId;
    }

    /**
     * Vacant Slot Contract ID field is enabled only when "Search By Vacant Slot Contract ID" mode is active.
     * Mirrors Aura: disabled="{!!v.searchBySlotCntId}"
     */
    get isSlotCntIdDisabled() {
        return !this.searchBySlotCntId;
    }

    // ─── Lifecycle ──────────────────────────────────────────────────────────────

    connectedCallback() {
        // Run initial pagination if a list was passed in via @api
        if (this.subPaymentSearchLst && this.subPaymentSearchLst.length > 0) {
            this.pagination();
        }
    }

    // ─── Search Mode Controllers ─────────────────────────────────────────────────

    /**
     * Switches search mode to "By Authorization ID".
     * Clears incompatible fields and resets the results list.
     */
    searchByAuthIdCtrl() {
        this._subPaymentSearchLst = [];
        this._selectedSubPayment = null;
        this.searchByAuthId = true;
        this.searchByChilName = false;
        this.searchBySlotCntId = false;
        this._caseId = '';
        this._slotCntId = '';
        this.subPaymentSearchLstPage = [];
        this.hasOnePage = true;
    }

    /**
     * Switches search mode to "By Case ID" (child name search).
     * Clears incompatible fields and resets the results list.
     */
    searchByChildNameCtrl() {
        this._subPaymentSearchLst = [];
        this._selectedSubPayment = null;
        this.searchByAuthId = false;
        this.searchByChilName = true;
        this.searchBySlotCntId = false;
        this._authId = '';
        this._slotCntId = '';
        this.subPaymentSearchLstPage = [];
        this.hasOnePage = true;
    }

    /**
     * Switches search mode to "By Vacant Slot Contract ID".
     * Clears incompatible fields and resets the results list.
     */
    searchBySlotCntrtIdCtrl() {
        this._subPaymentSearchLst = [];
        this._selectedSubPayment = null;
        this.searchByAuthId = false;
        this.searchByChilName = false;
        this.searchBySlotCntId = true;
        this._caseId = '';
        this._authId = '';
        this.subPaymentSearchLstPage = [];
        this.hasOnePage = true;
    }

    // ─── Input Change Handlers ───────────────────────────────────────────────────

    handlePaymentObjIdChange(event) {
        this._paymentObjId = event.detail.value;
    }

    handleSubPaymentObjIdChange(event) {
        this._subPaymentObj_Id = event.detail.value;
    }

    handleFirstNameChange(event) {
        this._subPaymentObj_NAM_FIRST = event.detail.value;
    }

    handleLastNameChange(event) {
        this._subPaymentObj_NAM_LAST = event.detail.value;
    }

    handleBeginDateChange(event) {
        this._servicePeriodObj_DTE_BEGIN_EFFV = event.detail.value;
    }

    handleEndDateChange(event) {
        this._servicePeriodObj_DTE_END_EFFV = event.detail.value;
    }

    handleCaseIdLookupChange(event) {
        this._caseId = event.detail.record ? event.detail.record.Id : '';
    }

    handleAuthIdLookupChange(event) {
        this._authId = event.detail.record ? event.detail.record.Id : '';
    }

    handleSlotCntIdLookupChange(event) {
        this._slotCntId = event.detail.record ? event.detail.record.Id : '';
    }

    // ─── Search ──────────────────────────────────────────────────────────────────

    /**
     * Fires the 'search' event to the parent component with current search criteria.
     * The parent is responsible for calling the server and updating subPaymentSearchLst.
     */
    handleSearch() {
        this.pageNavigated = false;
        this.currentPageNumber = 0;
        this.dispatchEvent(new CustomEvent('dosearch', {
            detail: {
                paymentObjId: this.paymentObjId,
                authId: this.authId,
                caseId: this.caseId,
                slotCntId: this.slotCntId,
                subPaymentObjNAMFIRST: this.subPaymentObj_NAM_FIRST,
                subPaymentObjNAMLAST: this.subPaymentObj_NAM_LAST,
                subPaymentObjId: this.subPaymentObj_Id,
                servicePeriodObjDTEBEGINEFFV: this.servicePeriodObj_DTE_BEGIN_EFFV,
                servicePeriodObjDTEENDEFFV: this.servicePeriodObj_DTE_END_EFFV,
                searchByAuthId: this.searchByAuthId,
                searchByChilName: this.searchByChilName,
                searchBySlotCntId: this.searchBySlotCntId
            },
            bubbles: true,
            composed: true
        }));
    }

    // ─── Row Selection ───────────────────────────────────────────────────────────

    /**
     * Handles the 'subpaymentselect' event bubbled up from c-sub-payment-rows_lwc.
     * Fires 'selectionchange' to the parent with the chosen sub-payment record.
     */
    handleSubPaymentSelect(event) {
        event.stopPropagation();
        const selected = event.detail.subPaymentObj;
        this._selectedSubPayment = selected !== null && selected !== undefined
            ? JSON.parse(JSON.stringify(selected))
            : null;
        this.dispatchEvent(new CustomEvent('subpaymentselect', {
            detail: { selectedSubPayment: selected },
            bubbles: true,
            composed: true
        }));
    }

    // ─── Pagination ──────────────────────────────────────────────────────────────

    /**
     * Advances to the next page of results.
     */
    handleNext() {
        const nextPage = this.currentPageNumber + 1;
        const list = this.subPaymentSearchLst || [];
        const size = list.length;
        const start = nextPage * PAGE_SIZE;
        const end = Math.min((nextPage + 1) * PAGE_SIZE, size);
        this.subPaymentSearchLstPage = list.slice(start, end);
        this.pageNavigated = true;
        this.currentPageNumber = nextPage;
        this._announcePageChange();
    }

    /**
     * Returns to the previous page of results.
     */
    handlePrevious() {
        const prevPage = this.currentPageNumber - 1;
        const list = this.subPaymentSearchLst || [];
        const start = prevPage * PAGE_SIZE;
        const end = Math.min((prevPage + 1) * PAGE_SIZE, list.length);
        this.subPaymentSearchLstPage = list.slice(start, end);
        this.pageNavigated = true;
        this.currentPageNumber = prevPage;
        this._announcePageChange();
    }

    /**
     * Recalculates pagination whenever subPaymentSearchLst changes.
     * Called internally after search results are received.
     */
    pagination() {
        const list = this.subPaymentSearchLst;
        if (list && list.length > 0) {
            const size = list.length;
            if (size > PAGE_SIZE) {
                this.hasOnePage = false;
                this.subPaymentSearchLstPage = list.slice(0, PAGE_SIZE);
                const pages = Math.floor(size / PAGE_SIZE);
                this.numberOfPages = (size % PAGE_SIZE === 0) ? pages : pages + 1;
            } else {
                this.hasOnePage = true;
                this.numberOfPages = 1;
                this.subPaymentSearchLstPage = list.slice();
            }
            if (!this.pageNavigated) {
                this.currentPageNumber = 0;
            }
            // Announce results to screen readers
            this._announceSearchResults(size);
        } else {
            this.currentPageNumber = 0;
            this.hasOnePage = true;
            this.subPaymentSearchLstPage = [];
            this.numberOfPages = 0;
            this.resultsAnnouncementText = 'No results found.';
        }
        this.pageNavigated = false;
    }

    /**
     * Announces search results to screen readers.
     * Called after pagination is complete.
     */
    _announceSearchResults(totalCount) {
        if (totalCount === 1) {
            this.resultsAnnouncementText = '1 payment found. Showing 1 result.';
        } else if (totalCount <= PAGE_SIZE) {
            this.resultsAnnouncementText = `${totalCount} payments found. Showing all ${totalCount} results.`;
        } else {
            const pageCount = Math.ceil(totalCount / PAGE_SIZE);
            this.resultsAnnouncementText = `${totalCount} payments found. Showing page 1 of ${pageCount}. Each page contains up to ${PAGE_SIZE} results.`;
        }
    }

    /**
     * Announces page change to screen readers.
     * Called when user navigates between pages.
     */
    _announcePageChange() {
        const totalCount = this.totalSearchResults;
        const pageNumber = this.currentPageLabel;
        const totalPages = this.numberOfPages;
        this.resultsAnnouncementText = `Navigated to page ${pageNumber} of ${totalPages}. Showing results for payment.`;
    }
}