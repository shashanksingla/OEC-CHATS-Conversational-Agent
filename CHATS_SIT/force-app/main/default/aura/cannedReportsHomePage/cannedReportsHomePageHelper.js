({
    sortBy: function(component, id) {
        var sortAsc = component.get("v.sortAsc"),
            field = id,
            sortField = id,
            records = component.get("v.encapsulatedSearchResult"),
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
        component.set("v.encapsulatedSearchResult", sortedRecord);
    },
    
    initHelper: function(component, event, helper){
        /*var reportTypeAction = component.get("c.getReportType");
        reportTypeAction.setCallback(this, function(response){
            var state = response.getReturnValue();
            
            if(component.isValid() && response.getState() === "SUCCESS"){
                var picklistValueArray = response.getReturnValue();
                picklistValueArray.unshift('Select an Option');
                component.set("v.lstOfPicklistValues",picklistValueArray); 
            }
        });        
        $A.enqueueAction(reportTypeAction);*/
        var reportNameAction = component.get("c.getAllReportName");
        reportNameAction.setCallback(this, function(response){
            var state = response.getReturnValue();
            if(component.isValid() && response.getState() === "SUCCESS"){
                component.set("v.lstOfPicklistNames",response.getReturnValue());
            }
        });        
        $A.enqueueAction(reportNameAction);
        var fetchUserdataAction = component.get("c.getAvailableReportsOnHomepage")
        fetchUserdataAction.setCallback(this, function(response){
            var lsr = response.getReturnValue();
            if(lsr.isSuccessful){
                component.set("v.encapsulatedSearchResult",lsr.objectData.test);  
            }
        });        
        $A.enqueueAction(fetchUserdataAction);
    },
    
    navigate2RequestReportHelper : function(component, event, helper){
        var repType = component.get("v.reportType");
        var repName = component.get("v.reportName");
        var reportObject = component.get("v.encapsulatedSearchResult");
        var validRecord = true;
        var nameField = component.find("reportName");
        var campname = nameField.get("v.value");
        if (campname === null || campname === undefined || campname === 'None'){
            validRecord = false;
            nameField.set("v.errors", [{message:"Report name is a required field."}]);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : "Error!",
                type: "error",
                message: 'You must choose a report in the report name field.'
            });
            toastEvent.fire(); 
        }else{
            var action = component.get("c.processViewResults");
            action.setParams({
                reportType: component.get("v.reportType"),
                reportName: component.get("v.reportName")
            });
            action.setCallback(this, function(response){
                var state = response.getReturnValue();
                if(component.isValid() && response.getState() === "SUCCESS"){ 
                    component.set("v.searchResults",state.objectData.test);
                    var reportObject = component.get("v.searchResults");
                    for(var obj in reportObject){
                        if(reportObject[obj].Report_Name__c === repName){
                            // Start: Added for CCCAP-3230 by Rishav
                            var selectedCounty;
                            if(!$A.util.isEmpty(state.objectData.userCountyMap) && reportObject[obj].isCountyAutoAssigned__c == true){
                                selectedCounty = state.objectData.userCountyMap.Owner_County__c;
                            }
                            // End: CCCAP-3230
                            component.set("v.searchResults", reportObject[obj]);
                            var event = $A.get("e.force:navigateToComponent");
                            // Added 'selectedCounty' parameter below for CCCAP-3230 by Rishav
                            event.setParams({
                                componentDef: "c:reportRequestScreen", 
                                componentAttributes: {
                                    selectedReport : reportObject[obj],
                                    selectedCounty : selectedCounty
                                }
                            });
                            event.fire(); 
                        }
                    }
                }
            });        
            $A.enqueueAction(action);  
        }  
    },
    
    onChangeHelper: function(component, event, helper){
        var reportType = component.find("reportType").get("v.value");
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
            }
        });        
        $A.enqueueAction(reportNameAction); 
    },
    
    navigate2ReportInboxHelper: function(component, event, helper){
        var event = $A.get("e.force:navigateToComponent");
        event.setParams({
            componentDef: "c:cannedReportInboxScreen", 
        });
        event.fire(); 
    }
})