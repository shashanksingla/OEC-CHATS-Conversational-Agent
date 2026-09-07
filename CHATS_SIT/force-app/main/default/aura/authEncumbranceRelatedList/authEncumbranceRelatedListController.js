({
    doInit : function(cmp, event, helper) {
    	if(!cmp.get("v.isNavigateToCmp")){
            var urlStr = window.location.origin + window.location.pathname;
            cmp.set('v.showMore', urlStr.endsWith('view'));
        }
        if(!cmp.get("v.isMonthYrBasedSearch")){
            helper.retrieveExtObjData(cmp, event, helper);
        }else{
            var date = new Date();
            console.log('month and year---'+date.getMonth()+':'+date.getFullYear());
            debugger;
           helper.retrieveExtArchivedData(cmp, event, helper,date.getMonth(),date.getFullYear()); 
        }
    },
    navigateToChilComponent : function(component, event, helper) {
        debugger;
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:authEncumbranceRelatedList",
            componentAttributes: {
                sortAscDsc : component.get("v.sortAscDsc"),
                orderByField : component.get("v.orderByField"),
                recCount : component.get("v.recCount"),
                listRecordsToDisplay : component.get("v.listRecordsToDisplay"),
                relatedListHeader : component.get("v.relatedListHeader"),
                parentObjIdentifier : component.get("v.parentObjIdentifier"),
                childApiName : component.get("v.childApiName"),
                recordId: component.get("v.recordId"),
                isNavigateToCmp:true,
                showMore:false
            }
        });
        console.log('0000000---------'+component.get("v.showMore"));
        if(component.get("v.showMore"))
            evt.fire();
        else
            window.history.back();
    },
    sortColumn: function(cmp, event, helper){
        if(!cmp.get("v.showMore")){
            cmp.set("{!v.orderByField}", event.target.id);
            var sortOrder = !cmp.get("v.sortAscDsc") || cmp.get("v.sortAscDsc") === 'ASC'?'DESC':'ASC';
            console.log('sortOrder---'+sortOrder);
            cmp.set("{!v.sortAscDsc}", sortOrder);
            helper.sortBy(cmp,event.target.id);
           // $A.util.toggleClass(cmp.find("mySpinner"), "slds-hide");
        }
    },
    navigateToDetail : function(component, event, helper){
        var externalId =event.currentTarget.id;
        console.log('externalId--'+externalId);
        var action2 = component.get("c.getAuthEncumbRecordId");
        action2.setParams({"externalId": externalId });
        action2.setCallback(this, function(response) {
            var spinner = component.find("mySpinner");
           // $A.util.toggleClass(spinner, "slds-hide");
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                console.log('res---'+JSON.stringify(res));
                if(!$A.util.isEmpty(res)){
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": res,
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
            }else if(response.getState() === "INCOMPLETE"){
                
            }else {
                
            }
        });
        $A.enqueueAction(action2);
    },
    getRequestedData: function(cmp, event, helper) {
        debugger;
         var params = event.getParam('arguments');
        debugger;
        if (params) {
            var spinner = cmp.find("mySpinner");
            $A.util.removeClass(spinner, "slds-hide");
            $A.util.addClass(spinner, "slds-show");
            var selectedMonth = params.selectedMonth;
            var selectedYear = params.selectedYear;
            console.log('selectedYear--'+selectedYear+'--selectedMonth:'+selectedMonth);
            debugger;
            helper.retrieveExtArchivedData(cmp, event, helper,selectedMonth,selectedYear);
        }
        
    },
})