({
    validate : function(component) {
        var mapCountyRateAmount = component.get("v.mapCountyRateAmount");
        var hasBlankEntries = false;
        var cellsHavingOutOfRangeValue = 0;
        var isValid = true;
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
            isValid = false;
        }
        if(cellsHavingOutOfRangeValue==1){
            error.push("Amount can not be greater than 500 or less than 0.");
            isValid = false;
        }
        if(cellsHavingOutOfRangeValue>1){
            error.push("One or more cells have amount either more than 500 or less than 0. Please correct it.");
            isValid = false;
        }
        
        component.set("v.pageMessages",error);
        component.set("v.messageType","error");
        return isValid;
    },
    save : function(component,providerType) {
        component.set("v.showSpinner",true);
        var lstCountyRateAmount = [];
        var mapCountyRateAmount = component.get("v.mapCountyRateAmount");
        var exempt5plusAgeGroupvalue =$A.get("$Label.c.exempt5plusAgeGroupvalue");
        var lstAgeGroup = component.get("v.lstAgeGroup");
        if(providerType==null){
            for(var key in mapCountyRateAmount){
                var countyRateAmount = mapCountyRateAmount[key];
                if(countyRateAmount.CDE_AGE_GROUP__c=='1'){
                    for(var k=2; k<lstAgeGroup.length;k++){
					var keyForCountyRateAmountForAgeGroup = countyRateAmount.CDE_PROVR_TYPE__c+'_'+
                        countyRateAmount.CDE_RATE_TYPE__c+'_'+k.toString()+'_'+
                        countyRateAmount.CDE_TIER__c+'_'+
                        countyRateAmount.CDE_UNIT__c;
                    var countyRateAmountForAgeGroup
                    if(mapCountyRateAmount[keyForCountyRateAmountForAgeGroup]!=undefined){
						countyRateAmountForAgeGroup = mapCountyRateAmount[keyForCountyRateAmountForAgeGroup];
                        countyRateAmountForAgeGroup.Id = mapCountyRateAmount[keyForCountyRateAmountForAgeGroup].Id;
                    }else{
                        countyRateAmountForAgeGroup = this.merge(component.get("v.countyRateAmount"),{});
                        countyRateAmountForAgeGroup.CDE_UNIT__c = countyRateAmount.CDE_UNIT__c;
                        countyRateAmountForAgeGroup.CDE_PROVR_TYPE__c = countyRateAmount.CDE_PROVR_TYPE__c;
                        countyRateAmountForAgeGroup.IDN_COUNTY_RATE__c = countyRateAmount.IDN_COUNTY_RATE__c;
                        countyRateAmountForAgeGroup.CDE_AGE_GROUP__c = k.toString();
                        countyRateAmountForAgeGroup.CDE_RATE_TYPE__c = countyRateAmount.CDE_RATE_TYPE__c;
                        countyRateAmountForAgeGroup.CDE_RATE_TEMPLT__c = countyRateAmount.CDE_RATE_TEMPLT__c;
                        countyRateAmountForAgeGroup.CDE_TIER__c = countyRateAmount.CDE_TIER__c;
                    }
                    countyRateAmountForAgeGroup.NBR_AMOUNT__c = countyRateAmount.NBR_AMOUNT__c;
                    if(countyRateAmountForAgeGroup.Id=='' || countyRateAmountForAgeGroup.Id==undefined || countyRateAmountForAgeGroup.Id==null){
                        delete countyRateAmountForAgeGroup.Id;
                    }
                    lstCountyRateAmount.push(countyRateAmountForAgeGroup);
					}
                    
                    /*
                    var keyForCountyRateAmountForAgeGroup2 = countyRateAmount.CDE_PROVR_TYPE__c+'_'+
                        countyRateAmount.CDE_RATE_TYPE__c+'_2_'+
                        countyRateAmount.CDE_TIER__c+'_'+
                        countyRateAmount.CDE_UNIT__c;
                    var countyRateAmountForAgeGroup2, countyRateAmountForAgeGroup3;
                    if(mapCountyRateAmount[keyForCountyRateAmountForAgeGroup2]!=undefined){
						countyRateAmountForAgeGroup2 = mapCountyRateAmount[keyForCountyRateAmountForAgeGroup2];
                        countyRateAmountForAgeGroup2.Id = mapCountyRateAmount[keyForCountyRateAmountForAgeGroup2].Id;
                    }else{
                        countyRateAmountForAgeGroup2 = this.merge(component.get("v.countyRateAmount"),{});
                        countyRateAmountForAgeGroup2.CDE_UNIT__c = countyRateAmount.CDE_UNIT__c;
                        countyRateAmountForAgeGroup2.CDE_PROVR_TYPE__c = countyRateAmount.CDE_PROVR_TYPE__c;
                        countyRateAmountForAgeGroup2.IDN_COUNTY_RATE__c = countyRateAmount.IDN_COUNTY_RATE__c;
                        countyRateAmountForAgeGroup2.CDE_AGE_GROUP__c = '2';
                        countyRateAmountForAgeGroup2.CDE_RATE_TYPE__c = countyRateAmount.CDE_RATE_TYPE__c;
                        countyRateAmountForAgeGroup2.CDE_RATE_TEMPLT__c = countyRateAmount.CDE_RATE_TEMPLT__c;
                        countyRateAmountForAgeGroup2.CDE_TIER__c = countyRateAmount.CDE_TIER__c;
                    }
                    countyRateAmountForAgeGroup2.NBR_AMOUNT__c = countyRateAmount.NBR_AMOUNT__c;
                    if(countyRateAmountForAgeGroup2.Id=='' || countyRateAmountForAgeGroup2.Id==undefined || countyRateAmountForAgeGroup2.Id==null){
                        delete countyRateAmountForAgeGroup2.Id;
                    }
                    lstCountyRateAmount.push(countyRateAmountForAgeGroup2);

                    var keyForCountyRateAmountForAgeGroup3 = countyRateAmount.CDE_PROVR_TYPE__c+'_'+
                        countyRateAmount.CDE_RATE_TYPE__c+'_3_'+
                        countyRateAmount.CDE_TIER__c+'_'+
                        countyRateAmount.CDE_UNIT__c;
                    if(mapCountyRateAmount[keyForCountyRateAmountForAgeGroup3]!=undefined){
						countyRateAmountForAgeGroup3 = mapCountyRateAmount[keyForCountyRateAmountForAgeGroup3];
                        countyRateAmountForAgeGroup3.Id = mapCountyRateAmount[keyForCountyRateAmountForAgeGroup3].Id;
                    }else{
                        countyRateAmountForAgeGroup3 = this.merge(component.get("v.countyRateAmount"),{});
                        countyRateAmountForAgeGroup3.CDE_UNIT__c = countyRateAmount.CDE_UNIT__c;
                        countyRateAmountForAgeGroup3.CDE_PROVR_TYPE__c = countyRateAmount.CDE_PROVR_TYPE__c;
                        countyRateAmountForAgeGroup3.IDN_COUNTY_RATE__c = countyRateAmount.IDN_COUNTY_RATE__c;
                        countyRateAmountForAgeGroup3.CDE_AGE_GROUP__c = '3';
                        countyRateAmountForAgeGroup3.CDE_RATE_TYPE__c = countyRateAmount.CDE_RATE_TYPE__c;
                        countyRateAmountForAgeGroup3.CDE_RATE_TEMPLT__c = countyRateAmount.CDE_RATE_TEMPLT__c;
                        countyRateAmountForAgeGroup3.CDE_TIER__c = countyRateAmount.CDE_TIER__c;
                    }
                    countyRateAmountForAgeGroup3.NBR_AMOUNT__c = countyRateAmount.NBR_AMOUNT__c;
                    if(countyRateAmountForAgeGroup3.Id=='' || countyRateAmountForAgeGroup3.Id==undefined || countyRateAmountForAgeGroup3.Id==null){
                        delete countyRateAmountForAgeGroup3.Id;
                    }
                    lstCountyRateAmount.push(countyRateAmountForAgeGroup3);*/
                }
                if(countyRateAmount.CDE_AGE_GROUP__c==exempt5plusAgeGroupvalue || countyRateAmount.CDE_AGE_GROUP__c=='1'){
                    if(countyRateAmount.Id=='' || countyRateAmount.Id==undefined || countyRateAmount.Id==null){
                        delete countyRateAmount.Id;
                    }
                    lstCountyRateAmount.push(countyRateAmount);
                }
            }
        }else{
            for(var key in mapCountyRateAmount){
                var countyRateAmount = mapCountyRateAmount[key];
                if(countyRateAmount.Id=='' || countyRateAmount.Id==undefined || countyRateAmount.Id==null){
                    delete countyRateAmount.Id;
                }
                lstCountyRateAmount.push(countyRateAmount);
            }
        }
        
        var action = component.get('c.saveLstCountyRateAmount');
        action.setParams({"lstCountyRateAmount":lstCountyRateAmount,
                          "recordId":component.get("v.countyRatePlan").Id,
                          "providerType":providerType});
        action.setCallback(this, function(actionResult) {
            try{
                var objectData = actionResult.getReturnValue();
                if(objectData.isSuccessful==false){
                    var errors = [];
                    for(var i=0;i<objectData.lstErrors.length;i++){
                        var lstErrOb = JSON.parse(objectData.lstErrors[i]);
                        for(var j=0;j<lstErrOb.length;j++){
                            var errOb = lstErrOb[j];
                            errors.push(errOb.message);
                        }
                        
                    }
                    component.set("v.pageMessages",errors);
                    component.set("v.messageType","error");
                }else if(objectData.isSuccessful==true){
                    if(providerType==null || providerType=='SAVEASDRAFT'){
                        var navEvt = $A.get("e.force:navigateToSObject");
                        
                        navEvt.setParams({
                            "recordId": component.get("v.countyRatePlan").Id,
                            "slideDevName": "detail",
                            "isredirect" : true
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
                            if(providerType=="HOM"){
                                component.set("v.currentTabNumber",1);
                                component.set("v.showCustomButton",true);
                            }else if(providerType=="CEN"){
                                component.set("v.currentTabNumber",2);
                                component.set("v.showCustomButton",true);
                            }else if(providerType=="EXE"){
                                component.set("v.currentTabNumber",3);
                                component.set("v.showCustomButton",false);
                            }
                        }
                    }
                }
            }catch(ex){
                component.set("v.pageMessages",[ex]);
                component.set("v.messageType","error");
            }
            component.set("v.showSpinner",false);
        });
        $A.enqueueAction(action);
    },
    redirectToLightningComponent : function(componentName, params){ //added as part of CCCAP-10471 to store history when redirecting
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : componentName,
            componentAttributes: params,
            isredirect : true
        });
        evt.fire();   
    }
})