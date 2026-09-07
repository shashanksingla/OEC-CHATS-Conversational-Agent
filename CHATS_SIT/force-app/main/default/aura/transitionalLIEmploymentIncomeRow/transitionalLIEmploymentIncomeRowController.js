({
	doInit : function(component, event, helper) {
		var empIncomeRcrd = component.get("v.empIncomeRcrd");
        if(!$A.util.isEmpty(empIncomeRcrd.CDE_FREQ_INCOME__c)){
            if(empIncomeRcrd.CDE_FREQ_INCOME__c == '2' || empIncomeRcrd.CDE_FREQ_INCOME__c == '02'){
                empIncomeRcrd.CDE_FREQ_INCOME__c == 'Quarterly';
            }else if(empIncomeRcrd.CDE_FREQ_INCOME__c == '4' || empIncomeRcrd.CDE_FREQ_INCOME__c == '04' ){
                empIncomeRcrd.CDE_FREQ_INCOME__c == 'Monthly';
            }else if(empIncomeRcrd.CDE_FREQ_INCOME__c == '5' || empIncomeRcrd.CDE_FREQ_INCOME__c == '05'){
                empIncomeRcrd.CDE_FREQ_INCOME__c == 'Twice per Month';
            }else if(empIncomeRcrd.CDE_FREQ_INCOME__c == '6' || empIncomeRcrd.CDE_FREQ_INCOME__c == '06'){
                empIncomeRcrd.CDE_FREQ_INCOME__c == 'One Time Only';
            }else if(empIncomeRcrd.CDE_FREQ_INCOME__c == '8' || empIncomeRcrd.CDE_FREQ_INCOME__c == '08'){
                empIncomeRcrd.CDE_FREQ_INCOME__c == 'Weekly';
            }else if(empIncomeRcrd.CDE_FREQ_INCOME__c == '9' || empIncomeRcrd.CDE_FREQ_INCOME__c == '09'){
                empIncomeRcrd.CDE_FREQ_INCOME__c == 'Annually';
            }else if(empIncomeRcrd.CDE_FREQ_INCOME__c == '10'){
                empIncomeRcrd.CDE_FREQ_INCOME__c == 'Semi-Annually';
            }else if(empIncomeRcrd.CDE_FREQ_INCOME__c == '12'){
                empIncomeRcrd.CDE_FREQ_INCOME__c == 'Every Two Weeks';
            }else if(empIncomeRcrd.CDE_FREQ_INCOME__c == '13'){
                empIncomeRcrd.CDE_FREQ_INCOME__c == 'Every Other Month';
            }
            
            component.set("v.empIncomeRcrd", empIncomeRcrd);
        }
	}
})