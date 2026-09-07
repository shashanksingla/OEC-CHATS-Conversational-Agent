({
    callUpdateParentFeeData : function(component, helper) {
        component.set("v.noDataReturnedFromServer",false);
        var isUpdate= false;
        var authParentFeeAllocationsMap = component.get("v.authParentFeeAllocationsMap");
        var caseParentFeeAllocations = component.get("v.caseParentFeeAllocations");
        for(var i=0;i<caseParentFeeAllocations.length; i++){
            if(authParentFeeAllocationsMap.has(caseParentFeeAllocations[i].authExternalId)){
                var value = authParentFeeAllocationsMap.get(caseParentFeeAllocations[i].authExternalId);
                if(value != caseParentFeeAllocations[i].allocatedAuthAmountDecimal){
                    isUpdate = true;
                }
            }
        }
        if(isUpdate){
        helper.callServerAndHandleError(component,"c.updateParentFeeData", 
                                        function(response){
                                            if(!$A.util.isEmpty(response.objectData) && !$A.util.isEmpty(response.objectData.title)){
                                                component.set("v.showCaseParentFeeData",false);
                                                component.set("v.noDataReturnedFromServer",true);
                                                component.set("v.title",response.objectData.title);
                                                component.set("v.description",response.objectData.description);
                                                if(!$A.util.isEmpty(response.objectData.xLog)){
                                                    helper.callServer(component,"c.logException", 
                                                                      function(response){
                                                                          console.log("Exception occurred on server and has been logged.");
                                                                      }, {"xLog":response.objectData.xLog}, false);
                                                }
                                            }else{
                                                helper.callServerAndHandleError(component,"c.createParentFeeData", 
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
                                                                                        helper.fireToast("dismissible","success","","Case Parent Fee data has been updated.");
                                                                                    }
                                                                                },{"caseParentFeeAllocationsJSON":JSON.stringify(component.get("v.caseParentFeeAllocations")),
                                                                                   "effectiveBeginDateJSON":component.get("v.caseParentFeeDetails.effectiveBeginDate"),
                                                                                   "month":component.get("v.selectedMonth"),"year":component.get("v.selectedYear")
                                                                                  }, false, null);
                                                
                                            }
                                        },{"caseParentFeeAllocationsJSON":JSON.stringify(component.get("v.caseParentFeeAllocations")),
                                          "month":component.get("v.selectedMonth"),"year":component.get("v.selectedYear")}, false, null);
                                        }
                                        else{
                                            helper.goToRecord(component.get("v.recordId"),'detail');
                                            helper.fireToast("dismissible","success","","No Changes in Case Parent Fee Allocations.");
                                        }
        
     },

     validatePFChange : function(component, helper) {
        component.set("v.noDataReturnedFromServer",false);
        var isUpdate= false;
        var authParentFeeAllocationsMap = component.get("v.authParentFeeAllocationsMap");
        var caseParentFeeAllocations = component.get("v.caseParentFeeAllocations");
        for(var i=0;i<caseParentFeeAllocations.length; i++){
            if(authParentFeeAllocationsMap.has(caseParentFeeAllocations[i].authExternalId)){
                var value = authParentFeeAllocationsMap.get(caseParentFeeAllocations[i].authExternalId);
                if(value != caseParentFeeAllocations[i].allocatedAuthAmountDecimal){
                    isUpdate = true;
                }
            }
        }
        if(isUpdate){
            helper.callModal(component,'confirmationModalOnParentFeeChange');
        } else {
            component.set("v.showSpinner", false); // Added by Rishav for CCCAP-8170
        }
    },
})