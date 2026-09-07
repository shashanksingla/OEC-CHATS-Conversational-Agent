({
    doInit : function(component){
        component.set("v.selectedMonth",'');
        let d = new Date();
        component.set("v.selectedYear",d.getFullYear());
    },
    doGetParentFeeData : function(component, event, helper) {
        var inputComponents = component.find('input-field');
        var areAllFieldsValid = true;
        if(inputComponents){
            if(inputComponents.length>0){
                areAllFieldsValid = component.find('input-field').reduce(function (validSoFar, inputComponents) {
                    inputComponents.showHelpMessageIfInvalid();
                    return validSoFar && inputComponents.get('v.validity').valid;
                }, true);
            }
        }
        if(areAllFieldsValid){
            component.set("v.noDataReturnedFromServer",false);
            component.set("v.showCaseParentFeeData",false);
            component.set("v.isDeletable", false); //added for CCCAP-15261
            var amount;// = component.get("v.newCaseCopayRec").amt_copay_case_assesd__c;
            helper.callServerAndHandleError(component,"c.getParentFeeData", 
                                            function(response){
                                                if(!$A.util.isEmpty(response.objectData)){
                                                if(response.objectData.isNotReadOnlyUser){
                                                        component.set("v.isNotReadOnlyUser", response.objectData.isNotReadOnlyUser);
                                                    }
                                                    console.log("isNotReadOnlyUser---"+response.objectData.isNotReadOnlyUser);
                                                    if(!$A.util.isEmpty(response.objectData.xLog)){
                                                        helper.callServer(component,"c.logException", 
                                                                                        function(response){
                                                                                            console.log("Exception occurred on server and has been logged.");
                                                                                        }, {"xLog":response.objectData.xLog}, false);
                                                    }
                                                    if(!$A.util.isEmpty(response.objectData.caseParentFeeDetails)){
                                                        component.set("v.isEditable",response.objectData.isEditable);
                                                        component.set("v.isAuthCopayEditable",response.objectData.isAuthCopayEditable);
                                                        component.set("v.isDeletable",response.objectData.isDeletable);
                                                        component.set("v.caseParentFeeDetails",response.objectData.caseParentFeeDetails);
                                                        component.set("v.showCaseParentFeeData",true);
                                                        if(!$A.util.isEmpty(response.objectData.caseParentFeeAllocations)){
                                                            component.set("v.caseParentFeeAllocations",response.objectData.caseParentFeeAllocations);
                                                            var caseALLocationMap =new Map();
                                                            var caseParentFeeAllocationsMap = JSON.parse(JSON.stringify( component.get("v.caseParentFeeAllocations")));;
                                                            for(var m =0 ; m<caseParentFeeAllocationsMap.length ;m++){
                                                                caseALLocationMap.set(caseParentFeeAllocationsMap[m].authExternalId, caseParentFeeAllocationsMap[m].allocatedAuthAmountDecimal);
                                                            }
                                                            component.set("v.authParentFeeAllocationsMap",caseALLocationMap);
                                                        }else{
                                                            component.set("v.caseParentFeeAllocations",null);
                                                            component.set("v.noDataReturnedFromServer",true);
                                                            component.set("v.title",response.objectData.title);
                                                            component.set("v.description",response.objectData.description);
                                                        }
                                                    }else{
                                                        component.set("v.noDataReturnedFromServer",true);
                                                        component.set("v.title",response.objectData.title);
                                                        component.set("v.description",response.objectData.description);
                                                    }
                                                }else{
                                                    component.set("v.noDataReturnedFromServer",true);
                                                    component.set("v.title",response.objectData.title);
                                                    component.set("v.description",response.objectData.description);
                                                }
                                            }, {"caseId":component.get("v.recordId"),"month":component.get("v.selectedMonth"),"year":component.get("v.selectedYear"),"caseParentFeeAmt":amount}, false, null);
        }
        
    },
    doCancel : function(component, event, helper) {
        window.history.back();
    },
    doFinish : function(component, event, helper) {
        try{
            debugger;
            component.set("v.showSpinner",true);
            var  isValid = component.find("parentFeeAllocation").validateAllRows();
            //we will go into this condition only when each auth copay row has some postive auth copay amount
            if(isValid==true){
                //Summing up all the allocatedAuthAmount of each auth copay
                var totalAllocatedAuthAmount = 0;
                var caseParentFeeAllocations = component.get("v.caseParentFeeAllocations");
                for(var i=0;i<caseParentFeeAllocations.length;i++){
                    totalAllocatedAuthAmount+=caseParentFeeAllocations[i].allocatedAuthAmount;
                }
                var caseParentFeeDetails = component.get("v.caseParentFeeDetails");
                //if this sum is not equal to parentFee of case parent fee record
                if(caseParentFeeDetails.parentFee!=totalAllocatedAuthAmount){
                    component.set("v.pageMessages",[$A.get("$Label.c.ERRORS_ON_THIS_PAGE"),"Sum of all authorization fee amounts does not equal the total case parent fee."]);
                    component.set("v.messageType","error");
                    component.set("v.showSpinner",false);
                }else{
                    component.set("v.pageMessages",[]);
                    component.set("v.messageType",null);
                    //helper.callUpdateParentFeeData(component,helper);
                    helper.validatePFChange(component,helper);
                }
            }else{
                component.set("v.pageMessages",[$A.get("$Label.c.ERRORS_ON_THIS_PAGE")]);
                component.set("v.messageType","error");
                var elements = component.find("parentFeeAllocation").find("parentFeeAllocationRow");
                if(!$A.util.isEmpty(elements.length)){
                    for(var i=0;i<elements.length;i++){
                        if(!elements[i].validateEachRow()){
                            elements[i].find("input-field").focus();
                            break;
                        }
                    }
                }else{
                    elements.find("input-field").focus();
                }
                component.set("v.showSpinner",false);
            }
        }catch(ex){
            component.set("v.showCaseParentFeeData",false);
            component.set("v.noDataReturnedFromServer",true);
            component.set("v.title","Something unexpected happened!!");
            component.set("v.description",JSON.stringify(ex));
        }
    },
    doDeleteParentFee : function(component, event, helper) {
        try{
            console.log(component.get("v.caseParentFeeDetails.caseCopayId"));
            helper.callServerAndHandleError(component,"c.deleteParentFeeData", 
                                            function(response){
                                                if(!$A.util.isEmpty(response.objectData)){
                                                    if(!$A.util.isEmpty(response.objectData.xLog)){
                                                        helper.callServer(component,"c.logException", 
                                                                                        function(response){
                                                                                            console.log("Exception occurred on server and has been logged.");
                                                                                        }, {"xLog":response.objectData.xLog}, false);
                                                    }
                                                    if(!$A.util.isEmpty(response.objectData.title)){
                                                        component.set("v.showCaseParentFeeData",false);
                                                        component.set("v.noDataReturnedFromServer",true);
                                                        component.set("v.title",response.objectData.title);
                                                        component.set("v.description",response.objectData.description);
                                                    }
                                                }else{
                                                    helper.goToRecord(component.get("v.recordId"),'detail');
                                                    helper.fireToast("dismissible","success","","Case Parent Fee data has been deleted.");
                                                }
                                            },{"caseCopayExternalId":JSON.stringify(component.get("v.caseParentFeeDetails.caseCopayId"))}, false, null);
        }catch(ex){
            component.set("v.showCaseParentFeeData",false);
            component.set("v.noDataReturnedFromServer",true);
            component.set("v.title","Something unexpected happened!!");
            component.set("v.description",JSON.stringify(ex));
         }
    },
    doCancelParentFeeChange : function(component, event, helper) {
        helper.goToRecord(component.get("v.recordId"),'detail');
        //helper.fireToast("dismissible","success","","No Changes in Case Parent Fee Allocations.");
    }, 
    confirmParentFeeChangeYes : function(component, event, helper) {
        helper.callUpdateParentFeeData(component,helper);
    },
})