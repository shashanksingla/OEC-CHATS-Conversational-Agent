import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { helper } from 'c/generic_Utilities';
const jsToObjectKeys = {
    'corrID': 'Name',
    'corrStatus': 'CDE_CORSPD_STATUS__c',
    'countyName': 'IDN_COUNTY_F__c',
    'caseID': 'IDN_CASE_F__c',
    'provID': 'IDN_PROVR_F__c',
    'dateReq': 'DTE_REQ__c',
    'corrName': 'NME_CORSPD__c',
    'userReq': 'Requested_By__c'
};
const columns = [
    { label:'Correspondence ID',fieldName: 'corrID', type: 'button', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left', style: 'padding-left: 1rem;' },
        typeAttributes:{ label:{fieldName: 'corrID'} , name: 'navigateButton',variant:'base' } },
    { label: 'Status', fieldName: 'corrStatus', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left' } },
    { label: 'County', fieldName: 'countyName', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left' } },
    { label: 'Case ID', fieldName: 'caseID', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left' } },
    { label: 'Provider ID', fieldName: 'provID', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left' } },
    { label: 'Date Requested', fieldName: 'dateReq', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment:'left' } },
    { label: 'Correspondence Name', fieldName: 'corrName', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left' }, initialWidth: 400 },
    { label: 'User Requested', fieldName: 'userReq', type: 'text', hideDefaultActions: true, sortable: true, cellAttributes: { alignment: 'left' }, initialWidth:200 }];
export default class CorspdPrintQueue_LWC extends NavigationMixin(LightningElement){
    @track toggleSpinner = false;
    columns = columns;
    isOpen = true;
    userInfoId;
    userData = {};
    userProfileName = '';
    //readOnlyProfile = 'Read Only User'; CCCAP-14993 commented
    corspdStatus;
    countyName;
    corspdName;
    caseID;
    providerId;
    beginDate;
    endDate;
    corspdRcptType;
    corspdId;
    @track searchResult = [];
    @track encapsulatedSearchResult = [];
    @track recordsToDisplay;
    @track selectedRows;
    @track sortedField;
    @track sortDirection;
    defaultSortDirection = 'asc';
    @track searchResultCount = 20;
    @track isOpen = true;
    @track openManCorspd = false;
    @track confirmationModal = false;
    @track numberOfPages = 0;
    @track currentPageNo = 0;
    @track retryAttempts = 0;
    @track totalNumberOfRecordsFound = 0;
    @track totalNumberOfRecordsDisplaying = 0;
    @track statusOptions = ['Requested', 'Failed', 'Generated', 'Deleted'];
    get hasSearchResults() {
        return this.encapsulatedSearchResult.length > 0;
    }
    get hasMorePages() {
        return this.encapsulatedSearchResult.length > this.searchResultCount;
    }
    get isReadOnlyProfile() {
        return this.userProfileName;
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
        let inputPicklists = this.template.querySelectorAll("c-multiselect-combobox");
        inputPicklists.forEach( picklist =>{
            picklist.clearSelectedValue();
        });
        const customLookups = this.template.querySelectorAll("c-custom-lookup_lwc");
        customLookups.forEach( lookupValue => {
            lookupValue.clearSelectedValue();
        });
    }
    connectedCallback() {
        this.initActions();
    }
    initActions(){
        helper.callServer(this, 'corspdPrintQueue', 'fetchUserdata', (function (response) {
            if (response.isSuccessful) {
                this.userData = response.objectData;
                this.userProfileName = response.objectData.userProfileName;
            }
        }).bind(this));
        this.setCorspdStatusOptions();
    }
    handleInput(evt) {
        this[evt.target.dataset.id] = evt.target.value;
    }
    handlePickselect(event) {
        if (event.detail.callingContext == 'T_DOC_RQ__c_CDE_CORSPD_STATUS__c') {
            this.corspdStatus = event.detail.payload.value;
        }else{
            this[event.detail.callingContext] = event.detail.payload.value;
        }
        event.stopPropagation();
    }
    handleLookupValue(evt){
        let detail = evt.detail;
        if (detail.objName == 'User' && detail.fieldName == 'Name') {
            this.userInfoId = detail.record.Id;
        }
        evt.stopPropagation();
    }
    setCorspdStatusOptions(){
        var currentStatusOptions = this.statusOptions || [];
        var options = [];
        currentStatusOptions.forEach((status => {
            options.push({
                label: status.toString(),
                value: status.toString()
            });
        }));
        this.statusOptions = options;
    }
    corspdSearch() {
        var beginDateProvided = this.beginDate;
        var endDateProvided = this.endDate;
        var todaysDate = this.getTodaysDate();
        var isBeginDateValid = true;
        var isEndDateValid = true;
        if(beginDateProvided){
            isBeginDateValid = beginDateProvided.toString().length == 10 ? true : false;
        }
        if(endDateProvided){
            isEndDateValid = endDateProvided.toString().length == 10 ? true : false;
        }
        if(isBeginDateValid && isEndDateValid){
            if((beginDateProvided != null && beginDateProvided > todaysDate) || (endDateProvided != null && endDateProvided > todaysDate)){
                helper.showToast(this, 'Error!', 'Requested Dates cannot be in future.', 'error', 'dismissible');
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
        this.selectAllCheckbox = false;
        let params = {
            corspdStatus: this.corspdStatus, 
            countyName: this.countyName,
            caseId: this.caseID,
            providerId: parseInt(this.providerId),
            dateRequested: this.beginDate,
            dateRequestedEndRange: this.endDate,
            correspondenceId: parseInt(this.corspdId),
            correspondenceType: this.corspdName,
            correspondenceRecipientType: this.corspdRcptType,
            requestedBy: this.userInfoId,
            datePrintedBeginDate:null,
            datePrintedEndDate:null,
            screen: "CorrespondenceGeneration"
        }
        helper.callServer(this, 'corspdPrintQueue', 'processCorspdSearch', (function (response) {
            if (response && response.payload) {
                this.searchResult = response.payload;
                this.totalNumberOfRecordsFound = response.corspdSearchListCount;
                this.totalNumberOfRecordsDisplaying = response.payload.length;
                var searchResults = response.payload || [];
                var formattedSearchResult= this.setDisplayedResults(response.payload);
                this.encapsulatedSearchResult = formattedSearchResult.map(item=>({
                    sfID: item.payload.Id,
                    corrID: item.payload.Name,
                    corrStatus: item.payload.CDE_CORSPD_STATUS__c,
                    countyName: item.payload.IDN_COUNTY_F__c,
                    caseID: item.payload.IDN_CASE_F__c,
                    provID: item.payload.IDN_PROVR_F__c,
                    dateReq: item.payload.DTE_REQ__c,
                    corrName: item.payload.NME_CORSPD__c,
                    userReq: item.payload.Requested_By__c,
                    corrURL: item.payload.url
                }));
                if(this.totalNumberOfRecordsFound > this.searchResultCount) {
                    helper.showToast(this, 'Warning', 'More records are available. Please refine your search criteria to limit the results', 'warning', 'dismissible');
                }
                this.currentPageNo = 1;
                this.setRecordsToDisplay();
            } 
            else if(response.returnStatus == 'Failure' && response.errorMessage.length > 0){
                var errorList = response.errorMessage;
                for(var i = 0; i < errorList.length ; i++){
                    helper.showToast(this, 'Error!', errorList[i].errorMsg, 'error', 'dismissible');
                }
            }
            else{
                this.searchResult = [];
                this.numberOfPages = 0;
                this.currentPageNo = 0;
                this.encapsulatedSearchResult = [];
                helper.showToast(this, 'Error!', 'No Correspondence Exists for the given Input.', 'error', 'dismissible');
            }
            this.toggleSpinner = false;
        }).bind(this), JSON.stringify(params));
    }
    setDisplayedResults(listOfResults){
        var length = listOfResults.length;
        var retVal = [];
        for (var i = 0; i < length; i += 1) {
            retVal.push({
                checked: false,
                payload: listOfResults[i]
            });
        }
        this.numberOfPages = Math.ceil(length / this.searchResultCount);
        this.currentPageNo = 0;
        return retVal;
    }
    getTodaysDate(){
        const today = new Date();
        const dd = String(today.getDate()).padStart(2, '0');
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const yyyy = today.getFullYear();
        return yyyy + '-' + mm + '-' + dd;
    }
    navigateToCorr(event){
        if(event.detail.action.name == 'navigateButton'){
            var corspdId = event.detail.row.corrID;
            this.retryAttempts = this.retryAttempts + 1;
            this.toggleSpinner = true;
            var time = 1;
            let param = {corspdId: corspdId};
            helper.callServer(this, 'corspdPrintQueue', 'processCorspdQueueToView', (function (response) {
                if(response){
                    if(response.returnStatus == 'Success'){
                        this.retryAttempts = 0;
                        if(response.CorrespondenceAlreadyGenerated){
                            var time = 1;
                            setTimeout(() => {
                                const alreadygenUrl = response.targetUrl+'pathInAws=correspondence/request&fileName='+response.CorrespondenceFileName;
                                const stopSpinner = true;
                                let params = {
                                    lstCorspdId: corspdId,
                                    alreadygenUrl:alreadygenUrl,
                                    fileName:response.CorrespondenceFileName 
                                }
                                helper.callServer(this, 'corspdPrintQueue','addPrintedDateToCorspdDate', (function(resp){
                                    if(resp){
                                        if(resp.returnStatus == 'Success'){
                                            if(resp.payload.is200){
                                                const pdfWin = window.open('/apex/CorrespondencePage?fileName='+response.CorrespondenceFileName, "", "height=650,width=840");
                                                setTimeout(() => {
                                                    this.searchReasonCode();
                                                }, time * 3000);
                                            }
                                            else{
                                                helper.showToast(this, 'Error', resp.payload.errorMessage, 'error', 'dismissible');                                          
                                            }
                                        }
                                        else if(response.errorMessage!=null){
                                            helper.showToast(this, 'Error', 'Error in calling server side action.', 'error', 'dismissible');
                                        }
                                    }
                                    else{
                                        helper.showToast(this, 'Error', 'Error in calling server side action.', 'error', 'dismissible');
                                        stopSpinner = false;
                                    }                            
                                }).bind(this), JSON.stringify(params));
                            }, time * 5000);
                        } else {
                            if(response.payload.aEMResponse){
                                var path = JSON.stringify(response.payload.aEMResponse.path);
                                var fileName = JSON.stringify(response.payload.aEMResponse.fileName);
                                var path1 = path.slice(1, -1);
                                var fileName1 = fileName.slice(1, -1);
                                if (response.targetUrl) {
                                    var labelUrl = response.targetUrl;
                                    let url = `${labelUrl}pathInAws=${path1}&fileName=${fileName1}`;
                                    let pdfWin = window.open('/apex/CorrespondencePage?fileName='+fileName1, "", "height=650,width=840");
                                    var time = 1;
                                    setTimeout(() => {
                                        this.searchReasonCode();
                                    }, time * 3000);
                                }
                            }
                            else {
                                helper.showToast(this, 'Error', 'AEMResponse returned is :'+response.payload.aEMResponse, 'error', 'dismissible');
                            }
                        }
                        this.toggleSpinner = false;
                    }
                    else{
                        if(response.errorMessage[0].errorMsg=='RETRY' && this.retryAttempts < 4){
                            setTimeout(() =>{
                                this.viewSelectedCorspd(corspdId);
                            }, time * 5000);
                        }else if(response.errorMessage[0].errorMsg=='RETRY' && this.retryAttempts >= 4){
                            helper.showToast(this, 'Error', 'Error in rendering letter in AEM. The number of attempts made to AEM: '+this.retryAttempts+'. Please Click on the Correspondence link again.', 'error','dismissable');
                            this.dispatchEvent(new CloseActionScreenEvent());
                            this.retryAttempts = 0;
                            this.toggleSpinner = false;
                        }else{
                            helper.showToast(this, 'Error', 'Error: '+ response.errorMessage[0].errorMsg, 'error','dismissable');
                            this.dispatchEvent(new CloseActionScreenEvent());
                            this.toggleSpinner = false;
                        }
                    }                    
                }
                else{
                    helper.showToast(this,'Error','Error in calling server side action.', 'error','dismissable');
                    this.toggleSpinner = false;
                }
            }).bind(this), JSON.stringify(param));
        }
    }
    createCorspdMan() {
        this.openManCorspd = true;
    }
    printCorspd() {
        this.toggleSpinner = true;
        let printCorspdId = [];
        let table = this.template.querySelector('lightning-datatable')
        let selectedRows = table.getSelectedRows();
        if(selectedRows.length > 20){
            helper.showToast(this, 'Error', 'Correspondence Print limit exceeded. Maximum of 20 Correspondences can be selected to print.', 'error','dismissable');
            this.toggleSpinner = false;
            return;
        }
        else if(selectedRows.length > 0){
            for (var i = 0; i < selectedRows.length; i++) {
                printCorspdId.push(selectedRows[i].sfID);
            }
            this.printSelected(printCorspdId);
        }else if (selectedRows.length == 0) {
            helper.showToast(this, 'Error', 'Please Select At Least One Correspondence to Print', 'error','dismissable');
            this.toggleSpinner = false;
        }
    }
    printSelected(printCorspdId){
        var stopSpinner = true;
        var time = 1; //in second
        let params= { lstCorspdId: printCorspdId};
        helper.callServer(this, 'corspdPrintQueue', 'processCorspdPrint', (function (response) {
            if (response) {
                if(response.returnStatus == 'Success'){
                    if (response.CountOfRequestedRecordsInPrint ){
                        helper.showToast(this,'Error','One or more correspondence selected is not in generated status. Please ensure correspondence selected are in generated status in order to print', 'error','dismissable');
                        setTimeout(() => {
                            this.searchReasonCode();
                        }, time * 1000);
                        stopSpinner = false;
                    }else{
                        if(response.payload.aem ){
                            var path = JSON.stringify(response.payload.aem.path);
                            var fileName = JSON.stringify(response.payload.aem.assembledFilename);
                            var path1 = path.slice(1, -1);
                            var fileName1 = fileName.slice(1, -1);
                            if (response.targetUrl){
                                var labelUrl = response.targetUrl;
                                var url = labelUrl + 'pathInAws=' + path1 + '&fileName=' + fileName1;
                                var pdfWin= window.open("/apex/CorrespondencePage?fileName="+fileName1, "", "height=650,width=840");
                                setTimeout(() => {
                                    this.searchReasonCode();
                                }, time * 5000);
                                stopSpinner = false;
                            }
                        }
                    }
                }
                else{
                    if(typeof response.errorMessage[0].errorMsg=='string'){
                        helper.showToast(this,'Error',response.errorMessage[0].errorMsg, 'error','dismissable');
                        this.selectedRows = [];
                    } else {
                        helper.showToast(this,'Error',JSON.stringify(response.errorMessage[0].errorMsg), 'error','dismissable');
                        this.selectedRows = [];
                    }
                    this.dispatchEvent(new CloseActionScreenEvent());
                    setTimeout(() => {
                        this.searchReasonCode();
                    }, time * 5000);
                    stopSpinner = false;
                }
            } else {
                helper.showToast(this,'Error','Error in calling server side action.', 'error','dismissable');
                stopSpinner = false;
            }
            this.toggleSpinner = stopSpinner;
        }).bind(this), JSON.stringify(params));
    }
    clickNext() {
        var currentNumber = this.currentPageNo;
        var length = this.searchResult.length;
        var searchResultCount = this.searchResultCount;
        currentNumber+=1;
        if(!(currentNumber<=Math.ceil(length/searchResultCount))){
            return;
        }
        this.currentPageNo = currentNumber;        
        this.setRecordsToDisplay();
    }
    clickPrevious() {
        var currentNumber = this.currentPageNo;
        if(currentNumber==1){
            return;
        }
        this.currentPageNo = --currentNumber;
        this.setRecordsToDisplay();
    }
    setRecordsToDisplay(){
        var start = (this.currentPageNo - 1) * this.searchResultCount;
        var end = start + this.searchResultCount;
        this.recordsToDisplay = this.encapsulatedSearchResult.slice(start, end);
    }
    navigateScreen(){
        this.encapsulatedSearchResult = [];
        this.recordsToDisplay = [];
        this.numberOfPages = 0;
        this.currentPageNo = 0;
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Printed_Corspd_View'
            }
        });
    }
    closeModal(event){
        event.stopPropagation();
        this.openManCorspd = false;
        setTimeout(() => {
            this.openManCorspd = false; 
        }, 0); 
    }
    handleSort(event){
        this.sortedField = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortedField, this.sortDirection);
    }
    sortData(fieldname, sortDirection) {
        let parseData = JSON.parse(JSON.stringify(this.encapsulatedSearchResult));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = sortDirection === 'asc' ? 1: -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; 
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.encapsulatedSearchResult = parseData;
        this.setRecordsToDisplay();
    }
}