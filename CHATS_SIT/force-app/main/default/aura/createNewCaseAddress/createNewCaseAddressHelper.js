({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
       
        var isValid = true;
        
		var caseAddressRec = cmp.get("v.caseAddressRec");
        if(caseAddressRec.CDE_TYPE_ADR__c=='MAL'){
            if(caseAddressRec.CDE_TYPE_VERIF__c == 'V' && $A.util.isEmpty(caseAddressRec.CDE_SOURCE_VRFD_ADR__c)){
                cmp.find("T_SBSD_CASE_ADR__c-CDE_SOURCE_VRFD_ADR__c").set("v.message",'"How Verified" is required if Verified is "Written Verification".');
                isValid = false;
            }else{
                cmp.find("T_SBSD_CASE_ADR__c-CDE_SOURCE_VRFD_ADR__c").set("v.message",null);
            }
        }
        return isValid;
	}
})