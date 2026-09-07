({
    doInit : function(component, event, helper) {
        console.log('careDateToAuthEncmbr init in authflow-->'+component.get("v.careDateToAuthEncmbr"));
        helper.setChildStateOptions(component);
        var sObjectName = component.get('v.sObjectName');//=='T_AUTH__c'
        var action1 = component.get('c.checkOwnerCountyMatch');
        action1.setParams({
            'recordId' : component.get("v.recordId"),
            'fieldName':'CDE_COUNTY__c'
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){
                    if(res.objectData.caseObj){
                        component.set("v.caseRec",res.objectData.caseObj);
                    }
                    if((res.objectData.showWarning)){
                        component.set("v.showWarningForCounty",true); 
                        component.set("v.countyMessage",res.objectData.warningMessage);
                    }else{
                        component.set("v.showWarningForCounty",false);
                        component.set("v.countyMessage",res.objectData.warningMessage);
                    }
                    if(res.objectData.isCaseClosed){
                        component.set("v.isReadOnly",res.objectData.isCaseClosed);
                    }
                    if(res.objectData.countyId){
                        component.set("v.countySFId",res.objectData.countyId);
                    }
                }
            }
        });
        $A.enqueueAction(action1);
        
        if(sObjectName == 'T_AUTH__c'){
            component.set("v.isCreate", false);
            //Getting the schedule recurrence records
            var action = component.get('c.getScheduleRecurrences');
            action.setParams({
                'recordId' : component.get("v.recordId")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state == 'SUCCESS') {
                    var res =response.getReturnValue();
                    if(res.isSuccessful){
                        if(res.objectData.recurrenceList){
                            component.set("v.scheduleRecurr",res.objectData.recurrenceList);
                        }
                    }
                } 
            });
            $A.enqueueAction(action);
            //end
        }else{
            var caseRec = component.get("v.caseRec");
            
            var action2 = component.get('c.checkChildProgram');
            action2.setParams({
                'recordId' : component.get("v.recordId")
            });
            action2.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state == 'SUCCESS') {
                    var res =response.getReturnValue();
                    console.log('res---'+res);
                    component.set("v.isChildWefareCare",res);                   
                } else {
                    console.log('error in InputPicklist');
                }
            });        
            $A.enqueueAction(action2);
        }
    },
    printdata : function(component, event, helper) {
        console.log('careDateToAuthEncmbr change in authflow-->'+component.get("v.careDateToAuthEncmbr"));
    },
    confirmYes : function(component, event, helper){
        var cmp = component.find('confirmationModalOnCountyCheck_1');
        cmp.hideConfirmModal();
        
        var date, lastDay;
        var authRecToBeUpserted = component.get("v.authRec");
        var caseRec = component.get("v.caseRec"); 
        
        component.set("v.showSpinner", false);
        var action3 = component.get('c.careLevelOfferedByProvider');
        var authRecToBeUpserted1 = component.get("v.authRec");
        var currentBeginDate = authRecToBeUpserted1.DTE_BEGIN_EFFV_AUTH__c;
        var currentProviderId = authRecToBeUpserted1.IDN_PROVR__c;
        var currentClientId = authRecToBeUpserted1.IDN_CLIENT__c;
        var	authId = component.get("v.caseRec").Id;
        action3.setParams({
            'authId':authId,
            'recordId':component.get("v.recordId"),
            'currentBeginDate':currentBeginDate,
            'currentProviderId':currentProviderId,
            'currentClientId':currentClientId
        });
        action3.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){
                    if((res.objectData.showWarningCareLevel)){
                        component.set("v.showWarningChildCareLevel",true);
                        component.set("v.careLevelMessage",res.objectData.warningMessageCareLevel);
                        component.set("v.showSpinner", false);
                        helper.callModal(component,'confirmationModalOnCareLevel');
                    }else{
                        component.set("v.showWarningChildCareLevel",false);
                        component.set("v.careLevelMessage",res.objectData.warningMessageCareLevel);
                        helper.checkValidations(component, event, helper);
                    }
                }
            } else {
                console.log('error in careLevelOfferedByProvider');
            }
        });        
        $A.enqueueAction(action3); 
    },
    
    confirmYes1 : function(component, event, helper){
        var cmp = component.find('confirmationModalOnCareLevel');
        cmp.hideConfirmModal();
        component.set("v.showSpinner", true);
        helper.validateIfBelowSchoolAge(component, event, helper); // Added by Rishav for CCCAP-6983
        //helper.checkValidations(component, event, helper); // Commented by Rishav for CCCAP-6983
    },
    
    confirmYes2: function(component, event, helper){
        var cmp = component.find('confirmationModalOnReplaceofscAssRec');
        cmp.hideConfirmModal();
        var caseRec = component.get("v.caseRec");
        var authRecToBeUpserted = component.get("v.authRec");
        var sObjectName = component.get('v.sObjectName');
        component.set("v.showSpinner", true);
        // Filter out fields with blank values before sending to server
        var authNewFiltered = {};
        for (var key in authRecToBeUpserted) {
            if (authRecToBeUpserted.hasOwnProperty(key) && authRecToBeUpserted[key] !== '') {
                authNewFiltered[key] = authRecToBeUpserted[key];
            }
        }
        var action1 = component.get('c.getAuthorizationNotesStatusValidation');
        action1.setParams({
            'authId' : authRecToBeUpserted.Id,'authNew':authNewFiltered
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res = response.getReturnValue();
                if(res.isSuccessful) {
                    if((res.objectData.AuthTerminated)){
                        component.set("v.authTerminated",true);
                    }
                    helper.validateIfBelowSchoolAge(component, event, helper); // Added by Rishav for CCCAP-6983
                    //helper.checkValidations(component, event, helper); // Commented by Rishav for CCCAP-6983
                } else {
                    component.set("v.showSpinner", false);
                    var recordError2 =[];
                    var message = '';
                    if((res.objectData.UpdateAuthorization)) {
                        message ='A terminated authorization cannot be updated'; 
                    }
                    if((res.objectData.AMT_ACTV_AUTH__c)) {
                        message ='Registration can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date'; 
                    } else if(res.objectData.AMT_TRANSP_AUTH__c) {
                        message ='Transportation can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                    } else if(res.objectData.AMT_RGSTR_AUTH__c) {
                        message ='Activity can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                    } else if(res.objectData.CDE_REL_PROVR__c) {
                        message ='Provider Location / Relation to Child can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                    }
                    if(message != ''){
                        recordError2.push(message);
                    }
                    component.set("v.message",'error');
                    component.set("v.recordError",recordError2);
                }
            } else {
                component.set("v.showSpinner", false);    
            }            
        });        
        $A.enqueueAction(action1); 
    },
    
    // Added by Rishav for CCCAP-6983
    confirmYes3 : function(component, event, helper){
        component.set("v.showSpinner", true);
        var cmp = component.find('confirmationModalBelowSchoolAge');
        cmp.hideConfirmModal();
        helper.checkValidations(component, event, helper);       
    },
    
    confirmNo: function(component, event, helper){
        var cmp = component.find('confirmationModalOnCountyCheck_1');
        cmp.hideConfirmModal();
    },
    
    confirmNo1: function(component, event, helper){
        var cmp = component.find('confirmationModalOnCareLevel');
        cmp.hideConfirmModal();
        component.set("v.showSpinner", false);
    },
    
    confirmNo3: function(component, event, helper){
        var cmp = component.find('confirmationModalBelowSchoolAge');
        cmp.hideConfirmModal();
    },
    
    confirmNo2: function(component, event, helper){
        var cmp = component.find('confirmationModalOnReplaceofscAssRec');
        cmp.hideConfirmModal();
        //component.set("v.showSpinner", true);
        var authRecClone = component.get("v.authRecClone");
        var scAssRecOldValue = authRecClone.IDN_SLOT_CONTRACT__c;
        var authRec = component.get("v.authRec");
        authRec.IDN_SLOT_CONTRACT__c = scAssRecOldValue;
        authRec.DTE_BEGIN_SLOT__c = authRecClone.DTE_BEGIN_SLOT__c;
        component.set("v.authRec",authRec);
        var scAssRecId = authRec.IDN_SLOT_CONTRACT__c;
        var action = component.get('c.queryPopulateSCAssRecord');
        action.setParams({
            'scAssId' : scAssRecId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){                        
                    if(!$A.util.isEmpty(scAssRecId)){
                        var scAssRec=component.get('v.SCAssociationRec');
                        scAssRec.DTE_BEGIN_SLOT__c=res.objectData.scAssRecBgnDte;
                        scAssRec.DTE_END_SLOT__c=res.objectData.scAssRecEndDte;
                        scAssRec.CDE_CARE_LEVEL__c=res.objectData.scAssCareLvl;
                        scAssRec.SLOT_CONTRACT_DESCRIPTION__c=res.objectData.scAssDesc;
                        component.set("v.SCAssociationRec",scAssRec);
                    } else {
                        component.set("v.SCAssociationRec",{'sobjectType':'T_SLOT_CONTRACT__c','IDN_AUTH__c':''});
                    }                        
                }
            } 
        });
        $A.enqueueAction(action);
    },
    
    hoursPerWeekDayChange : function(component, event, helper) {
        component.set("v.hoursPerWeekDayChanged", true);
    },
    
    doFinish : function(component, event, helper) {
        var childComponent = component.find("authorizationSchedPg2");
        var isInvalid=childComponent.handleUnsavedChanges();
        var isReadOnly = component.get("v.isReadOnly");
        var authRecUpserted = component.get("v.authRec");
        console.log('finish auth', JSON.stringify(authRecUpserted));
        var scAssRec = component.get("v.SCAssociationRec");
        if(isInvalid){
            helper.callModal(component, 'confirmationModalUnsavedChanges');
        } else if (!isReadOnly) {
            helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                            function(response){
                                                helper.callServerAndHandleError(component,"c.setAuthorizationFlag", 
                                                                                function(resp){
                                                                                    debugger;
                                                                                    if(resp){
                                                                                        helper.goToAuth(authRecUpserted.Id);
                                                                                    }
                                                                                },
                                                                                {'authId': authRecUpserted.Id,'isCreate':component.get("v.isCreate"),'isCreateCorrp':component.get("v.isCreateCorrp")}, false, null);
                                                // finializing the schedule recurrence records
                                                helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                                                                function(response){
                                                                                    var oldSlotId = component.get("v.authRecClone").IDN_SLOT_CONTRACT__c;
                                                                                    helper.callServerAndHandleError(component,"c.createSCAssociationRecord", 
                                                                                                                    function(response){
                                                                                                                        
                                                                                                                    }, {'authId': authRecUpserted.Id,'scAssRec':authRecUpserted.IDN_SLOT_CONTRACT__c,'scAssRecOldValue':oldSlotId}, false, null);
                                                                                }, {'lstSObject':component.get("v.scheduleRecurr"),'isFinalStep':true}, false, null);
                                                // end
                                            }, {'lstSObject':[component.get("v.authRec")],'isFinalStep':true}, false, null);                                            
        } else {
            helper.goToAuth(authRecUpserted.Id);
        }
    },
    
    doCancel : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var sObjectName = component.get('v.sObjectName');//=='T_AUTH__c'
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==1){
            if(sObjectName == 'T_SBSD_CASE__c'){
                var authRecToBeUpserted = component.get("v.authRec");
                if(authRecToBeUpserted != undefined && authRecToBeUpserted.Id != undefined){
                    helper.callServerAndDeleteRecords(component,function(response){
                        helper.redirectToRecord(component.get("v.recordId"));
                    },[authRecToBeUpserted]);   
                }
                helper.goToAuth(recordId);
            }else{
                var authRecClone = component.get("v.authRecClone");
                var authRec = component.get("v.authRec");
                var scAsscRecId = authRec.IDN_SLOT_CONTRACT__c;
                var authSlotBginDate = authRec.DTE_BEGIN_SLOT__c;
                var oldSlotId = authRecClone.IDN_SLOT_CONTRACT__c;
                var oldSlotDate = authRecClone.DTE_BEGIN_SLOT__c;
                if(oldSlotId != scAsscRecId || oldSlotDate != authSlotBginDate){
                    helper.callModal(component, 'confirmationModalOnCancel'); 
                } else {
                    helper.goToAuth(recordId); 
                }
            }
        }else{
            helper.goToAuth(recordId);   
        }
    }, 
    confirmCancel : function(component, event, helper) {
        var cmp = component.find('confirmationModalOnCancel');
        cmp.hideConfirmModal();
        
        var recordId = component.get("v.recordId");
        helper.callServerAndHandleError(component,"c.upsertRecordsFinal", 
                                        function(response){
                                            helper.goToAuth(recordId); 
                                        },{'lstSObject':[component.get("v.authRecClone")],'isFinalStep':true}, false, null);            
    },
    confirmCancelNo : function(component, event, helper) {
        var cmp = component.find('confirmationModalOnCancel');
        cmp.hideConfirmModal();
    },
    doShowHideCancel : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber == 1){
            component.set("v.showCancelButton", true);
        }else if(currentTabNumber == 2){
            component.set("v.showCancelButton", false);
        }
        
    },    
    doPrevious : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var sObjectName = component.get('v.sObjectName');//=='T_AUTH__c'
        var currentTabNumber = component.get("v.currentTabNumber");
        var authRecToBeUpserted = component.get("v.authRec");
        var isCountyRateSCQ = component.get("v.isCountyRateSCQ");
        
        if(authRecToBeUpserted != undefined && authRecToBeUpserted.Id != undefined){
            var action = component.get('c.getScheduleRecurrences');
            action.setParams({
                'recordId' : authRecToBeUpserted.Id
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state == 'SUCCESS') {
                    var res =response.getReturnValue();
                    if(res.isSuccessful){
                        if(res.objectData.recurrenceList){
                            component.set("v.scheduleRecurr",res.objectData.recurrenceList);
                        }
                    }
                } 
            });        
            $A.enqueueAction(action);
        }
        if(sObjectName == 'T_SBSD_CASE__c' && currentTabNumber==2){
            if(authRecToBeUpserted != undefined && authRecToBeUpserted.Id != undefined){
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
                component.set("v.originalBeginDate", authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c);
                component.set("v.originalClientId", authRecToBeUpserted.IDN_CLIENT__c);
                component.set("v.originalProviderId" , authRecToBeUpserted.IDN_PROVR__c);
                component.set("v.originalSCId" , authRecToBeUpserted.IDN_SLOT_CONTRACT__c);
                component.set("v.authRecToBeUpserted.DTE_BEGIN_SLOT__c" , authRecToBeUpserted.DTE_BEGIN_SLOT__c);
            }
        }else if(sObjectName == 'T_AUTH__c' && currentTabNumber==2){
            component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
            component.set("v.authRecToBeUpserted.IDN_SLOT_CONTRACT__c" , authRecToBeUpserted.IDN_SLOT_CONTRACT__c);
            component.set("v.authRecToBeUpserted.DTE_BEGIN_SLOT__c" , authRecToBeUpserted.DTE_BEGIN_SLOT__c);
        }
    },
    
    doNext : function(component, event, helper) {  
        component.set("v.showSpinner",true);
        var currentTabNumber = component.get("v.currentTabNumber");
        var date, lastDay;
        var authRecToBeUpserted = component.get("v.authRec");
        console.log('authrec 1', JSON.stringify(authRecToBeUpserted));
        var isValid = true;
        if(currentTabNumber==1){
            var isReadOnly = component.get("v.isReadOnly");        
            // handling client side validations
            var childCmp = component.find("authorizationInfoPg1");
            childCmp.callValidateCurrentPage();
            var relativeStatus = authRecToBeUpserted.CDE_REL_PROVR__c;
            var provRelation = authRecToBeUpserted.CDE_PRO_REL_CHLD__c;
            var sameResidence = authRecToBeUpserted.CDE_PROV_DIFF_RESI__c;
            if((relativeStatus == '2' || relativeStatus == '4') && (provRelation == 'B' || provRelation =='S') && sameResidence == 'N'){
                var recordError2 =[];
                var message ='This provider does not meet the Qualified Exempt Provider qualification requirements at this time.';
                recordError2.push(message);
                component.set("v.message",'error');
                component.set("v.recordError",recordError2);
                isValid = false;
            }
            if(component.get("v.isCurrentPageValid")==true && isValid == true){ 
                var childCmp = component.find("authorizationInfoPg1")
                childCmp.childDisabilityMethod();
                var caseRec = component.get("v.caseRec");
                component.set("v.provIdValtwo", authRecToBeUpserted.IDN_PROVR__c);
                var sObjectName = component.get('v.sObjectName');//=='T_AUTH__c'
                if(sObjectName == 'T_SBSD_CASE__c'){
                    component.set("v.showSpinner", true);
                    authRecToBeUpserted.CDE_COUNTY__c = caseRec.CDE_COUNTY__c;
                    authRecToBeUpserted.IDN_CASE__c = caseRec.Id; 
                    if(caseRec.DTE_REDET_CASE__c){
                        date = new Date(caseRec.DTE_REDET_CASE__c);
                        lastDay = new Date(date.getFullYear(), date.getMonth() + 1, 0);    
                    } else {
                        var authBeginDate = new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c); 
                        lastDay = new Date( authBeginDate.getFullYear() + 1, authBeginDate.getMonth() +1, 0);
                    }
                    authRecToBeUpserted.DTE_END_EFFV_AUTH__c = lastDay; 
                    console.log('authRecToBeUpserted-->'+authRecToBeUpserted.DTE_END_EFFV_AUTH__c);
                    var caseId = component.get('v.recordId');
                    var clientId = authRecToBeUpserted.IDN_CLIENT__c;
                    var action = component.get('c.isCaseEligible');
                    component.set("v.showSpinner",true);
                    action.setParams({
                        'caseRecId' : caseId,
                        'individualRecId':clientId,
                        'newAuthorizations':authRecToBeUpserted
                    });
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (component.isValid() && state == 'SUCCESS') {
                            // component.set("v.showSpinner", false);
                            var res =response.getReturnValue();
                            var isInvalidProvider = component.get("v.isInvalidProvider");
                            if(res.isSuccessful){
                                if(!isInvalidProvider){
                                    if(res.objectData){
                                        if(res.objectData.Enddate){
                                            component.set("v.eligibleChildEndDate",res.objectData.Enddate);
                                        }
                                    }
                                    var isCountyValid =component.get("v.showWarningForCounty");
                                    if(!isCountyValid){
                                        component.set("v.showSpinner", false);
                                        //helper.callModal(component,'confirmationModalOnCountyCheck_1');
                                        var countyError = [];
                                        countyError.push(component.get("v.countyMessage"));
                                        component.set("v.message",'error');
                                        component.set("v.recordError",countyError);
                                    }else{
                                        var action3 = component.get('c.careLevelOfferedByProvider');
                                        var authRecToBeUpserted1 = component.get("v.authRec");
                                        var currentBeginDate = authRecToBeUpserted1.DTE_BEGIN_EFFV_AUTH__c;
                                        var currentProviderId = authRecToBeUpserted1.IDN_PROVR__c;
                                        var currentClientId = authRecToBeUpserted1.IDN_CLIENT__c;
                                        var	authId = component.get("v.caseRec").Id;
                                        action3.setParams({
                                            'authId':authId,
                                            'recordId':component.get("v.recordId"),
                                            'currentBeginDate':currentBeginDate,
                                            'currentProviderId':currentProviderId,
                                            'currentClientId':currentClientId
                                        });
                                        action3.setCallback(this, function(response) {
                                            var state = response.getState();
                                            if (component.isValid() && state == 'SUCCESS') {
                                                var res =response.getReturnValue();
                                                if(res.isSuccessful){
                                                    if((res.objectData.showWarningCareLevel)) {
                                                        component.set("v.showWarningChildCareLevel",true);
                                                        component.set("v.careLevelMessage",res.objectData.warningMessageCareLevel);
                                                        var isCareLevel =component.get("v.showWarningChildCareLevel");
                                                        helper.callModal(component,'confirmationModalOnCareLevel');
                                                    } else {
                                                        component.set("v.showWarningChildCareLevel",false);
                                                        component.set("v.careLevelMessage",res.objectData.warningMessageCareLevel);
                                                        helper.validateIfBelowSchoolAge(component, event, helper); // Added by Rishav for CCCAP-6983
                                                        //helper.checkValidations(component, event, helper); // Commented by Rishav for CCCAP-6983
                                                    }
                                                }
                                            } else {
                                                console.log('error in careLevelOfferedByProvider');
                                            }
                                        });        
                                        $A.enqueueAction(action3);
                                        //helper.checkValidations(component, event, helper);
                                    }
                                } else {
                                    component.set("v.showSpinner", false);
                                    var recordError3 =[];
                                    var message1 = 'Invalid provider, please check related fiscal agreement records for this provider or select different provider.';
                                    recordError3.push(message1);
                                    component.set("v.message",'error');
                                    component.set("v.recordError",recordError3);
                                }
                            }else{
                                component.set("v.showSpinner", false); 
                                var recordError2 =[];
                                var message = res.errorMessage;
                                recordError2.push(message);
                                component.set("v.message",'error');
                                component.set("v.recordError",recordError2);
                            }
                        } else {
                            component.set("v.showSpinner", false);
                        }
                        //  component.set("v.showSpinner", false);            
                    });        
                    $A.enqueueAction(action);
                } else {
                    var isCountyValid =component.get("v.showWarningForCounty") || component.get('v.isReadOnly');
                    if(!isCountyValid){
                        component.set("v.showSpinner", false);
                        var countyError = [];
                        countyError.push(component.get("v.countyMessage"));
                        component.set("v.message",'error');
                        component.set("v.recordError",countyError);
                    } else {
                        var isValid = helper.callModalOnChngSCRec(component, event, helper);
                        if(isValid){
                            component.set("v.showSpinner", true);
                            // Filter out fields with blank values before sending to server
                            var authNewFiltered = {};
                            for (var key in authRecToBeUpserted) {
                                if (authRecToBeUpserted.hasOwnProperty(key) && authRecToBeUpserted[key] !== '') {
                                    authNewFiltered[key] = authRecToBeUpserted[key];
                                }
                            }
                            var action1 = component.get('c.getAuthorizationNotesStatusValidation');
                            action1.setParams({
                                'authId' : authRecToBeUpserted.Id,'authNew':authNewFiltered
                            });
                            action1.setCallback(this, function(response) {
                                var state = response.getState();
                                if(component.isValid() && state == 'SUCCESS') {
                                    // component.set("v.showSpinner", false);
                                    // component.set("v.showSpinner", false);
                                    var res =response.getReturnValue();
                                    if(res.isSuccessful){
                                        if((res.objectData.AuthTerminated)){
                                            component.set("v.authTerminated",true);
                                        }
                                        helper.validateIfBelowSchoolAge(component, event, helper); // Added by Rishav for CCCAP-6983
                                        //helper.checkValidations(component, event, helper); // Commented by Rishav for CCCAP-6983
                                    } else {
                                        component.set("v.showSpinner", false);
                                        var recordError2 =[];
                                        var message = '';
                                        if((res.objectData.UpdateAuthorization)){
                                            message ='A terminated authorization cannot be updated'; 
                                        }
                                        if((res.objectData.AMT_ACTV_AUTH__c)){
                                            message ='Registration can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date'; 
                                        } else if(res.objectData.AMT_TRANSP_AUTH__c) {
                                            message ='Transportation can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                                        } else if(res.objectData.AMT_RGSTR_AUTH__c) {
                                            message ='Activity can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                                        } else if(res.objectData.CDE_REL_PROVR__c) {
                                            message ='Provider Location / Relation to Child can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                                        }
                                        if(message !=''){
                                            recordError2.push(message);
                                        }
                                        component.set("v.message",'error');
                                        component.set("v.recordError",recordError2);
                                    }
                                } else {
                                    component.set("v.showSpinner", false);    
                                }
                                // component.set("v.showSpinner", false);            
                            });        
                            $A.enqueueAction(action1); 
                            // helper.checkValidations(component, event, helper);
                        }
                    }
                }
            } else {
                component.set("v.showSpinner", false); 
            }
            console.log('authrec2', JSON.stringify(authRecToBeUpserted));
        }
    },
    
    actionOnYesUnsavedChanges: function(component, event, helper){
        var authRecUpserted = component.get("v.authRec");
        helper.callServerAndHandleError(component,"c.finishAuthorization", 
                                        function(resp){
                                            if(resp){
                                                helper.goToAuth(authRecUpserted.Id);
                                            }
                                        },
                                        {'authId': authRecUpserted.Id}, false, null);
    },
    
    doValidateRecurrence : function(component, event, helper) {  
        component.set("v.showSpinner",true);
        var currentTabNumber = component.get("v.currentTabNumber");
        var date, lastDay;
        if(currentTabNumber==1){
            // handling client side validations
            var childCmp = component.find("authorizationInfoPg1");
            childCmp.callValidateCurrentPage();
            if(component.get("v.isCurrentPageValid")==true){ 
                var childCmp = component.find("authorizationInfoPg1")
                childCmp.childDisabilityMethod();
                var caseRec = component.get("v.caseRec");
                var authRecToBeUpserted = component.get("v.authRec");
                var sObjectName = component.get('v.sObjectName');//=='T_AUTH__c'
                if(sObjectName == 'T_SBSD_CASE__c'){
                    component.set("v.showSpinner", true);
                    authRecToBeUpserted.CDE_COUNTY__c = caseRec.CDE_COUNTY__c;
                    authRecToBeUpserted.IDN_CASE__c = caseRec.Id; 
                    if(caseRec.DTE_REDET_CASE__c){
                        date = new Date(caseRec.DTE_REDET_CASE__c);
                        lastDay = new Date(date.getFullYear(), date.getMonth() + 1, 0);    
                    } else {
                        var authBeginDate = new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c); 
                        lastDay = new Date( authBeginDate.getFullYear() + 1, authBeginDate.getMonth() +1, 0);
                    }
                    authRecToBeUpserted.DTE_END_EFFV_AUTH__c = lastDay; 
                    var caseId = component.get('v.recordId');
                    var clientId = authRecToBeUpserted.IDN_CLIENT__c;
                    var action = component.get('c.isCaseEligible');
                    component.set("v.showSpinner",true);
                    action.setParams({
                        'caseRecId' : caseId,
                        'individualRecId':clientId,
                        'newAuthorizations':authRecToBeUpserted
                    });
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (component.isValid() && state == 'SUCCESS') {
                            // component.set("v.showSpinner", false);
                            var res =response.getReturnValue();
                            var isInvalidProvider = component.get("v.isInvalidProvider");
                            if(res.isSuccessful){
                                if(!isInvalidProvider){
                                    if(res.objectData){
                                        if(res.objectData.Enddate){
                                            component.set("v.eligibleChildEndDate",res.objectData.Enddate);
                                        }
                                    }
                                    var isCountyValid =component.get("v.showWarningForCounty");
                                    var action3 = component.get('c.careLevelOfferedByProvider');
                                    var authRecToBeUpserted1 = component.get("v.authRec");
                                    var currentBeginDate = authRecToBeUpserted1.DTE_BEGIN_EFFV_AUTH__c;
                                    var currentProviderId = authRecToBeUpserted1.IDN_PROVR__c;
                                    var currentClientId = authRecToBeUpserted1.IDN_CLIENT__c;
                                    var	authId = component.get("v.caseRec").Id;
                                    action3.setParams({
                                        'authId':authId,
                                        'recordId':component.get("v.recordId"),
                                        'currentBeginDate':currentBeginDate,
                                        'currentProviderId':currentProviderId,
                                        'currentClientId':currentClientId
                                    });
                                    action3.setCallback(this, function(response) {
                                        var state = response.getState();
                                        if(component.isValid() && state == 'SUCCESS') {
                                            var res =response.getReturnValue();
                                            if(res.isSuccessful){                                          
                                                component.set("v.showWarningChildCareLevel",false);
                                                component.set("v.careLevelMessage",res.objectData.warningMessageCareLevel);
                                                helper.doValidateRecurrenceHlp(component, event, helper);
                                            }
                                        } else {
                                            console.log('error in careLevelOfferedByProvider');
                                        }
                                    });        
                                    $A.enqueueAction(action3);
                                } else {
                                    component.set("v.showSpinner", false);
                                    var recordError3 =[];
                                    var message1 = 'Invalid provider, please check related fiscal agreement records for this provider or select different provider.';
                                    recordError3.push(message1);
                                    component.set("v.message",'error');
                                    component.set("v.recordError",recordError3);
                                }
                            } else {
                                component.set("v.showSpinner", false); 
                                var recordError2 =[];
                                var message = res.errorMessage;
                                recordError2.push(message);
                                component.set("v.message",'error');
                                component.set("v.recordError",recordError2);
                            }
                        } else {
                            component.set("v.showSpinner", false);
                        }
                    });        
                    $A.enqueueAction(action);
                } else {
                    component.set("v.showSpinner", true);
                    // Filter out fields with blank values before sending to server
                    var authNewFiltered = {};
                    for (var key in authRecToBeUpserted) {
                        if (authRecToBeUpserted.hasOwnProperty(key) && authRecToBeUpserted[key] !== '') {
                            authNewFiltered[key] = authRecToBeUpserted[key];
                        }
                    }
                    var action1 = component.get('c.getAuthorizationNotesStatusValidation');
                    action1.setParams({
                        'authId' : authRecToBeUpserted.Id,'authNew':authNewFiltered
                    });
                    action1.setCallback(this, function(response) {
                        var state = response.getState();
                        if (component.isValid() && state == 'SUCCESS') {
                            // component.set("v.showSpinner", false);
                            // component.set("v.showSpinner", false);
                            var res =response.getReturnValue();
                            if(res.isSuccessful){
                                if((res.objectData.AuthTerminated)){
                                    component.set("v.authTerminated",true);
                                }
                                helper.doValidateRecurrenceHlp(component, event, helper);
                            } else {
                                component.set("v.showSpinner", false);
                                var recordError2 =[];
                                var message = '';
                                if((res.objectData.UpdateAuthorization)){
                                    message ='A terminated authorization cannot be updated'; 
                                }
                                if((res.objectData.AMT_ACTV_AUTH__c)){
                                    message ='Registration can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date'; 
                                } else if(res.objectData.AMT_TRANSP_AUTH__c) {
                                    message ='Transportation can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                                } else if(res.objectData.AMT_RGSTR_AUTH__c) {
                                    message ='Activity can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                                } else if(res.objectData.CDE_REL_PROVR__c) {
                                    message ='Provider Location / Relation to Child can not be updated,Cannot update if there is an Authorization Status of Terminated with an Effective Begin Date that is equal to or less than the current date';
                                }
                                if(message !=''){
                                    recordError2.push(message);
                                }
                                component.set("v.message",'error');
                                component.set("v.recordError",recordError2);
                            }
                        } else {
                            component.set("v.showSpinner", false);
                        }
                        // component.set("v.showSpinner", false);
                    });
                    $A.enqueueAction(action1); 
                    // helper.checkValidations(component, event, helper);
                }
            } else {
                component.set("v.showSpinner", false); 
            }
        }
    },
})