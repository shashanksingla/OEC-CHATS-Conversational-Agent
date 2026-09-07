/**
 * Created by gautrivedi on 6/28/18.
 * Modified by ckuester on 8/6/18
 * 	-added alternative error message functionality
 */
({
    retrieveExtObjData: function(component, event, helper){
        debugger;
        var action2 = component.get("c.fetchRelatedObjectdata");
        action2.setParams({"recordId": component.get("v.recordId") });
        action2.setCallback(this, function(response) {
            var spinner = component.find("mySpinner");
            $A.util.addClass(spinner, "slds-hide");
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                console.log('res---'+JSON.stringify(res));
                if(!$A.util.isEmpty(res)){
                    console.log('res.fetchedEncumberence--'+JSON.stringify(res.objectData.authEncumbranceRelatedList));
                    component.set("v.listRecordsToDisplay", res.objectData.authEncumbranceRelatedList);
                    component.set("v.recCount", res.objectData.authEncumbranceRelatedList.length);
                }
            }else if(response.getState() === "INCOMPLETE"){
                component.set("v.listRecordsToDisplay", []);
                component.set("v.recCount", 0);
                var error = 'Server could not be reached due to a network issue.';
                this.showErrorToast(error, 'SECTION NOTICE: '+component.get('v.relatedListHeader'), 'warning');
            }else {
                component.set("v.listRecordsToDisplay", []);
                component.set("v.recCount", 0);
                //case: state was "ERROR"
                var errors = response.getError();
                console.log(response);
                this.showErrorToast(errors[0].message, state+': '+component.get('v.relatedListHeader'), 'error');
            }
        });
        $A.enqueueAction(action2);
    },
    showErrorToast: function(message, state, type){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : state,
            message: message,
            duration:' 3000',
            key: 'info_alt',
            type: type,
            mode: 'pester'
        });
        toastEvent.fire();
    },
    sortBy: function(component, id) {
        debugger;
        var sortAsc = component.get("v.sortAsc"),
            field = id,
            sortField = id,
            records = component.get("v.listRecordsToDisplay"),
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
            console.log('a-----'+a);
            console.log('a-----'+a.field);
            console.log('a-----'+field);
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || (a[field] < b[field]);
            return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });
        
        
        for (var i = 0; i < records.length; i++) {
            sortedRecord.push(records[dummyRecordArray[i].parentIndex]);
        }
        console.log('------records', records);
        component.set("v.sortAsc", sortAsc);
        component.set("v.listRecordsToDisplay", sortedRecord);
    },
    retrieveExtArchivedData: function(component, event, helper,month,year){
        debugger;
        var action2 = component.get("c.fetchRelatedArchivedObjectdata");
        action2.setParams({"recordId": component.get("v.recordId"),"monthStr":month,"yearStr":year });
        action2.setCallback(this, function(response) {
            var spinner = component.find("mySpinner");
            $A.util.addClass(spinner, "slds-hide");
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                console.log('res---'+JSON.stringify(res));
                if(!$A.util.isEmpty(res)){
                    console.log('res.fetchedEncumberence--'+JSON.stringify(res.objectData.authEncumbranceRelatedList));
                    component.set("v.listRecordsToDisplay", res.objectData.authEncumbranceRelatedList);
                    component.set("v.recCount", res.objectData.authEncumbranceRelatedList.length);
                    if(component.get("v.isMonthYrBasedSearch")){
                        component.set("v.showMore",false);
                        debugger;
                    }
                }
            }else if(response.getState() === "INCOMPLETE"){
                component.set("v.listRecordsToDisplay", []);
                component.set("v.recCount", 0);
                var error = 'Server could not be reached due to a network issue.';
                this.showErrorToast(error, 'SECTION NOTICE: '+component.get('v.relatedListHeader'), 'warning');
            }else {
                component.set("v.listRecordsToDisplay", []);
                component.set("v.recCount", 0);
                //case: state was "ERROR"
                var errors = response.getError();
                console.log(response);
                this.showErrorToast(errors[0].message, state+': '+component.get('v.relatedListHeader'), 'error');
            }
        });
        $A.enqueueAction(action2);
    },
})