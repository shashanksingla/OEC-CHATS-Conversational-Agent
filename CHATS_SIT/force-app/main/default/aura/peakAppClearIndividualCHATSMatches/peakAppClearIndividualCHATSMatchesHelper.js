({
	getLstCHATSMatchedIndividualsPerPage : function(component, pageNo) {
        debugger;
		var lstCHATSMatchedIndividuals = component.get("v.lstCHATSMatchedIndividuals");
        var lstCHATSMatchedIndividualsPerPage = [];
        if(!$A.util.isEmpty(lstCHATSMatchedIndividuals)){
            for(var i=(pageNo-1)*10;i<(lstCHATSMatchedIndividuals.length>pageNo*10?pageNo*10:lstCHATSMatchedIndividuals.length);i++){
                lstCHATSMatchedIndividualsPerPage.push(lstCHATSMatchedIndividuals[i]);
            }
        }
        component.set("v.lstCHATSMatchedIndividualsPerPage", lstCHATSMatchedIndividualsPerPage);
	}
})