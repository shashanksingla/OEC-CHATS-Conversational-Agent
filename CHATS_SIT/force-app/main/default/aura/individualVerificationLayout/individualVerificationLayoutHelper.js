({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations. 
        
        var isValid = true;
        var indVerif = cmp.get("v.indVerif");
        var indivInfos = cmp.get("v.indivInfos");
        var individuald=cmp.get("v.individual");// {Added by Pragyan Nayak for CCCAP-2710 
        var hasChildIndividual = cmp.get("v.hasChildIndividual");
        var birthDate = new Date(individuald.DTE_DOB__c);
        var today = new Date();
        var age = today.getFullYear() - birthDate.getFullYear();
        var m = today.getMonth() - birthDate.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
            age--;
        }	        
        // Only validate fields if hasChildIndividual is true. added check as part of CCCAP-14038
        if(hasChildIndividual) {
            if(age<19 && $A.util.isEmpty(individuald.IND_CDE_TYPE_VERIF_DOB__c)){
                cmp.find("T_SBSD_INDIV__c-CDE_TYPE_VERIF_DOB__c").set("v.message","Please enter a value");
                isValid = false;
                
            }
            else{
                cmp.find("T_SBSD_INDIV__c-CDE_TYPE_VERIF_DOB__c").set("v.message",null);
                
            } // Added by Pragyan Nayak for CCCAP-2710   }    
            
            
            if(indivInfos.length==0 && (indVerif.CDE_TYPE_VERIF__c!="" && indVerif.CDE_TYPE_VERIF__c!=null)){
                cmp.find("T_INDIV_VERIF__c-CDE_TYPE_VERIF__c").set("v.message",'Please enter Citizenship Status for the Individual (by creating an Individual Information record with Individual Information Type as "Citizenship Status") before entering Citizenship Status verification information.');
                isValid = false;
            }
            else if (age<19 && $A.util.isEmpty(indVerif.CDE_TYPE_VERIF__c)) {
                cmp.find("T_INDIV_VERIF__c-CDE_TYPE_VERIF__c").set("v.message","Please enter a value");
                isValid = false;  //Added by Pragyan Nayak for CCCAP-2710        
            }
            
                else{
                    cmp.find("T_INDIV_VERIF__c-CDE_TYPE_VERIF__c").set("v.message",null);
                }       
            
            if(indivInfos.length==0 && (cmp.get("v.individual.CDE_SOURCE_VRFYD_CITIZEN__c")!="" && cmp.get("v.individual.CDE_SOURCE_VRFYD_CITIZEN__c")!=null)){
                cmp.find("T_SBSD_INDIV__c-CDE_SOURCE_VRFYD_CITIZEN__c").set("v.message",'Please enter Citizenship Status for the Individual (by creating an Individual Information record with Individual Information Type as "Citizenship Status") before entering Citizenship Status verification information.');
                isValid = false;
            }else{
                cmp.find("T_SBSD_INDIV__c-CDE_SOURCE_VRFYD_CITIZEN__c").set("v.message",null);
            }
            
            
            if(cmp.get("v.individual.IND_CDE_TYPE_VERIF_DOB__C")=="V" && 
               (cmp.get("v.individual.CDE_SOURCE_VRFYD_DOB__C")==null ||
                cmp.get("v.individual.CDE_SOURCE_VRFYD_DOB__C")=="")) {
                cmp.find("T_SBSD_INDIV__c-CDE_SOURCE_VRFYD_DOB__c").set("v.message",'Please enter How Verified (DOB) when the DOB is Written Verified.');
                isValid = false;
            }else{
                cmp.find("T_SBSD_INDIV__c-CDE_SOURCE_VRFYD_DOB__c").set("v.message",null);
            }
        }
        return isValid;
    },
    //CCCAP-13633
    checkForChildIndividuals: function(component) {
        var caseIndivs = component.get("v.caseIndiv");
        var hasChild = false;        
        if (caseIndivs && caseIndivs.length > 0) {
            for (var i = 0; i < caseIndivs.length; i++) {
                //added date check for CCCAP-14297
                if (caseIndivs[i].Individual_Status__c === 'Child' && ($A.util.isEmpty(caseIndivs[i].DTE_END_EFFV__c) || new Date(caseIndivs[i].DTE_END_EFFV__c) >= new Date())) {
                    hasChild = true;
                    break;
                }
            }
        }
        component.set("v.hasChildIndividual", hasChild);
    }
})