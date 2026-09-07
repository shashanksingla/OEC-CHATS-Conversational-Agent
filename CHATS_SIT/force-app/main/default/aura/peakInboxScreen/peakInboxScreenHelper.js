({
    initHelper : function(component, event, helper){
        var peakInboxWrapper = {};
        var cmpFromDate = component.get('v.peakInboxWrapper.fromDate');
        var cmpToDate = component.get('v.peakInboxWrapper.toDate');
        peakInboxWrapper.searchType = 'StringSearch';
        peakInboxWrapper.status = 'NEW;PEN;';
        component.set("v.peakInboxWrapper", peakInboxWrapper);
        var options= component.get("v.options_");
         options.push({
                        'label' : '--None--',
                        'value' : null,
                        'class' : 'optionClass'
                    });
        var action = component.get('c.getInitPeakRequestData');
        
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var res=response.getReturnValue();
            if (component.isValid() && state == 'SUCCESS') { 
                if(!$A.util.isEmpty(res) && !$A.util.isEmpty(res.objectData)){
                    
                    if(!$A.util.isEmpty(res.objectData.todayMinus30Days)){
                        component.set("v.peakInboxWrapper.fromDate",res.objectData.todayMinus30Days);
                    }
                    if(!$A.util.isEmpty(res.objectData.todayDate)){
                        component.set("v.peakInboxWrapper.toDate",res.objectData.todayDate);
                    }
                    if(!$A.util.isEmpty(res.objectData.user)){
                        component.set("v.peakInboxWrapper.county",res.objectData.user+';');
                    }
                    if(!$A.util.isEmpty(res.objectData.statusPickList)){
                        options = options.concat(res.objectData.statusPickList.map(function(v) {
                        var option = {
                            'label' : v.label,
                            'value' : v.value,
                            'class' : 'optionClass',
                            'selected' : false								
                        };
                        if(v.value=='NEW'|| v.value=='PEN')
                            option.selected=true;
                        return option;
                    }));
                    options = options.filter(val=> val.value!='INC');
                    }

                    var peakDefaultResult = component.get('v.peakInboxWrapper');
                    console.log(JSON.stringify(options));
                    component.set("v.options_",options);
                    component.set('v.toDisplatDefault',true);
                    component.set("v.initDone", true);                    
                    this.viewPeakHelper(component, helper);
                } 
            }
        });        
        $A.enqueueAction(action);
        
    },
    
    viewPeakHelper : function(component, helper){
        component.set("v.showSpinner", true);
        var pageSize = component.get("v.pageSize");
        var peakInboxWrapper =component.get("v.peakInboxWrapper");
        
        if(peakInboxWrapper.fromDate !=null && peakInboxWrapper.fromDate.trim() == '' ){
            peakInboxWrapper.fromDate = null;
        }
        if(peakInboxWrapper.toDate !=null && peakInboxWrapper.toDate.trim() == '' ){
            peakInboxWrapper.toDate = null;
        }
        var action = component.get("c.processViewResults");
        action.setParams({ peakSearchWrapperStr : JSON.stringify(peakInboxWrapper) });
        action.setCallback(this, function(response) {
            var state = response.getReturnValue();
            if(component.isValid() && response.getState() === "SUCCESS"){
                component.set('v.FinalList',state.objectData.test);
                var paginationList = [];
                var items = component.get('v.FinalList').length;
                component.set("v.totalSize", items);
                component.set("v.start",0);
                component.set("v.end",pageSize-1);
               
                if(items < pageSize){
                    paginationList= state.objectData.test;
                }
                else{
                    for(var i=0; i< pageSize; i++){
                        paginationList.push(state.objectData.test[i]);
                    } 
                }
                component.set('v.peakResultWrapper',paginationList);

                var navigtonCheck = component.get('v.navigationCheck');
                if(items == 0 && !component.get('v.navigationCheck'))
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        type:"error",
                        "message": "No peak application results found. Please refine the filter."
                    });
                    toastEvent.fire();
                }else{
                    component.set('v.navigationCheck',false); 
                }
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    },
    
    checkCustomValidations: function(component, event, helper){
        var isValid= true;
        var currentDate = new Date();
        
        var cmpFromDate = component.get('v.peakInboxWrapper.fromDate');
        var fromDate;
        var cmpToDate = component.get('v.peakInboxWrapper.toDate');
        var toDate;
        if(cmpFromDate != null){
            fromDate= new Date(component.get('v.peakInboxWrapper.fromDate'));
            var earlierToDate = new Date(fromDate.getFullYear(),fromDate.getMonth(),fromDate.getDate()+31) ;
        }
        if(cmpToDate != null){
            toDate= new Date(component.get('v.peakInboxWrapper.toDate')); 
        }
        
        var earlierFromDate =new Date(currentDate.getFullYear()-4,currentDate.getMonth(),currentDate.getDate()) ;
        var ssnNumber = component.get('v.peakInboxWrapper.ssn');

        
        if((fromDate!=null || fromDate!=undefined || fromDate!='') && fromDate > currentDate) 
        {	component.find('fromDate').set('v.message', 'Application Received From Date should be less than today.') ;
         isValid = false;
        }else if((fromDate!=null || fromDate!=undefined || fromDate!='') && fromDate < earlierFromDate) 
        {fromDate != null && component.find('fromDate').set('v.message', 'Application Received From Date cannot be earlier than 4 years.') ;
         isValid = false;
        }else{
            component.find('fromDate').set('v.message', '') ; 
        }
        if((toDate!=null || toDate!=undefined || toDate!='') && toDate > currentDate) 
        {component.find('toDate').set('v.message', 'Application Received To Date should be less than today.') ;
         isValid = false;
        }else if((toDate!=null || toDate!=undefined || toDate!='') && toDate < fromDate) 
        {component.find('toDate').set('v.message', 'Application Received To Date cannot be less than Application Received From Date.') ;
         isValid = false;
        }else if((toDate!=null || toDate!=undefined || toDate!='') && toDate > earlierToDate)
        {component.find('toDate').set('v.message', 'Application Received To Date cannot be more than 1 Month after Application Received From Date.') ;
         isValid = false;
        }else{
            component.find('toDate').set('v.message', '') ; 
        }
        /*if(toDate==null || toDate==undefined || toDate==''){
            component.find('toDate').set('v.message', 'Complete the field') ;
            isValid = false;
        }
        if(fromDate==null || fromDate==undefined || fromDate==''){
            component.find('fromDate').set('v.message', 'Complete the field') ;
            isValid = false;
        }*/
        if(ssnNumber != null){
            if(ssnNumber.length > 9){
                component.find('param-ssn').set('v.message', 'SSN Number cannot be greater than 9 digits. Please enter a valid SSN Number.') ;
                isValid = false;
            }else{
                component.find('param-ssn').set('v.message', '') ;  
            }
        }
        return isValid;
    },
    
    sortBy: function(component, id) {
        component.set("v.showSpinner", true);
        var sortAsc = component.get("v.sortAsc"),
            field = id,
            sortField = id,
            records = component.get("v.peakResultWrapper"),
            dummyRecordArray = [],
            sortedRecord = [];
        // dummyRecord will possess all 'PAYLOAD' Object from all records
        for (var i = 0; i < records.length; i++) {
            dummyRecordArray[i] = records[i];
            // Another additional attribute 'parentIndex' is added to keep track of actual index of the object
            dummyRecordArray[i].parentIndex = i;
        }
        sortAsc = sortField != field || !sortAsc;
        // dummyRecord Array is Sorted
        dummyRecordArray.sort(function(a, b) {
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || (a[field] < b[field]);
            return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });
        for (var i = 0; i < records.length; i++) {
            sortedRecord.push(records[dummyRecordArray[i].parentIndex]);
        }
        component.set("v.sortAsc", sortAsc);
        component.set("v.sortField", id);
        component.set("v.peakResultWrapper", sortedRecord);
        component.set("v.showSpinner", false);
    },
    returnPrevious : function(component, event){
        /*---Pagination previous Button Click--*/
        var wrapperList = component.get("v.FinalList");//All Account List
        var end = component.get("v.end");
        var start = component.get("v.start");
        var pageSize = component.get("v.pageSize");
        var paginationList = [];
        var paginationList = wrapperList.slice(start-pageSize,start);//Slicing List as page number
        start = start - pageSize;
        end = end - pageSize;
        component.set("v.start",start);
        component.set("v.end",end);
        component.set('v.peakResultWrapper', paginationList);
        var currentPageNumber= component.get('v.currentPageNumber')-1;//Current Page Number
        component.set('v.currentPageNumber',currentPageNumber);
    },
    returnNext : function(component, event)
    { /*---Pagination Next Button Click--*/
        var wrapperList = component.get("v.FinalList");//All Account List
        var end = component.get("v.end");
        var start = component.get("v.start");
        var pageSize = component.get("v.pageSize");
        var paginationList = [];
        var paginationList = wrapperList.slice(end+1,end+pageSize+1);//Slicing List as page number
        start = start + pageSize;
        end = end + pageSize;
        component.set("v.start",start);
        component.set("v.end",end);
        component.set('v.peakResultWrapper', paginationList);
        var currentPageNumber= component.get('v.currentPageNumber')+1;//Current Page Number
        component.set('v.currentPageNumber',currentPageNumber);
    },
    navigateToPDFCmp : function(component, event, helper) {
        var idx = component.get("v.selectedIDx");
        var navigtonCheck = component.get('v.navigationCheck');
        var navEvent = $A.get("e.force:navigateToComponent");

        if(navEvent){
            component.set("v.navigationCheck", true); 
            navEvent.setParams({
                componentDef : "c:viewPeakApplnPdf",
                componentAttributes: {
                    recordId : idx,
                    navigationCheck : component.get('v.navigationCheck')
                    
                }
            });
            navEvent.fire();
        }
        
        if(component.get('v.navigationCheck') == true){
            var navEvent = $A.get("e.force:navigateToComponent");
            if(navEvent){
                navEvent.setParams({
                    componentDef : "c:peakInboxScreen",
                    componentAttributes: {
                    	navigationCheck : component.get("v.navigationCheck"),
                        peakInboxWrapper: component.get("v.peakInboxWrapper"),
                        peakResultWrapper: component.get("v.peakResultWrapper"),
                        initRequired: false,
                        initDone: true,
                        options_:component.get("v.options_"),
                        FinalList:component.get('v.FinalList'),
                        totalSize:component.get("v.totalSize"),
                        start:component.get("v.start"),
                        end:component.get("v.end")
                    }
                });
                
                navEvent.fire();
            }
        }
        
    }
})