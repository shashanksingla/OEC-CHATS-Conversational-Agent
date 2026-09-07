({
    doInit : function(component, event, helper) {
        let smiValue;
        let caseEligibility = component.get('v.caseEligibility');
        if(caseEligibility && caseEligibility.amt_income_smi__c){
            smiValue = Math.floor(caseEligibility.amt_income_smi__c*0.85*1000)/1000;
        }else{
            smiValue = 0;
        }
        component.set('v.smiValue',smiValue);
    }
})