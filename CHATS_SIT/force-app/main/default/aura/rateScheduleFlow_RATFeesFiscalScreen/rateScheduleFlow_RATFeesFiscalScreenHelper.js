({
    filterPickListValues : function(cmp, fiscalRATFees, arrayOfPicklist) {
        
        for(var i=0;i<arrayOfPicklist.length;i++) {
            var val = fiscalRATFees[arrayOfPicklist[i]];
          
            switch(val){
                case 'MTH': {
                    val = 'Monthly';
                    break;
                }
                case 'ANN': {
                    val = 'Annually';
                    break;
                }
                case 'ONE': {
                    val = 'One Time';
                    break;
                }
                case 'YER': {
                    val = 'Yearly';
                    break;
                }
                default: {
                    val = '';
                    break;
                }
            }
            cmp.set("v."+arrayOfPicklist[i], val);
        }
    },
    filterFeeValues : function(component, fiscalRATFees, countyRatePlan, arrayOfFiscalFeeValues, arrayOfCountyRateValues, providerType, providerQualityRating, payHigherThanCeilingRate, arrayOfFiscalFeeFAValues){
        var fiscalRateValues = component.get("v.fiscalRateValues");
        for(var i=0; i<arrayOfFiscalFeeValues.length; i++){
            var minValue;
            if(countyRatePlan[arrayOfCountyRateValues[i]] != null && countyRatePlan[arrayOfCountyRateValues[i]] != undefined ) {
                if((((providerQualityRating=='Level 3')||(providerQualityRating=='Level 4')||(providerQualityRating=='Level 5')) 
                    && payHigherThanCeilingRate=='Y') || providerType=='EXE'){
                    minValue = countyRatePlan[arrayOfCountyRateValues[i]];
                    }
                else{
                    minValue = Math.min(fiscalRATFees[arrayOfFiscalFeeValues[i]], countyRatePlan[arrayOfCountyRateValues[i]]);
                }
            }else{
                minValue = 0;
            }
            component.set("v."+arrayOfFiscalFeeFAValues[i], minValue);
            fiscalRateValues[arrayOfFiscalFeeFAValues[i]]= minValue;
        }
    component.set("v.fiscalRateValues", fiscalRateValues);
    }
})