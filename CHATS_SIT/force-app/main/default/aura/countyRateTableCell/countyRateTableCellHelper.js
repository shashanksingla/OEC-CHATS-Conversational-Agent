({
	careUnitsUpdate : function(component,countyRateAmount,countyRateAmountReceived) {
        if(countyRateAmountReceived.CDE_UNIT__c == '3' && countyRateAmount.CDE_UNIT__c != '3' &&
           countyRateAmountReceived.CDE_PROVR_TYPE__c == countyRateAmount.CDE_PROVR_TYPE__c &&
           countyRateAmountReceived.CDE_RATE_TYPE__c == countyRateAmount.CDE_RATE_TYPE__c &&
           countyRateAmountReceived.CDE_AGE_GROUP__c == countyRateAmount.CDE_AGE_GROUP__c &&
           countyRateAmountReceived.CDE_TIER__c == countyRateAmount.CDE_TIER__c){
            if(countyRateAmountReceived.CDE_RATE_TYPE__c == '13'||countyRateAmountReceived.CDE_RATE_TYPE__c == '19'||countyRateAmountReceived.CDE_RATE_TYPE__c == '25'){ // Unit = FT
                countyRateAmount.NBR_AMOUNT__c = (countyRateAmountReceived.NBR_AMOUNT__c).toFixed(2); 
            } else if(countyRateAmount.CDE_UNIT__c == '2') { // Unit = PT
                countyRateAmount.NBR_AMOUNT__c = (Math.round((countyRateAmountReceived.NBR_AMOUNT__c * 0.55) * 100) / 100).toFixed(2);
            } else if(countyRateAmount.CDE_UNIT__c == '4') { // Unit = FTPT
                countyRateAmount.NBR_AMOUNT__c = (Math.round((countyRateAmountReceived.NBR_AMOUNT__c * 1.55) * 100) / 100).toFixed(2); 
            } else if(countyRateAmount.CDE_UNIT__c == '5') { // Unit = FTFT
                countyRateAmount.NBR_AMOUNT__c = (Math.round((countyRateAmountReceived.NBR_AMOUNT__c * 2) * 100) / 100).toFixed(2);
            }
            component.set("v.countyRateAmount", countyRateAmount);
        }
	}
})