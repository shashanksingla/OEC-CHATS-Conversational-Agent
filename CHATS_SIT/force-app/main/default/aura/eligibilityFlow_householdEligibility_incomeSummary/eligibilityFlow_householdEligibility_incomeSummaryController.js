({
	doInit : function(component, event, helper) {
        
        var indivEmplmtIncomeTypeEmploymentMap = component.get("v.indivEmplmtIncomeTypeEmployment");
        var indivEmplmtIncomeTypeEmploymentLst = [];
        /*if(indivEmplmtIncomeTypeEmploymentMap.length>0) {
            for(var i=0; i<indivEmplmtIncomeTypeEmploymentMap.length; i++) {
               //var eachVal = indivEmplmtIncomeTypeEmploymentMap[i].record;
                //eachVal.idn_case_indiv__r.NAM_INDIV__c = indivEmplmtIncomeTypeEmploymentMap[i].assocIndiv.NAM_INDIV__c;
                //indivEmplmtIncomeTypeEmploymentLst.push(eachVal);
            }
            //component.set("v.indivEmplmtIncomeTypeEmploymentLst",eachVal);
        }*/
        
        var transactionalArray = ['indivEmplmtIncomeTypeEmployment','indivEmplmtIncomeTypeSelfEmployment','indivEmplmtExpense','indivEligtyOtherIncome','indivEligtyIncomeDeduction'];
        var amountValuesOfTransactionalArray = ['amt_income_annual__c','amt_income_annual__c','amt_exp_annual__c','amt_income_annual__c','amt_ddtn_annual__c'];
        var grossValues = ['grossEmpIncome','grossSelfEmpIncome','grossSelfEmpexpense','grossOtherIncome','grossIncomeDeduction'];
        helper.computeGrossValues(component,transactionalArray,grossValues,amountValuesOfTransactionalArray);
		
	}
})