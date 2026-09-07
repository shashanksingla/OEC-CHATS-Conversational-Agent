({
    checkCustomValidations : function(cmp){
        var isValid = true;
        var indivRecord = cmp.get("v.indivRec");
        var caseIndivRecord = cmp.get("v.caseIndiv");//CCCAP-13633
        var birthDate = new Date(indivRecord.DTE_DOB__c);
        var today = new Date();
        var age = today.getFullYear() - birthDate.getFullYear();
        var m = today.getMonth() - birthDate.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
            age--;
        }
        if(today<birthDate){
            cmp.find("T_SBSD_INDIV__c-DTE_DOB__c").set("v.message","DOB cannot be a future date");
            isValid = false;
        }else{
            cmp.find("T_SBSD_INDIV__c-DTE_DOB__c").set("v.message",null);
        }
        if(age<19 && $A.util.isEmpty(indivRecord.IND_CDE_TYPE_VERIF_DOB__c)){
            cmp.find("T_SBSD_INDIV__c-IND_CDE_TYPE_VERIF_DOB__c").set("v.message","Please enter a value");
            isValid = false
        }else{
            cmp.find("T_SBSD_INDIV__c-IND_CDE_TYPE_VERIF_DOB__c").set("v.message",null);
        }
        //Added status check as part of CCCAP-13633
        if(indivRecord.IND_CDE_TYPE_VERIF_DOB__c == 'V'&& (caseIndivRecord.Individual_Status__c!='PC' && caseIndivRecord.Individual_Status__c!='AC' && $A.util.isEmpty(indivRecord.CDE_SOURCE_VRFYD_DOB__c))){
            cmp.find("T_SBSD_INDIV__c-CDE_SOURCE_VRFYD_DOB__c").set("v.message","Required: How Verified is must for Verification Type DOB as \"Written Verification\"");
            isValid = false
        }else{
            cmp.find("T_SBSD_INDIV__c-CDE_SOURCE_VRFYD_DOB__c").set("v.message",null);
        }       
        if((cmp.get("v.isIntake")==false) && (caseIndivRecord.Individual_Status__c=='PC')){
            cmp.find("T_SBSD_CASE_INDIV__c-Individual_Status__c").set("v.message","Primary Caretaker may be edited from the Case Individual record.");
            isValid = false
        }else{
            cmp.find("T_SBSD_CASE_INDIV__c-Individual_Status__c").set("v.message",null)               
        }//end CCCAP-13633
        //CCCAP-14038
        if($A.util.isEmpty(indivRecord.CDE_GENDER__c)){
            cmp.find("T_SBSD_INDIV__c-CDE_GENDER__c").set("v.message","Please enter a value");
            isValid = false
        }else{
            cmp.find("T_SBSD_INDIV__c-CDE_GENDER__c").set("v.message","");
        }
        if($A.util.isEmpty(indivRecord.CDE_ATTENDING_SCHOOL1__c)){
            cmp.find("T_SBSD_INDIV__c-CDE_ATTENDING_SCHOOL1__c").set("v.message","Please enter a value");
            isValid = false
        }else{
            cmp.find("T_SBSD_INDIV__c-CDE_ATTENDING_SCHOOL1__c").set("v.message","");
        }
        if($A.util.isEmpty(indivRecord.IND_CHILD_IDEA__c)){
            cmp.find("T_SBSD_INDIV__c-IND_CHILD_IDEA__c").set("v.message","Please enter a value");
            isValid = false
        }else{
            cmp.find("T_SBSD_INDIV__c-IND_CHILD_IDEA__c").set("v.message","");
        }
        if($A.util.isEmpty(indivRecord.IND_CHILD_SCREEN__c)){
            cmp.find("T_SBSD_INDIV__c-IND_CHILD_SCREEN__c").set("v.message","Please enter a value");
            isValid = false
        }else{
            cmp.find("T_SBSD_INDIV__c-IND_CHILD_SCREEN__c").set("v.message","");
        }
        //End CCCAP-14038
        if(!$A.util.isEmpty(indivRecord.NBR_SSN__c) && (indivRecord.NBR_SSN__c).length < 9){
            cmp.find("T_SBSD_INDIV__c-NBR_SSN__c").set("v.message","Please provide the correct 9-digit SSN, include a leading zero, if applicable.");
            isValid = false
        }else{
            cmp.find("T_SBSD_INDIV__c-NBR_SSN__c").set("v.message",null);   
        }
        
        if(!$A.util.isEmpty(indivRecord.CDE_ATTENDING_SCHOOL_BEGINDATE__c) && !$A.util.isEmpty(indivRecord.DTE_DOB__c)) {
            var SADate = new Date(indivRecord.CDE_ATTENDING_SCHOOL_BEGINDATE__c);
            let fourYrsfrombirth = birthDate.setFullYear(birthDate.getFullYear() + 4);
            if(SADate < fourYrsfrombirth){
                cmp.find("T_SBSD_INDIV__c-CDE_ATTENDING_SCHOOL_BEGINDATE__c").set("v.message","School Age (SA) begin date cannot be created before 4th birthday of the child.");
                isValid = false
            }else{
                cmp.find("T_SBSD_INDIV__c-CDE_ATTENDING_SCHOOL_BEGINDATE__c").set("v.message",null);
            }
        }else{
            cmp.find("T_SBSD_INDIV__c-CDE_ATTENDING_SCHOOL_BEGINDATE__c").set("v.message",null);
        }
        return isValid;
    },
    validateDOBDependency:function(component,event,helper){
        let indivRecord = component.get('v.indivRec');
        if(indivRecord.DTE_DOB__c){
            component.set('v.isBeginDateRequired',false);
            var birthDate = new Date(indivRecord.DTE_DOB__c);
            var today = new Date();
            var age = today.getFullYear() - birthDate.getFullYear();
            if(age>=18){
                component.set('v.isBeginDateDisabled',true);
                component.set('v.indivRec.CDE_ATTENDING_SCHOOL_BEGINDATE__c',null);
            }else if(age>=5 && age<18){
                component.set('v.isBeginDateDisabled',false);
            }else{
                let isRequired = indivRecord.CDE_ATTENDING_SCHOOL1__c == 'Y';
                component.set('v.isBeginDateRequired',isRequired);
                component.set('v.isBeginDateDisabled',false);
                if(isRequired && !indivRecord.CDE_ATTENDING_SCHOOL_BEGINDATE__c){
                    var today = new Date();
                    component.set('v.indivRec.CDE_ATTENDING_SCHOOL_BEGINDATE__c',today.toISOString().split('T')[0]);
                }
            }
        }else{
            component.set('v.isBeginDateDisabled',true);
            component.set('v.isBeginDateRequired',false);
            component.set('v.indivRec.CDE_ATTENDING_SCHOOL_BEGINDATE__c',null);
        }
    }
})