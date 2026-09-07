({
    doInit : function(component, event, helper) {
        helper.initHelper(component, helper);    
    },
    
    navigateToReportHome : function(component, event, helper) {
        helper.navigateToReportHomeHelper(component, helper);   
    },
    
    viewInboxReportResults : function(component, event, helper) {
        var isValid = helper.validateCurrentPage(component);
        if(isValid){
           helper.viewResults(component, helper); 
        }
    },
    
    onchangeEvent : function(component, event, helper) {
        helper.onChangeHelper(component, helper); 
        
    },
    
    reportIdLink : function (component, event, helper){
        var index = event.target.dataset.id; //added for CCCAP-13790 by Shashank
        var reportReqExternalId = event.target.id;
        var requestNameValue = event.target.text;
        helper.viewSelectedReport(component, event,helper, reportReqExternalId,requestNameValue,index);
    },
    
    sortbyColumn: function(component, event, helper) {
        var dataToSort = component.get("v.searchResults");
        if(dataToSort != null && dataToSort != undefined){
            var idToSort = event.target.id;
            if(undefined !== idToSort && "" !==idToSort){
                helper.sortBy(component, idToSort);
            }
        }
    }
})