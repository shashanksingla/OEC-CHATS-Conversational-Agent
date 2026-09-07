({
    doInitHlp : function(component, event, helper) {
        component.set('v.isLoading',true);
        var IndivId = component.get("v.recordId");//component.find("quoteField").get("v.value");
        var indivCareList = component.get("v.individualCareLst");
        
        var action = component.get("c.getIndividualCareLvls");
        action.setParams({"IndivId":IndivId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res =response.getReturnValue();
                
                component.set('v.individualCareWrap',res);
                
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        
                    }
                } else {
                    
                }
            }
            component.set('v.isLoading',false);
        });
        $A.enqueueAction(action);
    },
    checkCustomValidations : function(component, event, helper) 
    {
        
        var IndivId = component.get("v.recordId");//component.find("quoteField").get("v.value");
        component.set('v.isLoading',true);
        var careLvlWrap = component.get("v.individualCareWrap");
        var indivCareList = [];
        if(!$A.util.isEmpty(careLvlWrap)){
            careLvlWrap.forEach(function(entry){
                indivCareList.push(entry.indCareLvlObj);      
            });
        }
        component.set("v.individualCareLst",indivCareList);
        var individualCareLst = component.get("v.individualCareLst");
        
        var action = component.get("c.validateIndCareLst");
        action.setParams({"IndivId":IndivId,"individualCareLst":individualCareLst});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.isError){
                    component.set("v.isError",true);
                    var recordError2 =[];
                    recordError2.push(res.message);
                    component.set("v.message",'error');
                    component.set("v.recordError",recordError2);
                }else{
                    component.set("v.isError",false);
                    component.set('v.IndvicWrap',response.getReturnValue());
                    component.set('v.individualCareLst',res.indCareLvl);
                    var isError = component.get("v.isError");
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "message": "The School Age begin effective date has been changed. Please ensure this is correct and revisit the affected authorizations and update the rate types as needed. Provider payment will be impacted.",
                        "type":"warning",
                        "duration":'6000'
                    });
                    toastEvent.fire();
                    
                    helper.callServerForExternalObjAndHandleError(component,"c.insertExternalObjRecords", 
                                                                  function(response){
                                                                      helper.callServerAndHandleError(component,"c.insertATSRecord", 
                                                                                                      function(response){
                                                                                                      }, {'individualId':IndivId}, false, null);
                                                                      helper.redirectToRecord(component.get("v.recordId"));
                                                                  }, {'lstSObject':component.get("v.individualCareLst"),"isFinalStep":true}, false, null);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
	                        
                    }
                } else {
                    
                }
            }
            component.set('v.isLoading',false);
        });
        $A.enqueueAction(action);
    },
})