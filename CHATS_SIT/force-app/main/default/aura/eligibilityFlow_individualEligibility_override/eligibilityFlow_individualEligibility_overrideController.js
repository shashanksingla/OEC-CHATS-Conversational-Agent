({
    doInit : function(component,event, helper) {
        
        var indivDetails = component.get("v.indivDetails");
        var indivElig = component.get("v.indivElig");
        component.set("v.cde_status_detail_eligty_indiv",indivDetails.cde_status_detail_eligty_indiv__c);
        component.set("v.dte_begin_effv",indivDetails.dte_begin_effv__c);
        component.set("v.dte_end_effv",indivDetails.dte_end_effv__c);
        component.set("v.cde_reason_ovrd",indivElig.cde_reason_ovrd__c);
        component.set("v.txt_cmt_ovrd",indivElig.txt_cmt_ovrd__c);
        var reasonOptions = [];
        //Logic to make override reason picklist options dynamic based on parent caretaker
        reasonOptions.push({
            'label' : '--None--',
            'value' : null,
            'class' : 'optionClass',
            'selected' : false
        });
       
        if(component.get("v.parentCaretaker")==true){
            reasonOptions.push({
                'label' : 'Eligible Adult',
                'value' : 'EA',
                'class' : 'optionClass',
                'selected' : false
            });
            reasonOptions.push({
                'label' : 'Ineligible Adult',
                'value' : 'IA',
                'class' : 'optionClass',
                'selected' : false
            });
        }else{
            reasonOptions.push({
                'label' : 'Eligible Child',
                'value' : 'EC',
                'class' : 'optionClass',
                'selected' : false
            });
            reasonOptions.push({
                'label' : 'Ineligible Child',
                'value' : 'IC',
                'class' : 'optionClass',
                'selected' : false
            });
            reasonOptions.push({
                'label' : 'Not Requesting Individual',
                'value' : 'NC',
                'class' : 'optionClass',
                'selected' : false
            });
        }
        component.set("v.reasonOptions",reasonOptions);

    },
    doFinish : function(component, event, helper) {
        
        component.find("batchsit_t_indiv_eligty_detail__x-cde_status_detail_eligty_indiv__c").set("v.message",null);
        component.find("batchsit_t_indiv_eligty_detail__x-dte_begin_effv__c").set("v.message",null);
        component.find("batchsit_t_fcompsn_indiv_eligty__x-cde_reason_ovrd__c").set("v.message",null);
        component.find("batchsit_t_fcompsn_indiv_eligty__x-txt_cmt_ovrd__c").set("v.message",null);
        var areAllFieldsValid = component.find('input-field').reduce(function (validSoFar, inputComponents) {
            inputComponents.showHelpMessageIfInvalid();
            return validSoFar && inputComponents.get('v.validity').valid;
        }, true);
        if(areAllFieldsValid==true){
            
            if(component.get("v.cde_status_detail_eligty_indiv")==component.get("v.indivDetails.cde_status_detail_eligty_indiv__c") &&
               component.get("v.dte_begin_effv") == component.get("v.indivDetails.dte_begin_effv__c") &&
               component.get("v.cde_reason_ovrd") == component.get("v.indivElig.cde_reason_ovrd__c") &&
               component.get("v.txt_cmt_ovrd") == component.get("v.indivElig.txt_cmt_ovrd__c")
              ){
                component.set("v.pageMessages",[$A.get("$Label.c.Nothing_Changed_Click_Cancel")]); 
            }else{
                component.set("v.pageMessages",[]); 
                var pageMessages = [];
                var hasErrors = false;
                var statusError='';
                //Eligible Individuals cannot have any Individual Ineligibility Reasons
                if((component.get("v.indivDetails.cde_status_detail_eligty_indiv__c")=='EA' || component.get("v.indivDetails.cde_status_detail_eligty_indiv__c")=='EC') &&
                   (component.get("v.indivIneligibilityFailure")!=null && component.get("v.indivIneligibilityFailure").length>0)              
                  ){
                    statusError+=$A.get("$Label.c.HER_Eligible_Indiv_With_Inelig_Reasons");
                }
                
                //Ineligible Individuals must have at least one Individual Ineligibility Reason
                if((component.get("v.indivDetails.cde_status_detail_eligty_indiv__c")=='IA' || component.get("v.indivDetails.cde_status_detail_eligty_indiv__c")=='IC') &&
                   (component.get("v.indivIneligibilityFailure")==null || component.get("v.indivIneligibilityFailure").length==0)              
                  ){
                    statusError+=$A.get("$Label.c.HER_Ineligible_Indiv_Without_Inelig_Reasons");
                }
                
                if(!$A.util.isEmpty(statusError) || statusError!=''){
                    component.find("batchsit_t_indiv_eligty_detail__x-cde_status_detail_eligty_indiv__c").set("v.message",statusError);
                    hasErrors=true;
                }else{
                    component.find("batchsit_t_indiv_eligty_detail__x-cde_status_detail_eligty_indiv__c").set("v.message",null);
                }
                
                //Individual Eligibility Begin Date cannot be before Household Eligibility Begin Date
                //Individual Eligibility Begin Date cannot be before the Individual Entered the Household
                //Individual Eligibility Begin Date cannot be later than system populated date
                if(!$A.util.isEmpty(component.get("v.indivDetails.dte_begin_effv__c"))){
                    var CANNOT_BE_BEFORE = $A.get("$Label.c.CANNOT_BE_BEFORE");
                    CANNOT_BE_BEFORE = CANNOT_BE_BEFORE.replace("{0}","Individual Eligibility Begin Date");
                    var beginDateError='';
                    if(!$A.util.isEmpty(component.get("v.householdEligibilityBeginDate")) && component.get("v.indivDetails.dte_begin_effv__c")<component.get("v.householdEligibilityBeginDate")){
                        beginDateError+=CANNOT_BE_BEFORE.replace("{1}","Household Eligibility Begin Date");
                    }
                    
                    if(!$A.util.isEmpty(component.get("v.individualEnteredHouseholdDate")) && component.get("v.indivDetails.dte_begin_effv__c")<component.get("v.individualEnteredHouseholdDate")){
                        beginDateError+=CANNOT_BE_BEFORE.replace("{1}","Individual Entered the Household");
                    }
                    
                    if(!$A.util.isEmpty(component.get("v.lastIndivEligDetailEndDate")) && component.get("v.indivDetails.dte_begin_effv__c")<component.get("v.lastIndivEligDetailEndDate")){
                        beginDateError += $A.get("$Label.c.HER_INDIV_SEGMENTS_CANT_OVERLAP");
                    }
                    
                    if(component.get("v.indivDetails.dte_begin_effv__c")>component.get("v.dte_begin_effv")){
                        var CANNOT_BE_LATER_THAN = $A.get("$Label.c.CANNOT_BE_LATER_THAN");
                        CANNOT_BE_LATER_THAN = CANNOT_BE_LATER_THAN.replace("{0}","Individual Eligibility Begin Date");
                        beginDateError+=CANNOT_BE_LATER_THAN.replace("{1}","system populated date");
                    }
                    
                    if(!$A.util.isEmpty(beginDateError) || beginDateError!=""){
                        component.find("batchsit_t_indiv_eligty_detail__x-dte_begin_effv__c").set("v.message",beginDateError);
                        hasErrors=true;
                    }else{
                        component.find("batchsit_t_indiv_eligty_detail__x-dte_begin_effv__c").set("v.message",null);
                    }
                    
                    if(!hasErrors){
                        //Override Reason cannot be null if Individual Eligibility Status has been changed
                        //Override Reason cannot be null if the Eligibility Begin Date has been changed
                        if($A.util.isEmpty(component.get("v.indivElig.cde_reason_ovrd__c"))){
                            var CANNOT_BLANK_0_IF_1_IS_CHANGED = $A.get("$Label.c.CANNOT_BLANK_0_IF_1_IS_CHANGED");
                            CANNOT_BLANK_0_IF_1_IS_CHANGED = CANNOT_BLANK_0_IF_1_IS_CHANGED.replace("{0}","Override Reason");
                            var reasonOverrideError='';
                            if(component.get("v.indivDetails.cde_status_detail_eligty_indiv__c")!=component.get("v.cde_status_detail_eligty_indiv")){
                                reasonOverrideError += CANNOT_BLANK_0_IF_1_IS_CHANGED.replace("{1}","Individual Eligibility Status");
                            }
                            
                            if(component.get("v.indivDetails.dte_begin_effv__c")!=component.get("v.dte_begin_effv")){
                                reasonOverrideError += CANNOT_BLANK_0_IF_1_IS_CHANGED.replace("{1}","Eligibility Begin Date");
                            }
                            if(!$A.util.isEmpty(reasonOverrideError) || reasonOverrideError!=''){
                                hasErrors=true;
                                component.find("batchsit_t_fcompsn_indiv_eligty__x-cde_reason_ovrd__c").set("v.message",reasonOverrideError);                
                            }else{
                                component.find("batchsit_t_fcompsn_indiv_eligty__x-cde_reason_ovrd__c").set("v.message",null);
                            }
                        }else{
                            component.find("batchsit_t_fcompsn_indiv_eligty__x-cde_reason_ovrd__c").set("v.message",null);
                        }
                        
                        //Override Comments cannot be null if Individual Eligibility Status has been changed
                        //Override Comments cannot be null if Eligibility Begin Date has been changed
                        if($A.util.isEmpty(component.get("v.indivElig.txt_cmt_ovrd__c"))){
                            var CANNOT_BLANK_0_IF_1_IS_CHANGED = $A.get("$Label.c.CANNOT_BLANK_0_IF_1_IS_CHANGED");
                            CANNOT_BLANK_0_IF_1_IS_CHANGED = CANNOT_BLANK_0_IF_1_IS_CHANGED.replace("{0}","Override Comments");
                            var commentOverrideError='';
                            if(component.get("v.indivDetails.cde_status_detail_eligty_indiv__c")!=component.get("v.cde_status_detail_eligty_indiv")){
                                commentOverrideError += CANNOT_BLANK_0_IF_1_IS_CHANGED.replace("{1}","Individual Eligibility Status");
                            }
                            if(component.get("v.indivDetails.dte_begin_effv__c")!=component.get("v.dte_begin_effv")){
                                commentOverrideError += CANNOT_BLANK_0_IF_1_IS_CHANGED.replace("{1}","Eligibility Begin Date");
                            }
                            if(!$A.util.isEmpty(commentOverrideError) || commentOverrideError!=''){
                                hasErrors=true;
                                component.find("batchsit_t_fcompsn_indiv_eligty__x-txt_cmt_ovrd__c").set("v.message",commentOverrideError);                
                            }else{
                                component.find("batchsit_t_fcompsn_indiv_eligty__x-txt_cmt_ovrd__c").set("v.message",null);
                            }
                        }else{
                            component.find("batchsit_t_fcompsn_indiv_eligty__x-txt_cmt_ovrd__c").set("v.message",null);
                        }
                    }
                }
                
                if(!hasErrors){
                    var indivDetails = component.get("v.indivDetails");
                    indivDetails.ind_ovrd_data__c = 'Y';
                    helper.callServer(component, "c.insertExternalObjRecords", function(response){
                        // pass returned value to callback function
                        if(response.isSuccessful==true){
                            component.find("overlayLib").notifyClose();
                            helper.fireToast("duration", "success", "Success!", "Individual Eligibility has been successfully overridden");
                            $A.get('e.force:refreshView').fire();
                        }else{
                            component.set("v.pageMessages",[response.errorMessage]);
                        }
                    }, {"lstSObject":[indivDetails,
                                      component.get("v.indivElig")],
                        "isFinalStep":true}, false);
                }else{
                    pageMessages.push($A.get("$Label.c.ERRORS_ON_THIS_PAGE"));
                    component.set("v.pageMessages",pageMessages);
                }
            }
        }        
        
        /*
        var hasErrors = false;
        var validFamilyStatus = false;
        
        var indivDetailsObj = !$A.util.isEmpty(component.get("v.indivDetails"))?JSON.parse(JSON.stringify(component.get("v.indivDetails"))):null;
        var indivEligObj = !$A.util.isEmpty(component.get("v.indivElig"))?JSON.parse(JSON.stringify(component.get("v.indivElig"))):null;
        if(!$A.util.isEmpty(indivEligObj)){
            var overridereason = indivEligObj.cde_reason_ovrd__c;
            var overrideText = indivEligObj.txt_cmt_ovrd__c;
        }
        if(!$A.util.isEmpty(indivDetailsObj)){
            var statusElig = indivDetailsObj.cde_status_detail_eligty_indiv__c;
            var effectiveDate = indivDetailsObj.dte_begin_effv__c;
        }
        
        if((statusElig=="EA" || statusElig=="EC") && (component.get("v.indivIneligibilityFailure")!=null && component.get("v.indivIneligibilityFailure").length>0)){
            component.find("batchsit_t_indiv_eligty_detail__x-CDE_STATUS_DETAIL_ELIGTY_INDIV__c").set("v.message","All individual ineligibility reasons must be unchecked to update to Eligible");
            hasErrors=true;
        }else{
            component.find("batchsit_t_indiv_eligty_detail__x-CDE_STATUS_DETAIL_ELIGTY_INDIV__c").set("v.message",null);
            if(component.get("v.value")!=statusElig){
                if(overridereason==null || overridereason==""){
                    component.find("batchsit_t_fcompsn_indiv_eligty__x-CDE_REASON_OVRD__c").set("v.message","Please select a value");
                    hasErrors=true;
                }else{
                    component.find("batchsit_t_fcompsn_indiv_eligty__x-CDE_REASON_OVRD__c").set("v.message",null);
                }
                if(overrideText==null || overrideText==""){
                    component.find("batchsit_t_fcompsn_indiv_eligty__x-TXT_CMT_OVRD__c").set("v.message","Please provide a value");
                    hasErrors=true;
                }else{
                    component.find("batchsit_t_fcompsn_indiv_eligty__x-TXT_CMT_OVRD__c").set("v.message",null);
                }
            }
        }
        
        var clearDateError = true;
        if(component.get("v.withdrawCCR")==false){
            if(effectiveDate<=helper.getCurrentSystemDate(14)){
                component.find("batchsit_t_indiv_eligty_detail__x-DTE_BEGIN_EFFV__c").set("v.message","Please enter a date after 14 days.");
                hasErrors=true;
                clearDateError=false;
            }else{
                component.find("batchsit_t_indiv_eligty_detail__x-DTE_BEGIN_EFFV__c").set("v.message",null);
            }	            
        }
        
        
        if(component.get("v.indiv.DTE_DOB__c")>effectiveDate){
            component.find("batchsit_t_indiv_eligty_detail__x-DTE_BEGIN_EFFV__c").set("v.message","Please enter a date after individual DOB.");
            hasErrors=true;
        }else{
            if(clearDateError==true){
	            component.find("batchsit_t_indiv_eligty_detail__x-DTE_BEGIN_EFFV__c").set("v.message",null);
            }
        }
        
        
        if(hasErrors==false){
            component.set("v.pageMessages",[]); 
            component.set("v.indivDetails.CDE_STATUS_DETAIL_ELIGTY_INDIV__c",component.get("v.value"));
            component.set("v.pageMessages",[]); 
            helper.callServer(component, "c.upsertRecordsFinal", function(response){
                // pass returned value to callback function
                if(response.isSuccessful==true){
                    component.find("overlayLib").notifyClose();
                    helper.fireToast("duration", "success", "Success!", "Individual Eligibility has been successfully overridden");
                    $A.get('e.force:refreshView').fire();
                }else{
                    var pageMessages = [response.errorMessage];
                    component.set("v.pageMessages",pageMessages);
                }
            }, {"lstSObject":[component.get("v.indivDetails"),
                              component.get("v.indivElig")],
                "isFinalStep":true}, false);
        }else{
            component.set("v.pageMessages",["Please correct the below errors:"]);            
        }*/
    },
    closeModal : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    }
})