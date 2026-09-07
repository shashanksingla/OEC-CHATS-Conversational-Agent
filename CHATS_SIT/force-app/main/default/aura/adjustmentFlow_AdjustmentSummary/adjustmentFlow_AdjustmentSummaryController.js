({
    handleAdjustmentDetailSummaryEvent : function(component, event, helper) {
        var adjustmentAmount = event.getParam("adjustmentAmount");
       // var adjustmentDetailList =   event.getParam("adjustmentDetailList");
        var subPaymentDetail =   event.getParam("subPaymentDetail");
        var rateTypeOptions =   event.getParam("rateTypeOptions");
        var selectedSubPayment = event.getParam("selectedSubPayment");
       // var adjustmentObj = component.get("v.adjustmentObj");
        var adjustmentDtlWarp = event.getParam("adjustmentDtlWarp");
        component.set("v.adjustmentDtlWarp",adjustmentDtlWarp);
        component.set("v.rateTypeOptionsMap",rateTypeOptions);
      //  adjustmentObj.AMT_ADJMT__c = adjustmentObj.AMT_ADJMT__c+ adjustmentAmount;
      //  component.set("v.adjustmentObj",adjustmentObj);
     //   component.set("v.adjustmentDetailLst",adjustmentDetailList);
     //   component.set("v.subPaymentDetail",subPaymentDetail);
        component.set("v.selectedSubPayment",selectedSubPayment);
        var adjustmentObj = component.get("v.adjustmentObj");
        if(!$A.util.isEmpty(adjustmentObj)){
            console.log('adjustmentObj---'+JSON.stringify(adjustmentObj));
            console.log('adjustment Id--'+component.get("v.recordId"));
            var action = component.get("c.getAdjustmentDetailsMap");
            action.setParams({ 'adjustmentId':adjustmentObj.Id });
            // Create a callback that is executed after 
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var adjsutmentDtlMap = response.getReturnValue();
                    component.set("v.adjustDetailMap",adjsutmentDtlMap);
                    console.log('-adjsutmentDtlMap--'+JSON.stringify(adjsutmentDtlMap));
                }
            });
            $A.enqueueAction(action);
            var action1 = component.get("c.getCurrentUtilizationRecord");
            action1.setParams({ 'adjustmentId':adjustmentObj.Id });
            // Create a callback that is executed after 
            action1.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var res = response.getReturnValue();
                    console.log('-adjsutmentDtlMap--'+JSON.stringify(res));
                    if(res.objectData.currentUtilizationMap){
                        component.set("v.childCurrentUtilization", res.objectData.currentUtilizationMap);  
                    }
                }
            });
            $A.enqueueAction(action1);
        }
    },
    doInit : function(component, event, helper) {
        var action1 = component.get("c.getPicklistOptions");
        action1.setCallback(this, function(response) {
            var response = response.getReturnValue();
            if(response.objectData.careUnitTypeOptions){
                component.set("v.careUnitTypeOptions", response.objectData.careUnitTypeOptions);  
            }
            if(response.objectData.careUnitTypeOptionsMap){
                component.set("v.careUnitTypeOptionsMap", response.objectData.careUnitTypeOptionsMap);  
            }
            if(response.objectData.careLevelOptions){
                component.set("v.careLevelOptions", response.objectData.careLevelOptions);  
            }
            if(response.objectData.careLevelOptionsMap){
                component.set("v.careLevelOptionsMap", response.objectData.careLevelOptionsMap);  
            }
        });
        $A.enqueueAction(action1);
        var adjustmentDtlWarp = component.get("v.adjustmentDtlWarp");        
        if(adjustmentDtlWarp && adjustmentDtlWarp.length>0) {
            helper.calculateTotalAmount(adjustmentDtlWarp, component);
        }else {
            component.set("v.adjustmentObj.AMT_ADJMT__c",0);    
        }
    },
    updateTotalAmount :function(component, event, helper) {
        var adjustmentDtlWarp = component.get("v.adjustmentDtlWarp");
        if(adjustmentDtlWarp && adjustmentDtlWarp.length>0) {
            helper.calculateTotalAmount(adjustmentDtlWarp, component);
        }else {
            component.set("v.adjustmentObj.AMT_ADJMT__c",0);    
        }
    },
    sortbyColumn: function(component, event, helper) {
        debugger;
        var dataToSort = component.get("v.adjustmentDtlWarp");
		if(dataToSort != null && dataToSort != undefined){
            var idToSort = event.target.id;
         	if(undefined !== idToSort && "" !==idToSort){
        		helper.sortBy(component, idToSort);
        	}
        }
    }
})