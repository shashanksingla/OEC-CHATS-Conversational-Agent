({
    doInit: function(component, event, helper) {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var isNewCaseCommentFromCaseComment = component.get("v.componentAttributes").newCaseCommentFromCaseComment;
        component.set("v.loggedInUserId",userId);
        var recordId = component.get("v.recordId");//LINE 4
        helper.fetchUserId(component, event, helper);
         // Getting SobjectName
        var action2 = component.get("c.getCaseOrCaseCommentObjectAPI");
        if(isNewCaseCommentFromCaseComment == 'true'){
            action2.setParams({"recordId": component.get("v.recordId"),
                               "isNewCaseCommentFromCaseComment": isNewCaseCommentFromCaseComment});
        } else {
        	action2.setParams({"recordId": component.get("v.recordId"),
                               "isNewCaseCommentFromCaseComment": null});    
        }
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.objectData.isValidCounty == false){
                    var recordError = 'The Case Comment that you are trying to create belongs to '+res.objectData.countyName+' county. This does not match your assigned county(ies). Would you like to continue?';
                    component.set("v.msgOnDiffOwnerCounty", recordError);
                    helper.callModal(component,"warningModalOnDiffOwnerCounty");
                } 
                component.set("v.isSobjectName", true);
                if(res.objectData.sObjName == 'T_SBSD_CASE__c'){
                    component.set("v.isNew",true);
                    if(isNewCaseCommentFromCaseComment == 'true'){
                        component.set("v.caseRecordId",res.objectData.caseRecordId);
                        component.set("v.caseExtnlId",res.objectData.caseExtnlId);
                        // Added below 2 lines for CCCAP-2439 by Rishav on 21-Dec-2020
                        component.set("v.recordId",component.get("v.caseRecordId"));
                        component.set("v.isNewCaseCommentFromCaseComment",'true');
                    } else {
                        component.set("v.caseRecordId",recordId);    
                    }
                }else{
                    component.set("v.isNew",false);   
                }
                component.set("v.sObjectName", res.objectData.sObjName);                
            } else {
               
            }
        });
        $A.enqueueAction(action2);
    },

    handleSaveCaseComment : function(component, event, helper) {
        var isEditCommentFromCaseComment = component.get("v.componentAttributes").editCommentFromCaseComment;
        var isProceed = true;
        var simpleNewCaseComment = component.get("v.simpleNewCaseComment");
        if(simpleNewCaseComment.cde_type_note_cmt__c == 'Appointment'){
            isProceed= false;
            if((simpleNewCaseComment.dte_appointment__c != null && simpleNewCaseComment.dte_appointment__c != '')){
                isProceed= true;
            }else{
                isProceed= false;
                var recordError =[];
                recordError.push('Please enter appointment date/time');
                component.set("v.message",'error');
                component.set("v.recordError",recordError);
            }
        }
        if(simpleNewCaseComment.txt_subj__c =='' || simpleNewCaseComment.txt_subj__c == undefined){
            isProceed= false;
            var recordError2 =[];
            recordError2.push('Please enter Mandatory fields');
            component.set("v.message",'error');
            component.set("v.recordError",recordError2);
            
        }else if(simpleNewCaseComment.txt_cmt__c =='' || simpleNewCaseComment.txt_cmt__c == undefined){
            isProceed= false;
            var recordError1 =[];
            recordError1.push('Please enter Mandatory fields');
            component.set("v.message",'error');
            component.set("v.recordError",recordError1);
        }
        else if(!$A.util.isEmpty(simpleNewCaseComment.txt_subj__c) &&  (simpleNewCaseComment.txt_subj__c).length>30){
            isProceed= false;
            var recordError1 =[];
            recordError1.push('Subject can not exceed 30 characters.');
            component.set("v.message",'error');
            component.set("v.recordError",recordError1);
        }
       /* if(isNaN(simpleNewCaseComment.idn_sbsd_case_cmt__c)){
            var recordError =[];
            recordError.push('Case Note ID should be number.');
            component.set("v.message",'error');
            component.set("v.recordError",recordError);
        }else if(simpleNewCaseComment.idn_sbsd_case_cmt__c <=0){
            var recordError1 =[];
            recordError1.push('Case Note ID should be greater than 0.');
            component.set("v.message",'error');
            component.set("v.recordError",recordError1);
        }
        else */ 
        if(isProceed){
            var isNew = component.get("v.isNew");
            simpleNewCaseComment.cde_type_cmt__c = 'User-Generated';
            // simpleNewCaseComment.idn_sbsd_case_cmt = 123;
            simpleNewCaseComment.lastmodifiedbyid__c = component.get('v.loggedInUserId');
            simpleNewCaseComment.lastmodifieddate__c =new Date();// helper.getDateInUTC(new Date());
            if(isNew){
                var caseRec = component.get("v.caseRec");
                var isNewCaseCommentFromCaseComment = component.get("v.componentAttributes").newCaseCommentFromCaseComment;
                if(isNewCaseCommentFromCaseComment == 'true'){
                	simpleNewCaseComment.idn_case__c = component.get("v.caseExtnlId");
                } else {
                	simpleNewCaseComment.idn_case__c = caseRec.IDN_EXTNL__c ;//component.get('v.recordId');    
                }
                simpleNewCaseComment.createdbyid__c = component.get('v.loggedInUserId');
                simpleNewCaseComment.createddate__c =new Date();// helper.getDateInUTC(new Date());
            }
           
            var lstSObject = [];
            if(simpleNewCaseComment!=undefined){
                lstSObject.push(simpleNewCaseComment);
            }
            
            var whichOne = event.getSource().getLocalId();
            
            if(whichOne =='Save'){
                helper.callServerForExternalObjAndHandleError(component,"c.insertExternalObjRecords", 
                                                              function(response){
                                                                  if(!$A.util.isEmpty(response.objectData.recordToBeRedirected)){
                                                                          helper.redirectToRecord(response.objectData.recordToBeRedirected);
                                                                          if(isEditCommentFromCaseComment == 'true'){
                                                                              var showToast = $A.get("e.force:showToast");
                                                                              showToast.setParams({
                                                                                  'title': 'SUCCESS',
                                                                                  'message': 'Please reload the page to see the latest information.'
                                                                              });
                                                                              showToast.fire();
                                                                          }
                                                                      } else {
                                                                          helper.redirectToRecord(component.get("v.recordId"));    
                                                                      }
                                                              }, {'lstSObject':lstSObject,"isFinalStep":true}, false, null); 
            } else {
                helper.callServerForExternalObjAndHandleError(component,"c.insertExternalObjRecords", 
                                                              function(response){
											                    simpleNewCaseComment.cde_type_note_cmt__c = '';
											                    simpleNewCaseComment.txt_subj__c = '';
											                    simpleNewCaseComment.txt_cmt__c = '';
											                    simpleNewCaseComment.dte_appointment__c = null;
											                    component.set("v.simpleNewCaseComment",simpleNewCaseComment);
                                                              }, {'lstSObject':lstSObject,"isFinalStep":true}, false, null); 
            }
        }
    },

    handleCancelCaseComment :function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    },

    handleRecordUpdated :function(component, event, helper) {
    },
    
    closeModal : function(component, event, helper){
        var modalCall = component.find("warningModalOnDiffOwnerCounty");
        $A.util.removeClass(modalCall.find('backDrop'),'slds-backdrop--open');
        $A.util.removeClass(modalCall.find('confirmMsgModal'), 'slds-fade-in-open'); 
    }
})