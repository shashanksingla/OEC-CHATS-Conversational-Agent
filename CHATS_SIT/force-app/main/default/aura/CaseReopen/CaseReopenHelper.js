({
    callModal : function(cmp, modalName) {
        var modalCall = cmp.find(modalName);
        if(modalCall){
            modalCall.openModal();
        } else {
            this.redirectToRecord(cmp.get("v.recordId"));
        }
    },
    
    ReopenCompletion : function(component, event, helper) {
        var childCmp = component.find("CaseReopenLayout");
        childCmp.callValidateCurrentPage();
        if(component.get("v.isCurrentPageValid")==true){
            var pageMessages = [];
            var currentCaseStatusMode = component.get("v.currentCaseStatusMode");
            if((currentCaseStatusMode.CDE_STATUS_CASE__c=='PEN' && currentCaseStatusMode.CDE_MODE_CASE__c=='INT')
               || (currentCaseStatusMode.CDE_STATUS_CASE__c=='OPN' && currentCaseStatusMode.CDE_MODE_CASE__c=='ONG')
               || (currentCaseStatusMode.CDE_STATUS_CASE__c=='OPN' && currentCaseStatusMode.CDE_MODE_CASE__c=='RED')
               || (currentCaseStatusMode.CDE_STATUS_CASE__c=='REO' && (currentCaseStatusMode.CDE_MODE_CASE__c=='INT' || currentCaseStatusMode.CDE_MODE_CASE__c=='ONG' || currentCaseStatusMode.CDE_MODE_CASE__c=='RED'))
              ){
                pageMessages.push($A.get("$Label.c.CANNOT_INITIATE_REOPEN"));
            }
            var CaseStatus = component.get("v.caseStatus");
            var beginEffectiveDate = new Date(CaseStatus.DTE_BEGIN_EFFV__c);
            var todayDate = new Date();
            var todayMinus45 = new Date(); 
            var NewCaseStatus = component.get("v.newCaseStatus");
            todayMinus45.setDate(todayMinus45.getDate() - 45);
            var Red_plus15Days = new Date(component.get('v.case').DTE_REDET_CASE__c);
            Red_plus15Days.setDate(Red_plus15Days.getDate() + 15);
            if(todayMinus45>beginEffectiveDate && NewCaseStatus.CDE_ELIGTY_CONTNUS__c=='Y' && NewCaseStatus.CDE_REASON_CHANGE_MODE_STATUS__c != 'WEP'){
                pageMessages.push($A.get("$Label.c.CANNOT_REOPEN_CONT_MORE_THAN_45_DAYS"));
            }
            if(currentCaseStatusMode.CDE_STATUS_CASE__c=='CLS' && currentCaseStatusMode.CDE_MODE_CASE__c=='INT' && NewCaseStatus.CDE_ELIGTY_CONTNUS__c=='Y'){
                pageMessages.push($A.get("$Label.c.CANNOT_REOPEN_CLOSED_INT_CONT"));
            }
            //added below if blocks for CCCAP-11857 by Shashank S.
            if(NewCaseStatus.CDE_ELIGTY_CONTNUS__c=='Y' && NewCaseStatus.CDE_REASON_CHANGE_MODE_STATUS__c == 'WEP' && component.get('v.childCareProgram') == 'CW'){
                pageMessages.push($A.get("$Label.c.CW_Cannot_Reopen"));
            }
            if(NewCaseStatus.CDE_ELIGTY_CONTNUS__c=='Y' && NewCaseStatus.CDE_REASON_CHANGE_MODE_STATUS__c == 'WEP'
                && (component.get('v.childCareProgram') == 'TF' || component.get('v.childCareProgram') == 'LI')
                && currentCaseStatusMode.CDE_STATUS_CASE__c =='CLS' && (currentCaseStatusMode.CDE_MODE_CASE__c=='RED' || currentCaseStatusMode.CDE_MODE_CASE__c=='ONG')
                && todayDate > Red_plus15Days)
             {
                 pageMessages.push($A.get("$Label.c.CANNOT_REOPEN_15D_AFTER_RED"));
             }
             //change end for CCCAP-11857            
            if(pageMessages.length==0){
                var caseRec = component.get("v.case");
                var caseCopy = component.get("v.caseCopy");
                var caseAppln = component.get("v.caseApplnDateInfo");//CCCAP-13251
               /* if(NewCaseStatus.CDE_ELIGTY_CONTNUS__c=='Y'){ commented for CCCCAP-13251
                    caseRec.DTE_APPLN__c = caseCopy.DTE_APPLN__c;
                }*/
                //Start CCCAP-13251
                if(caseAppln.DTE_APPLN_NEW__c){
                	caseRec.DTE_APPLN__c = caseAppln.DTE_APPLN_NEW__c;//CCCAP-13251 
                }
                // end CCCAP-13251
                caseAppln.Reopened_or_Elig__c = 'Case Reopen';
                if(NewCaseStatus.CDE_ELIGTY_CONTNUS__c=='N' || currentCaseStatusMode.CDE_MODE_CASE__c=='INT'){
                    caseRec.DTE_RCVD_PACKET_REDET__c = caseCopy.DTE_RCVD_PACKET_REDET__c;
                }
                component.set("v.case",caseRec);
                //doFinish
                //added applnDateRec for CCCAP-13251
                helper.callServerAndHandleError(component,"c.onCaseReopenFlowCompletion", 
                                                function(response){
                                                    var recordId = component.get("v.recordId");
                                                    helper.goToRecord(recordId,'detail');
                                                }, {'caseRec':component.get("v.case"),
                                                    'newCaseStatus':component.get("v.newCaseStatus"),
                                                    'currentCaseStatusMode':component.get("v.currentCaseStatusMode"),
                                                    'caseRecCopay':component.get("v.caseCopy"),
                                                    'applnDateRec':component.get("v.caseApplnDateInfo")}, false, null);
            }else{
                component.set("v.pageMessages",pageMessages);
                component.set("v.messageType","error");
            }
        }
    }
})