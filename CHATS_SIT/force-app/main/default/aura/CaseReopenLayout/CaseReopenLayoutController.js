({
    handlProgramUpdate :function(component, event, helper) {
        helper.checkForCaseReopenOngoing(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    
    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    },
    //added for CCCAP-11857 by Shashank S.
    handleReasonUpdate:function(component,event,helper){
        var newCaseStatusMode = component.get("v.newCaseStatusMode");
        component.set('v.applicationDateState',""); //CCCAP-13251
        if(newCaseStatusMode.CDE_REASON_CHANGE_MODE_STATUS__c == 'WEP'){
            component.set('v.dateRedeterminationPacketReturnedState',"DISABLED");
            component.set('v.dateRedeterminationPacketSentState',"DISABLED");
            component.set('v.applicationDateState',"DISABLED"); //CCCAP-13251
            component.set('v.caseApplnDateInfo.DTE_APPLN_NEW__c',"");//CCCAP-13251
            component.set('v.caseRec.DTE_RCVD_PACKET_REDET__c',''); 
            if(newCaseStatusMode.CDE_ELIGTY_CONTNUS__c !='Y'){
               component.set('v.newCaseStatusMode.CDE_ELIGTY_CONTNUS__c','Y'); 
            }
        }
    },
    checkApplicationDateState : function(component, event, helper) {
        var newCaseStatusMode = component.get("v.newCaseStatusMode");
        var currentCaseStatusMode = component.get("v.currentCaseStatusMode");
        var dateRedeterminationPacketReturnedState = "OPTIONAL", applicationDateState = "OPTIONAL";
        if(newCaseStatusMode.CDE_ELIGTY_CONTNUS__c=='N'){
            if(currentCaseStatusMode.CDE_STATUS_CASE__c=='CLS' && (currentCaseStatusMode.CDE_MODE_CASE__c=='INT' || currentCaseStatusMode.CDE_MODE_CASE__c=='RED' || currentCaseStatusMode.CDE_MODE_CASE__c=='ONG')){
                applicationDateState = "REQUIRED";
                dateRedeterminationPacketReturnedState = "DISABLED";
            }
            //added for CCCAP-11857 by Shashank S.
            if(newCaseStatusMode.CDE_REASON_CHANGE_MODE_STATUS__c == 'WEP'){
                component.set('v.newCaseStatusMode.CDE_REASON_CHANGE_MODE_STATUS__c',undefined);
            }
        } else if(newCaseStatusMode.CDE_ELIGTY_CONTNUS__c=='Y') {
            if(currentCaseStatusMode.CDE_STATUS_CASE__c=='CLS' && (currentCaseStatusMode.CDE_MODE_CASE__c=='INT' || currentCaseStatusMode.CDE_MODE_CASE__c=='RED' || currentCaseStatusMode.CDE_MODE_CASE__c=='ONG')){
                //applicationDateState = "DISABLED";   commented for CCCAP-13251
            }
            if(currentCaseStatusMode.CDE_STATUS_CASE__c=='CLS' && currentCaseStatusMode.CDE_MODE_CASE__c=='RED'){
                dateRedeterminationPacketReturnedState = "REQUIRED";
            }
            if(currentCaseStatusMode.CDE_STATUS_CASE__c=='CLS' && currentCaseStatusMode.CDE_MODE_CASE__c=='INT'){
                dateRedeterminationPacketReturnedState = "DISABLED";
            }
            //added for CCCAP-11857 by Shashank S.
            if(newCaseStatusMode.CDE_REASON_CHANGE_MODE_STATUS__c == 'WEP'){
                dateRedeterminationPacketReturnedState = "DISABLED";
                applicationDateState = "DISABLED"; //CCCAP-13251
                component.set('v.caseApplnDateInfo.DTE_APPLN_NEW__c',"");//CCCAP-13251
            }
        }
        var caseRec = component.get("v.case");
        var caseCopy = component.get("v.caseCopy");
        if(dateRedeterminationPacketReturnedState == "DISABLED"){
            caseRec.DTE_RCVD_PACKET_REDET__c = '';
        } else {
            caseRec.DTE_RCVD_PACKET_REDET__c = caseCopy.DTE_RCVD_PACKET_REDET__c;
        }
        if(applicationDateState == "DISABLED"){
            caseRec.DTE_APPLN__c = '';
        } else {
            caseRec.DTE_APPLN__c = caseCopy.DTE_APPLN__c;
        }
        // Start: Added for CCCAP-3238 by Rishav
        if(newCaseStatusMode.CDE_ELIGTY_CONTNUS__c == 'Y'){
            caseRec.DTE_SENT_PACKET_REDET__c = caseCopy.DTE_SENT_PACKET_REDET__c;
        } else {
            caseRec.DTE_SENT_PACKET_REDET__c = '';
        }
        // End: CCCAP-3238
        component.set("v.applicationDateState",applicationDateState);
        component.set("v.dateRedeterminationPacketReturnedState",dateRedeterminationPacketReturnedState);
        component.set("v.case",caseRec);
        helper.checkForCaseReopenOngoing(component);
    }
})