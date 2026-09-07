({
    updateRecord : function(component, event, helper) {
        
        var fiscalRateAmount = component.get("v.fiscalRateAmount");
        if(fiscalRateAmount.amt_provr__c==undefined || fiscalRateAmount.amt_provr__c==null || fiscalRateAmount.amt_provr__c>500 || fiscalRateAmount.amt_provr__c<0){
            $A.util.addClass(component.find("amount"),"cellError");
        }else{
            $A.util.removeClass(component.find("amount"),"cellError");
        }
        
        fiscalRateAmount.AMT_PROVR__c =fiscalRateAmount.amt_provr__c;
        component.set("v.fiscalRateAmount",fiscalRateAmount);
        
        var appEvent = $A.get("e.c:createFiscalRateEvent");
        appEvent.setParams({ "fiscalRateAmount" : fiscalRateAmount });
        appEvent.fire();            
    },
    checkDecimalPlaces : function(component, event, helper){
        
        var fiscalRateAmount = component.get("v.fiscalRateAmount");
        try{
            fiscalRateAmount.amt_provr__c = fiscalRateAmount.amt_provr__c.toString().match(/^-?\d+(?:\.\d{0,2})?/)[0];
            component.set("v.fiscalRateAmount",fiscalRateAmount);
        }catch(ex){
            
        }
    },
    validateRecord : function(component, event, helper) {
        
        var actionType = event.getParam("actionType");
        if(actionType=="validate"){
            var fiscalRateAmount = component.get("v.fiscalRateAmount");
            if(fiscalRateAmount.amt_provr__c==undefined || fiscalRateAmount.amt_provr__c==null  || fiscalRateAmount.amt_provr__c<0){
                $A.util.addClass(component.find("amountPROVR"),"cellError");
            }else{
                $A.util.removeClass(component.find("amountPROVR"),"cellError");
            }            
        }
    }
})