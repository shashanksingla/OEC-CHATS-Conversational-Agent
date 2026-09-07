import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { helper } from 'c/generic_Utilities';

export default class AuthEncumbranceRelatedList_LWC extends NavigationMixin(LightningElement) {
    @track listRecordsToDisplay = [];
    @track recCount = 0;
    @track orderByField = ' ';
    @track sortAscDsc = 'ASC';
    @track sortAsc = false;
    @track showTable = true;
    @track isLoading = false;
    fieldApiNames = ['ExternalId', 'dateOfCare', 'status', 'actualAttendedHours', 'rateType', 'attendedFlag', 'ind0to36months', 'authorizedHours'];

    @api recordId;
    @api relatedListHeader = '';
    @api isMonthYrBasedSearch = false;
    @api showMore;
    @api isNavigateToCmp = false;

    @api
    getAuthEncumb(selectedMonth, selectedYear) {
        this.isLoading = true;
        this.retrieveExtArchivedData(selectedMonth, selectedYear);
    }

    connectedCallback() {
        this.initializeShowMore();
        if (!this.isMonthYrBasedSearch) {
            this.retrieveExtObjData();
        } else {
            const date = new Date();
            this.retrieveExtArchivedData(date.getMonth(), date.getFullYear());
        }
    }

    // Getters for template
    get showHeaderLink() {
        return !this.isMonthYrBasedSearch;
    }

    get showViewAllFooter() {
        return !this.isMonthYrBasedSearch && this.recCount > 0 && this.showMore;
    }

    get show0to36MonthsColumn() {
        return !this.isMonthYrBasedSearch;
    }

    get displayRecords() {
        if (this.showMore) {
            return this.listRecordsToDisplay.slice(0, 5);
        }
        return this.listRecordsToDisplay;
    }

    get isExternalIdSortAsc() {
        return this.sortAscDsc === 'ASC' && this.orderByField === this.fieldApiNames[0];
    }

    get isExternalIdSortDesc() {
        return this.sortAscDsc === 'DESC' && this.orderByField === this.fieldApiNames[0];
    }

    get isDateOfCareSortAsc() {
        return this.sortAscDsc === 'ASC' && this.orderByField === this.fieldApiNames[1];
    }

    get isDateOfCareSortDesc() {
        return this.sortAscDsc === 'DESC' && this.orderByField === this.fieldApiNames[1];
    }

    get isStatusSortAsc() {
        return this.sortAscDsc === 'ASC' && this.orderByField === this.fieldApiNames[2];
    }

    get isStatusSortDesc() {
        return this.sortAscDsc === 'DESC' && this.orderByField === this.fieldApiNames[2];
    }

    get isAuthorizedHoursSortAsc() {
        return this.sortAscDsc === 'ASC' && this.orderByField === this.fieldApiNames[7];
    }

    get isAuthorizedHoursSortDesc() {
        return this.sortAscDsc === 'DESC' && this.orderByField === this.fieldApiNames[7];
    }

    get isActualAttendedHoursSortAsc() {
        return this.sortAscDsc === 'ASC' && this.orderByField === this.fieldApiNames[3];
    }

    get isActualAttendedHoursSortDesc() {
        return this.sortAscDsc === 'DESC' && this.orderByField === this.fieldApiNames[3];
    }

    get isRateTypeSortAsc() {
        return this.sortAscDsc === 'ASC' && this.orderByField === this.fieldApiNames[4];
    }

    get isRateTypeSortDesc() {
        return this.sortAscDsc === 'DESC' && this.orderByField === this.fieldApiNames[4];
    }

    get isAttendedSortAsc() {
        return this.sortAscDsc === 'ASC' && this.orderByField === this.fieldApiNames[5];
    }

    get isAttendedSortDesc() {
        return this.sortAscDsc === 'DESC' && this.orderByField === this.fieldApiNames[5];
    }

    get is0to36MonthsSortAsc() {
        return this.sortAscDsc === 'ASC' && this.orderByField === this.fieldApiNames[6];
    }

    get is0to36MonthsSortDesc() {
        return this.sortAscDsc === 'DESC' && this.orderByField === this.fieldApiNames[6];
    }

    get showSortIcons() {
        return !this.showMore;
    }

