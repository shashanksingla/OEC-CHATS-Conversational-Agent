({
    validate : function(component) {
        var mapCountyRateAmount = component.get("v.mapCountyRateAmount");
     
        var hasBlankEntries = false;
        var cellsHavingOutOfRangeValue = 0;

        for(var key in mapCountyRateAmount){
            if(mapCountyRateAmount[key].NBR_AMOUNT__c==undefined || mapCountyRateAmount[key].NBR_AMOUNT__c==null){
                hasBlankEntries = true;
            }
            if(mapCountyRateAmount[key].NBR_AMOUNT__c>500 || mapCountyRateAmount[key].NBR_AMOUNT__c<0){
                cellsHavingOutOfRangeValue++;
            }
        }
        var error=[];
        if(hasBlankEntries){
            error.push("Please fill out all the entries");
        }
        if(cellsHavingOutOfRangeValue==1){
            error.push("Amount can not be greater than 500 or less than 0.");
        }
        if(cellsHavingOutOfRangeValue>1){
            error.push("One or more cells have amount either more than 500 or less than 0. Please correct it.");
        }

        component.set("v.lstError",error);
        if(error.length>0){
            component.set("v.showError",true);
            return false;
        }
        component.set("v.showError",false);
        return true;
        
    },
    save : function(component,providerType) {
        var lstCountyRateAmount = [];
        var mapCountyRateAmount = component.get("v.mapCountyRateAmount");
        for(var key in mapCountyRateAmount){
            var countyRateAmount = mapCountyRateAmount[key];
            if(countyRateAmount.Id=='' || countyRateAmount.Id==undefined || countyRateAmount.Id==null){
                delete countyRateAmount.Id;
            }
            lstCountyRateAmount.push(countyRateAmount);
        }
       
        var action = component.get('c.saveLstCountyRateAmount');
        action.setParams({"lstCountyRateAmount":lstCountyRateAmount,
                          "recordId":component.get("v.countyRatePlan").Id,
                          "providerType":providerType});
        action.setCallback(this, function(actionResult) {
            try{
                var objectData = actionResult.getReturnValue();
               
                
                if(objectData.isSuccessful==false){
                    component.set("v.showError",true);
                    var errors = [];
                    for(var i=0;i<objectData.lstErrors.length;i++){
                        var lstErrOb = JSON.parse(objectData.lstErrors[i]);
                        for(var j=0;j<lstErrOb.length;j++){
                            var errOb = lstErrOb[j];
                            errors.push(errOb.message);
                        }
                        
                    }
                    component.set("v.lstError",errors);
                }else if(objectData.isSuccessful==true){
                    if(providerType==null){
                        
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": component.get("v.countyRatePlan").IDN_COUNTY__c,
                            "slideDevName": "detail"
                        });
                        navEvt.fire();
                    }else{
                        var lstExistingCountyRateAmount = objectData.lstExistingCountyRateAmount;
                        if(lstExistingCountyRateAmount){
                           
                            var mapExistingCountyRateAmount = {};
                            for(var i=0;i<lstExistingCountyRateAmount.length;i++){
                                var key = lstExistingCountyRateAmount[i].CDE_PROVR_TYPE__c+'_'+
                                    lstExistingCountyRateAmount[i].CDE_RATE_TYPE__c+'_'+
                                    lstExistingCountyRateAmount[i].CDE_AGE_GROUP__c+'_'+
                                    lstExistingCountyRateAmount[i].CDE_TIER__c+'_'+
                                    lstExistingCountyRateAmount[i].CDE_UNIT__c;
                                mapExistingCountyRateAmount[key] = lstExistingCountyRateAmount[i];
                            }      
                            component.set("v.mapExistingCountyRateAmount",mapExistingCountyRateAmount);
                            component.set("v.mapCountyRateAmount",{});
                            component.set("v.providerType",providerType);
                            var mapProviderType = component.get("v.mapProviderType");
                            component.set("v.providerTypeLabel",mapProviderType[providerType]);
                        }
                    }
                }
            }catch(ex){
                
                component.set("v.showError",true);
                component.set("v.lstError",[ex]);
            }
            component.set("v.showSpinner",false);
        });
        $A.enqueueAction(action);
    }
})