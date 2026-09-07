({
	getLstCaseIndividualPerPage : function(component, pageNo) {
        debugger;
		var lstCaseIndividual = component.get("v.lstCaseIndividual");
        var lstCaseIndividualPerPage = [];
        if(!$A.util.isEmpty(lstCaseIndividual)){
            for(var i=(pageNo-1)*10;i<(lstCaseIndividual.length>pageNo*10?pageNo*10:lstCaseIndividual.length);i++){
                lstCaseIndividualPerPage.push(lstCaseIndividual[i]);
            }
        }
        component.set("v.lstCaseIndividualPerPage", lstCaseIndividualPerPage);
	}
})