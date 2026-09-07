({
    doInit: function(component, event, helper){
        helper.initHelper(component, event, helper);   
    },
    
    navigate2RequestReport : function (component, event, helper) {
        helper.navigate2RequestReportHelper(component, event, helper); 
    },    
    
    navigate2ReportInbox : function (component, event, helper) { 
    	helper.navigate2ReportInboxHelper(component, event, helper); 
    },
    
    onchangeEvent: function(component, event, helper) {
        helper.onChangeHelper(component, event, helper);
    },
    
    sortbyColumn: function(component, event, helper) {
    	var dataToSort = component.get("v.encapsulatedSearchResult");
		if(dataToSort != null && dataToSort != undefined){
         var idToSort = event.target.id;
         if(undefined !== idToSort && "" !==idToSort){
        	helper.sortBy(component, idToSort);
        	}
         }
    }
    
})