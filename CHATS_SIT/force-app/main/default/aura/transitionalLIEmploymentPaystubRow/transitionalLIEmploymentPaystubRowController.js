({
	doInit : function(component, event, helper) {
		var empPaystubRcrd = component.get("v.empPaystubRcrd");
        if(!$A.util.isEmpty(empPaystubRcrd.INCOME_FREQUENCY__c)){
            if(empPaystubRcrd.INCOME_FREQUENCY__c == '2' || empPaystubRcrd.INCOME_FREQUENCY__c == '02'){
                empPaystubRcrd.INCOME_FREQUENCY__c == 'Quarterly';
            }else if(empPaystubRcrd.INCOME_FREQUENCY__c == '4' || empPaystubRcrd.INCOME_FREQUENCY__c == '04' ){
                empPaystubRcrd.INCOME_FREQUENCY__c == 'Monthly';
            }else if(empPaystubRcrd.INCOME_FREQUENCY__c == '5' || empPaystubRcrd.INCOME_FREQUENCY__c == '05'){
                empPaystubRcrd.INCOME_FREQUENCY__c == 'Twice per Month';
            }else if(empPaystubRcrd.INCOME_FREQUENCY__c == '6' || empPaystubRcrd.INCOME_FREQUENCY__c == '06'){
                empPaystubRcrd.INCOME_FREQUENCY__c == 'One Time Only';
            }else if(empPaystubRcrd.INCOME_FREQUENCY__c == '8' || empPaystubRcrd.INCOME_FREQUENCY__c == '08'){
                empPaystubRcrd.INCOME_FREQUENCY__c == 'Weekly';
            }else if(empPaystubRcrd.INCOME_FREQUENCY__c == '9' || empPaystubRcrd.INCOME_FREQUENCY__c == '09'){
                empPaystubRcrd.INCOME_FREQUENCY__c == 'Annually';
            }else if(empPaystubRcrd.INCOME_FREQUENCY__c == '10'){
                empPaystubRcrd.INCOME_FREQUENCY__c == 'Semi-Annually';
            }else if(empPaystubRcrd.INCOME_FREQUENCY__c == '12'){
                empPaystubRcrd.INCOME_FREQUENCY__c == 'Every Two Weeks';
            }else if(empPaystubRcrd.INCOME_FREQUENCY__c == '13'){
                empPaystubRcrd.INCOME_FREQUENCY__c == 'Every Other Month';
            }
            
            component.set("v.empPaystubRcrd", empPaystubRcrd);
        }
	}
})