({
	updateMapFiscalRateAmount : function(component, event, helper) {
        
        var mapFiscalRateAmount = component.get("v.mapFiscalRateAmount");
        var fiscalRateAmount = event.getParam("fiscalRateAmount"); 
        if(fiscalRateAmount && fiscalRateAmount!=null){
            var key = fiscalRateAmount.cde_rate_type__c+'_'+
                fiscalRateAmount.cde_age_group__c+'_'+
                fiscalRateAmount.cde_care_unit__c;
            mapFiscalRateAmount[key] = fiscalRateAmount;
        }
        var lstFiscalRateAmount = event.getParam("lstFiscalRateAmount"); 
        if(lstFiscalRateAmount && lstFiscalRateAmount.length>0){
            for(var i=0;i<lstFiscalRateAmount.length;i++){
                fiscalRateAmount = lstFiscalRateAmount[i];
                var key = fiscalRateAmount.cde_rate_type__c+'_'+
                    fiscalRateAmount.cde_age_group__c+'_'+
                    fiscalRateAmount.cde_care_unit__c;
                mapFiscalRateAmount[key] = fiscalRateAmount;
            }
        }
        component.set("v.mapFiscalRateAmount",mapFiscalRateAmount);
    },
    handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
		helper.validateCurrentPage(component);
    },
})