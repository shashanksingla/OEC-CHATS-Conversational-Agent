({
    
    initHelper: function(component, helper) {
        var action = component.get('c.getInitReportRequestData');
        action.setParams({
            reportType: 'None'
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var res=response.getReturnValue();
            if (component.isValid() && state == 'SUCCESS') {
                if(!$A.util.isEmpty(res) && !$A.util.isEmpty(res.objectData)){
                    if(!$A.util.isEmpty(res.objectData.todayDate)){
                        component.set("v.endDate",res.objectData.todayDate);
                    }
                    if(!$A.util.isEmpty(res.objectData.todayMinus30Days)){
                        component.set("v.beginDate",res.objectData.todayMinus30Days);
                    }
                    if(!$A.util.isEmpty(res.objectData.user)){
                        component.set("v.userInfo",res.objectData.user);
                    }
                    if(!$A.util.isEmpty(res.objectData.reportTypeResult)){
                        component.set("v.lstOfPicklistValues",this.merge('None',res.objectData.reportTypeResult));
                    }
                    if(!$A.util.isEmpty(res.objectData.reportTypeName)){
                        component.set("v.lstOfPicklistNames",res.objectData.reportTypeName);
                    }
                    //this.viewResults(component, helper);
                } 
            }
        });        
        $A.enqueueAction(action);
    },
    navigateToReportHomeHelper: function(component, helper){
        var event = $A.get("e.force:navigateToComponent");
        event.setParams({
            componentDef: "c:cannedReportsHomePage"  
        });
        event.fire();  
    },
    
    viewResults: function(component, helper) {
        component.set("v.showSpinner", true);
        var input = component.get("v.reportRequestObj");
        var action = component.get("c.processViewResults");
        action.setParams({
            county: input.County__c, 
            reportType: component.get("v.reportType"),
            reportName: component.get("v.reportName"),
            requestedBy: component.get("v.userInfo").Id,
            requestStatus: input.Status__c,
            beginDtae: component.get("v.beginDate"),
            endDate: component.get("v.endDate")
        });
        action.setCallback(this, function(response) {
            var state = response.getReturnValue();
            if(component.isValid() && response.getState() === "SUCCESS"){
                state.objectData.test.forEach( item => {
                    if(item.County__c){
                        item.County__c = item.County__c.replace(/;/g, '; ');
                    }
                }) 
                component.set("v.searchResults",state.objectData.test);
                if (component.get("v.searchResults").length > 200) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Warning!",
                        "type": 'warning',
                        "message": "More records are available. Please refine your search criteria to limit the results."
                    });
                    toastEvent.fire();
                }else if(component.get("v.searchResults").length == 0){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        type:"error",
                        "message": "No Canned Request Report Records Exists for the given Input."
                    });
                    toastEvent.fire();
                }
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    },
    
    onChangeHelper: function(component, event, helper){
        component.set("v.showSpinner", true);
        var reportType = component.get("v.reportRequestObj.Report_Type__c");
        var reportName = component.find("reportName").get("v.value");
        component.set("v.reportType",reportType);
        component.set("v.reportName",reportName);
        var reportNameAction = component.get("c.getReportName");
        reportNameAction.setParams({
            'reportType' : reportType
        });
        reportNameAction.setCallback(this, function(response){
            var state = response.getReturnValue();
            if(component.isValid() && response.getState() === "SUCCESS"){
                component.set("v.reportName",null);
                component.set("v.lstOfPicklistNames",response.getReturnValue());
                component.set("v.showSpinner", false);
            }
        });        
        $A.enqueueAction(reportNameAction); 
    },
    
    checkCustomValidations: function(component, event, helper){
        var isValid= true;
        var currentDate = new Date();
        var cmpBeginDate = component.get('v.beginDate');
        var cmpEndDate = component.get('v.endDate');
        var beginDate= new Date(component.get('v.beginDate'));
        var endDate= new Date(component.get('v.endDate'));
        var earlierBeginDate =new Date(currentDate.getFullYear()-4,currentDate.getMonth(),currentDate.getDate()) ;
        var earlierEndDate = new Date(beginDate.getFullYear()+1,beginDate.getMonth(),beginDate.getDate()) ;
        if( beginDate > currentDate) 
        {	component.find('cmpBeginDate').set('v.message', 'Begin Date should be less than or equals to today.') ;
         isValid = false;
        }else if(beginDate < earlierBeginDate) 
        {	component.find('cmpBeginDate').set('v.message', 'Begin Date cannot be earlier than 4 years.') ;
         isValid = false;
        }else{
            component.find('cmpBeginDate').set('v.message', '') ; 
        }
        if(endDate > currentDate) 
        {	component.find('cmpEndDate').set('v.message', 'End Date should be less than or equals to today.') ;
         isValid = false;
        }else if(endDate < beginDate) 
        {component.find('cmpEndDate').set('v.message', 'End Date cannot be less than begin date.') ;
         isValid = false;
        }else if(endDate > earlierEndDate)
        {component.find('cmpEndDate').set('v.message', 'End Date cannot be more than 1 Year after begin date.') ;
         isValid = false;
        }
            else{
                component.find('cmpEndDate').set('v.message', '') ; 
            }
        if(endDate==null || endDate==undefined || endDate==''){
            component.find('cmpEndDate').set('v.message', 'Complete the field') ;
            isValid = false;
        }
        if(beginDate==null || beginDate==undefined || beginDate==''){
            component.find('cmpBeginDate').set('v.message', 'Complete the field') ;
            isValid = false;
        }
        return isValid;
    },
    
    sortBy: function(component, id) {
        component.set("v.showSpinner", true);
        var sortAsc = component.get("v.sortAsc"),
            field = id,
            sortField = id,
            records = component.get("v.searchResults"),
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
        component.set("v.searchResults", sortedRecord);
        component.set("v.showSpinner", false);
    },
    viewSelectedReport :function(component,event, helper,reportReqExternalId,requestNameValue,index){
        var fileName;
        //added for CCCAP-13790 by Shashank
        let cannedReport ={};
        if(index>-1){
            cannedReport = component.get('v.searchResults')[index];
        }
        console.log('reportReqExternalId--'+reportReqExternalId);
        if(!$A.util.isEmpty(reportReqExternalId) && reportReqExternalId =='RE210'){
             //added below logic for file extension for CCCAP-13790 by Shashank
            let extension_210 = '.csv';
            let dec25ReleaseDate = new Date($A.get("$Label.c.RE210_upgradeEffective")); // June'30 Release 06-30-2025
            let dateGen = new Date(cannedReport.Date_Generated__c);
            if(dateGen >= dec25ReleaseDate){
                extension_210 ='.xlsx';
            }
            fileName = reportReqExternalId+'_'+requestNameValue+extension_210;
         }else if(!$A.util.isEmpty(reportReqExternalId) && reportReqExternalId =='RE803'){
             fileName = reportReqExternalId+'_'+requestNameValue+'.pdf';
         }else{
              fileName = reportReqExternalId+'_'+requestNameValue+'.xlsx';
         }
        console.log('fileName---'+fileName);
       // fileName = 'RE210_'+requestNameValue+'.xlsx';
       // var pdfWin= window.open("/apex/ViewCannedReport?fileName="+fileName, "", "height=650,width=840");

       component.set("v.showSpinner", true);

        //start- added by Az
        var action = component.get('c.getReportResponse');
        action.setParams({
            fileName: fileName
        });
        
        action.setCallback(this, function(response) {

            component.set("v.showSpinner", false);
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res=response.getReturnValue();
                if(res.isSuccessful){
                    if(res.objectData.reportIdUrl){
                        window.open(res.objectData.reportIdUrl, "_blank");
                    }
                }else{
                   
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        type:"error",
                        "message": res.errorMessage
                    });
                    toastEvent.fire();
                }

            }
        }); 
        $A.enqueueAction(action);
        //End- added by Az
        /*
        window.setTimeout(
            $A.getCallback(function() {
                pdfWin.close()
            }), 100000
        );*/
    },
    merge : function(obj1,obj2){
        var obj3 = {};
        for (var attrname in obj1) { obj3[attrname] = obj1[attrname]; }
        for (var attrname in obj2) { obj3[attrname] = obj2[attrname]; }
        return obj3;}
})