({
    // Tax Year field value and assignment
    setTaxYear : function(component) {
        var today = new Date();
        var currentYear = today.getFullYear();
        var currentYearOptions = component.get("v.taxYearOptions");
        var taxYearOptions = [];
        for(var i=currentYearOptions[0]; i<=currentYear; i++){
            taxYearOptions.push(i.toString());
        }
        component.set("v.taxYearOptions", taxYearOptions);
        component.set("v.searchWrapper.taxRecord.Tax_Year__c", currentYear);
    },
    
    searchHelper : function(component, event, helper) {
        component.set("v.showSpinner", true);
        var searchWrapper = component.get("v.searchWrapper");
        var requiredFieldsVerified = helper.verifyRequiredFields(component);
        if(requiredFieldsVerified){
            var action = component.get("c.searchTaxIntercepts");
            action.setParams({searchWrapperString : JSON.stringify(searchWrapper)});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var res = response.getReturnValue();
                    component.set('v.searchResults', res.objectData.taxInterceptList);
                    component.set('v.searchResultCount', res.objectData.recordCount);
                    component.set("v.removeAccess", res.objectData.hasRemoveAccess);
                    component.set("v.userCounty", res.objectData.userCounty);
                    component.set("v.isAdmin", res.objectData.isAdmin);
                    component.set("v.sortAsc", true);
                    component.set("v.sortField", "Name");
                    if(res.objectData.taxInterceptList.length == 0){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "type":'error',
                            "message": 'No results found.'
                        });
                        toastEvent.fire();
                    }
                } else if(state === "ERROR") {
                    var errors = response.getError();
                    if(errors){
                        if (errors[0] && errors[0].message){
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type":'error',
                                "message": errors[0].message
                            });
                            toastEvent.fire();
                        }
                    }
                }
                component.set("v.showSpinner", false);
            });
            $A.enqueueAction(action);
        } else {
            component.set("v.showSpinner", false);
        }
    },
    
    // Table column sorting
    sortByHelper : function(component, id) {
        var sortAsc = component.get("v.sortAsc"),
            field = id,
            sortField = id,
            records = component.get("v.searchResults"),
            dummyRecordArray = [],
            sortedRecord = [];
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
    },
    
    // Show error if required fields empty
    verifyRequiredFields : function(component) {
        var searchWrapper = component.get("v.searchWrapper");
        var isVerified = true;
        var selectedCounty = searchWrapper.selectedCounty;
        if(!selectedCounty){
            isVerified = false;
        } else if(selectedCounty.length == 0) {
            isVerified = false;
        }
        if(isVerified){
            return true;
        } else {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "type":'error',
                "message": 'Please fill all the mandatory fields'
            });
            toastEvent.fire();
            return false;
        }
    }
})