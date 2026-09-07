({
    //added for CCCAP-11857 by Shashank S.
    checkForCaseReopenOngoing: function(component){
        var currentCaseStatusMode = component.get("v.currentCaseStatusMode") || {};
        let newCaseStatusMode = component.get("v.newCaseStatusMode") || {};
        if(currentCaseStatusMode.CDE_STATUS_CASE__c =='CLS' && newCaseStatusMode.CDE_ELIGTY_CONTNUS__c == 'Y')
            {
                component.set('v.hiddenReasons',undefined);
            }else{
                component.set('v.hiddenReasons',['WEP']);
            }
    },
    checkCustomValidations : function(component) {
        //should be implemented in child component if there are any custom validations.
        var isValid = true;
        /* Commenting as part of CCCAP-13251
        if(component.get("v.applicationDateState")=='REQUIRED' && $A.util.isEmpty(component.get("v.case.DTE_APPLN__c"))){
            component.find("T_SBSD_CASE__c-DTE_APPLN__c").set("v.message","Please provide a value");
            isValid=false;
        } else {
            component.find("T_SBSD_CASE__c-DTE_APPLN__c").set("v.message",null);
        }
        */
        if(component.get("v.childCareProgram") == 'LI' || component.get("v.childCareProgram") =='FT' || component.get("v.childCareProgram") =='TF'){
            if(component.get("v.dateRedeterminationPacketReturnedState")=='REQUIRED' && $A.util.isEmpty(component.get("v.case.DTE_RCVD_PACKET_REDET__c"))){
                component.find("T_SBSD_CASE__c-DTE_RCVD_PACKET_REDET__c").set("v.message","Please provide a value");
                isValid=false;
            } else {
                component.find("T_SBSD_CASE__c-DTE_RCVD_PACKET_REDET__c").set("v.message",null);
            }
        }
        //CCCAP-13251
        var todayDate = new Date();
        if(component.get("v.caseApplnDateInfo.DTE_APPLN_NEW__c")>todayDate.toISOString().split('T')[0]){
            component.find("Updated-DTE_APPLN_NEW__c").set("v.message",'Application Date cannot be in future.');
            isValid=false;
        }else if((component.get("v.caseApplnDateInfo.DTE_APPLN_NEW__c")!="") && component.get("v.caseApplnDateInfo.DTE_APPLN_NEW__c")<=component.get("v.case.DTE_APPLN__c")){
            component.find("Updated-DTE_APPLN_NEW__c").set("v.message",'Application Date must be greater than the current Application Received Date.');
            isValid=false;
        }else{
            component.find("Updated-DTE_APPLN_NEW__c").set("v.message",null);
        }
        if(((component.get("v.newCaseStatusMode.CDE_ELIGTY_CONTNUS__c") =='N')&&(component.get("v.newCaseStatusMode.CDE_REASON_CHANGE_MODE_STATUS__c")!='RP')&&(component.get("v.caseApplnDateInfo.DTE_APPLN_NEW__c")=="")) && (component.get("v.caseApplnDateInfo.CMT_OVERRIDE__c")=="")){
            component.find("Updated-CMT_OVERRIDE__c").set("v.message",'Please enter a value');
            isValid=false;
        }else if((((component.get("v.newCaseStatusMode.CDE_ELIGTY_CONTNUS__c") =='N')&&(component.get("v.newCaseStatusMode.CDE_REASON_CHANGE_MODE_STATUS__c")!='RP'))|| (component.get("v.caseApplnDateInfo.DTE_APPLN_NEW__c")!="")) && (component.get("v.caseApplnDateInfo.CMT_OVERRIDE__c")=="") ){
            component.find("Updated-CMT_OVERRIDE__c").set("v.message",'Override Comments cannot be blank if Updated Application Date is entered.');
            isValid=false;
        }
        else{
            component.find("Updated-CMT_OVERRIDE__c").set("v.message",null);
        }
        //end CCCAP-13251
        return isValid; 
    }
})