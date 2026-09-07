({
    doInit : function(component, event, helper) {
        var action2 = component.get("c.getDoInit");
        action2.setParams({"recordId": component.get("v.recordId")});
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res=response.getReturnValue();
                var CaseInfoObj = component.get("v.newcaseInfoObj");
                console.log("res.---"+JSON.stringify(res));
                console.log('recordId---'+component.get("v.recordId"));
                if(res.objectData.getSobjectName != undefined){
                    if(res.objectData.getSobjectName == 'T_SBSD_CASE__c'){ 
                        CaseInfoObj.IDN_CASE__c =component.get("v.recordId");
                        CaseInfoObj.CDE_TYPE_INFO_CASE__c='PMC'; // Case ID
                        component.set("v.newcaseInfoObj",CaseInfoObj);
                    }
                    else if(res.objectData.getSobjectName == 'T_SBSD_CASE_INFO__c'){ // Edit
                        if(res.objectData.sbsdcaseinfoRec){
                            console.log('newcaseInfoObj edit--'+JSON.stringify(res.objectData.sbsdcaseinfoRec));
                            component.set("v.newcaseInfoObj",res.objectData.sbsdcaseinfoRec);
                        }
                    }
                }
                
                component.set("v.sObjectName", res.objectData.getSobjectName);
                //component.set("v.options", res.objectData.CaseInfoTypeOptions);
                console.log('option in parent--'+component.get("v.options"));
                component.set("v.initDataLoaded",true);
            } else {
                console.log('response state: ' + state);
            }
        });
        $A.enqueueAction(action2);
    },
    doFinish : function(component, event, helper) {
        console.log("recordId---"+component.get("v.recordId"));
        debugger;
        var childCmp = component.find("newcaseInfoRecord");
        childCmp.callValidateCurrentPage();
        console.log(component.get("v.isCurrentPageValid"));
        if(component.get("v.isCurrentPageValid")==true){
            component.set("v.showSpinner", true); 
            console.log('----newcaseInfoObj---'+JSON.stringify(component.get("v.newcaseInfoObj")));
            helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response){
                                                debugger;
                                                if(response){
                                                    debugger;
                                                    helper.redirectToRecord(component.get("v.recordId"));
                                                }
                                            },
                                            {"lstSObject": [component.get("v.newcaseInfoObj")],"isFinalStep":true}, false, null);
                                             
            
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