({
    checkCustomValidations : function(cmp) {
        
        var isValid = true;
        var caseCopayRec = cmp.get("v.caseCopayRec");
        var firstDayOfNextMonth = this.getFirstDayOfNextMonth();
        var firstDayOfNextToNextMonth = this.getFirstDayOfNexToNexttMonth();
        var currentDate = this.getDateInUTC(new Date());
        
        if($A.util.isEmpty(cmp.get('v.parentFee'))) {
            cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","Please enter a value for this field");
            isValid = false;
        } else {
            cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message",null);
        }
        if(cmp.get('v.effectiveDate')=='' || cmp.get('v.effectiveDate')==undefined || cmp.get('v.effectiveDate')==null) {
            cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Please enter a value for this field");
            isValid = false;
        } else {
            
            
           
            var effectiveDate = this.getDateInUTC(cmp.get('v.effectiveDate'));
            if(effectiveDate.getDate()!=1) {
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Invalid Date! Must be 1st day of the month");
                isValid = false;
            }else if(cmp.get("v.eligRunDate") && effectiveDate<this.getDateInUTC(cmp.get("v.eligRunDate"))){
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Invalid Date! Must be after to eligibility begin date "+cmp.get("v.eligRunDate"));
                isValid = false;
            }
                else {
                    cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message",null);
                }
        }
        var isFirstCaseCopayRec = cmp.get("v.isFirstCaseCopayRec");
        if(!$A.util.isEmpty(caseCopayRec.amt_copay_case_assesd__c) && (!isFirstCaseCopayRec)){
            if(cmp.get('v.parentFee') && cmp.get('v.parentFee') != caseCopayRec.amt_copay_case_assesd__c) {
                if(cmp.get("v.overrideReason")==null || cmp.get("v.overrideReason")=='' || cmp.get("v.overrideReason")==undefined) {
                    cmp.find("batchsit_t_sbsd_case_copay__x-CDE_REASON_OVRD__c").set("v.message","Please enter a value");
                    isValid = false;   
                }
                else {
                    cmp.find("batchsit_t_sbsd_case_copay__x-CDE_REASON_OVRD__c").set("v.message",null);
                }
            }   
        }
        var effectiveDate = this.getDateInUTC(cmp.get('v.effectiveDate'));
        
        
        if(cmp.get('v.parentFee')) {
            if( cmp.get('v.parentFee')<= caseCopayRec.amt_copay_case_assesd__c && effectiveDate<firstDayOfNextMonth) {
            	cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","Parent Fee less than or equals to the previous record value!");
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Effective Date cannot be before the first of the next month.");
                isValid = false;
            }
            else if(cmp.get('v.parentFee')>caseCopayRec.amt_copay_case_assesd__c && currentDate.getDate()>=1 && currentDate.getDate()<=15 && effectiveDate < firstDayOfNextMonth) {
            	cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","Parent Fee exceeds the previous record value!");
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Effective date must be entered greater than this month.");
                isValid = false;
            }
            
                else if(cmp.get('v.parentFee')>caseCopayRec.amt_copay_case_assesd__c && 16<=currentDate.getDate() && currentDate.getDate()<=31 && effectiveDate < firstDayOfNextToNextMonth) {
                	cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","Parent Fee exceeds the previous record value!");
                    cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Effective date must be entered greater than next month.");
                    isValid = false;
                }
                    else {
                        cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message",null);
                    }   
        }
        return isValid;
    },
    
    getFirstDayOfNextMonth: function() {
        var now = new Date();
        var current;
       
        if (now.getMonth() == 11) {
            current = new Date(now.getFullYear() + 1, 0, 1);
        } else {
            current = new Date(now.getFullYear(), now.getMonth() + 1, 1);
        }
       
        return current;
    },
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    
    getFirstDayOfNexToNexttMonth: function() {
        var date =new Date();
        var now = date;
        
        var current;
        if (now.getMonth() == 10) {
            current = new Date(now.getFullYear() + 1, 0, 1);
        }
        else if(now.getMonth() == 11) {
            current = new Date(now.getFullYear(), 1, 1);
        }
            else {
                current = new Date(now.getFullYear(), now.getMonth() + 2, 1);
                
            }
        return current;
    },
    
    checkFieldValidity : function(cmp, fieldLabel, fieldValue) {
        var caseCopayRec = cmp.get("v.caseCopayRec");
        if(fieldLabel == 'Parent Fee') {
            if(cmp.get('v.parentFee')>caseCopayRec.amt_copay_case_assesd__c) {
                cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","WARNING! Parent Fee exceeds the previous record value.");
            } else {
                cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message",null);
            }
            cmp.set('v.parentFee', Math.floor(cmp.get('v.parentFee')));
        }
        if(fieldLabel == 'Effective Date') {
            if(new Date(cmp.get('v.effectiveDate')).getDate()!=1) {
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Invalid Date! Must be 1st day of the month");
            } else {
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message",null);
            }
        }
    }
})