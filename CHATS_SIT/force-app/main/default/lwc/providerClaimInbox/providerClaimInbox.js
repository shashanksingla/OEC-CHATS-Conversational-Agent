import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { helper } from 'c/generic_Utilities';
import { abs_helper } from 'c/abstract_Component';
import { claimHelper } from './providerClaimInboxHelper.js';
const columns = [
    {
        label: 'Record Id',
        fieldName: 'appQueueLink',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: { fieldName: 'queueId' },
            target: '_blank'
        }
    },
    { label: 'County', fieldName: 'queuecounty', type: 'text', sortable: true },
    {   // corrected date to date-local for CCCAP-14587
        label: 'Submitted Date', fieldName: 'queueSubmittedDate', type: 'date-local', sortable: true, typeAttributes: {
            month: "2-digit",
            day: "2-digit",
            year: "numeric"
        }
    },
    { label: 'Status', fieldName: 'queuestatus', type: 'text', sortable: true },
    { label: 'Provider ID', fieldName: 'queueProviderId', sortable: true, type: 'text' },
    { label: 'Provider Name', fieldName: 'queueProviderName', sortable: true, type: 'text', wrapText: true },
    { label: 'Care Month', fieldName: 'queueCareMonth', type: 'text', sortable: true },
    { label: 'Care Year', fieldName: 'queueCareYear', type: 'text', sortable: true },
    { label: 'Total Amount Claimed', fieldName: 'queueClaimAmount', type: 'currency', sortable: true, cellAttributes: { alignment: 'left' } },
    {
        type: "url", label: 'View Claim Details', fieldName: 'pdfLink', typeAttributes: {
            name: 'viewPDF',
            label: 'View Claim Details',
        }
    }
];
export default class ProviderClaimInbox extends NavigationMixin(LightningElement) {
    @api recordId;
    claimResultWrapper;
    FinalList;
    @track
    statusOptions = [{
        'label': 'In Progress', 'value': 'In Progress', 'class': 'optionClass',
        'selected': false
    },
    {
        'label': 'Submitted', 'value': 'Submitted', 'class': 'optionClass',
        'selected': false
    },
    {
        'label': 'Paid', 'value': 'Paid', 'class': 'optionClass',
        'selected': false
    },
    {
        'label': 'Denied', 'value': 'Denied', 'class': 'optionClass',
        'selected': false
    },
    ];
    @track
    claimInboxWrapper = { 'status': 'Submitted;In Progress;', 'searchType': 'StringSearch' };
    nameSearchoptions = [{
        'label': 'String Search', 'value': 'StringSearch'
    }];

    @track sortedBy;
    @track sortedDirection;
    initDone;
    pageSize = 200;
    totalSize;
    start;
    end;
    sortField;
    @track
    hiddenMonths = [];
    sampleYearOptions;
    showSpinner;
    columns = columns;
    message;
    connectedCallback() {
        let sampleYOptions = [];
        var currentTime = new Date()
        var currentYear = currentTime.getFullYear();
        let start = 2025;
        while (start <= currentYear) {
            sampleYOptions.push({ 'label': start.toString(), 'value': start.toString() });
            start++;
        }
        this.sampleYearOptions = sampleYOptions;
        this.initComponent();
    }
    get isPreviousDisabled() {
        return this.start === 0;
    }
    get isNextDisabled() {
        return this.end >= this.totalSize - 1;
    }
    get showTable() {
        return this.claimResultWrapper && this.claimResultWrapper.length > 0
    }
    get isLookupSelected() {
        return this.claimInboxWrapper && (this.claimInboxWrapper.providerId || '').length > 0;
    }
    initComponent() {
        let params = {};
        helper.callServer(this, 'ClaimInboxScreenCtrl', 'getInitClaimRequestData', (function (result) {
            if (result.isSuccessful) {
                if (result.objectData) {
                    if (result.objectData.todayMinus30Days) {
                        this.claimInboxWrapper.fromDate = result.objectData.todayMinus30Days;
                    }
                    if (result.objectData.todayDate) {
                        this.claimInboxWrapper.toDate = result.objectData.todayDate;
                    }
                    if (result.objectData.user) {
                        this.claimInboxWrapper.county = result.objectData.user + ';';
                    }
                    this.initDone = true;
                    this.viewClaimResults();
                }
            } else {
                helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
            }
        }).bind(this), JSON.stringify(params));
    }
    handleCompSelect(evt) {
        let compValue = evt.target.dataset.name;
        claimHelper.handleValueUpdates(this, compValue, evt.detail);
    }
    handleValueSelectedOnAccount(evt) {
        claimHelper.handleValueUpdates(this, evt.detail.objName + '-' + evt.detail.fieldName, evt.detail);
    }

