({
    doInit : function(component, event, helper) {
        component.set("v.saveAsDraftMsg",$A.get("$Label.c.FMFlow_SaveAsDraftMessage"));
        component.set("v.finishMsg",$A.get("$Label.c.FMFlow_FinishMessage"));
        component.set("v.cancelAdjustment",$A.get("$Label.c.FMFlow_CancelAdjustmentMessage"));
        component.set("v.previousMsg",$A.get("$Label.c.FMFlow_PreviousMessage"));
        helper.callServerAndHandleError(component,"c.doGetInitData", function(response){
            var adjustment = response.objectData.adjustment;
            if(response.objectData.adjustDetailMap){
                component.set("v.adjustDetailMap", response.objectData.adjustDetailMap);
            }
            if(response.objectData.currentUtilizationMap){
                component.set("v.childCurrentUtilization", response.objectData.currentUtilizationMap);
            }
            component.set("v.adjustment",adjustment);
            component.set("v.isEditableAddress", response.objectData.isEditableAddress); 
            if(!$A.util.isEmpty(adjustment.IDN_CASE__c) && adjustment.CDE_TYPE_ADJMT__c == 'Recovery'){
                component.set("v.disabledARTFees",true);
                
            }
            component.set("v.nonAdjustmentDetailObj",response.objectData.nonAdjustmentDetail);
            component.set("v.adjustmentDtlWarp",response.objectData.adjustmentDtlWarp);
            component.set("v.individualObj",response.objectData.individualObj);
            component.set("v.rateTypeOptions",response.objectData.rateTypeOptions);
            helper.setAddressFields(component, response.objectData);
            helper.setResponsibleParties(component, response.objectData);
            // Bug fix 2929 - added care type unit options map
            component.set("v.careUnitTypeOptionsMap", response.objectData.careUnitTypeOptionsMap);
            if(response.objectData.adjustment && component.get("v.pageMode")!='view'){
                helper.setAdjustmentReasonOptions(component, response.objectData);
            }
            component.set("v.initLoaded",true);            
        }, {'adjustmentId':component.get("v.recordId")}, false, null);
    },
    
    doNext : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        if(component.get("v.pageMode")=='view'){
            if(component.get("v.isEditableAddress")){
                if(component.get("v.adjustment").IDN_CASE__c && component.get("v.adjustment").IDN_CASE__c!=null){
                    helper.callServerAndHandleError(component,"c.upsertResponsiblePartiesAddress", function(response){
                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1); 
                    }, {'adjustmentId':component.get("v.recordId"),'responsiblePartiesAddressList':component.get("v.responsiblePartiesAddressList")}, false, null);
                } else {
                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1); 
                }                                 
            }//logic added to update address for provider Recoveries in Cal Complete status only CCCAP-10780
            // removed type check for recovery as it is needed for claims also CCCAP-14858 issue 2
            else if(component.get('v.adjustment').CDE_STATUS_ADJMT__c=='Calculation Complete'  && component.get('v.adjustment').IDN_PROVR__c){
                var resultFromThisPage = component.find("adjustmentFlow_AdjustmentInformation").callValidateCurrentPage();
                if(resultFromThisPage){
                    helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
                        var mergedAdjustment = helper.merge(component.get("v.address"), response.objectData.upsertedRecords[1]);
                        component.set("v.address", mergedAdjustment);
                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);    
                    }, {'lstSObject':[component.get("v.address")]}, false, null);
                }
            }else {
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1); 
            }
        } else {
            if(currentTabNumber==1){
                var resultFromThisPage = component.find("adjustmentFlow_AdjustmentInformation").callValidateCurrentPage();
                component.set("v.isCurrentPageValid",resultFromThisPage);
                if(resultFromThisPage==true){
                    if(!$A.util.isEmpty(component.get("v.responsiblePartiesAddressList"))){
                        helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
                            console.log('IPVRecordId before upsert--'+component.get("v.IPVRecordId"));
                            helper.callServerAndHandleError(component,"c.upsertResponsibleParties", 
                                                            function(response){
                                                                if(response.isSuccessful==true){
                                                                    console.log('responsiblePartiesAddressList before upsert--'+JSON.stringify(component.get("v.responsiblePartiesAddressList")));
                                                                    helper.callServerAndHandleError(component,"c.upsertResponsiblePartiesAddress", 
                                                                                                    function(response){
                                                                                                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1); 
                                                                                                    }, {'adjustmentId':component.get("v.recordId"),'responsiblePartiesAddressList':component.get("v.responsiblePartiesAddressList")}, false, null);                                                                                                  
                                                                }
                                                            }, {'adjustmentId':component.get("v.recordId"),'responsiblePartyList':component.get("v.responsiblePartyList")}, false, null);                                                    
                        }, {'lstSObject':[helper.getAdjustmentRecord(component)]}, false, null);   
                    } else{
                        helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
                            console.log('IPVRecordId before upsert--'+component.get("v.IPVRecordId"));
                            var mergedAdjustment = helper.merge(component.get("v.address"), response.objectData.upsertedRecords[1]);
                            component.set("v.address", mergedAdjustment);
                            helper.callServerAndHandleError(component,"c.upsertResponsibleParties", function(response){
                                if(response.isSuccessful==true){
                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);    
                                }
                            }, {'adjustmentId':component.get("v.recordId"),'responsiblePartyList':component.get("v.responsiblePartyList")}, false, null);                                                    
                        }, {'lstSObject':[helper.getAdjustmentRecord(component),component.get("v.address")]}, false, null);
                    }
                }
            }
        }
    },
    
    //added below method by vinanthi
    onClickCustomButton2 : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        var adjustment = component.get("v.adjustment");
        component.set("v.showSpinner",true);
        if(currentTabNumber == 2 && component.get("v.pageMode")!='view' && adjustment.CDE_AGNST_ADJMT__c=='Non Sub-Payment') {
            $A.createComponent("c:adjustmentFlow_NonSubPayment_AddAdjDetailFlow", {
                adjustmentObj:component.get("v.adjustment"),
                individualObj:component.get("v.individualObj"),
                authId:component.get("v.authId"),
                authorizationAssocIndiv:component.get("v.authorizationAssocIndiv"),
                isCurrentPageValid:component.get("v.isCurrentPageValid"),
                adjustmentEntryEditMode:component.get("v.adjustmentEntryEditMode"),
                nonAdjustmentDetail:component.get("v.nonAdjustmentDetail"),
                authorizationObj:component.get("v.authorizationObj"),
                hasNonAdjDetailError:component.get("v.hasNonAdjDetailError"),
                nonAdjustmentDetailObj:component.get("v.nonAdjustmentDetailObj")
            },function(content, status) {
                component.set("v.showSpinner",false);
                if (status === "SUCCESS") {
                    component.find('overlayLib').showCustomModal({
                        header: "Adjustment Entry",
                        body: content,
                        showCloseButton: true,
                        cssClass: "slds-modal_large",
                        closeCallback: function() {
                            
                        }                                       
                    });
                }
            });
        } else if(currentTabNumber == 2 && component.get("v.pageMode")!='view' && adjustment.CDE_AGNST_ADJMT__c=='Sub-Payment') {
            $A.createComponent("c:adjustmentFlow_SubPayment_AddAdjDetailFlow", {'adjustment':component.get("v.adjustment"), 
                                                                                adjustDetailMap:component.get("v.adjustDetailMap"),
                                                                                'disabledARTFees':component.get("v.disabledARTFees")
                                                                               },
                               function(content, status) {
                                   component.set("v.showSpinner",false);
                                   if (status === "SUCCESS") {
                                       component.find('overlayLib').showCustomModal({
                                           header: "Adjustment Entry",
                                           body: content,
                                           showCloseButton: true,
                                           cssClass: "slds-modal_large",
                                           closeCallback: function(){}                                       
                                       });
                                   }
                               });
        } else {
            component.set("v.showSpinner",true);
            component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);   
            component.set("v.showSpinner",false);
        }
    },
    
    doPrevious : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        var adjustment = component.get("v.adjustment");
        component.set("v.showSpinner",true);
        if((component.get("v.currentTabNumber")-1) == 1){
            helper.getReasonPicklistToLabel(component, event, helper);
        }
        if(!$A.util.isEmpty(component.get("v.responsiblePartiesAddressList"))){
            helper.callServerAndHandleError(component,"c.doGetAddress", function(response){
                if(response.objectData.responsiblePartiesAddressList){
                    component.set("v.responsiblePartiesAddressListClone",response.objectData.addressList);
                    component.set("v.responsiblePartiesAddressList",response.objectData.responsiblePartiesAddressList);
                    component.set("v.addressList",response.objectData.addressList);
                }
            }, {'adjustmentId':component.get("v.recordId")}, false, null);
        }
        component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);   
        component.set("v.showSpinner",false);
    },
    
    doUpdateCurrentTabHeadings : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        var tabNames = component.get("v.tabNames");
        var tabInfos = component.get("v.tabInfos");
        component.set("v.currentTabTitle", tabNames[currentTabNumber-1]);
        component.set("v.currentTabInfo", tabInfos[currentTabNumber-1]);
        var adjustment = component.get("v.adjustment");
        if(component.get("v.pageMode")!='view') {
            if(currentTabNumber==1) {
                component.set("v.showCustomButton", false);
                component.set("v.showCustomButton2", false);
                component.set("v.showCancel", true);
            }            
            if(currentTabNumber==2) {
                component.set("v.showCustomButton2", true);
                // Added below condition by Rishav for CCCAP-6051
                if(adjustment.CDE_TYPE_ADJMT__c == 'Recovery' && adjustment.CDE_STATUS_ADJMT__c == 'Calculation Complete'){
                    component.set("v.showCustomButton", false);
                } else {
                    component.set("v.showCustomButton", true);
                    component.set("v.customButtonLabel","Save as Draft");
                }
                //component.set("v.previousLabel", 'Add Adjustment Detail');
            }    
        } else {
            if(currentTabNumber==1) {
                component.set("v.showCustomButton2", false);
                component.set("v.showCustomButton", false);
                component.set("v.showCancel", false);
            }
            if(currentTabNumber==2) {
                component.set("v.showCustomButton", false);
                component.set("v.showCancel", false);
                component.set("v.showCustomButton2", false);
                component.set("v.finishLabel", "Finish");
            }
        }
        
    },
    
    doSaveAndNew : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        var adjustment = component.get("v.adjustment");
        if(currentTabNumber==2) {
            if(adjustment.CDE_AGNST_ADJMT__c=='Sub-Payment'){
                helper.callModal(component,'confirmationModalOnSaveAsDraft_sub');   
            } else {
                helper.callModal(component,'confirmationModalOnSaveAsDraft');   
            }
        }
    },
    
    confirmSaveAsDraft : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getRecordTypeId", function(response){
            var adjRecType = response.objectData.recordtypeId;
            var adjustment = {'sobjectType' : 'T_ADJMT__c',
                              'Id':component.get("v.recordId"),
                              'RecordTypeId':adjRecType};
            helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
                var recordId = component.get("v.recordId");
                helper.goToRecord(recordId,'detail');
            }, {'lstSObject':[adjustment]}, false, null);  	
        }, {'recordTypeName':'In Process',
            'parentObjectName':'T_ADJMT__c',
            'recordId':null,
            'adjustmentAmount':component.get("v.adjustment.AMT_ADJMT__c")}, false, null);
    },
    
    doFinish : function(component, event, helper) {
        var adjustment = component.get("v.adjustment");
        // Seperated logic for 'Recovery' adj and added date and amount validation by Rishav for CCCAP-6051
        if(adjustment.CDE_TYPE_ADJMT__c == 'Recovery'){
            // if section is for 'Recovery' adjustments
            var origDiscDateString = adjustment.DTE_DISCV_ADJMT_ORIG__c;
            if(origDiscDateString != null || origDiscDateString != undefined){
                var origDiscDate = new Date(new Date(origDiscDateString).toDateString());
                var past12Months = new Date(new Date().toDateString());
                past12Months.setDate(past12Months.getDate() - 365);
                if(origDiscDate < past12Months && adjustment.AMT_ADJMT__c < 50 && adjustment.CDE_TYPE_ADJMT__c == 'Recovery'){
                    component.set("v.pageMessages", [$A.get("$Label.c.adjustment_error_discoveryDate")]); 
                    component.set("v.messageType", "error");
                    // Moved 'c.doVerifyAdjustmentNote' inside else section
                } else {
                    helper.callServerAndHandleError(component,"c.doVerifyAdjustmentNote", function(response){
                        var noteFound = response.objectData.noteFound;
                        if(noteFound){
                            if(component.get("v.pageMode")!='view') {
                                var adjustmentDetailRec = component.get("v.adjustmentDtlWarp");
                                var nonAdjustmentDetailObj = component.get("v.nonAdjustmentDetailObj");
                                if (adjustmentDetailRec != null && adjustmentDetailRec != undefined && adjustment.CDE_AGNST_ADJMT__c=='Sub-Payment') {
                                    helper.callModal(component,'confirmationModalOnFinish_sub');
                                } else if(!$A.util.isEmpty(nonAdjustmentDetailObj) && adjustment.CDE_AGNST_ADJMT__c=='Non Sub-Payment') {
                                    helper.callModal(component,'confirmationModalOnFinish'); 
                                } else {
                                    component.set("v.pageMessages",["Please add adjustment details before finalizing the adjustment."]); 
                                    component.set("v.messageType","error");
                                }
                            } else {
                                var recordId = component.get("v.recordId");
                                helper.goToRecord(recordId,'detail');
                            }
                        } else {
                            helper.callModal(component,'confirmationModalAdjNotes');
                        }
                    },{'adjId':adjustment.Id}, false, null);
                }
            } else {
                component.set("v.pageMessages", [$A.get("$Label.c.adjustment_error_discDateRequired")]); 
                component.set("v.messageType", "error");
            }
        } else {
            // else section is for 'Claim' adjustments
            helper.callServerAndHandleError(component,"c.doVerifyAdjustmentNote", function(response){
                var noteFound = response.objectData.noteFound;
                if(noteFound){
                    if(component.get("v.pageMode")!='view') {
                        var adjustmentDetailRec = component.get("v.adjustmentDtlWarp");
                        var nonAdjustmentDetailObj = component.get("v.nonAdjustmentDetailObj");
                        if (adjustmentDetailRec != null && adjustmentDetailRec != undefined && adjustment.CDE_AGNST_ADJMT__c=='Sub-Payment') {
                            helper.callModal(component,'confirmationModalOnFinish_sub');
                        } else if(!$A.util.isEmpty(nonAdjustmentDetailObj) && adjustment.CDE_AGNST_ADJMT__c=='Non Sub-Payment') {
                            helper.callModal(component,'confirmationModalOnFinish'); 
                        } else {
                            component.set("v.pageMessages",["Please add adjustment details before finalizing the adjustment."]); 
                            component.set("v.messageType","error");
                        }
                    } else {
                        var recordId = component.get("v.recordId");
                        helper.goToRecord(recordId,'detail');
                    }
                } else {
                    helper.callModal(component,'confirmationModalAdjNotes');
                }
            },{'adjId':adjustment.Id}, false, null);
        }
    },
    
    confirmFinish : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getRecordTypeId", function(response){
            var adjRecType = response.objectData.recordtypeId;
            // Added below outstandingRecoveryBalance and triggerCR206 logic by Rishav for for CCCAP-6051
            var outstandingRecoveryBalance = component.get("v.adjustment.Outstanding_Recovery_Balance__c");
            if(response.objectData.outstandingRecoveryBalance){
                outstandingRecoveryBalance = response.objectData.outstandingRecoveryBalance;
            }
            var triggerCR206 = false;
            if(component.get("v.adjustment.CDE_TYPE_ADJMT__c") == 'Recovery' && component.get("v.adjustment.CDE_STATUS_ADJMT__c") == 'Calculation Complete' && component.get("v.pageMode")=='edit'){
                triggerCR206 = true;
            }
            var recoveryEffvDate = component.get("v.adjustment.DTE_EFFV_RECOVERY__c");
            if(component.get("v.adjustment.CDE_TYPE_ADJMT__c") == 'Recovery' && component.get("v.adjustment.RecordType.DeveloperName") != 'Finalized'){
                recoveryEffvDate = new Date();
            }
            var adjustment = {'sobjectType' : 'T_ADJMT__c',
                              'Id' : component.get("v.recordId"),
                              'RecordTypeId' : adjRecType,
                              'CDE_STATUS_ADJMT__c' : '2',
                              'AMT_ADJMT__c' : component.get("v.adjustment.AMT_ADJMT__c"),
                              'CHK_CR206ForceTrigger__c' : triggerCR206,
                              'DTE_EFFV_RECOVERY__c' : recoveryEffvDate};
            //added below change for CCCAP-11054, to only be set for Recoveries and not claim types
            if(component.get("v.adjustment.CDE_TYPE_ADJMT__c") == 'Recovery'){
                adjustment.Outstanding_Recovery_Balance__c = outstandingRecoveryBalance
             }
            helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
                var adjustmentTemp = component.get("v.adjustment");
                if(adjustmentTemp.CDE_AGNST_ADJMT__c=='Sub-Payment'){
                    var adjustmentDtlWarp = component.get("v.adjustmentDtlWarp");
                    if(adjustmentDtlWarp!=undefined && adjustmentDtlWarp.length!=undefined && adjustmentDtlWarp.length>0){
                        var adjObjUpdateList = [];
                        adjustmentDtlWarp.forEach(function(eachAdjDetailObj) {
                            eachAdjDetailObj.ajustmentDetails.CDE_STATUS_DETAIL_ADJMT__c = '2';
                            var adjObj = {'sobjectType' : 'T_ADJMT_DETAIL__c',
                                          'Id':eachAdjDetailObj.ajustmentDetails.Id,
                                          'CDE_STATUS_DETAIL_ADJMT__c':eachAdjDetailObj.ajustmentDetails.CDE_STATUS_DETAIL_ADJMT__c,
                                          'IDN_DETAIL_PMT_SUB__c':eachAdjDetailObj.subPaymentDetails.ExternalId
                                         };
                            adjObjUpdateList.push(adjObj);
                        });
                        helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
                            // Calling Callout
                            helper.callServerAndHandleError(component,"c.subPaymentCallOut", function(response){
                                var recordId = component.get("v.recordId");
                                helper.goToRecord(recordId,'detail');
                            }, {'adjustmentDtlList':adjObjUpdateList}, false, null);  
                        }, {'lstSObject':adjObjUpdateList}, false, null); 
                    } else {
                        // Calling Callout
                        helper.callServerAndHandleError(component,"c.subPaymentCallOut", function(response){
                            var recordId = component.get("v.recordId");
                            helper.goToRecord(recordId,'detail');
                        }, {'adjustmentDtlList':adjObjUpdateList}, false, null);  
                    }
                } else {
                    var nonAdjustmentDetailObj = component.get("v.nonAdjustmentDetailObj");
                    if(nonAdjustmentDetailObj!=undefined && nonAdjustmentDetailObj.length!=undefined && nonAdjustmentDetailObj.length>0){
                        var nonAdjObjUpdateList = [];
                        nonAdjustmentDetailObj.forEach(function(eachNonAdjDetailObj) {
                            eachNonAdjDetailObj.CDE_STATUS_DETAIL_ADJMT__c = '2';
                            var nonAdjObj = {'sobjectType' : 'T_NON_ADJMT_DETAIL__c',
                                             'Id':eachNonAdjDetailObj.Id,
                                             'CDE_STATUS_DETAIL_ADJMT__c':eachNonAdjDetailObj.CDE_STATUS_DETAIL_ADJMT__c
                                            };
                            nonAdjObjUpdateList.push(nonAdjObj);
                        });
                        helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
                            var recordId = component.get("v.recordId");
                            helper.goToRecord(recordId,'detail');
                        },{'lstSObject':nonAdjObjUpdateList}, false, null);
                    }else{
                        helper.goToRecord(component.get("v.recordId"),'detail');
                    }
                }
            }, {'lstSObject':[adjustment]}, false, null);
        }, {'recordTypeName':'Finalized',
        'parentObjectName':'T_ADJMT__c',
        'recordId':component.get("v.recordId"),
        'adjustmentAmount':component.get("v.adjustment.AMT_ADJMT__c")}, false, null);
},
    
    doCancel : function(component, event, helper) {
        var adjustment = component.get("v.adjustment");
        var currentTabNumber = component.get("v.currentTabNumber");
        if(adjustment.CDE_AGNST_ADJMT__c=='Sub-Payment'){
            helper.callModal(component,'confirmationModalOnCancel_'+currentTabNumber+'_sub');   
        } else {
            helper.callModal(component,'confirmationModalOnCancel_'+currentTabNumber);   
        }
    },
    
    confirmCancel : function(component, event, helper) {
        var isNonAdjustment = false;
        if(component.get("v.adjustment.RecordType.DeveloperName")=='New'){
            var recordsToBeDeleted = [];
            recordsToBeDeleted.push(component.get("v.address"));
            var nonAdjustmentDetailObj = component.get("v.nonAdjustmentDetailObj");
            if(nonAdjustmentDetailObj!=undefined && nonAdjustmentDetailObj.length!=undefined){
                nonAdjustmentDetailObj.forEach(function(rec){
                    rec.sobjectType ='T_NON_ADJMT_DETAIL__c';
                    isNonAdjustment = true;
                    recordsToBeDeleted.push(rec);
                });
            }
            var adjustmentDetailLst = component.get("v.adjustmentDetailLst");
            if(adjustmentDetailLst!=undefined && adjustmentDetailLst.length!=undefined){
                adjustmentDetailLst.forEach(function(rec){
                    isNonAdjustment = false;
                    recordsToBeDeleted.push(rec);
                });
            }
            helper.callServerAndHandleError(component,"c.doDeleteRecords", function(response){
                var recordId = component.get("v.recordId");
                helper.goToRecord(recordId,'detail');
            }, {'adjustmentId':component.get("v.recordId"), 'isNonAdjustment':isNonAdjustment}, false, null);        
        } else {
            var recordId = component.get("v.recordId");
            helper.goToRecord(recordId,'detail');
        }
    },
    
    confirmPrevious : function(component, event, helper) {
        helper.decrementCurrentTabNumber(component);
    },
    
    confirmNewRec : function(component, event, helper) {
        helper.updateOrNewRec(component);
    },
    
    doOnUpdate : function(component, event, helper) { 
        component.set("v.nonAdjustmentDetailObj",event.getParam("nonAdjustmentDetailObj"));
        helper.callServerAndHandleError(component,"c.doGetInitData", function(response){
            component.set("v.nonAdjustmentDetailObj",response.objectData.nonAdjustmentDetail);
        }, {'adjustmentId':component.get("v.recordId")}, false, null);
    },
    
    updateadjustmentDetail: function(component, event, helper) { 
        component.set("v.adjustmentDtlWarp",event.getParam("adjustmentDtlWarp"));
    },
    
    confirmAdjNote : function(component, event, helper){
        helper.openModalforAdjustmentNote(component);
    },
    
    closeModal : function(component, event, helper){
        helper.closeModal(component, event, helper);
    }
})