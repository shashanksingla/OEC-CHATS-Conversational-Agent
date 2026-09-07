({
    doInit : function(component, event, helper) {
        var action2 = component.get("c.getDoInit");
        action2.setParams({"recordId": component.get("v.recordId")});
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res=response.getReturnValue();
                var employmentPayStabObj = component.get("v.newEmploymentPayStabObj");
                console.log("res.---"+JSON.stringify(res));
                console.log('recordId---'+component.get("v.recordId"));
                if(res.objectData.getSobjectName != undefined){
                    if(res.objectData.getSobjectName == 'T_EMPLMT_INCOME__c'){
                        employmentPayStabObj.IDN_EMPLMT_INCOME__c =component.get("v.recordId");
                        component.set("v.newEmploymentPayStabObj",employmentPayStabObj);
                    }
                    else if(res.objectData.getSobjectName == 'T_EMPLMT_PAY_STUB__c'){
                        if(res.objectData.employmentPayStubRec){
                            component.set("v.newEmploymentPayStabObj",res.objectData.employmentPayStubRec);
                        }
                    }
                }
                
                component.set("v.oneTimeDateLoadValidatity",false);
                component.set("v.oneTimeDateLoadValidatity",true);
                component.set("v.sObjectName", res.objectData.getSobjectName);
                component.set("v.options", res.objectData.rateTypeOptions);
                console.log('option in parent--'+component.get("v.options"));
                component.set("v.initDataLoaded",true);
            } else {
                console.log('Problem getting authorization, response state: ' + state);
            }
        });
        $A.enqueueAction(action2);
    },
    doFinish : function(component, event, helper) {
        var childCmp = component.find("newpayStubRecord");
        childCmp.callValidateCurrentPage();
        console.log(component.get("v.isCurrentPageValid"));
        if(component.get("v.isCurrentPageValid")==true){
            component.set("v.showSpinner", true); 
            console.log('----newEmploymentPayStabObj---'+JSON.stringify(component.get("v.newEmploymentPayStabObj")));
            helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response){
                                                if(response){
                                                    helper.redirectToRecord(component.get("v.recordId"));
                                                }
                                            },
                                            {"lstSObject": [component.get("v.newEmploymentPayStabObj")],"isFinalStep":true}, false, null);
            
        }else{
            component.set("v.showSpinner", false); 
        }
    },
    doCancel : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.recordId"))){
            helper.redirectToRecord(component.get("v.recordId"));
        }else{
            window.history.back();
        }
        
    },
})