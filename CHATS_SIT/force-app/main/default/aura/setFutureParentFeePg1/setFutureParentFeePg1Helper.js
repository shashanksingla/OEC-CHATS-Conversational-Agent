({
    checkCustomValidations : function(cmp) {
        var isValid = true;
        var caseCopayRec = cmp.get("v.caseCopayRec");
        var newCaseCopayRec = cmp.get("v.newCaseCopayRec");
        var firstDayOfNextMonth = this.getFirstDayOfNextMonth();
        var firstDayOfNextToNextMonth = this.getFirstDayOfNexToNexttMonth();
        var currentDate = this.getDateInUTC(new Date());
        var parentFee = newCaseCopayRec.amt_copay_case_assesd__c;
        var newEffectiveDate =newCaseCopayRec.dte_begin_effv__c;
        var overrideReason = newCaseCopayRec.cde_reason_ovrd__c;
        var isUpdate =false;
        var isfutureParentFee =false;
        var existingCopayBeginDate = caseCopayRec.dte_begin_effv__c;
        var existingCopayEndDate = this.getDateInUTC(caseCopayRec.dte_end_effv__c);
        var effectiveDate = this.getDateInUTC(newEffectiveDate);
         if(!$A.util.isEmpty(cmp.get("v.caseCopayRec")) && (!$A.util.isEmpty(cmp.get("v.caseCopayRec").dte_begin_effv__c))){
            if((this.getDateInUTC(cmp.get("v.caseCopayRec").dte_begin_effv__c)).getTime() === effectiveDate.getTime() ){
               isUpdate=true; 
            }
            if(cmp.get("v.caseCopayRec").dte_end_effv__c != null && existingCopayEndDate > currentDate){
                isfutureParentFee = true;
            }
            
        }
         if($A.util.isEmpty(parentFee)) {
           // cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","Please enter a value for this field");
            isValid = false;
        }  else if(!$A.util.isEmpty(caseCopayRec.amt_copay_case_assesd__c)){
            if(parentFee>caseCopayRec.amt_copay_case_assesd__c) {
                cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","WARNING! Parent Fee exceeds the previous record value.");
            } else {
                cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message",null);
            } 
            cmp.set('v.newCaseCopayRec.amt_copay_case_assesd__c', Math.floor(parentFee));
        } else {
            cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message",null);
        }
        if($A.util.isEmpty(newEffectiveDate)) {
           // cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Please enter a value for this field");
            isValid = false;
        } else {
            var currentDate = this.getDateInUTC(new Date());
            
            if((effectiveDate)<= currentDate && (!isUpdate)){
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Date must not be before the 1st of next month.");
                isValid = false;
            }
            else if(effectiveDate.getDate()!=1) {
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Must be 1st day of the month.");
                isValid = false;
            }else if(cmp.get("v.eligRunDate") && effectiveDate<this.getDateInUTC(cmp.get("v.eligRunDate"))){
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Must be after to eligibility begin date."+cmp.get("v.eligRunDate"));
                isValid = false;
            }
                else if(!$A.util.isEmpty(cmp.get("v.caseCopayRec").dte_begin_effv__c) && this.getDateInUTC(cmp.get("v.caseCopayRec").dte_begin_effv__c) && this.getDateInUTC(cmp.get("v.caseCopayRec").dte_begin_effv__c)>= effectiveDate && (!isUpdate)){
                    cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Please set a future parent fee that is after Effective Date of the most recent parent fee on this case.");
                    isValid = false;
                }
             else if(isfutureParentFee && isUpdate){
                    cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","A future dated parent fee already exists. Please set a future parent fee after the most recent effective parent fee OR delete the future parent fee to update the existing parent fee.");
                    isValid = false;
             } else if(isfutureParentFee && (!isUpdate)){
                 cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","A future dated parent fee already exists. Please set a future parent fee after the most recent effective parent fee OR delete the future parent fee to create a new parent fee.");
                    isValid = false;
             }
                    else {
                        cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message",null);
                    }
        }
        var isFirstCaseCopayRec = cmp.get("v.isFirstCaseCopayRec");
        if(!$A.util.isEmpty(caseCopayRec.amt_copay_case_assesd__c) && (!isFirstCaseCopayRec)){
            if(!$A.util.isEmpty(parentFee) && parentFee != caseCopayRec.amt_copay_case_assesd__c) {
                if($A.util.isEmpty(overrideReason)) {
                    cmp.set("v.isOverrideReasonRequired",true);
                   // cmp.find("batchsit_t_sbsd_case_copay__x-CDE_REASON_OVRD__c").set("v.message","Please enter a value");
                    isValid = false;   
                }
                else {
                    cmp.find("batchsit_t_sbsd_case_copay__x-CDE_REASON_OVRD__c").set("v.message",null);
                }
            }   
        }
        var effectiveDate = this.getDateInUTC(newEffectiveDate);
        var userLocalDateTime = new Date();
        var dateAfter15Days = new Date();
        dateAfter15Days.setDate(dateAfter15Days.getDate() + 15);
        if(!$A.util.isEmpty(parentFee) && (!$A.util.isEmpty(caseCopayRec.amt_copay_case_assesd__c))) {
            if( parentFee<= caseCopayRec.amt_copay_case_assesd__c && effectiveDate < firstDayOfNextMonth) {
                cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","Parent Fee less than or equals to the previous record value!");
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Effective Date cannot be before the first of the next month.");
                isValid = false;
            }
            else if(parentFee>caseCopayRec.amt_copay_case_assesd__c && userLocalDateTime.getDate()>=1 && userLocalDateTime.getDate()<=15  && effectiveDate < firstDayOfNextMonth) {
                cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","WARNING! Parent Fee exceeds the previous record value.");
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Effective Date can not be before the first of the next month.");
                isValid = false;
            }
            else if(parentFee>caseCopayRec.amt_copay_case_assesd__c && userLocalDateTime.getDate()>=1 && userLocalDateTime.getDate()<=15 && dateAfter15Days >= firstDayOfNextMonth && effectiveDate < firstDayOfNextToNextMonth) {
                    cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","WARNING! Parent Fee exceeds the previous record value.");
                    cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Effective date must be entered greater than next month.");
                    isValid = false;
                }
            
                else if(parentFee>caseCopayRec.amt_copay_case_assesd__c && 16<=userLocalDateTime.getDate() && userLocalDateTime.getDate()<=31 && dateAfter15Days >= firstDayOfNextMonth && effectiveDate < firstDayOfNextToNextMonth) {
                    cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","WARNING! Parent Fee exceeds the previous record value.");
                    cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Effective date must be entered greater than next month.");
                    isValid = false;
                }
            
                    else {
                      //  cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message",null);
                    }   
        }
        if(isFirstCaseCopayRec){
             if(userLocalDateTime.getDate()>=1 && userLocalDateTime.getDate()<=15  && effectiveDate < firstDayOfNextMonth) {
               // cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","WARNING! Parent Fee exceeds the previous record value.");
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Effective Date can not be before the first of the next month.");
                isValid = false;
            }
            else if( userLocalDateTime.getDate()>=1 && userLocalDateTime.getDate()<=15 && dateAfter15Days >= firstDayOfNextMonth && effectiveDate < firstDayOfNextToNextMonth) {
                    //cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","WARNING! Parent Fee exceeds the previous record value.");
                    cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Effective date must be entered greater than next month.");
                    isValid = false;
                }
            
                else if(16<=userLocalDateTime.getDate() && userLocalDateTime.getDate()<=31 && dateAfter15Days >= firstDayOfNextMonth && effectiveDate < firstDayOfNextToNextMonth) {
                    //cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","WARNING! Parent Fee exceeds the previous record value.");
                    cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Effective date must be entered greater than next month.");
                    isValid = false;
                }
            
                    else {
                      //  cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message",null);
                    }
        }
        if(!$A.util.isEmpty(parentFee)){
            let effectiveD = this.getDateInUTC(effectiveDate);
            let oct1Date = this.getDateInUTC(new Date("10/01/2024"));
                if(parentFee>5 && cmp.get("v.isAdamCounty") && effectiveD<oct1Date) {
                    cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","Adams County has elected to reduce all Case Parent Fees to $5.00 beginning 3/1/2024 for an initial 6 month period.  Please update the Case Parent Fee to $5.00 or less.");
                    isValid = false;
                } else {
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
        var newCaseCopayRec = cmp.get("v.newCaseCopayRec");
        var parentFee = Math.floor(newCaseCopayRec.amt_copay_case_assesd__c);
        var newEffectiveDate =newCaseCopayRec.dte_begin_effv__c;
        if(fieldLabel == 'Parent Fee') {
            if(!$A.util.isEmpty(caseCopayRec.amt_copay_case_assesd__c)){
                if(parentFee>caseCopayRec.amt_copay_case_assesd__c) {
                    cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message","WARNING! Parent Fee exceeds the previous record value.");
                } else {
                    cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_ASSESD__c").set("v.message",null);
                } 
            }
            cmp.set('v.newCaseCopayRec.amt_copay_case_assesd__c', Math.floor(parentFee));
        }
        if(fieldLabel == 'Effective Date') {
            if(new Date(newEffectiveDate).getDate()!=1) {
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Invalid Date! Must be 1st day of the month");
            } else {
                cmp.find("batchsit_t_sbsd_case_copay__x-DTE_BEGIN_EFFV__c").set("v.message",null);
            }
        }
    },
    getActiveAuthHlp : function(component, event, helper,newDate) {
        try{
            if(!$A.util.isEmpty(newDate)){
                var caseId =component.get("v.recordId");
                var action1 = component.get('c.getActiveAuthorizationForCase');
                action1.setParams({
                    'caseId':caseId,'newDate':component.get("v.newCaseCopayRec").dte_begin_effv__c
                });
                action1.setCallback(this, function(response) {
                    var state = response.getState();
                    var res = response.getReturnValue();
                    component.set("v.showSpinner", false); 
                    if (component.isValid() && state == 'SUCCESS') {
                        if(res && res.objectData){
                            var newCaseCopayObj = component.get("v.newCaseCopayRec");

                            if(res.objectData.isQualityRating =='Y'){
                                if(newCaseCopayObj.cde_rec_copay__c =='FT'){
                                   component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",newCaseCopayObj.amt_copay_case_ft_qlty__c); 
                                }else if(newCaseCopayObj.cde_rec_copay__c =='PT'){
                                    component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",newCaseCopayObj.amt_copay_case_pt_qlty__c); 
                                }
                            }
                            else if(res.objectData.isQualityRating =='N'){
                                if(newCaseCopayObj.cde_rec_copay__c =='FT'){
                                    component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",newCaseCopayObj.amt_copay_case_ft__c); 
                                    
                                }else if(newCaseCopayObj.cde_rec_copay__c =='PT'){
                                    component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",newCaseCopayObj.amt_copay_case_pt__c); 
                                    
                                }
                            }
                            component.set("v.newCaseCopayRec.ind_qlty__c",res.objectData.isQualityRating);
                        }
                    } else {
                    }
                });        
                $A.enqueueAction(action1);
            }  
        }catch(ex){
        }
    },
     getCaseParentFeeHlp : function(component, event, helper,newDate) {
         try{
             if(!$A.util.isEmpty(newDate)){
                 var caseId =component.get("v.recordId");
                 var caseExternalId =component.get("v.caseCopayRec.idn_case__c");
                 var amount = component.get("v.newCaseCopayRec").amt_copay_case_assesd__c;
                 var action = component.get('c.getCaseParentFeeRecord');
                 action.setParams({"caseExternalId":component.get("v.caseCopayRec.idn_case__c"),"EffectiveDate": component.get("v.newCaseCopayRec.dte_begin_effv__c"),"caseParentFeeAmt":amount});
                 action.setCallback(this, function(response) {
                     component.set("v.isSpinner", false);
                     var res = response.getReturnValue();
                     if(!$A.util.isEmpty(res.objectData)){
                         if(res.objectData){
                             if(res.objectData.caseParentFeeDetails){
                                 component.set("v.isExistingCaseParentFee",true);
                                 var caseParentFeeDetails = res.objectData.caseParentFeeDetails;
                                 var caseCopayRec = {};
                                 caseCopayRec.dte_begin_effv__c =caseParentFeeDetails.effectiveBeginDate;
                                 caseCopayRec.dte_end_effv__c =caseParentFeeDetails.effectiveEndDate;
                                 caseCopayRec.cde_reason_ovrd__c =caseParentFeeDetails.overrideReason;
                                 caseCopayRec.amt_copay_case_assesd__c =caseParentFeeDetails.parentFee;
                                 caseCopayRec.ind_qlty__c = caseParentFeeDetails.indQlty;
                                 caseCopayRec.idn_sbsd_case_copay__c = caseParentFeeDetails.caseCopayId;
                                 caseCopayRec.idn_case__c = caseExternalId;
                                 caseCopayRec.amt_copay_case_ft__c = caseParentFeeDetails.ftFee;
                                 caseCopayRec.amt_copay_case_pt__c = caseParentFeeDetails.ptFee;
                                 caseCopayRec.amt_copay_case_ft_qlty__c = caseParentFeeDetails.qualityRatingFTFee;
                                 caseCopayRec.amt_copay_case_pt_qlty__c = caseParentFeeDetails.qualityRatingPTFee;
                                 component.set("v.caseCopayRec", caseCopayRec);
                                 console.log('caseCopayRec'+JSON.stringify(caseCopayRec));
                             }
                         }
                     }
                 });
                 $A.enqueueAction(action);
             }  
         }catch(ex){
         }
         
     },
     getRecommendedCopayUnit : function(component, event, helper,newDate){
        if(!$A.util.isEmpty(newDate)){
            var dateParentFee = component.get("v.newCaseCopayRec").dte_begin_effv__c;
             console.log('dateParentFee--'+dateParentFee);
            var action = component.get('c.getAuthWeight');
                action.setParams({'caseRecId' : component.get("v.recordId"),"effectiveDateStr": newDate});
                
             action.setCallback(this, function(response) {
                 console.log('response--'+JSON.stringify(response));
                 response = response.getReturnValue();
                 component.set("v.showSpinner", false); 
                 if(response != null && response.objectData){
                    if(response.objectData.recommendedCopayUnit){
                        var newCaseCopayRec = component.get("v.newCaseCopayRec");
                        newCaseCopayRec.cde_rec_copay__c = response.objectData.recommendedCopayUnit;
                        component.set("v.newCaseCopayRec", newCaseCopayRec);
                        var newCaseCopayObj = component.get("v.newCaseCopayRec");
                        if(newCaseCopayObj.cde_rec_copay__c == 'FT'){
                            debugger;
                            if(newCaseCopayObj.ind_qlty__c =='Y'){
                                debugger;
                                component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",Math.floor(newCaseCopayObj.amt_copay_case_ft_qlty__c));
                               // component.set("v.isParentFeeSetDefault",true);
                            }else{
                                debugger;
                                component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",Math.floor(newCaseCopayObj.amt_copay_case_ft__c));
                                //component.set("v.isParentFeeSetDefault",true);
                            }
                            
                        }
                        else if(newCaseCopayObj.cde_rec_copay__c == 'PT'){
                            debugger;
                            if(newCaseCopayObj.ind_qlty__c =='Y'){
                                debugger;
                                component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",Math.floor(newCaseCopayObj.amt_copay_case_pt_qlty__c));
                               // component.set("v.isParentFeeSetDefault",true);
                            }else{
                                debugger;
                                component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",Math.floor(newCaseCopayObj.amt_copay_case_pt__c));
                                //component.set("v.isParentFeeSetDefault",true);
                            }
                        }
                    }
                }
                this.checkCustomValidations(component);
             });
             $A.enqueueAction(action);
        }
    }
})