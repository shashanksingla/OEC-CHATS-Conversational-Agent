import { LightningElement, track } from 'lwc';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DEFAULT_STATUSES = 'New;In progress;Transferred To';

const COLUMNS = [
    {
        label: 'Complaint ID', fieldName: 'complaintUrl', type: 'url',
        typeAttributes: { label: { fieldName: 'name' }, target: '_blank' },
        sortable: true
    },
    { label: 'Case ID',      fieldName: 'caseName',               type: 'text',      sortable: true, wrapText: true },
    { label: 'Provider ID',  fieldName: 'providerName',            type: 'text',      sortable: true, wrapText: true },
    { label: 'Complaint Type', fieldName: 'complaintTypes',        type: 'text',      sortable: true, wrapText: true },
    { label: 'Initial Date of Complaint', fieldName: 'initialDateOfComplaint', type: 'date-local', sortable: true },
    { label: 'Initial County Response Date', fieldName: 'countyResponseDate',  type: 'date-local', sortable: true },
    { label: 'Date Complaint Resolved', fieldName: 'dateComplaintResolved',    type: 'date-local', sortable: true },
    { label: 'Method of Contact', fieldName: 'methodOfContact',   type: 'text',      sortable: true, wrapText: true },
    { label: 'Complaint Status',  fieldName: 'complaintStatus',   type: 'text',      sortable: true, wrapText: true }
];

export default class ClientComplaintSearch extends LightningElement {

    // ── Filter state ──────────────────────────────────────────────────────────
    countyValue        = '';
    countyOptions      = [];
    statusValue        = DEFAULT_STATUSES;
    complaintTypeValue = '';
    methodOfContactValue = '';
    recipientTypeValue = '';
    providerId         = null;
    caseId             = null;
    assigneeId         = null;
    createdById        = null;
    initialDateBegin   = '';
    initialDateEnd     = '';
    countyResponseBegin = '';
    countyResponseEnd  = '';

    // ── Results state ─────────────────────────────────────────────────────────
    @track complaints        = [];
    @track recordsToDisplay  = [];
    sortedBy                 = 'initialDateOfComplaint';
    sortedDirection          = 'desc';
    pageSize                 = 20;
    currentPage              = 1;
    totalPages               = 0;

    // ── UI / error state ──────────────────────────────────────────────────────
    countyError                    = '';
    initialDateBeginError          = '';
    initialDateEndError            = '';
    countyResponseBeginError       = '';
    countyResponseEndError         = '';
    hasSearched             = false;
    showResults             = false;
    showSpinner             = false;
    showNewComplaint        = false;

    // ── Static data ───────────────────────────────────────────────────────────
    get columns() { return COLUMNS; }

    get _sortedAll() {
        if (!this.complaints || this.complaints.length === 0) return [];
        const data    = [...this.complaints];
        const reverse = this.sortedDirection === 'asc';
        const field   = this.sortedBy;
        return data.sort((a, b) => {
            let valA = a[field] == null ? '' : a[field];
            let valB = b[field] == null ? '' : b[field];
            if (valA < valB) return reverse ? -1 : 1;
            if (valA > valB) return reverse ? 1 : -1;
            return 0;
        });
    }

    get hasPreviousPage()         { return this.currentPage > 1; }
    get hasNextPage()             { return this.currentPage < this.totalPages; }
    get isPreviousPageDisabled()  { return this.currentPage <= 1; }
    get isNextPageDisabled()      { return this.currentPage >= this.totalPages; }
    get showPagination()          { return this.totalPages > 1; }

