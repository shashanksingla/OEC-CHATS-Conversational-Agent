({
    checkCustomValidations : function(cmp){
		//should be implemented in child component if there are any custom validations.
		
		
		var isValid = true;
        var caseHomelessRec = cmp.get("v.caseHomelessRec");
       
        /*if(caseHomelessRec.IND_LVG_OTHER__c==true && (caseHomelessRec.TXT_CMT__c=='' || caseHomelessRec.TXT_CMT__c==null)){
            cmp.find("T_SBSD_CASE_HOMELESS__c-TXT_CMT__c").set("v.message","Required if IND_LVG_OTHER = TRUE");
        	isValid = false;
        }else{
			cmp.find("T_SBSD_CASE_HOMELESS__c-TXT_CMT__c").set("v.message",null);            
        }*/
        return isValid;
    }
})