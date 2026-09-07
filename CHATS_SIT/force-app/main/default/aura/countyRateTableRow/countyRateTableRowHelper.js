({
    merge:function(obj1,obj2){
        var obj3 = {};
        for (var attrname in obj1) { obj3[attrname] = obj1[attrname]; }
        for (var attrname in obj2) { obj3[attrname] = obj2[attrname]; }
        return obj3;
    },
    findRegularRate: function(component,countyRateAmount,regularRateAmount){
        
        let countyRatePlan = component.get('v.countyRatePlan');
        let rate;
        let amount =regularRateAmount?.NBR_AMOUNT__c || 0;
        let response = {'amount':amount};
        let changedAmount;
    	let changePercent;
        if(countyRateAmount.CDE_RATE_TYPE__c == '13' && countyRatePlan.RT_Q8_1__c == '1'){
            //Before School
            changePercent  = countyRatePlan.RT_Q8_1P__c;
        }else if(countyRateAmount.CDE_RATE_TYPE__c == '19' && countyRatePlan.RT_Q8_2__c == '1'){
            //After School
            changePercent  = countyRatePlan.RT_Q8_2P__c;
        }else if(countyRateAmount.CDE_RATE_TYPE__c == '25' && countyRatePlan.RT_Q8_3__c == '1'){
            //B and A School
            changePercent  = countyRatePlan.RT_Q8_3P__c;
        }else if(countyRateAmount.CDE_RATE_TYPE__c == '31' && countyRatePlan.RT_Q8_4__c == '1'){
            //Overnight
            changePercent  = countyRatePlan.RT_Q8_4P__c;
        }else if(countyRateAmount.CDE_RATE_TYPE__c == '37' && countyRatePlan.RT_Q8_5__c == '1'){
            //Weekend
            changePercent  = countyRatePlan.RT_Q8_5P__c;
        }else if(countyRateAmount.CDE_RATE_TYPE__c == '43' && countyRatePlan.RT_Q8_6__c == '1'){
            //Evening
            changePercent  = countyRatePlan.RT_Q8_6P__c;
        }else if(countyRateAmount.CDE_RATE_TYPE__c == '55' && countyRatePlan.RT_Q8_7__c == '1'){
            //Disability
            changePercent  = countyRatePlan.RT_Q8_7P__c;
        }else if(countyRateAmount.CDE_RATE_TYPE__c == '91' && countyRatePlan.RT_Q8_8__c == '1'){
            //Out of County
            changePercent  = countyRatePlan.RT_Q8_8P__c;
        }
        if(changePercent>0){
            changedAmount = Math.round((amount*changePercent).toFixed(2))/100 || 0;
            if(changedAmount && changedAmount>0){
                response = {'percentageApplied': true,'amount':changedAmount} 
            }
		}
        return response;
    }
})