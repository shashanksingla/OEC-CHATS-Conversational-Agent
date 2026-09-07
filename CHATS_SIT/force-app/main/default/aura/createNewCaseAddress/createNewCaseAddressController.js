({
    handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
		return helper.validateCurrentPage(component);
    },
    doSetVerificationFields : function(component, event, helper) {
        
        var caseAddressRec = component.get("v.caseAddressRec");
        if(component.get("v.IND_IS_HOMELESS")==true){
            caseAddressRec.CDE_SOURCE_VRFD_ADR__c = "HL";
            caseAddressRec.CDE_TYPE_VERIF__c = "HL";
        }else{
            caseAddressRec.CDE_SOURCE_VRFD_ADR__c = "";
            caseAddressRec.CDE_TYPE_VERIF__c = "";
        }
        component.set("v.caseAddressRec",caseAddressRec);
    },
    doCopyAddress : function(component, event, helper) {
        var caseAddressRec = component.get("v.caseAddressRec");
        if(component.get("v.copyAddressFlag")==true && caseAddressRec.CDE_TYPE_ADR__c=='MAL'){
            var copyFromAddressRec = component.get("v.copyFromAddressRec");
            if(copyFromAddressRec){
                caseAddressRec.ADR_LINE_1__c = copyFromAddressRec.ADR_LINE_1__c;
                caseAddressRec.ADR_LINE_2__c = copyFromAddressRec.ADR_LINE_2__c;
                caseAddressRec.ADR_CITY__c = copyFromAddressRec.ADR_CITY__c;
                caseAddressRec.ADR_ZIP_MAIN__c = copyFromAddressRec.ADR_ZIP_MAIN__c;
                caseAddressRec.ADR_ZIP_EXTN__c = copyFromAddressRec.ADR_ZIP_EXTN__c;
                caseAddressRec.ADR_STATE__c = copyFromAddressRec.ADR_STATE__c;
            }
        }else if(component.get("v.copyAddressFlag")==false && caseAddressRec.CDE_TYPE_ADR__c=='MAL'){
            caseAddressRec.ADR_LINE_1__c = null;
            caseAddressRec.ADR_LINE_2__c = null;
            caseAddressRec.ADR_CITY__c = null;
            caseAddressRec.ADR_ZIP_MAIN__c = null;
            caseAddressRec.ADR_ZIP_EXTN__c = null;
            caseAddressRec.ADR_STATE__c = 'CO';
        }
        component.set("v.caseAddressRec",caseAddressRec);
  }
})