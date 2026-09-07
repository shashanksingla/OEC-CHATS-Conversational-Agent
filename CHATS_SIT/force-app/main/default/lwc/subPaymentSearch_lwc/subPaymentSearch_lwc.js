import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { helper } from 'c/generic_Utilities';
const jsToServerKeys = {
    'subPaymentId': 'subPymtId',
    'paymentName': 'pymtId',
    'payDate': 'paymentDatePaid',
    'periodBeginDate': 'servicePeriodBgnDte',
    'periodEndDate': 'servicePeriodEndDte',
    'authorizationId': 'authid',
    'caseId': 'caseId',
    'firstName': 'childFirstName',
    'lastName': 'childLastName',
    'countyName': 'county'
};
const columns = [
    {
        label: 'VIEW', hideLabel: 'true', fieldName: '', type: 'button-icon',
        typeAttributes: { alternativeText: 'View', title: 'View', iconName: 'utility:preview', size: 'xx-small', variant: 'bare' }, cellAttributes: { alignment: 'center' }
    },
    { label: 'SUB PAYMENT ID', fieldName: 'subPymtId', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'center' } },
    { label: 'SUB PAYMENT STATUS', fieldName: 'subPymtStatus', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'center' } },
    { label: 'PAYMENT ID', fieldName: 'pymtId', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'center' } },
    { label: 'AUTHORIZATION ID', fieldName: 'authid', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'center' } },
    { label: 'CASE ID', fieldName: 'caseId', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'center' } },
    { label: 'SERVICE PERIOD BEGIN DATE', fieldName: 'servicePeriodBgnDte', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'center' } },
    { label: 'SERVICE PERIOD END DATE', fieldName: 'servicePeriodEndDte', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'center' } },
    { label: 'PAID DATE', fieldName: 'payDate', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'center' } },
    { label: 'COUNTY', fieldName: 'county', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'center' } },
    { label: "CHILD'S FIRST NAME", fieldName: 'childFirstName', type: 'text', hideDefaultActions: true, wrapText: true, cellAttributes: { alignment: 'center' } },
    { label: "CHILD'S LAST NAME", fieldName: 'childLastName', type: 'text', hideDefaultActions: true, wrapText: true, cellAttributes: { alignment: 'center' } },
    { label: 'TOTAL SUB PAYMENT RATE PAID', fieldName: 'subPymtAmount', type: 'currency', wrapText: true, hideDefaultActions: true, cellAttributes: { alignment: 'center'} },
    { label: 'TOTAL SUB PAYMENT PARENT FEE', fieldName: 'subPymtCopayAmt', type: 'currency', wrapText: true, hideDefaultActions: true, cellAttributes: { alignment: 'center' } },
    { label: 'TOTAL SUB PAYMENT AMOUNT', fieldName: 'subPymtAmount', type: 'currency', hideDefaultActions: true, wrapText: true, cellAttributes: { alignment: 'center' } }
];
export default class SubPaymentSearch_lwc extends LightningElement {
    paymentId;
    providerId
    caseId;
    showSpinner;
    countyId;
    servicePeriodId;
    stateId;
    childFirstName;
    childLastName;
    subPaymentSearchLst = [];
    hasSearched;
    pageMessages;
    messageType;
    isCurrentPageValid = true;
    showSpinner;
    columns = columns;
    stylesLoaded;
    currentIndex;
    sortBy;
    sortDirection = 'asc';
    get showTable() {
        return this.subPaymentSearchLst.length > 0
    }
    get dataList() {
        let subpymtList = JSON.parse(JSON.stringify(this.subPaymentSearchLst)) || [];
        return subpymtList.slice(0, this.currentIndex);
    }
    @wire(CurrentPageReference) 
    setCurrentPageRef (currentPageRef){
        if(currentPageRef){
            this.refreshView();
        }
    }
    refreshView(){
        this.paymentId = '';
        this.childFirstName = '';
        this.childLastName = '';
        const customLookups = this.template.querySelectorAll("c-custom-lookup_lwc");
        customLookups.forEach( lookupValue => {
            lookupValue.clearSelectedValue();
        });
    }
    loadMoreData(evt) {
        evt.target.isLoading = true;
        if (this.currentIndex >= this.subPaymentSearchLst.length) {
            evt.target.enableInfiniteLoading = false;
        } else {
            let newIndex = this.currentIndex + 10;
            this.currentIndex = newIndex >= this.subPaymentSearchLst.length ? this.subPaymentSearchLst.length : newIndex;
        }
        evt.target.isLoading = false;
    }
    handleInput(evt) {
        this[evt.target.dataset.id] = evt.target.value;
        this.reportValidityofChildComponents();
    }
    handleValueSelectedOnAccount(evt) {
        let detail = evt.detail;
        if (detail.objName && detail.fieldName) {
            this.subPaymentSearchLst = [];
            switch (detail.objName + '-' + detail.fieldName) {
                case 'T_CHATS_PROVR_STATUS__c-Name':
                    this.providerId = detail.record.Id;
                    break;
                case 'T_SBSD_CASE__c-Name':
                    this.caseId = detail.record.Id;
                    break;
                case 'T_COUNTY__c-Name':
                    this.countyId = detail.record.Id;
                    break;
                case 'T_SERV_PERIOD__c-Service_Period_Dates__c':
                    this.servicePeriodId = detail.record.Id;
                    break;
                case 'T_SBSD_INDIV__c-IDN_STATE__c':
                    this.stateId = detail.record.IDN_STATE__c;
                    break;
                default:
            }
            this.reportValidityofChildComponents();
        }

    }
    reportValidityofChildComponents() {
        this.isCurrentPageValid = true;
        this.pageMessages = [];
        Promise.resolve().then(() => {
            const customLookups = this.template.querySelectorAll("c-custom-lookup_lwc");
            customLookups.forEach(lookupValue => {
                lookupValue.reportValidity();
            });
            var inputComponents = this.template.querySelectorAll("lightning-input");
            if (inputComponents && inputComponents.length > 0) {
                areAllFieldsValid = [...inputComponents]
                    .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
                    }, true);
            }
        });

    }
    get isRequired() {
        return !(this.paymentId || this.providerId || this.caseId || this.stateId);
    }
    doSearch() {
        if (!(this.paymentId || this.providerId || this.caseId || this.stateId)) {
            this.isCurrentPageValid = false;
            this.hasSearched = false;
            this.messageType = "Error";
            this.pageMessages=[
                {
                    Id:0,
                    message: "At least one of the fields marked as required must be entered"
                }
            ];
        } else {
            this.currentIndex = -1;
            this.subPaymentSearchLst = [];
            let params;
            params = {
                'paymentId': this.paymentId, 'providerId': this.providerId,
                'caseId': this.caseId, 'countyId': this.countyId,
                'servicePeriodId': this.servicePeriodId, 'stateId': this.stateId,
                'childFirstName': this.childFirstName, 'childLastName': this.childLastName
            };
            this.isCurrentPageValid = true;
            helper.callServer(this, 'subPaymentSearch', 'doSearchSubPayment', (function (response) {
                if (response.isSuccessful == true) {
                    var searchResults = response.objectData.SubpaymentSearchResults || [];
                    searchResults.forEach(val => {
                        Object.keys(jsToServerKeys).forEach((key) => {
                            val[key] = val[jsToServerKeys[key]];
                        });
                    });
                    this.subPaymentSearchLst = searchResults;
                    this.currentIndex = 10;
                    this.hasSearched = true;
                    if (searchResults && searchResults.length > 200) {
                        helper.showToast(this, 'Warning', 'Over 200 records have been returned, please refine the search criteria.', 'warning', '');
                    }
                }else{
                    helper.showToast(this, 'error', response.errorMessage, 'error', 'dismissible');
                }
            }).bind(this), JSON.stringify(params));

        }
    }
    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.subPaymentSearchLst));
        let isReverse = direction === 'asc' ? 1 : -1;
        parseData.sort((a, b) => {
            a = a[fieldname] ? a[fieldname].toLowerCase() : '';
            b = b[fieldname] ? b[fieldname].toLowerCase() : '';

            return isReverse * ((a > b) - (b > a));
        });
        this.subPaymentSearchLst = parseData;
    }
    viewSubpayment(event) {
        const row = event.detail.row;
        var subPaymentId = row.subPymtId;
        let params = {
            'subPaymentId': subPaymentId
        }
        helper.callServer(this, 'subPaymentSearch', 'doSearchSubpymntId', (function (response) {
            if (response.objectData.subPaymntSfId) {
                let url = '/one/one.app#/sObject/' + response.objectData.subPaymntSfId + '/view';
                window.open(url);
            }
        }).bind(this), JSON.stringify(params));
    }
}