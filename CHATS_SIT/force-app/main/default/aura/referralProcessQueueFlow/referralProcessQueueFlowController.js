({
    doInit : function(component, event, helper){
        component.set("v.closedCaseMsg","You have selected a Closed case to be associated with the Referral. Please reject the Referral and process this as a Paper Referral.");

        debugger;
        if(!component.get("v.isChangeRefFlow")){
            debugger;
            component.set("v.showNext",false);
        }else{
            component.set("v.showNext",true);
            component.set("v.showNextPeakFlow",false);
        }
        console.log('showNext---'+component.get("v.showNext"));
        if(component.get("v.isChangeRefFlow")){
            helper.callServerAndHandleError(component,"c.getInitDataChangeRef", 
                                        function(response){
                                            //component.set("v.mapIndivSequenceToRelationship",response.objectData.mapIndivSequenceToRelationship);
                                            component.set("v.mapIndivToRelationship",response.objectData.mapIndivToRelationship);
                                            component.set("v.lstApplicationIndividualsOld",response.objectData.applicationIndividualsOld);
                                            component.set("v.lstApplicationIndividuals",response.objectData.applicationIndividuals);
                                            component.set("v.appProcessQueueRec",response.objectData.appProcessQueue);
                                            component.set("v.appCaseId",response.objectData.appProcessQueue.IDN_APPLN__c);
                                            component.set("v.appCaseIdOld",response.objectData.appProcessQueueOld.IDN_APPLN__c);
                                            component.set("v.appProcessQueueRecOld",response.objectData.appProcessQueueOld);
	                                        component.set("v.hasPrimaryCaretaker",true);
                                        }, {'appProcessQueueId':component.get("v.recordId"),'appProcessQueueIdNewRef':component.get("v.oldAppProcessQueueRecId")}, false, null);
        }else{
            helper.callServerAndHandleError(component,"c.getInitData", 
                                        function(response){
                                            //component.set("v.mapIndivSequenceToRelationship",response.objectData.mapIndivSequenceToRelationship);
                                            component.set("v.mapIndivToRelationship",response.objectData.mapIndivToRelationship);
                                            component.set("v.lstApplicationIndividuals",response.objectData.applicationIndividuals);
                                            component.set("v.appProcessQueueRec",response.objectData.appProcessQueue);
                                            component.set("v.appCaseId",response.objectData.appProcessQueue.IDN_APPLN__c);
                                            if(!$A.util.isEmpty(response.objectData) ){
	                                            component.set("v.hasPrimaryCaretaker",response.objectData.hasPrimaryCaretaker);
                                            }
                                        }, {'appProcessQueueId':component.get("v.recordId")}, false, null);
        }
    },
    doNext : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        var lstError = [];
        if(currentTabNumber==1)
        {
          component.set("v.currentTabNumber",currentTabNumber+1);
             component.set("v.showNext",true);
            component.set("v.showNextPeakFlow",false);
        }
        else if(currentTabNumber==2){
            if(component.get("v.lstSelectedApplicationIndividuals").length==0){
                lstError.push("Please select at least one individual to proceed.");
                
            }else{
                component.set("v.currentTabNumber",currentTabNumber+1);
            }
        }else if(currentTabNumber==3){
            var hasIndividualWithBlankStateID = false;
            var lstSelectedApplicationIndividuals = component.get("v.lstSelectedApplicationIndividuals");
            for(var i=0;i<lstSelectedApplicationIndividuals.length;i++){
                if(lstSelectedApplicationIndividuals[i].IDN_STATE__c==null || lstSelectedApplicationIndividuals[i].IDN_STATE__c=="" || lstSelectedApplicationIndividuals[i].IDN_STATE__c==$A.get("$Label.c.SIDMOD_STATE_ID_REQUIRED")){
                    hasIndividualWithBlankStateID = true;
                }
            }
            if(hasIndividualWithBlankStateID){
                lstError.push("All individuals must be cleared before proceeding to case selection.");
            }else{
                helper.doFindCaseAndPrimaryCaretakerDetails(component);
            }
        }        
        component.set("v.pageMessages",lstError);
        component.set("v.messageType","error");
    },
       doUpdateShowCustomButton : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==3){
            
            component.set("v.customButtonLabel","Run Clearance");
            component.set("v.showCustomButton",true);
            
        }else if(currentTabNumber==4){
            component.set("v.customButtonLabel","Clear Individual");
            component.set("v.showCustomButton",true);
        }else{
            component.set("v.showCustomButton",false);
        }
        component.set("v.pageMessages",[]);
    },
    doPrevious : function(component, event, helper) {
        
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==5){
            currentTabNumber = 3;
        }else{
            currentTabNumber = currentTabNumber-1;
        }
        if(currentTabNumber==1){
             component.set("v.showNext",false);
            component.set("v.showNextPeakFlow",true);
        }
        component.set("v.currentTabNumber",currentTabNumber);
    },
    doFinish : function(component, event, helper) {
        var caseStatus = component.get("v.caseStatus");
        
        if(component.get("v.anyCaseSelected")){
            if(caseStatus =='Closed'){
                debugger;
                $A.util.toggleClass(component.find("backdropclosedCaseSelection"),"slds-backdrop");
                $A.util.toggleClass(component.find("backdropclosedCaseSelection"),"slds-backdrop_open");
                $A.util.toggleClass(component.find("closedCaseSelection"),"slds-fade-in-open");
            }else{
                if(component.get("v.isChangeRefFlow")){
                    helper.doHandleChangeRef(component); 
                }else{
                    helper.doHandleExistingCaseSelection(component);
                }
            }
        }else{
            component.set("v.pageMessages",["Please select at least one option to proceed."]);
        }
        
        
    },
    doUpdateComponentAttribute : function(component, event, helper) {    
        component.set("v."+event.getParam("attributeName"),event.getParam("attributeValue"));
        if(event.getParam("attributeName")=='stateID'){
            component.set("v.anyIndividualSelected",true);
            var individualFromSIDMOD = component.get("v.individualFromSIDMOD");
            var applicationIndividualForClearance = component.get("v.applicationIndividualForClearance");
            if(event.getParam("dataFromSidmod") == true){
                component.set('v.sidmodSelection',true); // added for CCCAP-10315 for SIDMOD Notify Feature
                individualFromSIDMOD.NAM_FIRST__c = event.getParam("firstNameSIDMOD");
            	individualFromSIDMOD.NAM_LAST__c = event.getParam("lastNameSIDMOD");
                individualFromSIDMOD.NAM_MI__c = !$A.util.isEmpty(event.getParam("middleInitialSIDMOD"))?event.getParam("middleInitialSIDMOD").substring(0,1):event.getParam("middleInitialSIDMOD");
                individualFromSIDMOD.DTE_DOB__c = event.getParam("dobSIDMOD");
                individualFromSIDMOD.DTE_Death__c = event.getParam("dateOfDeathSIDMOD"); // added for CCCAP-7695 by Shashank
                individualFromSIDMOD.CDE_GENDER__c = event.getParam("genderSIDMOD");
                individualFromSIDMOD.NBR_SSN__c = event.getParam("ssnSIDMOD");
            } else {
                component.set('v.sidmodSelection',false); // added for CCCAP-10315 for SIDMOD Notify Feature
                individualFromSIDMOD.NAM_FIRST__c = applicationIndividualForClearance.NAM_FIRST__c;
            	individualFromSIDMOD.NAM_LAST__c = applicationIndividualForClearance.NAM_LAST__c;
                individualFromSIDMOD.NAM_MI__c = applicationIndividualForClearance.NAM_MI__c;
                individualFromSIDMOD.DTE_DOB__c = applicationIndividualForClearance.DTE_DOB__c;
                individualFromSIDMOD.CDE_GENDER__c = applicationIndividualForClearance.CDE_GENDER__c;
                individualFromSIDMOD.NBR_SSN__c = applicationIndividualForClearance.NBR_SSN__c;
            }
            console.log(JSON.stringify(individualFromSIDMOD));
            component.set("v.individualFromSIDMOD",individualFromSIDMOD);
        }
        else
        if(event.getParam("attributeName")=='selectedCaseID'){
            var caseStatus = event.getParam("caseStatus");
            component.set("v.anyCaseSelected",true);
             component.set("v.caseStatus",caseStatus);
        }   
    },
    doClickCustomButton : function(component, event, helper) {
        if(component.get("v.currentTabNumber")==3){
            console.log(component.get("v.applicationIndividualForClearance"));
            if(component.get("v.applicationIndividualForClearance")==null || component.get("v.applicationIndividualForClearance").Id==null){
                component.set("v.pageMessages",["Please select at least one individual to proceed."]);
                component.set("v.messageType","error");
            }else{
                component.set("v.pageMessages",[]);
                helper.doGetMatchedIndividuals(component, event);
            }
        }else if(component.get("v.currentTabNumber")==4){
            if(component.get("v.anyIndividualSelected")){
                component.set("v.pageMessages",[]);
                var stateID = component.get("v.stateID");
                if(stateID == 'SID Req'){
                    var sidmodMatchedIndividuals = component.get("v.lstSIDMODMatchedIndividuals");
                    if(sidmodMatchedIndividuals != undefined){
                        var tempScore = '0';
                        for(var i= 0 ; i<sidmodMatchedIndividuals.length; i++){
                            if(tempScore < sidmodMatchedIndividuals[i].score) {
                                tempScore = sidmodMatchedIndividuals[i].score;
                            }
                        }
                        if(tempScore >= 96){
                            component.set("v.pageMessages",[" Override failed: SSN already exists. State ID set for " +sidmodMatchedIndividuals[0].lastName + " , " + sidmodMatchedIndividuals[0].firstName]);
                            component.set("v.messageType","error");
                        }else if (tempScore >=60 && tempScore < 96) {
                            var applicationIndividualForClearance = component.get("v.applicationIndividualForClearance");
                            console.log("stateID="+stateID);
                            applicationIndividualForClearance.IDN_STATE__c = stateID;
                            helper.doOverrideClearance(component, event, applicationIndividualForClearance);
                            component.set("v.pageMessages",["Request will be processed in 24 hours."]);
                            component.set("v.messageType","success");
                        }else if (tempScore < 60) {
                            helper.assignStateId(component, event, helper);    
                        }
                    } else {
                        helper.assignStateId(component, event, helper);
                    }
                }else{
                    var stateID = component.get("v.stateID");
                    var applicationIndividualForClearance = component.get("v.applicationIndividualForClearance");
                    var individualFromSIDMOD = component.get("v.individualFromSIDMOD");
                    if(!$A.util.isEmpty(individualFromSIDMOD.NAM_FIRST__c)){
                        applicationIndividualForClearance.NAM_FIRST__c = individualFromSIDMOD.NAM_FIRST__c;
                    }
                    if(!$A.util.isEmpty(individualFromSIDMOD.NAM_LAST__c)){
                        applicationIndividualForClearance.NAM_LAST__c = individualFromSIDMOD.NAM_LAST__c;
                    }
                    if(!$A.util.isEmpty(individualFromSIDMOD.NAM_MI__c)){
                        applicationIndividualForClearance.NAM_MI__c = individualFromSIDMOD.NAM_MI__c;
                    } else{
                    	applicationIndividualForClearance.NAM_MI__c = individualFromSIDMOD.NAM_MI__c;
                    }
                    if(!$A.util.isEmpty(individualFromSIDMOD.DTE_DOB__c)){
                        applicationIndividualForClearance.DTE_DOB__c = individualFromSIDMOD.DTE_DOB__c;
                    }
                    if(!$A.util.isEmpty(individualFromSIDMOD.CDE_GENDER__c)){
                        applicationIndividualForClearance.CDE_GENDER__c = individualFromSIDMOD.CDE_GENDER__c;
                    }
                    if(!$A.util.isEmpty(individualFromSIDMOD.NBR_SSN__c)){
                        applicationIndividualForClearance.NBR_SSN__c = individualFromSIDMOD.NBR_SSN__c;
                    } else{
                    	applicationIndividualForClearance.NBR_SSN__c = individualFromSIDMOD.NBR_SSN__c;
                    }
                    // added for CCCAP-7695 by Shashank
                    if(individualFromSIDMOD.DTE_Death__c){
                        applicationIndividualForClearance.DTE_Death__c = individualFromSIDMOD.DTE_Death__c;
                    }
                    console.log("stateID="+stateID);
                    applicationIndividualForClearance.IDN_STATE__c = stateID;
                    helper.doUpdateRecords(component, event, applicationIndividualForClearance,false);
                }
                component.set("v.anyIndividualSelected",false);
            }else{
                component.set("v.pageMessages",["Please select at least one option to proceed."]);
                component.set("v.messageType","error");
            }
        }
    },
     hideConfirmModal: function(component, evt, helper){
        $A.util.removeClass(component.find("backdropNewCase"),"slds-backdrop");
        $A.util.removeClass(component.find("backdropNewCase"),"slds-backdrop_open");
        $A.util.removeClass(component.find("NewCaseSection"),"slds-fade-in-open");
        helper.showToast('success', 'Referral has been processed successfully.');
        helper.redirectToRecord(component.get("v.caseIdToRedirect"));
    },
    hideConfirmModalClosedCase: function(component, evt, helper){
        $A.util.removeClass(component.find("backdropclosedCaseSelection"),"slds-backdrop");
        $A.util.removeClass(component.find("backdropclosedCaseSelection"),"slds-backdrop_open");
        $A.util.removeClass(component.find("closedCaseSelection"),"slds-fade-in-open");
        if(component.get("v.isChangeRefFlow")){
            helper.redirectToRecord(component.get("v.recordId"));
            
        }else{
            helper.redirectToRecord(component.get("v.recordId"));
        }
    },
})