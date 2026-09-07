({
    doInit : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getInitDataView", 
                                        function(response){
                                            if(!$A.util.isEmpty(response.objectData.mapRateDescription)){
                                                component.set("v.mapRateDescription", response.objectData.mapRateDescription);
                                            }
                                            component.set("v.countyName",response.objectData.countyName);
                                            var lstTierGroupValuetoLabel = JSON.parse(response.objectData.lstTierGroupValuetoLabel);
                                            component.set("v.lstAgeGroup",lstTierGroupValuetoLabel);
                                            var mapRateTypeValuetoLabel = JSON.parse(response.objectData.mapRateTypeValuetoLabel);
                                            component.set("v.mapRateTypes",mapRateTypeValuetoLabel);
                                            var rateTypes = [];
                                            var mapRateTypes = component.get("v.mapRateTypes");
                                            for(var i=0;i<response.objectData.rateTypeOptions.length;i++){
                                                if(response.objectData.rateTypeOptions[i] !='100'){
                                                    rateTypes.push({
                                                        'value':response.objectData.rateTypeOptions[i],
                                                        'label':mapRateTypes[response.objectData.rateTypeOptions[i]]
                                                    });   
                                                }
                                            }
                                            component.set("v.providerQualityRating",response.objectData.providerQualityRating);
                                            component.set("v.rateTypeOptions",rateTypes);
                                            component.set("v.selectedRateTypes", response.objectData.selectedRateTypeOptions);
                                            if(response.objectData.effectiveBeginDate!=null){
                                                component.set("v.effectiveBeginDate",response.objectData.effectiveBeginDate);
                                                component.set("v.effectiveBeginDateReadOnly",true);
                                            }
                                            var lstExistingFiscalRateAmount = response.objectData.lstExistingFiscalRateAmount;
                                            if(lstExistingFiscalRateAmount && lstExistingFiscalRateAmount.length>0){
                                                var mapExistingFiscalRateAmount = {};
                                                for(var i=0;i<lstExistingFiscalRateAmount.length;i++){
                                                    var key = lstExistingFiscalRateAmount[i].cde_rate_type__c+'_'+
                                                        lstExistingFiscalRateAmount[i].cde_age_group__c+'_'+
                                                        lstExistingFiscalRateAmount[i].cde_care_unit__c;
                                                    mapExistingFiscalRateAmount[key] = lstExistingFiscalRateAmount[i];
                                                } 
                                            }
                                            component.set("v.mapExistingFiscalRateAmount", helper.merge(mapExistingFiscalRateAmount,{}));
                                            component.set("v.mapFiscalRateAmount" , component.get("v.mapExistingFiscalRateAmount"));
                                            var returnedFiscalRates = response.objectData.ratFeesRec;
                                            if(returnedFiscalRates){
                                                component.set("v.fiscalRateValues", returnedFiscalRates);
                                                var fieldsToUpdate = ['AMT_TRANS_FA__c', 'CDE_TRANS_FREQ__c', 'AMT_ACT_FA__c',
                                                                      'CDE_REG_FREQ__c', 'AMT_REG_FA__c', 'CDE_ACT_FREQ__c'];
                                                for(var i=0; i<fieldsToUpdate.length; i++){
                                                    var field = "v.fiscalRateValues."+fieldsToUpdate[i];
                                                    var returnedFieldValue =  returnedFiscalRates[fieldsToUpdate[i]];
                                                    if(returnedFieldValue != undefined) {
                                                        component.set(field, returnedFieldValue);      
                                                    }
                                                    
                                                }
                                            }
                                            if(response.objectData.effectiveCountyRatePlan) {
                                                component.set("v.countyRatePlan", response.objectData.effectiveCountyRatePlan);
                                            }
                                        }, {'rateScheduleId':component.get("v.recordId")}, false, null);
    },
    
    doNext: function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        var exemptFacType = component.get("v.rateSchedule").IDN_AGRMT_FISCAL__r.CDE_TYPE_FACILITY__c;
        if(exemptFacType != 'EXE'){
            // Added one more else if for Tab 4 by Rishav for CCCAP-2616
            if(currentTabNumber==1){
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);    
            } else if(currentTabNumber==2) {
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1); 
            }else if(currentTabNumber==3) {
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
            }else if(currentTabNumber==4){
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
            }else if(currentTabNumber==5){
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
            }else if(currentTabNumber==6){
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
            }
        }else{
            if(currentTabNumber==1){
                helper.actionOnDoNextTab1(component, event, helper);
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
            }
        }
    },
    
    doPrevious: function(component, event, helper) {
        var exemptFacType = component.get("v.rateSchedule").IDN_AGRMT_FISCAL__r.CDE_TYPE_FACILITY__c;
        if(exemptFacType != 'EXE'){
            helper.decrementCurrentTabNumber(component);
        }else{
            helper.exemptDecrementCurrentTabNumber(component);
        }
    },
    
    doUpdateCurrentTabName: function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        // Added tab 4 and updated next tab numbers by Rishav for CCCAP-2616
        if(currentTabNumber==1){
            component.set("v.currentTabName","New Rate Schedule");
        }else if(currentTabNumber==2){
            component.set("v.currentTabName","Fiscal Agreement Rates");
        }else if(currentTabNumber==3){
            component.set("v.currentTabName","ART Fees (Fiscal Rates)");
        }else if(currentTabNumber==4){
            component.set("v.currentTabName","ART Fees Payment Restriction");
        }else if(currentTabNumber==5){
            component.set("v.currentTabName","New Private Rates");
        }else if(currentTabNumber==6){
            component.set("v.currentTabName","ART Fees (Private Rates)");
        }
    },
    
    doFinish: function(component, event, helper){
        var childCmp = component.find("rateScheduleFlow_RATFeesFiscalScreen");
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');
    },
    
    doCancel: function(component, event, helper){
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');    
    },
    
    actionOnCancelYesButton: function(component, event, helper){
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');
    },
    
    actionOnPreviousYesButton: function(component, event, helper){
        var fiscalRates = component.get("v.fiscalRateValues");
        var fiscalObjFields = ['AMT_TRANS_FA__c', 'CDE_TRANS_FREQ__c','AMT_ACT_FA__c','CDE_REG_FREQ__c','AMT_REG_FA__c','CDE_ACT_FREQ__c','IDN_FISCAL_SCH__c'];
        helper.clearObjectFields(fiscalRates, fiscalObjFields);
        helper.decrementCurrentTabNumber(component);
    }
})