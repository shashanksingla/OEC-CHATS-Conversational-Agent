({
    doInitHlp : function(component, event, helper) {
        var indivCareList = component.get("v.individualCareLst");        
        var action = component.get("c.getIndividualCareLvls");
        action.setParams({"IndivId":component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res =response.getReturnValue();
                component.set('v.individualCareWrap',res);
            }
        });
        $A.enqueueAction(action);
    },
    checkCustomValidations : function(component, event, helper) 
    {   
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
        action.setParams({"IndivId":component.get("v.recordId"),"individualCareLst":individualCareLst});
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
                    helper.showToast(component,event,res.message,'error');
                }else{
                    component.set("v.isError",false);
                    component.set('v.individualCareLst',res.indCareLvl);
                    var isError = component.get("v.isError");
                    helper.callServerForExternalObjAndHandleError(component,"c.insertExternalObjRecords", 
                                                                  function(response){
                                                                      helper.callServerAndHandleError(component,"c.insertATSRecord", 
                                                                                                      function(response){
                                                                                                      }, {'individualId':component.get("v.recordId")}, false, null);
                                                                      helper.redirectToRecord(component.get("v.recordId"));
                                                                  }, {'lstSObject':component.get("v.individualCareLst"),"isFinalStep":true}, false, null);
                }
            }
            component.set('v.isLoading',false);
        });
        $A.enqueueAction(action);
    },
    showToast:function(component,event,message,errType){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type":errType,
            "duration":'6000'
        });
        toastEvent.fire();
    }
})