    get paginationLabel() {
        const total = this.complaints.length;
        if (total === 0) return '';
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end   = Math.min(this.currentPage * this.pageSize, total);
        return `${start} - ${end} of ${total}`;
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    connectedCallback() {
        this._loadUserCountiesAndSearch();
    }

    _loadUserCountiesAndSearch() {
        helper.callServer(
            this,
            'ClientComplaintApxCtrl',
            'getUserCounties',
            (response) => {
                if (response.isSuccessful) {
                    const data          = response.objectData;
                    const userCounties  = data.countyCodes || [];
                    const allOptions    = data.countyOptions || [];

                    // Build options array for the combobox (already includes 'All State' prepended)
                    this.countyOptions = allOptions;

                    // Pre-select user's assigned counties
                    if (userCounties.length > 0) {
                        this.countyValue = userCounties.join(';');
                    }

                    // Auto-run search with defaults
                    this._executeSearch();
                }
            },
            null
        );
    }

    // ── Search execution ──────────────────────────────────────────────────────
    handleSearch() {
        this.hasSearched = true;
        this._executeSearch();
    }

    _executeSearch() {
        if (this.hasSearched && !abs_helper.validateCurrentPage(this)) {
            return;
        }
        // Validate date ranges before searching
        if (this._hasDateErrors()) return;

        // Build filter arrays
        const countyIds        = this.countyValue.split(';').filter(v => v.trim() !== '');
        const statuses         = this.statusValue  ? this.statusValue.split(';').filter(v => v.trim() !== '')  : [];
        const complaintTypes   = this.complaintTypeValue   ? this.complaintTypeValue.split(';').filter(v => v.trim() !== '')   : [];
        const methodsOfContact = this.methodOfContactValue ? this.methodOfContactValue.split(';').filter(v => v.trim() !== '') : [];
        const providerIds      = this.providerId   ? [this.providerId]   : [];
        const caseIds          = this.caseId       ? [this.caseId]       : [];

        const filters = {
            countyIds,
            statuses,
            providerIds,
            caseIds,
            recipientType:      this.recipientTypeValue  || null,
            complaintTypes,
            methodsOfContact,
            assigneeId:         this.assigneeId          || null,
            createdById:        this.createdById         || null,
            initialDateBegin:   this.initialDateBegin    || null,
            initialDateEnd:     this.initialDateEnd      || null,
            countyResponseBegin: this.countyResponseBegin || null,
            countyResponseEnd:  this.countyResponseEnd   || null
        };

        this.showResults = false;

        helper.callServer(
            this,
            'ClientComplaintApxCtrl',
            'searchComplaints',
            (response) => {
                if (response.isSuccessful) {
                    const results = response.objectData.complaints || [];
                    if (results.length === 0) {
                        this.complaints  = [];
                        this.showResults = false;
                        if (this.hasSearched) {
                            this.dispatchEvent(new ShowToastEvent({
                                title   : 'No Results Found',
                                message : 'No Client Complaints results found. Please refine the filter.',
                                variant : 'warning'
                            }));
                        }
                    } else {
                        this.complaints  = results;
                        this.showResults = true;
                        this._setPage(1);
                        if (results.length >= 2000) {
                            this.dispatchEvent(new ShowToastEvent({
                                title   : 'Warning',
                                message : 'More records may be available. Please refine your search criteria to limit the results.',
                                variant : 'warning'
                            }));
                        }
                    }
                }
            },
            JSON.stringify({ filters })
        );
    }

    // ── Pagination ────────────────────────────────────────────────────────────
    _setPage(page) {
        const sorted = this._sortedAll;
        this.totalPages      = Math.ceil(sorted.length / this.pageSize);
        this.currentPage     = Math.min(Math.max(page, 1), this.totalPages || 1);
        const start          = (this.currentPage - 1) * this.pageSize;
        this.recordsToDisplay = sorted.slice(start, start + this.pageSize);
    }

    handlePrevious() { this._setPage(this.currentPage - 1); }
    handleNext()     { this._setPage(this.currentPage + 1); }

    // ── Sort ──────────────────────────────────────────────────────────────────
    handleSort(event) {
        this.sortedBy        = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this._setPage(1);
    }

    // ── Filter handlers ───────────────────────────────────────────────────────
    handlePicklistChange(event) {
        if (!event.detail || !event.detail.payload) return;
        const key   = event.detail.uniqueKey;
        const value = event.detail.payload.value || '';

        if (key === 'county') {
            this.countyValue = value;
            if (value && value.trim() !== '') this.countyError = '';
        } else if (key === 'status') {
            this.statusValue = value;
        } else if (key === 'complaintType') {
            this.complaintTypeValue = value;
        } else if (key === 'methodOfContact') {
            this.methodOfContactValue = value;
        } else if (key === 'recipientType') {
            this.recipientTypeValue = value;
        }
    }

    handleLookupValue(event) {
        const key      = event.detail.uniqueKey;
        const recordId = event.detail.record ? event.detail.record.Id : null;

        if (key === 'providerId')   this.providerId  = recordId;
        else if (key === 'caseId')  this.caseId      = recordId;
        else if (key === 'assigneeId')  this.assigneeId  = recordId;
        else if (key === 'createdById') this.createdById = recordId;
    }

    handleDateChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;

        if (field === 'initialDateBegin')         this.initialDateBegin    = value;
        else if (field === 'initialDateEnd')      this.initialDateEnd      = value;
        else if (field === 'countyResponseBegin') this.countyResponseBegin = value;
        else if (field === 'countyResponseEnd')   this.countyResponseEnd   = value;

        this._validateDateRanges();
    }

