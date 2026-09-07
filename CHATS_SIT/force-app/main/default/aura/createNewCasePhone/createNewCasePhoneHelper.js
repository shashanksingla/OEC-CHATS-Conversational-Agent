({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
       
        
        var isValid = true;
        var casePhoneRec = cmp.get("v.casePhoneRec");
       
        var errorMessages = [];
        if((casePhoneRec.NBR_PHONE_EXTN__c!='' && casePhoneRec.NBR_PHONE_EXTN__c!=null) && (casePhoneRec.NBR_PHONE__c=='' || casePhoneRec.NBR_PHONE__c==null)){
            errorMessages.push("Please provide Message/Work Phone Number (XXX-XXX-XXXX)");
        }
        var caseInfoRec = cmp.get("v.caseInfoRec");
        if(caseInfoRec){
            
            if(caseInfoRec.TXT_VALUE_INFO_CASE__c == 'Home Phone' && casePhoneRec.CDE_TYPE_PHONE__c == 'HOM' && (casePhoneRec.NBR_PHONE__c=='' || casePhoneRec.NBR_PHONE__c==null)){
                errorMessages.push("Please provide Home Phone Number");
            }else if(caseInfoRec.TXT_VALUE_INFO_CASE__c == 'Work Phone' && casePhoneRec.CDE_TYPE_PHONE__c == 'WOR' && (casePhoneRec.NBR_PHONE__c=='' || casePhoneRec.NBR_PHONE__c==null)){
                errorMessages.push("Please provide Work Phone Number");
            }else if(caseInfoRec.TXT_VALUE_INFO_CASE__c == 'Mobile Phone' && casePhoneRec.CDE_TYPE_PHONE__c == 'MOB' && (casePhoneRec.NBR_PHONE__c=='' || casePhoneRec.NBR_PHONE__c==null)){
                errorMessages.push("Please provide Mobile Phone Number");
            }
        }
        
        if(errorMessages.length>0){
            var errorMessage = "";
            for(var i=0;i<errorMessages.length;i++){
                errorMessage+=errorMessages[i]+", ";
            }
            errorMessage = errorMessage.substring(0,errorMessage.length-2);
            cmp.find("T_SBSD_CASE_PHONE__c-NBR_PHONE__c").set("v.message",errorMessage);
            isValid = false;
        }else{
            cmp.find("T_SBSD_CASE_PHONE__c-NBR_PHONE__c").set("v.message",null);
        }
        
        return isValid;
    }
})