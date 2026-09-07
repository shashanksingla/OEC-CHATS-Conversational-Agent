({
    doInit : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.recordId")) && !component.get("v.isRejectedReferralFlow")){
	        component.set("v.caseRec.CDE_COUNTY__c",component.get("v.recordId").substring(0,15));
        }else{
            helper.callServerAndHandleError(component,"c.getUsersOwnerCounty", 
                                            function(response){
                                                if(!$A.util.isEmpty(response.objectData.userCounty)){
											        component.set("v.caseRec.CDE_COUNTY__c",response.objectData.userCounty);
                                                }else{
                                                    component.set("v.caseRec.CDE_COUNTY__c",null);
                                                }
                                            }, {}, false, null);
        }
    },
    doChangeCurrentTab : function(component, event, helper) {
        component.set("v.pageMessages",[]);
        component.set("v.messageType",null);
    },
    doPrevious : function(component, event, helper) {
        component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
    },
    doFinish : function(component, event, helper) {
        if(helper.validateAddressClearance(component)){
            helper.redirectToRecord(component.get("v.caseRec").Id);
        }
        else{
            component.set("v.pageMessages", "Please select an option for address clearance for each address");
            component.set("v.messageType", "error");
        }
    },
    doNext : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        
        if(currentTabNumber==1){
            
            // handling client side validations
            var childCmp = component.find("createNewCasePage1");
            childCmp.callValidateCurrentPage();
          
            // check with Ram whether to hit server even after there are client side errors.
           
            // server side call
            if(component.get("v.isCurrentPageValid")==true){                
                helper.callServerAndHandleError(component,"c.checkCountyWithUserCounty", 
                                                function(response){
                                                    if(response.objectData.countyMatched==true){
                                                        if(component.get("v.isRejectedReferralFlow") && !$A.util.isEmpty(component.get("v.applnProcessQueueRec"))){
                                                            component.set("v.caseRec.IDN_CBMS_REF__c",component.get("v.applnProcessQueueRec").IDN_APPLN__r.IDN_CBMS_REF__c);
                                                        }
                                                        helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                                                        function(response){
                                                                                            var caseRec = helper.merge(component.get("v.caseRec"),response.objectData.upsertedRecords[0]);
                                                                                            helper.callServerAndHandleError(component,"c.getCaseName", function(response){
                                                                                                if(!$A.util.isEmpty(response.objectData.caseName)){
                                                                                                    caseRec.Name = response.objectData.caseName;
                                                                                                }                                                                                                
                                                                                                component.set("v.caseRec", caseRec);
                                                                                                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);                                                                                                
                                                                                            }, {'caseId':caseRec.Id}, false, null);
                                                                                        }, {'lstSObject':[component.get("v.caseRec")]}, false, null);
                                                    }else{
                                                        //component.find("countyDifferentThanUserCounty").openModal();
                                                        component.set("v.pageMessages",['The case that you are trying to create is with '+response.objectData.countyName+' county. This does not match your assigned county(ies).']);
                                                        component.set("v.messageType",'error');
                                                    }
                                                }, {'countyId':component.get("v.caseRec.CDE_COUNTY__c")}, false, null);
                
            }
        }else if(currentTabNumber==2){
            var childCmp = component.find("createNewCasePage2");
            childCmp.callValidateCurrentPage();
           
            if(component.get("v.isCurrentPageValid")==true){
                helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                function(response){
                                                    component.set("v.caseRec", helper.merge(component.get("v.caseRec"),response.objectData.upsertedRecords[0]));
                                                   
                                                    component.set("v.caseHomelessRec.IDN_CASE__c",component.get("v.caseRec").Id);
                                                    component.set("v.caseResidenceAddressRec.IDN_CASE__c",component.get("v.caseRec").Id);
                                                    component.set("v.caseMailingAddressRec.IDN_CASE__c",component.get("v.caseRec").Id);
                                                    component.set("v.caseHomePhoneRec.IDN_CASE__c",component.get("v.caseRec").Id);
                                                    component.set("v.caseWorkPhoneRec.IDN_CASE__c",component.get("v.caseRec").Id);
                                                    component.set("v.caseMobilePhoneRec.IDN_CASE__c",component.get("v.caseRec").Id);
                                                    //component.set("v.caseEMInfoRec.IDN_CASE__c",component.get("v.caseRec").Id);
                                                    component.set("v.casePMCInfoRec.IDN_CASE__c",component.get("v.caseRec").Id);
                                                    var today = helper.getCurrentSystemDate();
                                                    //component.set("v.caseEMInfoRec.DTE_BEGIN_EFFV__c",today);
                                                    component.set("v.casePMCInfoRec.DTE_BEGIN_EFFV__c",today);
                                                    component.set("v.caseResidenceAddressRec.DTE_BEGIN_EFFV__c",today);
                                                    component.set("v.caseMailingAddressRec.DTE_BEGIN_EFFV__c",today);
                                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                }, {'lstSObject':[component.get("v.caseRec")]}, false, null);
                
            }
        }else if(currentTabNumber==3){
            // handling client side validations
            var childCmp = component.find("createNewCasePage3");
            var resultFromThisPage = childCmp.callValidateCurrentPage();
            
            
            if(resultFromThisPage==true){
                
                var caseResidenceAddressRec = component.get("v.caseResidenceAddressRec");
                var caseMailingAddressRec = component.get("v.caseMailingAddressRec");
                caseResidenceAddressRec.DTE_BEGIN_EFFV__c  =component.get("v.caseRec.DTE_APPLN__c");
                caseMailingAddressRec.DTE_BEGIN_EFFV__c  =component.get("v.caseRec.DTE_APPLN__c");
                var caseWorkPhoneRec =component.get("v.caseWorkPhoneRec");
                var caseHomePhoneRec =component.get("v.caseHomePhoneRec");
                var caseMobilePhoneRec =component.get("v.caseMobilePhoneRec");
                caseWorkPhoneRec.DTE_BEGIN_EFFV__c  =component.get("v.caseRec.DTE_APPLN__c");
                caseHomePhoneRec.DTE_BEGIN_EFFV__c  =component.get("v.caseRec.DTE_APPLN__c");
                caseMobilePhoneRec.DTE_BEGIN_EFFV__c  =component.get("v.caseRec.DTE_APPLN__c");
                //var caseEMInfoRec = component.get("v.caseEMInfoRec");
                //caseEMInfoRec.DTE_BEGIN_EFFV__c  =component.get("v.caseRec.DTE_APPLN__c");
                caseResidenceAddressRec.CDE_TYPE_VERIF__c = caseMailingAddressRec.CDE_TYPE_VERIF__c;
                caseResidenceAddressRec.CDE_SOURCE_VRFD_ADR__c = caseMailingAddressRec.CDE_SOURCE_VRFD_ADR__c;
                helper.callServerAndHandleError(component,"c.handleCaseRelatedRecords", 
                                                function(response){
                                                   
                                                    // Vai - Bug fix 2421 / 2426
                                                    var objectData = response.objectData.upsertedRecords;
                                                    var caseAddressTracker = [], addressTracker = {},
                                                        caseAddressList = [], j=0;
                                                    if(!$A.util.isEmpty(objectData)){
                                                        for(var i=0; i<objectData.length; i++){
                                                            // Checking for zip to identify address record
                                                            if(objectData[i].hasOwnProperty("ADR_ZIP_MAIN__c")
                                                              && objectData[i].hasOwnProperty("IDN_CASE__c")){
                                                                
                                                                objectData[i].sobjectType = 'T_SBSD_CASE_ADR__c';
                                                                caseAddressList[j] = objectData[i];
                                                                j=j+1;
                                                                if(objectData[i].CDE_TYPE_ADR__c=='MAL'){
                                                                    var caseMailingAddressRec = component.get("v.caseMailingAddressRec");
                                                                    caseMailingAddressRec.Id = objectData[i].Id;
                                                                    component.set("v.caseMailingAddressRec",caseMailingAddressRec);
                                                                }
                                                                if(objectData[i].CDE_TYPE_ADR__c=='HOM'){
                                                                    var caseResidenceAddressRec = component.get("v.caseResidenceAddressRec");
                                                                    caseResidenceAddressRec.Id = objectData[i].Id;
                                                                    component.set("v.caseResidenceAddressRec",caseResidenceAddressRec);
                                                                }
                                                            }
                                                            //Checking to identify Case Homeless Record
                                                            else if(objectData[i].hasOwnProperty("IND_LVG_HOTEL__c")){
                                                                var caseHomelessRec = component.get("v.caseHomelessRec");
                                                                caseHomelessRec.Id = objectData[i].Id;
                                                            }
                                                            //Logic to identify case information
                                                           /* if(!$A.util.isEmpty(objectData[i].CDE_TYPE_INFO_CASE__c) && objectData[i].CDE_TYPE_INFO_CASE__c=='EM'){
                                                                var caseEMInfoRec = component.get("v.caseEMInfoRec");
                                                                caseEMInfoRec.Id = objectData[i].Id;
                                                            }*/
                                                            if(!$A.util.isEmpty(objectData[i].CDE_TYPE_INFO_CASE__c) && objectData[i].CDE_TYPE_INFO_CASE__c=='PMC'){
                                                                var casePMCInfoRec = component.get("v.casePMCInfoRec");
                                                                casePMCInfoRec.Id = objectData[i].Id;
                                                            }
                                                            //Logic to identify case Phone
                                                            if(!$A.util.isEmpty(objectData[i].CDE_TYPE_PHONE__c) && objectData[i].CDE_TYPE_PHONE__c=='HOM'){
                                                                var caseHomePhoneRec = component.get("v.caseHomePhoneRec");
                                                                caseHomePhoneRec.Id = objectData[i].Id;
                                                            }
                                                            if(!$A.util.isEmpty(objectData[i].CDE_TYPE_PHONE__c) && objectData[i].CDE_TYPE_PHONE__c=='WOR'){
                                                                var caseWorkPhoneRec = component.get("v.caseWorkPhoneRec");
                                                                caseWorkPhoneRec.Id = objectData[i].Id;
                                                            }
                                                            if(!$A.util.isEmpty(objectData[i].CDE_TYPE_PHONE__c) && objectData[i].CDE_TYPE_PHONE__c=='MOB'){
                                                                var caseMobilePhoneRec = component.get("v.caseMobilePhoneRec");
                                                                caseMobilePhoneRec.Id = objectData[i].Id;
                                                            }
                                                            
                                                        }
                                                        if(!$A.util.isEmpty(caseAddressList)){
                                                            j=0;
                                                            for(var x=0; x<caseAddressList.length; x++){
                                                                addressTracker.caseAddress = caseAddressList[x];
                                                                addressTracker.selectedValidAddress = false;
                                                                addressTracker.unvalidatedAddress = false;
                                                                caseAddressTracker[j] = addressTracker;
                                                                addressTracker = {};
                                                                j=j+1;
                                                            }
                                                        }
                                                        component.set("v.caseAddressTracker", caseAddressTracker);
                                                    }
                                                    if(component.get("v.isCurrentPageValid")==true){
                                                        // if application id is passed, call CaseFlowApxCtrl which will stamp case on application
                                                        // clone the child records from the application onto the case
                                                        // on success, redirect either to Address clearnce component or case record detail page.	
                                                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                    }
                                                }, {'lstSObject':[component.get("v.caseHomelessRec"),
                                                                  caseResidenceAddressRec,
                                                                  caseMailingAddressRec,
                                                                  caseHomePhoneRec,
                                                                  caseWorkPhoneRec,
                                                                  caseMobilePhoneRec,
                                                                  //caseEMInfoRec,
                                                                  component.get("v.casePMCInfoRec")
                                                                 ],
                                                    'caseRecord':component.get("v.caseRec"),
                                                    'isRejectedReferralFlow':component.get("v.isRejectedReferralFlow"),
                                                    'appQueueId':component.get("v.isRejectedReferralFlow")== true? component.get("v.applnProcessQueueRec").Id : component.get("v.appQueueId")
                                                   }, false, null);
                
            }
            else{
                     component.set("v.pageMessages",["There are errors on this page. Please correct them to proceed."]); 
                component.set("v.messageType","error");
           
            }
            // check with Ram whether to hit server even after there are client side errors.
        }
    },
    doHideCountyDifferentThanUserCounty : function(component, event, helper){
        component.find("countyDifferentThanUserCounty").hideConfirmModal();
        helper.callServerAndHandleError(component,"c.upsertRecords", 
                                        function(response){
								            var caseRec = helper.merge(component.get("v.caseRec"),response.objectData.upsertedRecords[0]);
								            helper.callServerAndHandleError(component,"c.getCaseName", function(response){
								                if(!$A.util.isEmpty(response.objectData.caseName)){
								                    caseRec.Name = response.objectData.caseName;
								                }                                                                                                
								                component.set("v.caseRec", caseRec);
								                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);                                                                                                
								            }, {'caseId':caseRec.Id}, false, null);
                                        }, {'lstSObject':[component.get("v.caseRec")]}, false, null);
        
    }
})