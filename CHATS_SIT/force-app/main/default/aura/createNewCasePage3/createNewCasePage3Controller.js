({
    handleValidateCurrentPage : function(component, event, helper) {
        var caseHomelessResult = component.find("caseHomeless").callValidateCurrentPage();
        var caseAddressMALResult = component.find("caseAddressMAL").callValidateCurrentPage();
        var caseAddressRESResult = component.find("caseAddressRES").callValidateCurrentPage();
        var casePhoneWORResult = component.find("casePhoneWOR").callValidateCurrentPage();
        var casePhoneMOBResult = component.find("casePhoneMOB").callValidateCurrentPage();
        var casePhoneHOMResult = component.find("casePhoneHOM").callValidateCurrentPage();
        var caseInfoPMCResult = component.find("caseInfoPMC").callValidateCurrentPage();
        return caseHomelessResult && caseAddressRESResult && caseAddressMALResult && casePhoneWORResult && casePhoneMOBResult && casePhoneHOMResult && caseInfoPMCResult;
    }
})