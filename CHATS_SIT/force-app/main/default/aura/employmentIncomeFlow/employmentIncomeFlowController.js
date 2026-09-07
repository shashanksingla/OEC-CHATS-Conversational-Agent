({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.getInitData");
        action.setParams({"recordId": recordId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.isSuccessful){
                    component.set('v.employmentType', res.objectData.employmentType);
                    component.set('v.parentObjId', res.objectData.parentObjId);
                    component.set('v.sObjName', res.objectData.sObjName);
                    component.set('v.howVerifiedOptions', res.objectData.howVerifiedOptions);
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    doFinish : function(component, event, helper) {
        var empObjToUpdate;
        if(component.get("v.sObjName") == 'T_SBSD_INDIV_EMPLMT__c'){
            var childCmp = component.find("newEmpIncomeRecord");
            empObjToUpdate= component.get("v.empIncomeObjNew");
        } else {
            var childCmp = component.find("editEmpIncomeRecord");
            empObjToUpdate= component.get("v.empIncomeObj");
        }
        childCmp.callValidateCurrentPage();
        if(component.get("v.isCurrentPageValid") == true){
            component.set("v.showSpinner", true);
            helper.callServerAndHandleError(component,"c.saveEmploymentIncome", function(resp){
                if(resp){
                    helper.redirectToRecord(component.get("v.recordId"));
                }
            },{"empIncomeObj": empObjToUpdate}, false, null);            
        } else {
            component.set("v.showSpinner", false); 
        }
    },
    
    doCancel : function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    }
})