({
    handleValidateCurrentPage : function(component, event, helper) {
        let caseIndividualsWithCCR = component.get('v.caseIndividualsWithCCR');
        var overallResults = true;
        var cmps = component.find("childCareRequestRow");
        if(cmps.length!=undefined && cmps.length>0){
            for(var i=0;i<cmps.length;i++){
                overallResults = overallResults && cmps[i].callValidateCurrentPage();
                caseIndividualsWithCCR[i].isOverriden = cmps[i].get('v.isOverriden');
            }
        }else{
            overallResults = cmps.callValidateCurrentPage();
            caseIndividualsWithCCR[0].isOverriden = cmps.get('v.isOverriden');
        }
        component.set('v.caseIndividualsWithCCR',caseIndividualsWithCCR);
        return overallResults;
    }
})