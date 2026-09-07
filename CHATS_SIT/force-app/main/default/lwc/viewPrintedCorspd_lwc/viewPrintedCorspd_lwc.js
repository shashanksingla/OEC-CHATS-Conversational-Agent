import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { helper } from 'c/generic_Utilities';
const columns = [
    { label:'Correspondence ID',fieldName: 'corrID', type: 'button', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left', style: 'padding-left: 1rem;' },
        typeAttributes:{ label:{fieldName: 'corrID'} , name: 'navigateButton',variant:'base' } },
    { label: 'County', fieldName: 'countyName', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left' } },
    { label: 'Case ID', fieldName: 'caseID', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left' } },
    { label: 'Provider ID', fieldName: 'provID', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left' } },
    { label: 'Correspondence Name', fieldName: 'corrName', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left', title: {fieldName: 'corrName'} }, initialWidth: 320 },    
    { label: 'User Requested', fieldName: 'userReq', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left' }, initialWidth: 200 },
    { label: 'Date Requested', fieldName: 'dateReq', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment:'left' } },
    { label: 'Date Printed', fieldName: 'datePrinted', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment:'left' } },
    { label: 'Suppress Indicator', fieldName: 'supIndicator', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment:'left' } },
    { label: 'Date Suppressed', fieldName: 'dateSuppressed', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment:'left' } }];
    
export default class ViewPrintedCorspd_lwc extends NavigationMixin(LightningElement) {
    redirectCmp = true;
    @track toggleSpinner = false;
    columns = columns;
    isOpen = true;
    userInfoId;
    userData = {};
    userProfileName = '';
    userCounties;
    isAdminUser;
    readOnlyProfile = 'Read Only User';
    corspdStatus;
    countyName;
    corspdName;
    caseID;
    providerId;
    beginDate;
    endDate;
    printedBeginDate;
    printedEndDate;
    corspdRcptType;
    corspdId;
    suppressIndicator;
    servletUrl;
    corspdPathInAws;
    @track searchResult = [];
    @track recordsToDisplay = [];
    @track selectedRows;
    @track sortedField;
    @track sortDirection;
    defaultSortDirection = 'asc';
    @track searchResultCount = 500;
    @track isOpen = true;
    @track confirmationModalSupressed = false;
    @track confirmationModalUnSuppressed = false;
    @track confirmationModal = false;
    @track numberOfPages = 0;
    @track currentPageNo = 0;
    @track retryAttempts = 0;
    @track totalNumberOfRecordsFound = 0;
    @track totalNumberOfRecordsDisplaying = 0;
    @track statusOptions = ['Requested', 'Failed', 'Generated', 'Deleted'];
    printCorspdId =[];
    supressedUnSuppressedMessage = '';
    get hasSearchResults() {
        return this.recordsToDisplay.length > 0;
    }
    get hasMorePages() {
        return this.searchResult.length > this.totalNumberOfRecordsFound;
    }
    get isReadOnlyProfile() {
        return this.userProfileName === this.readOnlyProfile;
    }
    @wire(CurrentPageReference) 
    setCurrentPageRef (currentPageRef){
        if(currentPageRef){
            this.refreshView();
        }
    }
    refreshView(){
        this.corspdId = '';
        this.caseID = '';
        this.providerId = '';
        this.beginDate = null;
        this.endDate = null;
        this.printedBeginDate = null;
        this.printedEndDate = null;
        let inputPicklists = this.template.querySelectorAll("c-multiselect-combobox");
        inputPicklists.forEach( picklist =>{
            picklist.clearSelectedValue();
        });
        const customLookups = this.template.querySelectorAll("c-custom-lookup_lwc");
        customLookups.forEach( lookupValue => {
            lookupValue.clearSelectedValue();
        });
    }
    handleInput(evt) {
        this[evt.target.dataset.id] = evt.target.value;
    }
    handlePickselect(event) {
        this[event.detail.callingContext] = event.detail.payload.value;
        event.stopPropagation();
    }
    handleLookupValue(evt){
        let detail = evt.detail;
        if (detail.objName == 'User' && detail.fieldName == 'Name') {
            this.userInfoId = detail.record.Id;
        }
    }
    getTodaysDate(){
        const today = new Date();
        const dd = String(today.getDate()).padStart(2, '0');
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const yyyy = today.getFullYear();
        return yyyy + '-' + mm + '-' + dd;
    }
    handleSort(event){
        this.sortedField = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortedField, this.sortDirection);
    }
    sortData(fieldname, sortDirection) {
        let parseData = JSON.parse(JSON.stringify(this.recordsToDisplay));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = sortDirection === 'asc' ? 1: -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; 
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.recordsToDisplay = parseData;
    }
    clickNext(){
        var currentNumber = this.currentPageNo;
        currentNumber++;
        if(!(currentNumber < Math.ceil(this.searchResult.length/this.searchResultCount))){
            return;
        }
        var beginIndex = currentNumber * this.searchResultCount;
        this.recordsToDisplay = this.searchResult.slice(beginIndex, beginIndex + this.searchResultCount);
        this.currentPageNo = currentNumber;
    }
    clickPrevious(){
        var currentNumber = this.currentPageNo;
        if(currentNumber==0){
            return;
        }
        currentNumber--;
        var beginIndex = currentNumber * this.searchResultCount;
        this.recordsToDisplay = this.searchResult.slice(beginIndex, beginIndex + this.searchResultCount);
        this.currentPageNo = currentNumber;
    }
    handleRowSelection(event){
        this.selectedRows = event.detail.selectedRows.map(row => {
            let rtnId;
            if(row.countyMatched == true){
                rtnId = row.corrID;
            }
            else{
                helper.showToast(this, 'Info', 'This does not match your assigned county(ies).', 'info', 'dismissible');
            } 
            return rtnId;
        });   
        event.detail.selectedRows = event.detail.selectedRows.filter(row => row.countyMatched == true);
    }
    corspdSearch(){
        helper.callServer(this, 'corspdPrintQueue', 'fetchUserCounties', (function (response) {
            if (response) {
                this.userCounties = response.allUserCounties;
                this.isAdminUser = response.adminUser;
            }
        }).bind(this));
        var todaysDate = this.getTodaysDate();
        var beginDateProvided = this.beginDate;
        var endDateProvided = this.endDate;
        var beginDatePrinted = this.printedBeginDate;
        var endDatePrinted = this.printedEndDate;
        var isBeginDateValid = true, isEndDateValid = true, isBeginDatePrintedValid = true, isEndDatePrintedValid = true;
        if(beginDateProvided){
            isBeginDateValid = beginDateProvided.toString().length == 10 ? true : false;
        }
        if(endDateProvided){
            isEndDateValid = endDateProvided.toString().length == 10 ? true : false;
        }
        if(beginDatePrinted){
            isBeginDatePrintedValid = beginDatePrinted.toString().length == 10 ? true : false;
        }
        if(endDatePrinted){
            isEndDatePrintedValid = endDatePrinted.toString().length == 10 ? true : false;
        }
        if(isBeginDateValid && isEndDateValid && isBeginDatePrintedValid && isEndDatePrintedValid){
            if((beginDateProvided != null && beginDateProvided > todaysDate) || (endDateProvided != null && endDateProvided > todaysDate)){
                helper.showToast(this, 'Error!', 'Requested Dates cannot be in future.', 'error', 'dismissible');
            } else if((beginDatePrinted != null && beginDatePrinted > todaysDate) || (endDatePrinted != null && endDatePrinted > todaysDate)){
                helper.showToast(this, 'Error!', 'Date Printed cannot be in future', 'error', 'dismissible');
            } else if (endDateProvided != null && endDateProvided != '' && beginDateProvided != null && beginDateProvided > endDateProvided){
                helper.showToast(this, 'Error!', 'End Date must be greater than or Equal to Begin Date', 'error', 'dismissible');
            } else {
                this.searchReasonCode();    
            }    
        } else {
            helper.showToast(this, 'Error!', 'Please enter valid date format(MM/DD/YYYY).', 'error', 'dismissible');
        }
    }
    searchReasonCode(){
        this.toggleSpinner = true;
        let params = {
            corspdStatus: 'REL', 
            countyName: this.countyName,
            caseId: this.caseID,
            providerId: parseInt(this.providerId),
            dateRequested: this.beginDate,
            dateRequestedEndRange: this.endDate,
            correspondenceId: parseInt(this.corspdId),
            correspondenceType: this.corspdName,
            correspondenceRecipientType: this.corspdRcptType,
            requestedBy: this.userInfoId,
            datePrintedBeginDate:this.printedBeginDate,
            datePrintedEndDate:this.printedEndDate,
            screen: "PrintedCorrespondence",
            suppressIndicator: this.suppressIndicator
        }
        helper.callServer(this, 'corspdPrintQueue', 'processCorspdSearch', (function (response) {
            if (response && response.payload) {
                var recordList = response.payload.listOfRecords;
                this.totalNumberOfRecordsFound = response.payload.totalNumberOfRecordsFound;
                this.totalNumberOfRecordsDisplaying = recordList.length;
                var formattedRecords = recordList.map(item=>({
                    corrID: item.idn_corr_nam,
                    corrStatus: item.cde_corr_status,
                    countyName: item.idn_county_name,
                    caseID: item.idn_case_name,
                    provID: item.idn_provr_name,
                    dateReq: item.dte_reqstd,
                    datePrinted: item.dte_prntd,
                    corrName: item.nam_corr,
                    userReq: item.idn_user_reqstd_name,
                    supIndicator: item.suppressed,
                    dateSuppressed: item.dateSuppressed,
                    corspdRcptType: item.cde_type_rcpt,
                }));
                var allUserCounties = this.userCounties.split(';');
                for(var i=0; i<formattedRecords.length; i++){
                    if(this.isAdminUser || allUserCounties.includes(formattedRecords[i].countyName)){
                        formattedRecords[i].countyMatched = true;
                    }                            
                    else{
                        formattedRecords[i].countyMatched = false;
                    }
                }
                this.searchResult = formattedRecords;
                this.currentPageNo = 1;
                if(this.totalNumberOfRecordsFound > recordList.length){
                    helper.showToast(this,'Warning','More records are available. Please refine your search criteria to limit the results', 'warning','dismissable');
                }
                if(this.totalNumberOfRecordsDisplaying <= this.totalNumberOfRecordsFound){
                    this.recordsToDisplay = this.searchResult.slice(0, this.totalNumberOfRecordsDisplaying);
                    this.numberOfPages = 1;
                }else{
                    this.recordsToDisplay = this.searchResult.slice(0, this.totalNumberOfRecordsFound);
                    this.numberOfPages = Math.ceil(recordList.length/this.totalNumberOfRecordsFound);
                }                
                if(response.payload.listOfRecords){
                    this.servletUrl = response.targetUrl;
                    this.corspdPathInAws = response.corspdPathInAws;
                    if(response.payload.listOfRecords.length == 0){
                        this.resetSearchView();
                    }
                } 
                else{
                    this.resetSearchView();
                }
            } 
            else{
                this.resetSearchView();
            }
            this.toggleSpinner = false;
        }).bind(this), JSON.stringify(params));
    }
    resetSearchView(){
        this.searchResult = [];
        this.recordsToDisplay = [];
        this.numberOfPages = 0;
        this.currentPageNo = 0;
        helper.showToast(this, 'Error', 'No Correspondence Exists for the given Input.', 'error', 'dismissible');
    }
    suppressClicked(){
        this.toggleSpinner = true;
        let table = this.template.querySelector('lightning-datatable')
        let selectedRows = table.getSelectedRows();
        var printCorspdId = [];
        if(selectedRows.length > 20){
            helper.showToast(this, 'Error', 'Correspondence Suppress limit exceeded. Maximum of 20 Correspondences can be selected to Suppress.', 'error', 'dismissible');
            this.toggleSpinner = false;
            this.selectedRows = [];
            return;
        } else if(selectedRows.length > 0) {
            for(var i = 0; i < selectedRows.length; i++) {
                printCorspdId.push(selectedRows[i].corrID);
            }
            this.printCorspdId = printCorspdId;
            this.confirmationModalSupressed = true;
            this.supressedUnSuppressedMessage = 'Are you sure you want Suppress or Unsuppress the selected correspondence?';
            this.toggleSpinner = false;
        } else if(selectedRows.length == 0) {
            helper.showToast(this, 'Error!', 'Please select atleast one Correspondence to suppress.', 'error', 'dismissible');
            this.toggleSpinner = false;
            this.selectedRows = [];
        }
    }
    unSuppressClicked(){
        this.toggleSpinner = true;
        let table = this.template.querySelector('lightning-datatable')
        let selectedRows = table.getSelectedRows();
        var printCorspdId = [];
        if(selectedRows.length > 20){
            helper.showToast(this, 'Error', 'Correspondence Unsuppress limit exceeded. Maximum of 20 Correspondences can be selected to Unsuppress.', 'error', 'dismissible');
            this.toggleSpinner = false;
            this.selectedRows = [];
            return;
        } else if(selectedRows.length > 0) {
            for(var i = 0; i < selectedRows.length; i++) {
                printCorspdId.push(selectedRows[i].corrID);
            }
            this.printCorspdId = printCorspdId;
            this.confirmationModalUnSuppressed = true;
            this.supressedUnSuppressedMessage = 'Are you sure you want Suppress or Unsuppress the selected correspondence?';
            this.toggleSpinner = false;
        } else if(selectedRows.length == 0) {
            helper.showToast(this, 'Error!', 'Please select atleast one Correspondence to Unsuppress.', 'error', 'dismissible');
            this.toggleSpinner = false;
            this.selectedRows = [];
        }
    }
    deleteCorspd(){
        let table = this.template.querySelector('lightning-datatable')
        let selectedRows = table.getSelectedRows();
        if(selectedRows.length > 0){
            this.confirmationModal = true;
        }
        else{
            helper.showToast(this, 'Error', 'Please select atleast one Correspondence to delete.', 'error', 'dismissible');
        }
    }
    confirmDelete(event){
        event.stopPropagation();
        var corspdIdsToRemove = [];
        let table = this.template.querySelector('lightning-datatable')
        let selectedRows = table.getSelectedRows();
        if(selectedRows.length > 0){
            for (var i = 0; i < selectedRows.length; i++) {
                corspdIdsToRemove.push(selectedRows[i].corrID);
            }
            this.toggleSpinner = true;
            this.deleteSelected(corspdIdsToRemove);
        }
    }
    deleteSelected(corspdIdsToRemove){
        this.toggleSpinner = true;
        let params = {
            lstCorspdId: corspdIdsToRemove,
            operation: 'DELETE',
            listSearchResults: this.searchResult
        };
        helper.callServer(this, 'corspdPrintQueue', 'corspdSuppressOrDeleteAction', (function(response){
            if (response) {       
                if(response.returnStatus == 'Success'){
                    helper.showToast(this, 'Success', 'Selected Correspondences are deleted.', 'success', 'dismissible');
                    this.confirmationModal = false;
                    this.searchReasonCode();
                }else {
                    helper.showToast(this, 'Error',JSON.stringify(response.errorMessage[0].errorMsg), 'error', 'dismissible');
                }
            } else {
                helper.showToast(this, 'Error', 'Error in calling server side action.', 'error', 'dismissable');
            }
            this.toggleSpinner = false;
            this.selectedRows = [];
        }).bind(this), JSON.stringify(params));

    }
    confirmSuppress(event){
        event.stopPropagation();
        this.confirmationModalSupressed = false;
        this.toggleSpinner = false;
        this.selectedRows = [];
        this.suppressSelected();
    }
    suppressSelected(){
        this.toggleSpinner = true;
        let params={
            lstCorspdId: this.printCorspdId,
            operation: "SUPPRESS"
        };
        helper.callServer(this, 'corspdPrintQueue', 'corspdSuppressOrDeleteAction', (function(response){
            if(response){
                if(response.returnStatus == 'Success'){
                    if(response.payload.errorMessage){
                        helper.showToast(this, 'Error', 'One or more of the correspondences selected are not in Suppressed or Unsuppressed status. Please ensure all correspondence selected are in the same Suppressed or Unsuppressed status.', 'error', 'dismissable');
                        this.searchReasonCode();
                    }
                    else{
                        helper.showToast(this, 'Success', 'Selected Correspondences are Suppressed.', 'success', 'dismissable');
                        this.searchReasonCode();
                    }
                }
                else{
                    helper.showToast(this, 'Error', 'Error in calling server side action.', 'error', 'dismissable');
                }
            }
            else{
                helper.showToast(this, 'Error', 'Error in calling server side action.', 'error', 'dismissable');
            }
            this.toggleSpinner = false;
        }).bind(this), JSON.stringify(params));
    }
    confirmUnsuppress(event){
        event.stopPropagation();
        this.confirmationModalUnSuppressed= false;
        this.toggleSpinner = false;
        this.selectedRows = [];
        this.unSuppressSelected();
    }
    unSuppressSelected(){
        this.toggleSpinner = true;
        let params={
            lstCorspdId: this.printCorspdId,
            operation: "UNSUPPRESS"
        };
        helper.callServer(this, 'corspdPrintQueue', 'corspdSuppressOrDeleteAction', (function(response){
            if(response){
                if(response.returnStatus == 'Success'){
                    if(response.payload.errorMessage){
                        helper.showToast(this, 'Error', 'One or more of the correspondences selected are not in Suppressed or Unsuppressed status. Please ensure all correspondence selected are in the same Suppressed or Unsuppressed status.', 'error', 'dismissable');
                        this.searchReasonCode();
                    }
                    else{
                        helper.showToast(this, 'Success', 'Selected Correspondences are Unsuppressed.', 'success', 'dismissable');
                        this.searchReasonCode();
                    }
                }
                else{
                    helper.showToast(this, 'Error', 'Error in calling server side action.', 'error', 'dismissable');
                }
            }
            else{
                helper.showToast(this, 'Error', 'Error in calling server side action.', 'error', 'dismissable');
            }
            this.toggleSpinner = false;
        }).bind(this), JSON.stringify(params));
    }
    closeModal(event){
        event.stopPropagation();
        this.confirmationModal = false;
        this.confirmationModalSupressed = false;
        this.confirmationModalUnSuppressed = false;
    }
    viewPrintedCorspd(event){
        var corspdId = event.detail.row.corrID;
        let params = { corspdId: corspdId} ;
        helper.callServer(this, 'corspdPrintQueue', 'getFileName', (function(response){
            if(response){
                if(response.payload) {
                    var fileName;
                    if(response.payload[0].cde_lang_doc__c){
                        fileName = response.payload[0].idn_corr_nam__c + '_' + response.payload[0].cde_lang_doc__c +'.pdf';
                    }else{
                        fileName = response.payload[0].idn_corr_nam__c+'.pdf';
                    }
                    var pdfWin= window.open("/apex/CorrespondencePage?fileName="+fileName, "", "height=650,width=840");
                } else{
                    helper.showToast(this, 'Error', 'Error in Retrieving Correspondence Pdf filename.', 'error', 'dismissible');
                }
            } else{
                helper.showToast(this, 'Error', 'Error in retrieving FileName of the Pdf.', 'error', 'dismissible');
            }
        }).bind(this), JSON.stringify(params));
    }
    navigateScreen(){
        this.searchResult = [];
        this.recordsToDisplay = [];
        this.numberOfPages = 0;
        this.currentPageNo = 0;
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Corspd_Print_Queue'
            }
        });
    }
}