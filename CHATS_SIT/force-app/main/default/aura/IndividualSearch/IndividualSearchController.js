({
    doInit : function(cmp, event, helper) {
        var indivSearchWrapper = {};
        indivSearchWrapper.indivRec = {'sobjectType':'T_SBSD_INDIV__c'};
        indivSearchWrapper.searchType = 'StringSearch';
        cmp.set("v.indivSearchWrapper", indivSearchWrapper);
                
        if(cmp.get("v.recordId")){
            var action1 = cmp.get("c.checkRejectedReferral");
            action1.setParams({"recordId":cmp.get("v.recordId")});
            action1.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var res =response.getReturnValue();
                    cmp.set("v.isRejectedReferralFlow", res.objectData.isRejectedReferral);
                    if(res.objectData.applnProcessQueueRec){
                        cmp.set("v.applnProcessQueueRec", res.objectData.applnProcessQueueRec);
                    }
                }
            });
            $A.enqueueAction(action1);            
        }
        helper.setNewCaseButtonVisibility(cmp, event, helper);
    },
    
    clearIndivs : function(cmp, event, helper) {
        var indivSearchWrapper = {};
        indivSearchWrapper.indivRec = {'sobjectType':'T_SBSD_INDIV__c'};
        indivSearchWrapper.searchType = 'StringSearch';
        cmp.set("v.indivSearchWrapper", indivSearchWrapper);
        cmp.set("v.searchResults",[]);
        cmp.set("v.stateRefresh",false);
        cmp.set("v.stateRefresh",true);
        $A.get('e.force:refreshView').fire();
    },
    
    searchIndivs : function(cmp, event, helper) {
        cmp.set("v.showSpinner", true);
        var temp =cmp.get("v.indivSearchWrapper");
        if(temp.indivRec.DTE_DOB__c == ''){
            temp.indivRec.DTE_DOB__c = undefined;
        }
        var criteriaVerified = helper.verifyCriteria(cmp, event, helper);;
        if(criteriaVerified){
            var action = cmp.get("c.searchIndividuals");
            action.setParams({ indivSearchWrapperStr : JSON.stringify(temp) });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var res =response.getReturnValue();
                    // Alert the user with the value returned 
                    // from the server
                    if(res.isSuccessful){
                        cmp.set('v.searchResults', res.objectData.listIndiv);
                        if(res.objectData.listIndiv.length ==0){
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type":'error',
                                "message": 'No results found.'
                            });
                            toastEvent.fire();
                            cmp.set("v.newCaseDisabled", false);
                            cmp.set("v.isNextBtnVisible", false);
                        } else {
                            cmp.set("v.newCaseDisabled", false);
                            cmp.set("v.isNextBtnVisible", false);
                        }
                    } else {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "type":'error',
                            "message": 'More than 2,000 records were returned. Please refine the search criteria.'
                        });
                        toastEvent.fire();
                        cmp.set("v.newCaseDisabled", true);
                    }
                    // You would typically fire a event here to trigger 
                    // client-side notification that the server-side 
                    // action is complete
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if(errors){
                        if (errors[0] && errors[0].message){
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams(errors[0].message);
                            toastEvent.fire();
                        }
                    } else {}
                    cmp.set("v.newCaseDisabled", true);
                }
                cmp.set("v.showSpinner", false);
            });
            $A.enqueueAction(action);
        } else {
            cmp.set("v.showSpinner", false);
        }
    },
    
    openRecordDetail : function(component, event, helper) {
        var recordId = event.currentTarget.dataset.item;
        helper.redirectToLightningComponent("c:individualSearchDetail", {"recordId": recordId});
    },
    
    navigateToNewCase : function(component, event, helper) {
        var indivSearchWrapper = {};
        indivSearchWrapper.indivRec = {'sobjectType':'T_SBSD_INDIV__c'};
        indivSearchWrapper.searchType = 'StringSearch';
        component.set("v.indivSearchWrapper", indivSearchWrapper);
        component.set("v.newCaseDisabled", true);
        helper.redirectToLightningComponent("c:caseFlow", {"recordId": component.get("v.recordId"),
                                                           "isRejectedReferralFlow": component.get("v.isRejectedReferralFlow"),
                                                           "applnProcessQueueRec" : component.get("v.applnProcessQueueRec")});
    },
    
    doNext :function(component, event, helper){
        var onNextFun = component.get("v.onNext");
        if(onNextFun!=null){
            $A.enqueueAction(onNextFun);          
        } else {
            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
        }
    }
})