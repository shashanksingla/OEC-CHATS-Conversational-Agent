({
    doInit : function(component, event, helper) {
        var nonAdjustmentDetailLst = component.get("v.nonAdjustmentDetailLst");
        if(nonAdjustmentDetailLst && nonAdjustmentDetailLst.length>0) {
        	helper.calculateTotalAmount(nonAdjustmentDetailLst, component);
        }else {
            component.set("v.adjustmentObj.AMT_ADJMT__c",0);    
        }
	},
    handleAfterDelete : function(component, event, helper) {
		
	},
    updateTotalAmount : function(component, event, helper) {
        var nonAdjustmentDetailLst = component.get("v.nonAdjustmentDetailLst");
        if(nonAdjustmentDetailLst && nonAdjustmentDetailLst.length>0) {
        	helper.calculateTotalAmount(nonAdjustmentDetailLst, component);
        }else {
            component.set("v.adjustmentObj.AMT_ADJMT__c",0);    
        }
    }
})