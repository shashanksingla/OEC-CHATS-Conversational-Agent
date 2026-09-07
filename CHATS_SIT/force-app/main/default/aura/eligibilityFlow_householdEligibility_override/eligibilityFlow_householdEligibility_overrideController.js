({
    doInit : function(component,event, helper) {
        /*if(!$A.util.isEmpty(component.get("v.caseEligibilityDetails"))){
		      component.set("v.value", JSON.parse(JSON.stringify(component.get("v.caseEligibilityDetails"))).cde_status_eligty_family__c);  
        }*/
        if(!$A.util.isEmpty(component.get("v.caseEligibilityDetails"))){
            component.set("v.cde_status_eligty_family", component.get("v.caseEligibilityDetails.cde_status_eligty_family__c"));
        }
        if(!$A.util.isEmpty(component.get("v.caseEligibility"))){
            component.set("v.txt_cmt_ovrd", component.get("v.caseEligibility.txt_cmt_ovrd__c"));
            component.set("v.cde_reason_ovrd", component.get("v.caseEligibility.cde_reason_ovrd__c"));
        }
    },
    doFinish : function(component, event, helper) {
        debugger;
        component.find("batchsit_t_fcompsn_eligty_detail__x-cde_status_eligty_family__c").set("v.message", null);
        var areAllFieldsValid = component.find('input-field').reduce(function (validSoFar, inputComponents) {
            inputComponents.showHelpMessageIfInvalid();
            return validSoFar && inputComponents.get('v.validity').valid;
        }, true);
        if(areAllFieldsValid==true){
            if(component.get("v.caseEligibility.cde_reason_ovrd__c")==component.get("v.cde_reason_ovrd") &&
               component.get("v.caseEligibility.txt_cmt_ovrd__c")==component.get("v.txt_cmt_ovrd") &&
               component.get("v.caseEligibilityDetails.cde_status_eligty_family__c")==component.get("v.cde_status_eligty_family")
              ){
                component.set("v.pageMessages",[$A.get("$Label.c.Nothing_Changed_Click_Cancel")]); 
            }else{
                component.set("v.pageMessages",[]); 
                var hasErrors = false;
                if(component.get("v.caseEligibilityDetails.cde_status_eligty_family__c")=='ELI'){
                    var indivEligIdToWrapper = component.get("v.indivEligIdToWrapper");
                    var anyIneligibleParentCaretaker = false;
                    var noOfChild=0, noOfIneligibleChild=0;
                    for(var key in indivEligIdToWrapper){
                        if(!anyIneligibleParentCaretaker && indivEligIdToWrapper[key].isParentCaretaker==true && indivEligIdToWrapper[key].status!='EA'){
                            anyIneligibleParentCaretaker = true;
                        }
                        if(indivEligIdToWrapper[key].isParentCaretaker==false){
                            noOfChild++;
                            if(indivEligIdToWrapper[key].status=='EC'){
                                noOfIneligibleChild++;
                            }	
                        }
                    }
                    
                    if(anyIneligibleParentCaretaker==true || (noOfChild>0 && noOfIneligibleChild==0) || (!$A.util.isEmpty(component.get("v.householdIneligibilityFailure")) && component.get("v.householdIneligibilityFailure").length>0)){
                        var error = '';
                        if(anyIneligibleParentCaretaker){
                            error = $A.get("$Label.c.HER_Parent_Caretaker_Eligible");
                        }
                        if(noOfChild>0 && noOfIneligibleChild==0){
                            error += $A.get("$Label.c.HER_At_Least_One_Child_Eligible");
                        }
                        if(!$A.util.isEmpty(component.get("v.householdIneligibilityFailure")) && component.get("v.householdIneligibilityFailure").length>0){
                            error+= $A.get("$Label.c.HER_Eligible_HH_With_Inelig_Reasons");
                        }
                        
                        component.find("batchsit_t_fcompsn_eligty_detail__x-cde_status_eligty_family__c").set("v.message",error);
                        hasErrors = true;
                    }else{
                        component.find("batchsit_t_fcompsn_eligty_detail__x-cde_status_eligty_family__c").set("v.message", null);
                    }
                }else if(component.get("v.caseEligibilityDetails.cde_status_eligty_family__c")=='INE'){
                    if($A.util.isEmpty(component.get("v.householdIneligibilityFailure")) || component.get("v.householdIneligibilityFailure").length==0){
                        component.find("batchsit_t_fcompsn_eligty_detail__x-cde_status_eligty_family__c").set("v.message", $A.get("$Label.c.HER_Eligible_HH_Without_Inelig_Reasons"));
                        hasErrors = true;
                    }else{
                        component.find("batchsit_t_fcompsn_eligty_detail__x-cde_status_eligty_family__c").set("v.message", null);
                    }    
                }
                if(!hasErrors && component.get("v.caseEligibilityDetails.cde_status_eligty_family__c")!=component.get("v.cde_status_eligty_family")){
                    
                    if($A.util.isEmpty(component.get("v.caseEligibility.cde_reason_ovrd__c"))){
                        var HER_Override_Reason_Mandatory_General = $A.get("$Label.c.HER_Override_Reason_Mandatory_General");
                        component.find("batchsit_t_fcompsn_eligty__x-cde_reason_ovrd__c").set("v.message",HER_Override_Reason_Mandatory_General.replace("{0}","Household Eligibility Status"));
                        hasErrors = true;
                    }else{
                        component.find("batchsit_t_fcompsn_eligty__x-cde_reason_ovrd__c").set("v.message", null);
                    }
                    if($A.util.isEmpty(component.get("v.caseEligibility.txt_cmt_ovrd__c"))){
                        var HER_Override_Comments_Mandatory_General = $A.get("$Label.c.HER_Override_Comments_Mandatory_General");
                        component.find("batchsit_t_fcompsn_eligty__x-txt_cmt_ovrd__c").set("v.message",HER_Override_Comments_Mandatory_General.replace("{0}","Household Eligibility Status"));
                        hasErrors = true;
                    }else{
                        component.find("batchsit_t_fcompsn_eligty__x-txt_cmt_ovrd__c").set("v.message", null);
                    }
                }
                if(!hasErrors){
                    var caseEligibilityDetails = component.get("v.caseEligibilityDetails");
                    caseEligibilityDetails.ind_ovrd_data__c = 'Y';
                    helper.callServer(component, "c.insertExternalObjRecords", function(response){
                        // pass returned value to callback function
                        if(response.isSuccessful==true){
                            component.find("overlayLib").notifyClose();
                            helper.fireToast("duration", "success", "Success!", "Household Eligibility has been successfully overridden.");
                            $A.get('e.force:refreshView').fire();
                        }else{
                            var pageMessages = [response.errorMessage];
                            component.set("v.pageMessages",pageMessages);
                        }
                    }, {"lstSObject":[component.get("v.caseEligibility"),
                                      caseEligibilityDetails],
                        "isFinalStep":true}, false);
                }else{
                    component.set("v.pageMessages",[$A.get("$Label.c.ERRORS_ON_THIS_PAGE")]); 
                    component.set("v.messageType","error"); 
                }
            }
            
            /*
            var validFamilyStatus = false;
            var hasErrors = false;
            var householdDetailsObj = JSON.parse(JSON.stringify(component.get("v.caseEligibilityDetails")));
            var householdEligObj = JSON.parse(JSON.stringify(component.get("v.caseEligibility")));
            var statusElig = householdDetailsObj.cde_status_eligty_family__c;
            var overridereason = householdEligObj.cde_reason_ovrd__c;
            var overrideText = householdEligObj.txt_cmt_ovrd__c;
            var effectiveDate = householdDetailsObj.dte_begin_effv__c;
            
            if(statusElig=="ELI" && (component.get("v.householdIneligibilityFailure")!=null && component.get("v.householdIneligibilityFailure").length>0)){
                component.find("batchsit_t_fcompsn_eligty_detail__x-CDE_STATUS_ELIGTY_FAMILY__c").set("v.message","All household ineligibility reasons must be unchecked to update to Eligible");
                hasErrors=true;
            }else if(statusElig=="INE" && (component.get("v.householdIneligibilityFailure")==null || component.get("v.householdIneligibilityFailure").length==0)){
                component.find("batchsit_t_fcompsn_eligty_detail__x-CDE_STATUS_ELIGTY_FAMILY__c").set("v.message","There should be at least one ineligibility reason record to update to Ineligible");
                hasErrors=true;
            }else{
                component.find("batchsit_t_fcompsn_eligty_detail__x-CDE_STATUS_ELIGTY_FAMILY__c").set("v.message",null);
                validFamilyStatus = true;
            }
            
            if(validFamilyStatus==true){
                if(component.get("v.value")!=statusElig){
                    if(overridereason==null || overridereason==""){
                        component.find("batchsit_t_fcompsn_eligty__x-CDE_REASON_OVRD__c").set("v.message","Please select a value");
                        hasErrors=true;
                    }else{
                        component.find("batchsit_t_fcompsn_eligty__x-CDE_REASON_OVRD__c").set("v.message",null);
                    }
                    if(overrideText==null || overrideText==""){
                        component.find("batchsit_t_fcompsn_eligty__x-TXT_CMT_OVRD__c").set("v.message","Please provide a value");
                        hasErrors=true;
                    }else{
                        component.find("batchsit_t_fcompsn_eligty__x-TXT_CMT_OVRD__c").set("v.message",null);
                    }
                }
            }
            //Need to rework upon data comparision logic
            if(component.get("v.withdrawCCR")==false){
                if(effectiveDate<=helper.getCurrentSystemDate(14)){
                    component.find("batchsit_t_fcompsn_eligty_detail__x-DTE_BEGIN_EFFV__c").set("v.message","Please enter a date after 14 days.");
                    hasErrors=true;
                }else{
                    component.find("batchsit_t_fcompsn_eligty_detail__x-DTE_BEGIN_EFFV__c").set("v.message",null);
                }	            
            }
            
            if(hasErrors==false){
                component.set("v.caseEligibilityDetails.CDE_STATUS_ELIGTY_FAMILY__c",component.get("v.value"));
                component.set("v.pageMessages",[]); 
                helper.callServer(component, "c.upsertRecordsFinal", function(response){
                    // pass returned value to callback function
                    if(response.isSuccessful==true){
                        component.find("overlayLib").notifyClose();
                        helper.fireToast("duration", "success", "Success!", "Household Eligibility has been successfully overridden");
                        $A.get('e.force:refreshView').fire();
                    }else{
                        var pageMessages = [response.errorMessage];
                        component.set("v.pageMessages",pageMessages);
                    }
                }, {"lstSObject":[component.get("v.caseEligibility"),
                                  component.get("v.caseEligibilityDetails")],
                    "isFinalStep":true}, false);
            }else{
                component.set("v.pageMessages",["Please correct the below errors:"]);            
            }*/
        }
    },
    closeModal : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    }
})