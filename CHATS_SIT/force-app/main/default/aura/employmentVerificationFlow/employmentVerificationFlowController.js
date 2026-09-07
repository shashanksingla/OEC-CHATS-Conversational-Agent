({
    doInit : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getInitData", 
                                        function(response){
                                           
                                            component.set("v.employment",response.objectData.data);
                                            if(response.objectData.data.Employment_Verifications__r!=undefined && response.objectData.data.Employment_Verifications__r.length>0){
                                                component.set("v.employmentVerification",response.objectData.data.Employment_Verifications__r[0]);
                                            }
                                            if(response.objectData.data.Employment_Information__r!=undefined && response.objectData.data.Employment_Information__r.length>0){
                                                component.set("v.employmentInformation",response.objectData.data.Employment_Information__r[0]);
                                            }
                                            if(response.objectData && response.objectData.isReadOnlyUser){
                                                component.set("v.isReadOnlyUser",response.objectData.isReadOnlyUser);
                                            }
                                        }, {'employmentId':component.get("v.recordId")}, false, null);
    },
    doFinish : function(component, event, helper) {
        var employmentVerification = component.get("v.employmentVerification");
        var employmentInformation = component.get("v.employmentInformation");
        var recordId = component.get("v.recordId");
        var childCmp = component.find("employmentVerificationLayout");
        childCmp.callValidateCurrentPage();
        // server side call
        if(component.get("v.isCurrentPageValid")==true){
            var lstSObject = [employmentVerification];
            if(employmentVerification.IDN_EMPLMT_INDIV__c=='' || employmentVerification.IDN_EMPLMT_INDIV__c==null){
                employmentVerification.IDN_EMPLMT_INDIV__c = component.get("v.recordId");
            }
            if(employmentInformation.Id!=null && employmentInformation!=undefined){
                lstSObject.push(employmentInformation);
            }
            helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response){
                                                helper.redirectToRecord(component.get("v.recordId"));
                                            }, {'lstSObject':lstSObject,"isFinalStep":true}, false, null);
        }
    }
})