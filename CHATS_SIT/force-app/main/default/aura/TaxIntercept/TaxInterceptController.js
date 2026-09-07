({
    doInit : function(component, event, helper) {
        document.title = "State Tax Intercept"; // Browser tab title
        var searchWrapper = {};
        searchWrapper.taxRecord = {'sobjectType':'Tax_Intercept__c'};
        component.set("v.searchWrapper", searchWrapper);
        helper.setTaxYear(component);
    },
    
    // Clearing filters and results
    clearScreen : function(component, event, helper) {
        var searchWrapper = {};
        searchWrapper.taxRecord = {'sobjectType':'Tax_Intercept__c'};
        component.set("v.searchWrapper", searchWrapper);
        component.set("v.searchResults", []);
        $A.get('e.force:refreshView').fire();
    },
    
    search : function(component, event, helper) {
        helper.searchHelper(component, event, helper);
    },
    
    // Rendering 'TaxInterceptDetails' cmp with record details
    openDetailsModal : function(component, event, helper) {
        var taxRecord = event.target.dataset.index;
        var searchResults = component.get("v.searchResults");
        var selectedRecord = searchResults[taxRecord];
        var userCounty = component.get("v.userCounty");
        var thisYear = new Date().getFullYear(); // Added this line and one condition below by Rishav for CCCAP-4908
        if(component.get("v.isAdmin") || (component.get("v.removeAccess") && (userCounty.includes((selectedRecord.County__r.CDE_COUNTY__c).toString()) || userCounty.includes('66')) && thisYear.toString() == selectedRecord.Tax_Year__c)) {
            component.set("v.removeAccessSingle", true);
        } else {
            component.set("v.removeAccessSingle", false);
        }
        component.set("v.selectedRecord", selectedRecord);
        component.set("v.removeReason", selectedRecord.Remove_Reason__c);
        component.set("v.showDetailsModal", true);
    },
    
    // Table column resizing
    calculateWidth : function(component, event, helper) {
        var childObj = event.target
        var parObj = childObj.parentNode;
        var count = 1;
        //parent element traversing to get the TH
        while(parObj.tagName != 'TH') {
            parObj = parObj.parentNode;
            count++;
        }
        //to get the position from the left for storing the position from where user started to drag
        var mouseStart=event.clientX;
        component.set("v.mouseStart",mouseStart);
        component.set("v.oldWidth",parObj.offsetWidth);
    },
    
    // Table column resizing
    setNewWidth : function(component, event, helper) {
        var childObj = event.target
        var parObj = childObj.parentNode;
        var count = 1;
        //parent element traversing to get the TH
        while(parObj.tagName != 'TH') {
            parObj = parObj.parentNode;
            count++;
        }
        var mouseStart = component.get("v.mouseStart");
        var oldWidth = component.get("v.oldWidth");
        //To calculate the new width of the column
        var newWidth = event.clientX- parseFloat(mouseStart)+parseFloat(oldWidth);
        parObj.style.width = newWidth+'px'; //assign new width to column
    },
    
    // Table column sorting
    sortbyColumn: function(component, event, helper) {
        var dataToSort = component.get("v.searchResults");
		if(dataToSort != null && dataToSort != undefined){
         var idToSort = event.target.id;
         if(undefined !== idToSort && "" !==idToSort){
        	helper.sortByHelper(component, idToSort);
        	}
         }
    }
})