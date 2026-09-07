({
    doInit : function(component, event, helper){
        helper.callServerAndHandleError(component,"c.getDoInit", 
                                        function(response){
                                            debugger;
                                            if(!$A.util.isEmpty(response.objectData) ){
                                                debugger;
                                                console.log('res--'+JSON.stringify(response.objectData));
                                                if(!$A.util.isEmpty(response.objectData.isOnlyTANFProgram) ){
                                                    debugger;
                                                    component.set("v.isCBMSTANFProgm",response.objectData.isOnlyTANFProgram);
                                                    var programOptions =[{'value':null,'label':'--None--','selected':false}];
                                                    programOptions.push({'value':'TF','label':'TANF','selected':false});
                                                    component.set("v.programOptions",programOptions);
                                                }
                                                if(!$A.util.isEmpty(response.objectData.caseRecord)){ // added for CCCAP-13251
                                                    component.set("v.caseRecord", response.objectData.caseRecord);
                                                    component.set("v.newApplnDateInfo.DTE_APPLN_OLD__c", response.objectData.caseRecord.DTE_APPLN__c);
                                                } 
                                                if(!$A.util.isEmpty(response.objectData.loggedInUserId)){ // added for CCCAP-13251
                                                    component.set("v.loggedInUserId", response.objectData.loggedInUserId);
                                                }
                                            }
                                        }, {'caseRecId':component.get("v.recordId")}, false, null);
    },
    doCancel : function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    },
    doFinish : function(component, event, helper) {
        var isValid = helper.validateInputFields(component);
        if($A.util.isEmpty(component.get("v.programType"))){
            if(component.get("v.isCBMSTANFProgm")){
                component.find("input-field2").showHelpMessageIfInvalid();
            }else{
                component.find("input-field1").showHelpMessageIfInvalid();
            }
            isValid = false;
        }      
        
        if(isValid){
            var prgmType = component.get("v.programType");
            
            helper.callServerAndHandleError(component,"c.validateCaseForEligibility", function(response){
          
                if(response.objectData.assessPageMessages!=null && response.objectData.assessPageMessages.length>0) {
  
                    component.set("v.pageMessages",response.objectData.assessPageMessages);
                }else if(response.objectData.caseProgram!=null && response.objectData.caseProgram!=prgmType){
          
                    if(response.objectData.assessProgramWarnings!=null && response.objectData.assessProgramWarnings.length>0){
                      
                        var warningProgramMessageList=[];
                        for(var i=0;i<response.objectData.assessProgramWarnings.length;i++) {
                            warningProgramMessageList[i] = response.objectData.assessProgramWarnings[i];
                        }
                        component.set("v.warningProgramMessageList",warningProgramMessageList);
                        helper.callModal(component,'assessEligibilityPrgm_warningMessage');
                    }
                }else{
                
                    if(response.objectData.assessPageWarnings!=null && response.objectData.assessPageWarnings.length>0) {
                      
                        var warningMessageList=[];
                        for(var i=0;i<response.objectData.assessPageWarnings.length;i++) {
                            warningMessageList[i] = response.objectData.assessPageWarnings[i];
                        }
                        component.set("v.warningMessageList",warningMessageList);
                        helper.callModal(component,'assessEligibility_warningMessage');
                    }else{
                       
                        helper.callBRE(component, component.get("v.recordId"), component.get("v.programType"));  
                    }  
                }
            },{'caseRecId':component.get("v.recordId"),
               'programType':component.get("v.programType")},false,null);
        }
    },
    confirmCancel : function(component, event, helper) {
        helper.callBRE(component, component.get("v.recordId"), component.get("v.programType"));
    },
    confirmPrgCancel : function(component, event, helper) {
        var confirmationModalOnNewProgramNonDetail = component.find("assessEligibilityPrgm_warningMessage");
        confirmationModalOnNewProgramNonDetail.hideConfirmModal();
        helper.callModal(component,'assessEligibilityApplnDt_warningMessage');
    },
    confirmApplnDate: function(component, event, helper){
        var eligibilityRunApplnDateWarningModal = component.find("assessEligibilityApplnDt_warningMessage");
        eligibilityRunApplnDateWarningModal.hideConfirmModal();
        helper.callServerAndHandleError(component,"c.validateCaseForEligibility", function(response){
            if(response.objectData.assessPageWarnings!=null && response.objectData.assessPageWarnings.length>0) {
                var warningMessageList=[];
                for(var i=0;i<response.objectData.assessPageWarnings.length;i++) {
                    warningMessageList[i] = response.objectData.assessPageWarnings[i];
                }
                component.set("v.warningMessageList",warningMessageList);
                helper.callModal(component,'assessEligibility_warningMessage');
            }else{	
                helper.callBRE(component, component.get("v.recordId"), component.get("v.programType"));    
            }
        },{'caseRecId':component.get("v.recordId"),
           'programType':component.get("v.programType")},false,null);
    },
    validateInput: function(component, event, helper){
        var isValid = helper.validateInputFields(component);
    }
})