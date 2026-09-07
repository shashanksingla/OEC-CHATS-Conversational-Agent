({
    doInit : function(component, event, helper) { 
        if(!$A.util.isEmpty(component.get("v.adjustmentObj").IDN_CASE__r)){
            //component.set("v.searchByAuthId",true);
            //component.set("v.showCancel",false);
            component.set("v.caseId", component.get("v.adjustmentObj").IDN_CASE__r.Id);
            component.set("v.disableCaseId", true);
        }
    },
    searchByAuthIdCtrl : function(component, event, helper) {
        component.set("v.nonSubPaymentSearchLst",[]);
        component.set("v.selectedNonSubPayment","");
        component.set("v.searchByAuthId",true);
        component.set("v.searchByChilName",false);
        component.set("v.showNext",false);
        component.set("v.currentTabNumber",3);
        component.set("v.showCancel",false);
        
    },
    searchByChildNameCtrl : function(component, event, helper) {
         component.set("v.nonSubPaymentSearchLst",[]);
        component.set("v.selectedNonSubPayment","");
        component.set("v.searchByAuthId",false);
        component.set("v.searchByChilName",true);
        component.set("v.showNext",true);
        component.set("v.currentTabNumber",2);
        component.set("v.showCancel",true);
        
    },
    doSearch : function(component, event, helper) {
         component.set("v.nonSubPaymentSearchLst",[]);
        component.set("v.selectedNonSubPayment","");
        helper.callServerAndHandleError(component,"c.searchRelatedAuthRecord", function(response){
            component.set("v.nonSubPaymentSearchLst",response.objectData.authList);
        }, {
            'nonSubPaymentObjNAMFIRST':component.get("v.nonSubPaymentObj_NAM_FIRST"),
            'nonSubPaymentObjNAMLAST':component.get("v.nonSubPaymentObj_NAM_LAST"),
            'adjustmentInfo': component.get("v.adjustmentObj"),
            'selectedCaseId': component.get("v.caseId")
           }, false, null);
    },
    doNext : function(component, event, helper) {
        var authObj = component.get("v.selectedNonSubPayment");
        if(!$A.util.isEmpty(authObj) && authObj != null){
            component.set("v.searchByAuthId",true);
            component.set("v.showNext",false);
            component.set("v.showCancel",false);
            component.set("v.searchByChilName",false);
            if(!$A.util.isEmpty(authObj)){
                component.set("v.authId",authObj.Id);
                component.set("v.pageMessages",[]);
                component.set("v.showPrevious",true);
                component.set("v.searchByChilNameFlow",true);
            } 
        }else{
            component.set("v.pageMessages","Please select Authorization record");
            component.set("v.messageType","error");
        }
    },
    doCancel : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        helper.callModal(component,'confirmationModal_NonSubPayment_EntryModal_'+currentTabNumber);
    },
    confirmCancel : function(component, event, helper){
        component.find("overlayLib").notifyClose();	
        // component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
    },
    doPrevious : function(component, event, helper){
        if(component.get("v.searchByChilNameFlow")){
            component.set("v.searchByChilName",true);
            component.set("v.searchByAuthId",false);
            component.set("v.showPrevious",false);
            component.set("v.showNext",true);
            component.set("v.showCancel",true);
            component.set("v.selectedNonSubPayment","");
            component.set("v.searchByChilNameFlow",false);
            component.set("v.authId",'');
        }
    },
})