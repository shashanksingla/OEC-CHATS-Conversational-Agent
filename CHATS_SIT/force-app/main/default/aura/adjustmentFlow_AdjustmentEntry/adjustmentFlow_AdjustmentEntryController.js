({
	doInit : function(component, event, helper) {
        var adjustmentDetailList = component.get("v.adjustmentDetailList");
        if(!$A.util.isEmpty(adjustmentDetailList)){
            var rec = adjustmentDetailList[0];
            if(rec.IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_slot_contract__c != null 
               && rec.IDN_DETAIL_PMT_SUB__r.idn_pmt_sub__r.idn_auth__c == null){
                component.set("v.slotCntcheckbox", true);
            }
        }
	},
    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
        var hlp = helper.validateCurrentPage(component);
        return hlp;
    },
    
})