    // ── Date validation ───────────────────────────────────────────────────────
    _toLocalDate(dateStr) {
        return dateStr ? new Date(dateStr + 'T00:00:00') : null;
    }

    _validateDateRanges() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const initialBegin  = this._toLocalDate(this.initialDateBegin);
        const initialEnd    = this._toLocalDate(this.initialDateEnd);
        const responseBegin = this._toLocalDate(this.countyResponseBegin);
        const responseEnd   = this._toLocalDate(this.countyResponseEnd);

        // ── Initial Date of Complaint Begin Date ──────────────────────────────
        if (initialBegin && initialBegin > today) {
            this.initialDateBeginError = 'Begin date should be less than or equal to today';
        } else {
            this.initialDateBeginError = '';
        }

        // ── Initial Date of Complaint End Date ────────────────────────────────
        if (initialEnd && initialEnd > today) {
            this.initialDateEndError = 'End date should be less than or equal to today';
        } else if (initialEnd && !initialBegin) {
            this.initialDateEndError   = '';
            this.initialDateBeginError = this.initialDateBeginError || 'Please Enter Initial Date of Complaint Begin Date';
        } else if (initialEnd && initialBegin && initialEnd < initialBegin) {
            this.initialDateEndError = 'Initial Date of Complaint End Date cannot be less than Initial Date of Complaint Begin Date';
        } else {
            this.initialDateEndError = '';
        }

        // ── Initial County Response Begin Date ────────────────────────────────
        if (responseBegin && responseBegin > today) {
            this.countyResponseBeginError = 'Begin date should be less than or equal to today';
        } else {
            this.countyResponseBeginError = '';
        }

        // ── Initial County Response End Date ──────────────────────────────────
        if (responseEnd && responseEnd > today) {
            this.countyResponseEndError = 'End date should be less than or equal to today';
        } else if (responseEnd && !responseBegin) {
            this.countyResponseEndError   = '';
            this.countyResponseBeginError = this.countyResponseBeginError || 'Please Enter Initial County Response Begin Date';
        } else if (responseEnd && responseBegin && responseEnd < responseBegin) {
            this.countyResponseEndError = 'Initial County Response End Date cannot be less than Initial County Response Begin Date';
        } else {
            this.countyResponseEndError = '';
        }
    }

    _hasDateErrors() {
        this._validateDateRanges();
        return !!(this.initialDateBeginError || this.initialDateEndError || this.countyResponseBeginError || this.countyResponseEndError);
    }

    // ── New Complaint modal ───────────────────────────────────────────────────
    handleNewClientComplaint() {
        this.showNewComplaint = true;
    }

    handleCloseNewComplaint() {
        this.showNewComplaint = false;
    }

    handleComplaintSaved() {
        this.showNewComplaint = false;
        // Refresh results after saving a new complaint
        this._executeSearch();
    }
}