({
    doInit : function(component, event, helper) {
        
        var lstFiscalRateAmountRow = [];
        var lstCareUnit = component.get("v.lstCareUnit");
        var mapExistingFiscalRateAmount = component.get("v.mapExistingFiscalRateAmount");
        
        
        for(var i=0;i<lstCareUnit.length;i++){
            var fiscalRateAmount = helper.merge(component.get("v.fiscalRate"),{});
            fiscalRateAmount.cde_care_unit__c = lstCareUnit[i].key;
            fiscalRateAmount.idn_fiscal_sch__c = component.get("v.fiscalSchedule").Id;
            fiscalRateAmount.cde_age_group__c = component.get("v.ageGroup");
            fiscalRateAmount.cde_rate_type__c = component.get("v.rateType").key;
            var key = fiscalRateAmount.cde_rate_type__c+'_'+
                fiscalRateAmount.cde_age_group__c+'_'+
                fiscalRateAmount.cde_care_unit__c;
            var amountField = component.get('v.amountField');
            
            if (amountField =='PROVR')
            {
                if(mapExistingFiscalRateAmount[key]!=undefined && mapExistingFiscalRateAmount[key].amt_provr__c!=null){
                    fiscalRateAmount.amt_provr__c = mapExistingFiscalRateAmount[key].amt_provr__c;
                    fiscalRateAmount.amt_fa__c = mapExistingFiscalRateAmount[key].amt_fa__c;
                    fiscalRateAmount.Id = mapExistingFiscalRateAmount[key].Id;
                }
            }
            else if (amountField=='FA'){
                if(mapExistingFiscalRateAmount[key]!=undefined && mapExistingFiscalRateAmount[key].amt_fa__c!=null){
                    fiscalRateAmount.amt_fa__c = mapExistingFiscalRateAmount[key].amt_fa__c;
                    fiscalRateAmount.amt_provr__c = mapExistingFiscalRateAmount[key].amt_provr__c;
                    fiscalRateAmount.Id = mapExistingFiscalRateAmount[key].Id;
                }  
            }
            
            lstFiscalRateAmountRow.push(fiscalRateAmount);
        }
        
        component.set("v.lstFiscalRateAmountRow",lstFiscalRateAmountRow);
        var appEvent = $A.get("e.c:createFiscalRateEvent");
        appEvent.setParams({ "lstFiscalRateAmount" : lstFiscalRateAmountRow });
        appEvent.fire();         
    },
calculateProviderAmt :function(component){
        
        var lstFiscalRateAmountRow = component.get('v.lstFiscalRateAmountRow');
        var FTproviderAmt; 
        for(var i=0;i<lstFiscalRateAmountRow.length;i++)
        {
            if(lstFiscalRateAmountRow[i].cde_care_unit__c=='3'){
                FTproviderAmt=lstFiscalRateAmountRow[i].amt_provr__c;
            }
        }
        for(var i=0;i<lstFiscalRateAmountRow.length;i++)
        {
            var aFscAmt = lstFiscalRateAmountRow[i];
            
            if(aFscAmt.care_unit__c != '3'){ 
                if(aFscAmt.cde_rate_type__c == '13' || aFscAmt.cde_rate_type__c == '19' || aFscAmt.cde_rate_type__c== '25'){
                	aFscAmt.amt_provr__c = FTproviderAmt;
                	
                }else{
                    
                    if(aFscAmt.cde_care_unit__c == '2')aFscAmt.amt_provr__c = (FTproviderAmt*0.55).toFixed(2);
                    else if(aFscAmt.cde_care_unit__c == '4')aFscAmt.amt_provr__c = (FTproviderAmt*1.55).toFixed(2);
                        else if(aFscAmt.cde_care_unit__c == '5')aFscAmt.amt_provr__c = (FTproviderAmt*2).toFixed(2); 
                }
            }
            
             var appEvent = $A.get("e.c:createFiscalRateEvent");
            appEvent.setParams({ "fiscalRateAmount" : aFscAmt });
            appEvent.fire();
        }
        component.set('v.lstFiscalRateAmountRow', lstFiscalRateAmountRow);
    }
})