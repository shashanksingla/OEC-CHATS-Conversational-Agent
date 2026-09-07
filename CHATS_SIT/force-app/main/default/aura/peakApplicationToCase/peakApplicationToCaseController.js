({
    doInit : function(component, event, helper) {
      
        component.set("v.appCaseId",component.get("v.appProcessQueueRec").IDN_APPLN__c);
        helper.doGetRelatedApplicationIndividuals(component);
    },
    goNext : function(component, event, helper) {
        var lstError = [];
        if(component.get("v.currentState")=="APP_INDIV_SELECTION"){
            if(component.get("v.lstSelectedApplicationIndividuals").length==0){
                lstError.push("Please select at least one individual to proceed.");
            }else{
                component.set("v.currentState","APP_INDIV_CLEARANCE");
                component.set("v.currentStateTitle","Application Individual Clearance");
            }
        }else if(component.get("v.currentState")=="APP_INDIV_CLEARANCE"){
            var hasIndividualWithBlankStateID = false;
            var lstSelectedApplicationIndividuals = component.get("v.lstSelectedApplicationIndividuals");
            for(var i=0;i<lstSelectedApplicationIndividuals.length;i++){
                if(lstSelectedApplicationIndividuals.IDN_STATE__c==null || lstSelectedApplicationIndividuals.IDN_STATE__c==null){
                    hasIndividualWithBlankStateID = true;
                }
            }
           
            if(hasIndividualWithBlankStateID && !component.get("v.anyIndividualSelected")){
                lstError.push("All individuals must be cleared before proceeding to case selection.");
            }else{
                helper.doFindCaseAndPrimaryCaretakerDetails(component);
            }
        }
        component.set("v.lstError",lstError);
        if(lstError.length>0){
            component.set("v.showError",true);
        }else{
            component.set("v.showError",false);
        }
    },
    goPrev : function(component, event, helper) {
        component.set("v.lstError",[]);
        component.set("v.showError",false);
        if(component.get("v.currentState")=="APP_INDIV_CLEARANCE"){
            component.set("v.currentState","APP_INDIV_SELECTION");
            component.set("v.currentStateTitle","Application Individual Selection");
        }else if(component.get("v.currentState")=="CASE_SELECTION"){
            component.set("v.currentState","APP_INDIV_CLEARANCE");
            component.set("v.currentStateTitle","Application Individual Clearance");
        }
    },
    goToClearIndividual : function(component, event, helper) { 
        
        if(component.get("v.applicationIndividualForClearance")==null || component.get("v.applicationIndividualForClearance").Id==null){
            component.set("v.lstError",["Please select at least one individual to proceed."]);
            component.set("v.showError",true);
        }else{
            component.set("v.lstError",[]);
            component.set("v.showError",false);
            helper.doGetMatchedIndividuals(component, event);
        }
    },
    doClearIndividual : function(component, event, helper) { 
        if(component.get("v.anyIndividualSelected")){
            component.set("v.lstError",[]);
            component.set("v.showError",false);
            var stateID = component.get("v.stateID");
            var applicationIndividualForClearance = component.get("v.applicationIndividualForClearance");
            
            applicationIndividualForClearance.IDN_STATE__c = stateID;
            helper.doUpdateRecords(component, event, applicationIndividualForClearance);
            component.set("v.stateID",null);
        }else{
            component.set("v.lstError",["Please select at least one option to proceed."]);
            component.set("v.showError",true);
        }
    },
    doFinish : function(component, event, helper) {    
        if(component.get("v.anyCaseSelected")){
            component.set("v.lstError",[]);
            component.set("v.showError",false);
            var selectedCaseID = component.get("v.selectedCaseID");
            if(selectedCaseID==null || selectedCaseID==''){
                helper.redirectToLightningComponent("c:caseFlow",{"applicationId":component.get("v.recordId")});
            }else{
                helper.doHandleExistingCaseSelection(component);
            }
        }else{
            component.set("v.lstError",["Please select at least one option to proceed."]);
            component.set("v.showError",true);
        }
    },
    doUpdateComponentAttribute : function(component, event, helper) {    
        
        component.set("v."+event.getParam("attributeName"),event.getParam("attributeValue"));
        if(event.getParam("attributeName")=='stateID'){
            component.set("v.anyIndividualSelected",true);
        }
        else if(event.getParam("attributeName")=='selectedCaseID'){
            component.set("v.anyCaseSelected",true);
        }
    }
})