    initializeShowMore() {
        if (!this.isNavigateToCmp) {
            const urlStr = window.location.origin + window.location.pathname;
            this.showMore = urlStr.endsWith('view');
        }
    }

    retrieveExtObjData() {
        this.isLoading = true;
        const params = {
            recordId: this.recordId
        };

        helper.callServer(
            this,
            'AuthEncumbRelatedListController',
            'fetchRelatedObjectdata',
            ((response) => {
                this.isLoading = false;
                if (response && response.isSuccessful) {
                    if (response.objectData && response.objectData.authEncumbranceRelatedList) {
                        this.listRecordsToDisplay = response.objectData.authEncumbranceRelatedList;
                        this.recCount = response.objectData.authEncumbranceRelatedList.length;
                    }
                } else {
                    this.handleError(response);
                }
            }).bind(this),
            JSON.stringify(params)
        );
    }

    retrieveExtArchivedData(month, year) {
        this.isLoading = true;
        const params = {
            recordId: this.recordId,
            monthStr: String(month),
            yearStr: String(year)
        };

        helper.callServer(
            this,
            'AuthEncumbRelatedListController',
            'fetchRelatedArchivedObjectdata',
            ((response) => {
                this.isLoading = false;
                if (response && response.isSuccessful) {
                    if (response.objectData && response.objectData.authEncumbranceRelatedList) {
                        this.listRecordsToDisplay = response.objectData.authEncumbranceRelatedList;
                        this.recCount = response.objectData.authEncumbranceRelatedList.length;
                        if (this.isMonthYrBasedSearch) {
                            this.showMore = false;
                        }
                    }
                } else {
                    this.handleError(response);
                }
            }).bind(this),
            JSON.stringify(params)
        );
    }

    handleError(response) {
        this.listRecordsToDisplay = [];
        this.recCount = 0;
        const message = response && response.message ? response.message : 'An error occurred';
        this.showToast('Error', message, 'error');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'pester'
        });
        this.dispatchEvent(event);
    }

    handleHeaderClick() {
        if (!this.isMonthYrBasedSearch) {
            this.navigateToChildComponent();
        }
    }

    navigateToChildComponent() {
        if (this.showMore) {
            // Navigate to full view component
            this[NavigationMixin.Navigate]({
                type: 'standard__component',
                attributes: {
                    componentName: 'c__authEncumbranceRelatedList_LWC'
                },
                state: {
                    c__recordId: this.recordId,
                    c__sortAscDsc: this.sortAscDsc,
                    c__orderByField: this.orderByField,
                    c__recCount: this.recCount,
                    c__relatedListHeader: this.relatedListHeader,
                    c__isNavigateToCmp: true,
                    c__showMore: false
                }
            });
        } else {
            window.history.back();
        }
    }

    handleViewAllClick() {
        this.navigateToChildComponent();
    }

    sortColumn(event) {
        if (!this.showMore) {
            const fieldId = event.currentTarget.dataset.id;
            this.orderByField = fieldId;
            this.sortAscDsc = (!this.sortAscDsc || this.sortAscDsc === 'ASC') ? 'DESC' : 'ASC';
            this.sortBy(fieldId);
        }
    }

    sortBy(field) {
        const records = [...this.listRecordsToDisplay];
        const sortAsc = this.sortAscDsc === 'ASC';

        records.sort((a, b) => {
            const aVal = a[field];
            const bVal = b[field];
            
            if (aVal === bVal) return 0;
            if (!aVal && bVal) return sortAsc ? 1 : -1;
            if (aVal && !bVal) return sortAsc ? -1 : 1;
            if (aVal < bVal) return sortAsc ? -1 : 1;
            return sortAsc ? 1 : -1;
        });

        this.listRecordsToDisplay = records;
    }

    navigateToDetail(event) {
        const externalId = event.currentTarget.dataset.id;
        const params = {
            externalId: externalId
        };

        helper.callServer(
            this,
            'AuthEncumbRelatedListController',
            'getAuthEncumbRecordId',
            ((response) => {
                if (response && response.isSuccessful && response.objectData) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: response.objectData.recordId,
                            actionName: 'view'
                        }
                    });
                }
            }).bind(this),
            JSON.stringify(params)
        );
    }

    formatDate(dateValue) {
        if (!dateValue) return '';
        const date = new Date(dateValue);
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        const year = date.getFullYear();
        return `${month}/${day}/${year}`;
    }
}