({
    doInit : function(component, event, helper) {
        var lstCountyRateAmountRow = [];
        var lstTierGroup = component.get("v.lstTierGroup");
        var lstAgeGroup = component.get("v.lstAgeGroup");
        var mapExistingCountyRateAmount = component.get("v.mapExistingCountyRateAmount");
        for(var i=0;i<lstTierGroup.length;i++){
            var countyRateAmount = helper.merge(component.get("v.countyRateAmount"),{});
            countyRateAmount.CDE_UNIT__c = component.get("v.careUnit");
            countyRateAmount.CDE_PROVR_TYPE__c = component.get("v.providerType");
            countyRateAmount.IDN_COUNTY_RATE__c = component.get("v.countyRatePlan").Id;
            countyRateAmount.CDE_AGE_GROUP__c = component.get("v.ageGroup");
            countyRateAmount.CDE_RATE_TYPE__c = component.get("v.rateType").key;
            countyRateAmount.CDE_RATE_TEMPLT__c = component.get("v.countyRatePlan").CDE_RATE_PLAN_TEMPLT__c;
            countyRateAmount.CDE_TIER__c = lstTierGroup[i].key;
            var key = countyRateAmount.CDE_PROVR_TYPE__c+'_'+
                countyRateAmount.CDE_RATE_TYPE__c+'_'+
                countyRateAmount.CDE_AGE_GROUP__c+'_'+
                countyRateAmount.CDE_TIER__c+'_'+
                countyRateAmount.CDE_UNIT__c;
            //adding below logic for CCCAP-8864 applying percentages start
            let response;
            //Rate Type other than Regular and Unit is FT
            if(countyRateAmount.CDE_RATE_TYPE__c!='1' && countyRateAmount.CDE_UNIT__c == '3' && component.get("v.providerType")!='EXE'){
                var regKey = countyRateAmount.CDE_PROVR_TYPE__c+'_'+'1'+'_'+
                    countyRateAmount.CDE_AGE_GROUP__c+'_'+ countyRateAmount.CDE_TIER__c+'_'+
                    countyRateAmount.CDE_UNIT__c;
                response = helper.findRegularRate(component,countyRateAmount,mapExistingCountyRateAmount[regKey]);
            }
            //CCCAP-8864 end
            if(mapExistingCountyRateAmount[key]!=undefined && (mapExistingCountyRateAmount[key].NBR_AMOUNT__c!=null)){
                countyRateAmount.NBR_AMOUNT__c =  mapExistingCountyRateAmount[key].NBR_AMOUNT__c;
                countyRateAmount.Id = mapExistingCountyRateAmount[key].Id;
            }
            //CCCAP-8864 start
            if(response && response.percentageApplied){
                countyRateAmount.NBR_AMOUNT__c = response.amount.toFixed(2);
                component.set('v.readOnly',true);
            }
            //CCCAP-8864 end
            lstCountyRateAmountRow.push(countyRateAmount);
            
            if(component.get("v.providerType")=='EXE' && countyRateAmount.CDE_AGE_GROUP__c=='1'){
                for(var k=2; k<lstAgeGroup.length;k++){
                 var countyRateAmountForAgeGroup = helper.merge(component.get("v.countyRateAmount"),{});
                countyRateAmountForAgeGroup.CDE_UNIT__c = component.get("v.careUnit");
                countyRateAmountForAgeGroup.CDE_PROVR_TYPE__c = component.get("v.providerType");
                countyRateAmountForAgeGroup.IDN_COUNTY_RATE__c = component.get("v.countyRatePlan").Id;
                countyRateAmountForAgeGroup.CDE_AGE_GROUP__c = k.toString();
                countyRateAmountForAgeGroup.CDE_RATE_TYPE__c = component.get("v.rateType").key;
                countyRateAmountForAgeGroup.CDE_RATE_TEMPLT__c = component.get("v.countyRatePlan").CDE_RATE_PLAN_TEMPLT__c;
                countyRateAmountForAgeGroup.CDE_TIER__c = lstTierGroup[i].key;
                countyRateAmountForAgeGroup.NBR_AMOUNT__c = countyRateAmount.NBR_AMOUNT__c;
                var keyForCountyRateAmountForAgeGroup = countyRateAmountForAgeGroup.CDE_PROVR_TYPE__c+'_'+
                    countyRateAmountForAgeGroup.CDE_RATE_TYPE__c+'_'+
                    countyRateAmountForAgeGroup.CDE_AGE_GROUP__c+'_'+
                    countyRateAmountForAgeGroup.CDE_TIER__c+'_'+
                    countyRateAmountForAgeGroup.CDE_UNIT__c;
                if(mapExistingCountyRateAmount[keyForCountyRateAmountForAgeGroup]!=undefined && mapExistingCountyRateAmount[keyForCountyRateAmountForAgeGroup].NBR_AMOUNT__c!=null){
                    countyRateAmountForAgeGroup.Id = mapExistingCountyRateAmount[keyForCountyRateAmountForAgeGroup].Id;
                }
                lstCountyRateAmountRow.push(countyRateAmountForAgeGroup);   
                }
                
            }
        }
        component.set("v.lstCountyRateAmountRow",lstCountyRateAmountRow);
        var appEvent = $A.get("e.c:createCountyRateEvent");
        appEvent.setParams({ "lstCountyRateAmount" : lstCountyRateAmountRow });
        appEvent.fire();
    }
})