({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        var rateType = ';'+cmp.get("v.countyPlanRec").ELIGIBILITY_Q9_2_1__c+';';
        var isValid = true;
        var isValid1=true;
        var isValid2=true;
        isValid=this.cannotAnswerWaitlistEnrolmentFreeze(cmp);
        if(isValid){
            isValid1= this.checkWaitlistEnrolmentFreeze(cmp);
        	isValid2=this.handleNoSelectionValHelper(cmp);
        	isValid = isValid1 && isValid2;}
        else{
            this.checkWaitlistEnrolmentFreeze(cmp);
            this.handleNoSelectionValHelper(cmp);
        }
        //Moved to handleNoSelectionValHelper CCCAP-15399
        
        /*if(rateType !=null && rateType !='' && ((rateType.indexOf(';9;')>-1 || rateType.indexOf(';4;')>-1 || rateType.indexOf(';6;')>-1 || rateType.indexOf(';12;')>-1) && 
                                                !(rateType.indexOf(';1;')!= -1 && rateType.indexOf(';11;') != -1 && rateType.indexOf(';7;') != -1))){
            cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q9_2_1__c").set("v.message",'All Federal Target Populations must be selected before selecting a county identified Target Population.');
            isValid = false;
        }else{
            if(!$A.util.isEmpty(cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q9_2_1__c"))){
                cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q9_2_1__c").set("v.message",null); 
            }
        }*/
        /*
        var stateSMI =$A.get("$Label.c.State_SMI");
        var maxStateSMIErrorMsg = 'Value Cannot be greater than 85% of State SMI('+stateSMI+')';
        if(countyPlanRec.ELIGIBILITY_Q1_1__c > stateSMI*85/100){
           cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q1_1__c").set("v.message",maxStateSMIErrorMsg);
           isValid = false; 
        }
        else if((countyPlanRec.ELIGIBILITY_Q1_1__c != null) && (countyPlanRec.ELIGIBILITY_Q1_1__c % 5 != 0)){
            cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q1_1__c").set("v.message","Value must be a multiple of 5.");
            isValid = false;
        }else {
            cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q1_1__c").set("v.message",null);
        }
        if(countyPlanRec.ELIGIBILITY_Q1_2__c > stateSMI*85/100){
           cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q1_2__c").set("v.message",maxStateSMIErrorMsg);
           isValid = false; 
        }
        else 
        if((countyPlanRec.ELIGIBILITY_Q1_2__c != null) && (countyPlanRec.ELIGIBILITY_Q1_2__c % 5 != 0)){
            cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q1_2__c").set("v.message","Value must be a multiple of 5.");
            isValid = false;
        }else {
            cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q1_2__c").set("v.message",null);
        }
        if( (countyPlanRec.ELIGIBILITY_Q1_1__c != null) && (countyPlanRec.ELIGIBILITY_Q1_2__c != null) && (countyPlanRec.ELIGIBILITY_Q1_1__c > countyPlanRec.ELIGIBILITY_Q1_2__c)){
            cmp.set("v.messageType" , "error");
            cmp.set("v.pageMessages", ["% of poverty level at application must be less than % of poverty level for ongoing cases in Question 1"]);
            isValid = false;
        }
        else{
            cmp.set("v.pageMessages",[]);
        }
        */
        return isValid;
    },
    checkWaitlistEnrolmentFreeze : function(cmp){
        var isValid = true;
        var countyPlanRec = cmp.get("v.countyPlanRec");
        if(countyPlanRec.ELIGIBILITY_Q9__c=='Y' && countyPlanRec.ELIGIBILITY_Q10__c=='Y' ){
            cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q10__c").set("v.message",'You cannot activate enrollment Freeze if Waitlist is turned on.');
            isValid = false; 
        }
        else {
            var msg = cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q10__c").get("v.message");
            if(msg=='You cannot activate enrollment Freeze if Waitlist is turned on.'){
                cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q10__c").set("v.message",null);
            }
            isValid = true;
        }
        //this.cannotAnswerWaitlistEnrolmentFreeze(cmp);
        return isValid;
    },
    setRequired : function(cmp){        
        var countyPlan = cmp.get("v.countyPlanRec");
        if(countyPlan.ELIGIBILITY_Q10_4__c && countyPlan.ELIGIBILITY_Q10_4__c.indexOf('0;')!=-1){
            cmp.set("v.q10_4_other_Required", true);
        }else{
            cmp.set("v.q10_4_other_Required", false);
        }
        if(countyPlan.ELIGIBILITY_Q9_2_1__c && countyPlan.ELIGIBILITY_Q9_2_1__c.indexOf('12;')!=-1){
            cmp.set("v.isELIGIBILITY_Q9ReadOnly", true);
        }else{
            cmp.set("v.isELIGIBILITY_Q9ReadOnly", false);
        }
        
        var countyPlanCheck = ';'+countyPlan.ELIGIBILITY_Q9_2_1__c+';';
        if(countyPlanCheck &&
            (countyPlanCheck.indexOf(';1;')!=-1 && countyPlanCheck.indexOf(';11;')!=-1 && countyPlanCheck.indexOf(';7;')!=-1)){
            cmp.set("v.allFederalValuesSelected", false);
        } else {
            cmp.set("v.allFederalValuesSelected", true);
        }
        /* commented for CCCAP-14956
         * if(countyPlan.ELIGIBILITY_Q9_4__c && countyPlan.ELIGIBILITY_Q9_4__c.indexOf('Other;')!=-1){
            cmp.set("v.isELIGIBILITY_Q9_4ReadOnly", true);
        }else{
            cmp.set("v.isELIGIBILITY_Q9_4ReadOnly", false);
        }*/
        if("v.isDateAfter_16Feb2025"==false){
            if(countyPlan.ELIGIBILITY_Q2__c!='Y'){
                cmp.set('v.countyPlanRec.ELIGIBILITY_Q2_1__c','');
            }
            if(countyPlan.ELIGIBILITY_Q3__c!='Y'){
               cmp.set('v.countyPlanRec.ELIGIBILITY_Q3_1__c','');
        }
    }
        if(countyPlan.PF_Q1__c!='Y'){
            cmp.set('v.countyPlanRec.PF_Q2__c','');
            cmp.set('v.countyPlanRec.PF_Q3__c','');
            cmp.set('v.countyPlanRec.PF_Q4__c','');            
            cmp.set('v.countyPlanRec.PF_Q4_1__c','');
            cmp.set('v.countyPlanRec.PF_Q5__c','');
            cmp.set('v.countyPlanRec.PF_Q6__c','');
            cmp.set('v.countyPlanRec.PF_Q7__c','');
            cmp.set('v.countyPlanRec.PF_Q7_1__c','');
            cmp.set('v.countyPlanRec.PF_Q8__c','');
            cmp.set('v.countyPlanRec.PF_Q9__c','');
            cmp.set('v.countyPlanRec.PF_Q7_new__c','');
        }
        if(countyPlan.PF_Q4__c!='7'){
            cmp.set('v.countyPlanRec.PF_Q4_1__c','');
        }
        if(countyPlan.PF_Q7__c!='7'){
            cmp.set('v.countyPlanRec.PF_Q7_1__c','');
        }
        if(countyPlan.PF_Q10__c!='Y'){
            cmp.set('v.countyPlanRec.PF_Q10_1__c','');
            cmp.set('v.countyPlanRec.PF_Q10_2__c','');
        }
        if(countyPlan.PF_Q11__c!='Y'){
            cmp.set('v.countyPlanRec.PF_Q11_1__c','');
        }
        if(countyPlan.ELIGIBILITY_Q9__c!='Y'){
            //cmp.set('v.countyPlanRec.ELIGIBILITY_Q9_4__c',''); commented for CCCAP-14956
            //cmp.set('v.countyPlanRec.ELIGIBILITY_Q9_4_2__c',''); commented for CCCAP-14956
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q9_1__c','');
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q9_3__c','');
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q9_2_1__c','');
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q9_2_2__c','');
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q9_5__c','');
        }
        if(countyPlan.ELIGIBILITY_Q10__c!='Y'){
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q10_1__c','');
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q10_2__c','');
        }
        if(countyPlan.ELIGIBILITY_Q11__c!='Y'){
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q11_1__c','');
        }
        if(countyPlan.ELIGIBILITY_Q11_1__c!='Y'){
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q11_1D__c','');
        }
        if(countyPlan.ELIGIBILITY_Q12__c!='Y'){
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q12_1__c','');
        }
        if(countyPlan.ELIGIBILITY_Q7_1__c!='N'){
            cmp.set('v.countyPlanRec.ELG_ATS_Q2__c','');
        }
        if(!$A.util.isEmpty(countyPlan.ELIGIBILITY_Q20_new__c) && countyPlan.ELIGIBILITY_Q20_new__c.indexOf('Other')!=-1){
            cmp.set("v.isQ20_OtherRequired", true);
        } else{
            cmp.set("v.isQ20_OtherRequired", false);
            cmp.set('v.countyPlanRec.ELIGIBILITY_Q20_other__c','');
        }
    },
    
    cannotAnswerWaitlistEnrolmentFreeze: function(cmp){
        var isValid = true;
        var waitlistEnrolmentFreezeSwitch = $A.get("$Label.c.RestrictWaitlistEnrolmentFreeze");
        var countyPlanRec = cmp.get("v.countyPlanRec");
        var approvalDate = new Date("2019-07-01");
        if(countyPlanRec.ELIGIBILITY_Q9__c=='Y' && waitlistEnrolmentFreezeSwitch && new Date(countyPlanRec.DTE_BEGIN_EFFEV__c )< approvalDate){
            cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q9__c").set("v.message",'Is not applicable until 7/1/2019 You must select “No”.');
            isValid = false; 
        }
        else{
            cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q9__c").set("v.message",null);
            isValid = true;
        }
        if(countyPlanRec.ELIGIBILITY_Q10__c=='Y' && waitlistEnrolmentFreezeSwitch && new Date(countyPlanRec.DTE_BEGIN_EFFEV__c )< approvalDate){
            cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q10__c").set("v.message",'Is not applicable until 7/1/2019 You must select “No”.');
            isValid = false; 
        }
        else{
            cmp.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q10__c").set("v.message",null);
            isValid = true;
        }
        return isValid;
        
    },
    
    handleNoSelectionValHelper: function(component){
        var isValid = true;
        var rateType = ';'+component.get("v.countyPlanRec").ELIGIBILITY_Q9_2_1__c+';';
        /*
        if(rateType !=null && rateType !='' && ((rateType.indexOf(';9;')>-1 || rateType.indexOf(';4;')>-1 || rateType.indexOf(';6;')>-1 || rateType.indexOf(';12;')>-1) && 
                                                !(rateType.indexOf(';1;')!= -1 && rateType.indexOf(';11;') != -1 && rateType.indexOf(';7;') != -1))){
            component.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q9_2_1__c").set("v.message",'All Federal Target Populations must be selected before selecting a county identified Target Population.');  
        }else{
            if(!$A.util.isEmpty(component.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q9_2_1__c"))){
                component.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q9_2_1__c").set("v.message",null); 
            }
        }*/
       //CCCAP-15399
        if (rateType !== '' && rateType!=null) {
            var fieldCmp = component.find("T_COUNTY_PLAN__c-ELIGIBILITY_Q9_2_1__c");
            
            var has1 = rateType.indexOf(';1;') > -1;
            var has11 = rateType.indexOf(';11;') > -1;
            var has7 = rateType.indexOf(';7;') > -1;
            var has13 = rateType.indexOf(';13;') > -1;
            
            var has4 = rateType.indexOf(';4;') > -1;
            var has6 = rateType.indexOf(';6;') > -1;
            var has12 = rateType.indexOf(';12;') > -1;
            
            var anyFederalSelected = (has1 || has11 || has7);
            var anyCountySelected = (has4 || has6 || has12);
            
            //all three federal populations must be selected, and TANF cannot be selected by itself
            if (has13 && component.get("v.allFederalValuesSelected")) {
                isValid = false;
                fieldCmp.set("v.message", "All Federal Target Populations must be selected before selecting TANF.");
            }
            //counties cannot select county-identified priority populations without first selecting all 3 federal and TANF
            else if (anyCountySelected && !(has13 && component.get("v.allFederalValuesSelected")==false)) {
                isValid = false;
                fieldCmp.set("v.message", "All Federal Target Populations and TANF must be selected before selecting a county identified Target Population.");
            }
            // If 1 or 2 federal populations are selected, all 3 must be selected plus TANF
                else if (!(component.get("v.allFederalValuesSelected")==false && has13) && anyFederalSelected) {
                    isValid = false;
                    fieldCmp.set("v.message", "All Federal Target Populations and TANF must be selected.");
                }else if(!$A.util.isEmpty(fieldCmp)){
                    isValid = true;
                    fieldCmp.set("v.message", "");}          
        }
        return isValid;
    }
})