({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        console.log("inside child checkCustomValidations cmp");
        var isValid = true;
        var indivRecord = cmp.get("v.indivRec");
        var indivInfoRec = cmp.get("v.indivInfoRec");
        var indivVerifRec =  cmp.get("v.indivVerifRec");
        var birthDate = new Date(indivRecord.DTE_DOB__c);        
        var today = new Date();
        var age = today.getFullYear() - birthDate.getFullYear();
        var m = today.getMonth() - birthDate.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
            age--;
        }	      

        if(age<19 && $A.util.isEmpty(indivVerifRec.CDE_TYPE_VERIF__c) && !(indivInfoRec.CDE_VALUE_INFO_INDIV__c == 'N/A-adult caretaker' || indivInfoRec.CDE_VALUE_INFO_INDIV__c=='N/A-not requesting child' )){
            
            cmp.find("T_INDIV_VERIF__c-CDE_TYPE_VERIF__c").set("v.message","Please enter a value");
            isValid = false;            
        }else{
            cmp.find("T_INDIV_VERIF__c-CDE_TYPE_VERIF__c").set("v.message",null);
        }
        
        return isValid;
    },
            //CCCAP-13633
    handleStsUpdate:function(component, event, helper) {
        if(component.get("v.caseIndiv.Individual_Status__c")=='PC'||component.get("v.caseIndiv.Individual_Status__c")=='AC') {
			component.set("v.indivInfoRec.CDE_VALUE_INFO_INDIV__c", 'N/A-adult caretaker');
        }
    },
    //end CCCAP-13633
})