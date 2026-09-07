({
    validateFields : function(cmp) {
        
        var areAllFieldsValid = true;
        
        //[SJ 3/28: Added logic to check if caseEligibilityRun is modified]
        
        if(cmp.get("v.caseEligibilityRun.dte_redet_ovrd__c")==cmp.get("v.dte_redet_ovrd__c") &&
           cmp.get("v.caseEligibilityRun.cde_date_redet_ovrd__c")==cmp.get("v.cde_date_redet_ovrd__c") &&
           cmp.get("v.caseEligibilityRun.txt_cmt_ovrd__c")==cmp.get("v.txt_cmt_ovrd__c")
          ){
            cmp.set("v.pageMessages",[$A.get("$Label.c.Nothing_Changed_Click_Cancel")]);
            areAllFieldsValid=false;
        }else{
            //[SJ 3/28: Changed logic to check caseEligibilityRun.dte_redet_ovrd__c]
            var dteRedetOvrdError = "";
            if($A.util.isEmpty(cmp.get("v.caseEligibilityRun.dte_redet_ovrd__c")) && 
              (cmp.get("v.caseEligibilityRun.cde_date_redet_ovrd__c")!=cmp.get("v.cde_date_redet_ovrd__c") ||
           		cmp.get("v.caseEligibilityRun.txt_cmt_ovrd__c")!=cmp.get("v.txt_cmt_ovrd__c"))
              ){
                dteRedetOvrdError = $A.get("$Label.c.HER_Redetermination_Override_Date_Mandatory");
            }

            //[SJ 4/24: Changed logic to check caseEligibilityRun.dte_redet_ovrd__c if override reason & comment is changed]
	    //[BJ: 3/1 Commented for CCCAP-2822 - Allow past dates in Override Case Redet date
            /*if(!$A.util.isEmpty(cmp.get("v.caseEligibilityRun.dte_redet_ovrd__c")) && cmp.get("v.caseEligibilityRun.dte_redet_ovrd__c")<this.getCurrentSystemDate()){
                dteRedetOvrdError = $A.get("$Label.c.HER_Redetermination_Override_Date_In_Past_Error");
            }*/	
            
            if(!$A.util.isEmpty(dteRedetOvrdError)){
                cmp.find("batchsit_t_eligty_run__x-dte_redet_ovrd__c").set("v.message",dteRedetOvrdError);                
                areAllFieldsValid=false;
            }else{
                cmp.find("batchsit_t_eligty_run__x-dte_redet_ovrd__c").set("v.message",null);                
            }
            
            if(areAllFieldsValid){
                //[SJ 3/28: Changed logic to check caseEligibilityRun.dte_redet_ovrd__c]
                if(!$A.util.isEmpty(cmp.get("v.caseEligibilityRun.dte_redet_ovrd__c")) && 
                   $A.util.isEmpty(cmp.get("v.caseEligibilityRun.cde_date_redet_ovrd__c"))
                  ){
                    cmp.find("batchsit_t_eligty_run__x-cde_date_redet_ovrd__c").set("v.message", $A.get("$Label.c.HER_Override_Reason_Mandatory"));
                    areAllFieldsValid=false;
                }else{
                    cmp.find("batchsit_t_eligty_run__x-cde_date_redet_ovrd__c").set("v.message",null);
                }
                
                if(!$A.util.isEmpty(cmp.get("v.caseEligibilityRun.dte_redet_ovrd__c")) && 
                   $A.util.isEmpty(cmp.get("v.caseEligibilityRun.txt_cmt_ovrd__c"))
                  ){
                    cmp.find("batchsit_t_eligty_run__x-txt_cmt_ovrd__c").set("v.message", $A.get("$Label.c.HER_Override_Comment_Mandatory"));
                    areAllFieldsValid=false;
                }else{
                    cmp.find("batchsit_t_eligty_run__x-txt_cmt_ovrd__c").set("v.message",null);
                }
                
            }
            
            if(!areAllFieldsValid){
                cmp.set("v.pageMessages",[$A.get("$Label.c.ERRORS_ON_THIS_PAGE")]);   
            }else{
                cmp.set("v.pageMessages",[]);   
            }
        }
        return areAllFieldsValid;
    },
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    }    
})