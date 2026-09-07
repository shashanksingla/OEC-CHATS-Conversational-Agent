({
    doInit : function(component, event, helper) {
        component.set("v.cancelMsg",$A.get("$Label.c.rateScheduleFlowCancelMsg"));
        component.set("v.previousMsg",$A.get("$Label.c.rateScheduleFlowPreviousMsg"));
        if(component.get("v.effectiveBeginDate")==null||component.get("v.effectiveBeginDate")==''){
            component.set("v.effectiveBeginDate", '');
        }
        helper.callServerAndHandleError(component,"c.getInitData", 
                                        function(response){
                                            component.set("v.countyName",response.objectData.countyName);
                                            component.set("v.latestRateSchedule",response.objectData.latestRateSchedule);
                                            if(!$A.util.isEmpty(response.objectData.latestRateSchedule)){
                                                component.set("v.latestRateTypes",response.objectData.latestRateSchedule[0].CDE_RATE_TYPE__c);  
                                            }
                                            if(!$A.util.isEmpty(response.objectData.mapRateDescription)){
                                                component.set("v.mapRateDescription", response.objectData.mapRateDescription);
                                            }
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
                                            component.set("v.CDE_TYPE_FACILITY__c",response.objectData.CDE_TYPE_FACILITY__c);
                                            component.set("v.providerQualityRating",response.objectData.providerQualityRating);
                                            component.set("v.rateTypeOptions",rateTypes);
                                            if(response.objectData.effectiveBeginDate!=null) {
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
                                                    var fiscalRateAmount = lstExistingFiscalRateAmount[i];
                                                    delete fiscalRateAmount.Id;
                                                    delete fiscalRateAmount.idn_fiscal_sch__c;
                                                    mapExistingFiscalRateAmount[key] = fiscalRateAmount;
                                                } 
                                            }
                                            component.set("v.mapExistingFiscalRateAmount", helper.merge(mapExistingFiscalRateAmount,{}));
                                            component.set("v.mapFiscalRateAmount", helper.merge(mapExistingFiscalRateAmount,{}));
                                            var returnedFiscalRates = response.objectData.ratFeesRec;
                                            if(returnedFiscalRates) {
                                                // Added 3 TXT MONTH fields Rishav for CCCAP-2616
                                                var fieldsToUpdate = ['AMT_TRANS_PROVR__c', 'AMT_ACT_PROVR__c','AMT_REG_PROVR__c' ,
                                                                      'CDE_TRANS_FREQ__c', 'CDE_REG_FREQ__c','CDE_ACT_FREQ__c',
                                                                      'TXT_ACT_MONTH__c','TXT_REG_MONTH__c','TXT_TRANS_MONTH__c'];
                                                for(var i=0; i<fieldsToUpdate.length; i++) {
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
                                            if(response.objectData.countyMatched == false) {
                                                var recordError = 'The Fiscal Agreement record that you are trying to access belongs to '+response.objectData.countyName+' county. This does not match your assigned county(ies).';
                                                component.set("v.msgOnDiffOwnerCounty", recordError);
                                                helper.callModal(component,"warningModalOnDiffOwnerCounty");
                                            }
                                        },
                                        {'prvdrFiscalAgreementId':component.get("v.recordId"),
                                            'effectiveBeginDateInput':component.get("v.effectiveBeginDate")
                                        }, false, null);
    },
    
    doNext: function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==1) {
            helper.callModal(component, 'confirmationModalRateTypes');
        } else if(currentTabNumber==2) {
            var isValidated = helper.validate(component);
            if(!isValidated) {
                var appEvent = $A.get("e.c:createFiscalRateValidateError");
                appEvent.setParams({ "actionType" : "validate" });
                appEvent.fire();
            } else {
                var mapFiscalRateAmount = component.get("v.mapFiscalRateAmount");
                component.set('v.mapExistingFiscalRateAmount' ,mapFiscalRateAmount);
                //var lstFiscalRateAmount= component.get("v.lstFiscalRateAmount");
                var lstFiscalRateAmount= [];
                for(var key in mapFiscalRateAmount) {
                    var fiscalRateAmount = mapFiscalRateAmount[key];
                    if(fiscalRateAmount.Id=='' || fiscalRateAmount.Id==undefined || fiscalRateAmount.Id==null) {
                        delete fiscalRateAmount.Id;
                    }
                    fiscalRateAmount.idn_fiscal_sch__c = component.get("v.rateSchedule").Id;
                    lstFiscalRateAmount.push(fiscalRateAmount);
                }
                component.set("v.lstFiscalRateAmount", lstFiscalRateAmount);
                var childCmp = component.find("rateScheduleFlow_NewPrivateRates");
                childCmp.callValidateCurrentPage();
                // var providerType= component.get('v.providerFiscalAgreementRec').CDE_TYPE_FACILITY__c;
                var providerType= component.get('v.CDE_TYPE_FACILITY__c');
                var providerQualityRating = component.get('v.providerQualityRating');
                var tierValue = helper.getTierValue(providerQualityRating,providerType);                                            
                if(component.get("v.isCurrentPageValid")) {
                    var lstFiscalRateAmount = component.get("v.lstFiscalRateAmount");
                    helper.callServerAndHandleError(component,"c.getCeilingAmount", 
                                                    function(response) {
                                                        var lstCountyRateAmt = response.objectData.lstCountyRateAmt; 
                                                        for(var i=0;i<lstCountyRateAmt.length;i++){
                                                            var key = lstCountyRateAmt[i].CDE_RATE_TYPE__c+'_'+lstCountyRateAmt[i].CDE_AGE_GROUP__c + '_'+lstCountyRateAmt[i].CDE_UNIT__c; 
                                                            var payHigherThanCeilingRate =component.get("v.countyRatePlan").PAYMENT_Q17__c;
                                                            if(key in mapFiscalRateAmount) {
                                                                var mapFiscal = mapFiscalRateAmount[key];
                                                                if(mapFiscal) {
                                                                    //CHATS- 7344
                                                                    /*
                                                                    if((((providerQualityRating=='Level 3')||(providerQualityRating=='Level 4')||(providerQualityRating=='Level 5')) 
                                                                        && payHigherThanCeilingRate=='Y') || providerType=='EXE') {
                                                                        mapFiscal.amt_fa__c = lstCountyRateAmt[i].NBR_AMOUNT__c; 
                                                                    } else {
                                                                    mapFiscal.amt_fa__c = Math.min(lstCountyRateAmt[i].NBR_AMOUNT__c,mapFiscal.amt_provr__c );
                                                                    }
                                                                    */
                                                                    mapFiscal.amt_fa__c = Math.min(lstCountyRateAmt[i].NBR_AMOUNT__c,mapFiscal.amt_provr__c );
                                                                }
                                                            }
                                                        }
                                                        component.set('v.mapExistingFiscalRateAmount' ,helper.merge(component.get('v.mapExistingFiscalRateAmount'), mapFiscalRateAmount));
                                                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                    },
                                                    {'countyRatePlanId':component.get("v.countyRatePlan").Id,
                                                     'providerType': providerType,
                                                     'tierValue':tierValue
                                                    }, false, null);
                }
            }
        } else if(currentTabNumber==3) {
            var childCmp = component.find("rateScheduleFlow_FiscalRate");
            childCmp.callValidateCurrentPage();
            if(component.get("v.isCurrentPageValid")){
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
            }
        } else if(currentTabNumber==4) {
            var childCmp = component.find("rateScheduleFlow_NewRATFeesScreen");
            childCmp.callValidateCurrentPage();
            if(component.get("v.isCurrentPageValid")){
                // Start: Added by Rishav for CCCAP-2616
                if(component.get("v.fiscalRateValues.CDE_ACT_FREQ__c") != 'MTH' &&  component.get("v.fiscalRateValues.CDE_REG_FREQ__c") != 'MTH' && component.get("v.fiscalRateValues.CDE_TRANS_FREQ__c") != 'MTH'){
                    component.set("v.totalTabNumber","5");
                } else {
                    component.set("v.totalTabNumber","6");
                }
                // End: CCCAP-2616
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
            }
        } else if(currentTabNumber==5) {
            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
        } else if(currentTabNumber==6) { // Added this else if by Rishav for CCCAP-2616
            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
        }
    },
    
    doPrevious: function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        var exemptFacType = component.get("v.CDE_TYPE_FACILITY__c");
        if(exemptFacType != 'EXE') {
            if(currentTabNumber == 4  || currentTabNumber == 2 ) {
                var modalName = 'confirmationModalOnPrevious_'+currentTabNumber;
                helper.callModal(component,modalName);    
            } else {
                helper.decrementCurrentTabNumber(component);
            } 
        } else {
            if(currentTabNumber == 3) {
                var modalName = 'confirmationModalOnPrevious_'+currentTabNumber;
                helper.callModal(component,modalName); 
            } else {
                helper.exemptDecrementCurrentTabNumber(component);
            }
        } 
    },
    
    doUpdateCurrentTabName: function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        // Added tab 4 and updated next tab numbers by Rishav for CCCAP-2616
        if(currentTabNumber==1) {
            component.set("v.currentTabName","New Rate Schedule");
        } else if(currentTabNumber==2) {
            component.set("v.currentTabName","New Private Rates");
        } else if(currentTabNumber==3) {
            component.set("v.currentTabName","Fiscal Agreement Rates");
        } else if(currentTabNumber==4) {
            component.set("v.currentTabName","ART Fees (Private Rates)");
        } else if(currentTabNumber==5) {
            component.set("v.currentTabName","ART Fees (Fiscal Agreement Rates)");
        } else if(currentTabNumber==6) {
            component.set("v.currentTabName","ART Fees Payment Restriction");
        }
    },
    
    doFinish: function(component, event, helper){
        helper.actionOnDoFinish(component,event,helper); 
    },
    
    doCancel: function(component, event, helper){
        var currentTabNumber = component.get("v.currentTabNumber");
        helper.callModal(component,'confirmationModalOnCancel_'+currentTabNumber);
    },
    
    actionOnCancelYesButton: function(component, event, helper){
        helper.callServerAndDeleteRecords(component, function(response){
            var recordId = component.get("v.recordId");
            helper.goToRecord(recordId,'detail');
        }, [component.get("v.rateSchedule")]);
    },
    
    actionOnPreviousYesButton: function(component, event, helper){
        var currentTabNumber= component.get('v.currentTabNumber');
        var exemptFacType = component.get("v.CDE_TYPE_FACILITY__c");
        if(exemptFacType != 'EXE') {
            if (currentTabNumber == 2) {
                component.set('v.mapFiscalRateAmount', {});
                component.set("v.lstFiscalRateAmount",[]);
                component.set("v.doNextEnabled", true);
                helper.decrementCurrentTabNumber(component);
            } else if (currentTabNumber == 4) {
                var fiscalRates = component.get("v.fiscalRateValues");
                // Added 3 TXT MONTH fields Rishav for CCCAP-2616
                var fiscalObjFields = ['AMT_TRANS_FA__c', 'CDE_TRANS_FREQ__c','AMT_ACT_FA__c','CDE_REG_FREQ__c',
                                       'AMT_REG_FA__c','CDE_ACT_FREQ__c','IDN_FISCAL_SCH__c','AMT_TRANS_PROVR__c', 
                                       'AMT_REG_PROVR__c','AMT_ACT_PROVR__c',
                                       'TXT_ACT_MONTH__c','TXT_REG_MONTH__c','TXT_TRANS_MONTH__c'];
                helper.clearObjectFields(fiscalRates, fiscalObjFields);
                helper.decrementCurrentTabNumber(component);
            }
        } else {
            if (currentTabNumber == 3) {
                component.set('v.mapExistingFiscalRateAmount', {});
                component.set('v.mapFiscalRateAmount', {});
                component.set("v.lstFiscalRateAmount",[]);
                component.set("v.lstExistingFiscalRateAmount",[]);
                component.set("v.doNextEnabled", true);
                helper.exemptDecrementCurrentTabNumber(component);
            }  
        }
    },
    
    doHandleCustomButton: function(component, event, helper){
        if (component.get("v.currentTabNumber")==2) {
            component.set("v.showCalculateButton" , true);
        } else {
            component.set("v.showCalculateButton" , false);
        }
    },
    
    fireCalculate: function(component,event,helper){
        var appEvent = $A.get("e.c:calculateProviderAmt");
        appEvent.fire();
        component.set("v.doNextEnabled",true);
    },
    
    actionOnYesRateTypes: function(component,event,helper){
        var latestRateSchedule = component.get("v.latestRateSchedule");
        var mapRateTypes = component.get("v.mapRateTypes");
        var latestRateTypes = component.get("v.latestRateTypes")+';';
        var effectiveBeginDate = component.get("v.effectiveBeginDate");
        var selectedRateTypes = component.get("v.selectedRateTypes");
        var warningMsg;
        var lastestRateType = component.get("v.latestRateTypes");
        var warningMsg = 'Rate type(s) ' ;
        var missedRateType = false;
        var showMissingRateTypeModal = false;
        var modal = component.find("confirmationModalRateTypes");
        modal.hideConfirmModal();
        if(!$A.util.isEmpty(latestRateTypes) && component.get("v.latestRateTypes") != undefined) {
            var latestRateTypesArray = latestRateTypes.split(';');
            for(var i=0;i<latestRateTypesArray.length;i++) {
                if(!$A.util.isEmpty(latestRateTypesArray[i]) && ($A.util.isEmpty(selectedRateTypes) || selectedRateTypes.indexOf(latestRateTypesArray[i])==-1)){
                    missedRateType = true;
                    warningMsg = warningMsg +mapRateTypes[latestRateTypesArray[i]]+',';
                }
            }
            
            if(warningMsg.charAt(warningMsg.length-1)==",") {
                warningMsg = warningMsg.substring(0,warningMsg.length-1);
            }
            warningMsg =warningMsg+' was active on previous rate schedule. Verify this is no longer an applicable rate type. Click next to continue without this rate type.';
            component.set("v.previousRateTypeMsg",warningMsg);
            if(missedRateType) {
                helper.callModal(component, 'confirmationModalNoCheckOnRateTypes');  
                showMissingRateTypeModal = true;
            }
        }
        if(showMissingRateTypeModal==false) {
            if(effectiveBeginDate < helper.getFutureDate(15)) {
                helper.callModal(component, 'confirmationModalDatelessThan15Days');  
            } else {
                helper.actionOnDoNextTab1(component, event, helper);
            }
        } 
    },
    
    actionOnYesButtonDateLess15Days: function(component,event,helper){
        var modal = component.find("confirmationModalDatelessThan15Days");
        modal.hideConfirmModal();
        helper.actionOnDoNextTab1(component,event,helper);
    },
    
    actionOnNoCheckOnRateTypes: function(component,event,helper){
        var modal = component.find("confirmationModalNoCheckOnRateTypes");
        modal.hideConfirmModal();
        var effectiveBeginDate = component.get("v.effectiveBeginDate");
        if(effectiveBeginDate < helper.getFutureDate(15)){
            helper.callModal(component, 'confirmationModalDatelessThan15Days');  
        }else{
            helper.actionOnDoNextTab1(component, event, helper); 
        }
    }
})