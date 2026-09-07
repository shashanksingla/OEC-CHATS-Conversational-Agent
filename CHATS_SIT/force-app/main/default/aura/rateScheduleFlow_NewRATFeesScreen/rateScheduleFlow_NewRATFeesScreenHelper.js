({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        
       
        var isValid = true;
        var arrOfFields = this.getControllingAndDependentFieldMap();
        var controlling_fields=arrOfFields[0];
        var dependent_fields_map=arrOfFields[1];
        
        var sObjectName='T_FISCAL_RAT_FEES__c';
        var fiscalRateObj = cmp.get("v.fiscalRateValues");
       
        if(fiscalRateObj){
            for(var i=0; i<controlling_fields.length;i++){
                var controlling_field = controlling_fields[i];
                var dependent_field = dependent_fields_map[controlling_field];
                if((fiscalRateObj[controlling_field] != '' && fiscalRateObj[controlling_field] != 0) && 
                   (fiscalRateObj[dependent_field] == null || fiscalRateObj[dependent_field] == '')){
                    cmp.find(sObjectName+"-"+dependent_field).set("v.message", 'Complete this field');
                    isValid = false;
                }else if(fiscalRateObj[controlling_field] == '0' && 
                   		 (fiscalRateObj[dependent_field] != '' && fiscalRateObj[dependent_field] != null)) {
                    cmp.find(sObjectName+"-"+dependent_field).set("v.message", $A.get("$Label.c.RAT_Fees_Frequency_Error_Msg"));
                    isValid = false;
                }
                else{
                    cmp.find(sObjectName+"-"+dependent_field).set("v.message",null);
                }
            }
        }
        
        return isValid;
    },
    getControllingAndDependentFieldMap : function(){
        var controlling_fields=['AMT_TRANS_PROVR__c', 'AMT_ACT_PROVR__c', 'AMT_REG_PROVR__c'];
        var dependent_fields_map={'AMT_TRANS_PROVR__c':'CDE_TRANS_FREQ__c',
                                  'AMT_ACT_PROVR__c':'CDE_ACT_FREQ__c',
                                  'AMT_REG_PROVR__c':'CDE_REG_FREQ__c'};
        return [controlling_fields, dependent_fields_map];
    },
    calcAmountPerPeriod : function(cmp){
        var fiscalRate = cmp.get("v.fiscalRateValues");
        
        //get all fields to calculate the amount
        var arrOfFields = this.getControllingAndDependentFieldMap();
        var controlling_fields=arrOfFields[0];
        var dependent_fields_map=arrOfFields[1];
        
        var amountArr = ['v.amountPerPeriodTrans', 'v.amountPerPeriodAct', 'v.amountPerPeriodReg'];
        
        if(fiscalRate){
            
            for(var i=0; i<controlling_fields.length;i++) {
                var calculatedAmt=0;
                if(fiscalRate[controlling_fields[i]] != '' && 
                   fiscalRate[dependent_fields_map[controlling_fields[i]]] != null) {
                    calculatedAmt = this.calculateAmount(fiscalRate[controlling_fields[i]], 
                                                           fiscalRate[dependent_fields_map[controlling_fields[i]]]);
                }
                cmp.set(amountArr[i], calculatedAmt);
            }
        }
    },
    calculateAmount : function(feeValue, frequency){
        var amountVal;
        switch(frequency){
            case 'MTH' : {
                amountVal = (feeValue/12).toFixed(2);
                break;
            }
            default : {
                amountVal = feeValue;
                break;
            }
        }
        return amountVal;
    }  
})