    handlePickselect(event) {
        claimHelper.handleValueUpdates(this, event.detail.callingContext, event.detail);
        event.stopPropagation();
    }
    handleNext() {
        this.toggleLoading();
        let wrapperList = this.FinalList; // all claims list
        let end = this.end;
        let paginationList = [];
        paginationList = wrapperList.slice(end + 1, end + this.pageSize + 1);//Slicing List as page number
        this.start = this.start + this.pageSize;
        this.end = end + this.pageSize;
        this.claimResultWrapper = paginationList;
        this.toggleLoading();
    }
    handlePrevious() {
        this.toggleLoading();
        let wrapperList = this.FinalList;// all claims list
        let start = this.start;
        let paginationList = [];
        paginationList = wrapperList.slice(start - this.pageSize, start);//Slicing List as page number
        start = start - this.pageSize;
        this.start = start;
        this.end = this.end - this.pageSize;
        this.claimResultWrapper = paginationList;
        this.toggleLoading();
    }
    onSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy, this.sortedDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.FinalList));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === "asc" ? 1 : -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : "";
            y = keyValue(y) ? keyValue(y) : "";
            return isReverse * ((x > y) - (y > x));
        });
        this.FinalList = parseData;
        // Update the paginated data
        claimHelper.updatePagination(this);

    }

    viewClaimResults() {
        let isValid = abs_helper.validateCurrentPage(this);
        if (isValid) {
            this.claimResultWrapper = undefined;
            let params = { 'claimSearchWrapperStr': JSON.stringify(this.claimInboxWrapper) };
            helper.callServer(this, 'ClaimInboxScreenCtrl', 'processViewResults', (function (result) {
                try {
                    if (result.isSuccessful) {
                        let claimsList = result.objectData.claims;
                        claimsList.forEach(val => {
                            val.appQueueLink = '/one/one.app?#/sObject/' + val.recordId + '/view';
                            val.pdfLink = '/one/one.app?#/cmp/c__providerClaimScreen?c__recordId=' + val.recordId;
                            val.queueSubmittedDate = (val.queueSubmittedDate || '').split('T')[0]; // added for CCCAP-14587
                        });
                        this.FinalList = claimsList;

                        let paginationList = [];
                        let pageSize = this.pageSize;
                        this.totalSize = claimsList.length;
                        this.start = 0;
                        this.end = pageSize - 1;
                        if (claimsList.length < pageSize) {
                            paginationList = claimsList;
                        }
                        else {
                            for (let i = 0; i < pageSize; i++) {
                                paginationList.push(claimsList[i]);
                            }
                        }
                        this.claimResultWrapper = paginationList;
                        if (claimsList.length == 0) {
                            helper.showToast(this, 'Error!', 'No Manual Claim results found. Please refine the filter.', 'error', 'dismissible');
                        }
                    } else {
                        helper.showToast(this, 'Error!', result.errorMessage, 'error', 'dismissible');
                    }

                } catch (err) {
                    console.log(err.message);
                }
            }).bind(this), JSON.stringify(params));
        }
    }

    checkCustomValidations() {
        return claimHelper.checkCustomValidations(this);
    }
    toggleLoading() {
        this.showSpinner = !this.showSpinner;
    }
}