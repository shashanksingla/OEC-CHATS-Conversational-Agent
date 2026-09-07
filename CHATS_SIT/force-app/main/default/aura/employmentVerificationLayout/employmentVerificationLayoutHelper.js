({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
       
        
        var isValid = true;
        var employmentInformation = cmp.get("v.employmentInformation");
        if(employmentInformation.Id==undefined && (employmentInformation.CDE_TYPE_VERIF__c!=null && employmentInformation.CDE_TYPE_VERIF__c!='')){
            cmp.find("T_INDIV_EMPLMT_INFO__c-CDE_TYPE_VERIF__c").set("v.message","Please first indicate Maternity Leave and Begin Date on the Employment record before entering maternity leave verification information.");
            isValid = false
        }else{
            cmp.find("T_INDIV_EMPLMT_INFO__c-CDE_TYPE_VERIF__c").set("v.message",null);
        }
        return isValid;
    }
})