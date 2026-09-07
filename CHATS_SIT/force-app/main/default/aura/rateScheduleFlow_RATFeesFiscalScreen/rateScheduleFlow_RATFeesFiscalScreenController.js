({
	doInit : function(component, event, helper) {
        
        var fiscalRATFees = component.get("v.fiscalRateValues");
        var countyRatePlan = component.get("v.countyRatePlan");
       
        var arrayOfPicklist = ['CDE_TRANS_FREQ__c', 'CDE_ACT_FREQ__c', 'CDE_REG_FREQ__c'];
		helper.filterPickListValues(component, fiscalRATFees, arrayOfPicklist);
        var providerType= component.get('v.providerFiscalAgreementRec').CDE_TYPE_FACILITY__c;
        var providerQualityRating = component.get("v.providerQualityRating");
        var payHigherThanCeilingRate =component.get("v.countyRatePlan").PAYMENT_Q17__c;
        var arrayOfFiscalFeeFAValues = ['AMT_REG_FA__c','AMT_ACT_FA__c','AMT_TRANS_FA__c'];
        var arrayOfFiscalFeeValues = ['AMT_REG_PROVR__c','AMT_ACT_PROVR__c','AMT_TRANS_PROVR__c'];
        var arrayOfCountyRateValues = ['PAYMENT_Q9_1__c','PAYMENT_Q10_1__c','PAYMENT_Q11_1__c'];
        if(component.get("v.isReadOnly")) {
            component.set("v.AMT_REG_FA__c", component.get("v.fiscalRateValues").AMT_REG_FA__c);
            component.set("v.AMT_ACT_FA__c", component.get("v.fiscalRateValues").AMT_ACT_FA__c);
            component.set("v.AMT_TRANS_FA__c", component.get("v.fiscalRateValues").AMT_TRANS_FA__c);
        } else{
        	helper.filterFeeValues(component, fiscalRATFees, countyRatePlan, arrayOfFiscalFeeValues, arrayOfCountyRateValues,providerType, providerQualityRating, payHigherThanCeilingRate, arrayOfFiscalFeeFAValues);    
        }
	}
})