({
    callModal : function(cmp, modalName) {
        
        var modalCall = cmp.find(modalName);
        if(modalCall){
            modalCall.openModal();
        }else{
            this.redirectToRecord(cmp.get("v.recordId"));
        }
    }, 
    callBRE : function(cmp, caseId, programType) {
        //callout BRE
        
        var confirmationModalOnNewNonDetail = cmp.find("assessEligibility_warningMessage");
        confirmationModalOnNewNonDetail.hideConfirmModal();
        var self = this;
        this.doContinuousCallOuts(cmp,"BRECreate",[caseId,programType], function(response){
           
            if(response.isSuccessful && !$A.util.isEmpty(response.objectData.eligRunSFID)){
                //CCCAP-13251
                if(!$A.util.isEmpty(cmp.get("v.newApplnDateInfo.DTE_APPLN_NEW__c"))){
                    var applnDateRec = cmp.get("v.newApplnDateInfo");
                    applnDateRec.Reopened_or_Elig__c = 'Eligibility';
                    self.callServerAndHandleError(cmp,"c.insertApplnDateInfoRec", function(resp){
                        if(resp.isSuccessful){
                            self.updateEligRunRecord(cmp, response.objectData.eligRunSFID);
                        }
                    }, {"applnDateRec": applnDateRec, "caseRec": cmp.get("v.caseRecord")}, false, null);
                }
                else{
                    self.updateEligRunRecord(cmp, response.objectData.eligRunSFID);
                }     
            }
        });
        /*
        this.callServerAndHandleError(cmp,"c.doCallBRE", 
                                      function(response){
                                          
                                          if(response.isSuccessful && !$A.util.isEmpty(response.objectData.eligRunSFID)){
                                          	this.redirectToLightningComponent("c:eligibilityFlow",{"recordId":response.objectData.eligRunSFID});    
                                          }
                                      }, {caseId:caseId, programName:programType}, false, null);*/
        
    },
    //CCCAP-13251
    updateEligRunRecord: function(component, eligRunSFId){
        var eligRunRec;
        if(!$A.util.isEmpty(component.get("v.newApplnDateInfo.DTE_APPLN_NEW__c"))){
            eligRunRec = {"sobjectType":'batchsit_t_eligty_run__x',
                "Id":eligRunSFId,
                "dte_appln_old__c":component.get("v.newApplnDateInfo.DTE_APPLN_OLD__c"),
                "dte_appln_new__c":component.get("v.newApplnDateInfo.DTE_APPLN_NEW__c"),
                "rsn_appln_dte_override__c":component.get("v.newApplnDateInfo.RSN_OVERRIDE__c"),
                "cmt_appln_dte_override__c":component.get("v.newApplnDateInfo.CMT_OVERRIDE__c"),
                "lastmodifieddate__c": new Date(),
                "lastmodifiedbyid__c" : component.get("v.loggedInUserId")
            };
        } else{
            eligRunRec = {"sobjectType":'batchsit_t_eligty_run__x',
                "Id":eligRunSFId,
                "dte_appln_old__c":component.get("v.newApplnDateInfo.DTE_APPLN_OLD__c"),
                "lastmodifieddate__c": new Date(),
                "lastmodifiedbyid__c" : component.get("v.loggedInUserId")
            };
        }
		this.callServerForExternalObjAndHandleError(component, "c.updateExternalObjRecords", function(response){
                if(response.isSuccessful==true){
                    this.redirectToLightningComponent("c:eligibilityFlow",{"recordId":eligRunSFId});
                }else{
                    var pageMessages = [response.errorMessage];
                    component.set("v.pageMessages",pageMessages);
                }
            }, {"lstSObject":[eligRunRec],"isFinalStep":true}, false); 
	},
    validateInputFields : function(component){
        var isValid = true;
        if (!$A.util.isEmpty(component.get("v.newApplnDateInfo.DTE_APPLN_NEW__c"))){ //CCCAP-13251
            if($A.util.isEmpty(component.get("v.newApplnDateInfo.RSN_OVERRIDE__c"))){
                isValid = false;
                component.find("input-field3").showHelpMessageIfInvalid();
            }
        	if($A.util.isEmpty(component.get("v.newApplnDateInfo.CMT_OVERRIDE__c"))){
           		isValid = false;
                component.find("T_CASE_APPLN_DTE__c-CMT_OVERRIDE__c").set("v.message","Override Comments cannot be blank if Updated Application Date is entered.");
            }
            else{
                component.find("T_CASE_APPLN_DTE__c-CMT_OVERRIDE__c").set("v.message","");
            }
            var newDate = new Date(component.get("v.newApplnDateInfo.DTE_APPLN_NEW__c"));
            var today = new Date();
            if(newDate > today){
                isValid = false;
                component.find("T_CASE_APPLN_DTE__c-DTE_APPLN_NEW__c").set("v.message","Application Date cannot be in future.");
            }
            else{
                component.find("T_CASE_APPLN_DTE__c-DTE_APPLN_NEW__c").set("v.message","");
            }
        }
        else{
            component.find("T_CASE_APPLN_DTE__c-CMT_OVERRIDE__c").set("v.message","");
        }
        return isValid;
    }
})