({
    doInit : function(component, event, helper) { 
        component.set("v.adjustmentEntryEditMode", false);
        component.set("v.authorizationAssocIndiv","");  
        component.set("v.authorizationAssocFundingProg","");  
        component.set("v.AMT_DETAIL_ADJMT__c",0);
        component.set("v.newAdjustmentError",$A.get("$Label.c.FMFlow_nonAdjDetailErrMessage"));
        if(component.get("v.nonAdjustmentDetail")) {
            component.set("v.oneTimeAuthChangeHandle", false);
            component.set("v.adjustmentEntryEditMode", true);
            component.set("v.authId",component.get("v.nonAdjustmentDetail").IDN_AUTH__c);   
            component.set("v.authorizationAssocFundingProgVal",component.get("v.nonAdjustmentDetail").IDN_PROG_FNDG__c);  
            component.set("v.authorizationAssocFundingProg",component.get("v.nonAdjustmentDetail").IDN_PROG_FNDG__c);  
            component.set("v.AMT_DETAIL_ADJMT__c",component.get("v.nonAdjustmentDetail").AMT_DETAIL_ADJMT__c);    
        }
    },
    
    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    },
    
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    
    getChildName : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.authId"))){
            var adjmt = component.get("v.adjustmentObj");         
            var adStartDate = new Date(adjmt.DTE_START_ADJMT__c);
            var adEndDate = new Date(adjmt.DTE_END_ADJMT__c);            
            helper.callServerAndHandleError(component,"c.getIndivInfoFromAuth", function(response){
                
                component.set("v.authorizationObj",response.objectData.authorization);
                
                if(response.objectData.authorization.IDN_CLIENT__r){
                    component.set('v.authorizationAssocIndiv', 
                                  response.objectData.authorization.IDN_CLIENT__r.NAM_FIRST__c + ', ' + response.objectData.authorization.IDN_CLIENT__r.NAM_LAST__c);    
                }

                //START: Payment by Enrollment
                var checkPmtByEnrollment = response.objectData.checkPmtByEnrollment;
                if(checkPmtByEnrollment == true){
                    var dob = response.objectData.authorization.IDN_CLIENT__r.DTE_DOB__c;
                    var dobDate = new Date(dob);
                    dobDate.setFullYear(dobDate.getFullYear() + 3);                    
                    var pmtEnrollBegin = $A.get("$Label.c.Payment_by_Enrollment_Begin_Date");
                    var pmtEnrollEnd = $A.get("$Label.c.Payment_by_Enrollment_End_Date");
                    var pmtEnrollBeginDate = new Date(pmtEnrollBegin);
                    var pmtEnrollEndDate = pmtEnrollEnd != 'null' ? new Date(pmtEnrollEnd) : null;

                    console.log('adStartDate: '+adStartDate+' ***** adEndDate: '+adEndDate);
                    console.log('pmtEnrollBegin: '+pmtEnrollBeginDate+' ***** pmtEnrollEnd: '+pmtEnrollEndDate);
                    
                    if(adStartDate < dobDate && (adStartDate >= pmtEnrollBeginDate && (pmtEnrollEndDate == null || adStartDate <= pmtEnrollEndDate))
                           || (adStartDate < pmtEnrollBeginDate && adEndDate >= pmtEnrollBeginDate)){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            message: 'The child’s age during the care begin and end date indicates payment by enrollment is required and claim or recovery must be made for authorized hours.',
                            duration:' 5000',
                            key: 'info_alt',
                            type: 'warning',
                            mode: 'sticky'
                        });
                        toastEvent.fire();
                    }
                }
                //END: Payment by Enrollment
                if(component.get("v.oneTimeAuthChangeHandle")==true && response.objectData.fundingProg){
                    component.set("v.authorizationAssocFundingProg",response.objectData.fundingProg.label);
                    component.set("v.authorizationAssocFundingProgVal",response.objectData.fundingProg.val);
                }
                //CCCAP-13818
                if(component.get("v.oneTimeAuthChangeHandle")==true && response.objectData.isProgramChangedInCareDateRange){
                    component.set("v.programChangeOverCareRange", response.objectData.isProgramChangedInCareDateRange);
                }

                var prog = response.objectData.fundingProg.label;
                var errorComponent = component.find('adjustmentFundingProgramBlank');
                if(errorComponent){
                    if(component.get("v.oneTimeAuthChangeHandle")==true && (prog == '' || prog == null || component.get("v.programChangeOverCareRange") == true)){
                    	errorComponent.set("v.message",'Please review the program types over the care dates entered and enter appropriate value.  If multiple program types are found over care dates, enter a separate Adjustment for each type.');
                    }
                    else{
                        errorComponent.set("v.message",'');
                    }
                }
                component.set("v.oneTimeAuthChangeHandle", true);
            },{'authorizationId':component.get("v.authId"), 'adStartDate':adStartDate, 'adEndDate':adEndDate}, false, null);
        }
    },
    
    closeModalConfirm : function(component, event, helper) {
        component.set("v.adjustmentEntryEditMode", false);
        helper.callModal(component,'confirmationModalOnCancel'); 
    },
    
    closeModal : function(component, event, helper) {
        component.set("v.adjustmentEntryEditMode", false);
        helper.closeAdjEntryModal(component);
    },
    
    createAdjDetail : function(component, event, helper) {
        component.set("v.userAction",event.getSource().getLocalId());
        component.set("v.isCurrentPageValid" , helper.checkCustomValidations(component));
        if(component.get("v.isCurrentPageValid")) {
            helper.validateAdjustmentAmount(component, event, helper);
        }   
    },
    
    confirmNewRec : function(component, event, helper) {
        helper.validateAuthDateRange(component,event, helper);
    },
    
    confirmAuthValidRec : function(component, event, helper) {
        helper.updateOrNewRec(component);
    },
})