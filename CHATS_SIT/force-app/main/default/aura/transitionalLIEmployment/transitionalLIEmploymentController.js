({
	doInit : function(component, event, helper) {
		var employmentLIRefInfoRcrd = component.get("v.employmentLIRefInfoRcrd");
        if(!$A.util.isEmpty(employmentLIRefInfoRcrd.ADR_LINE_1__c) || !$A.util.isEmpty(employmentLIRefInfoRcrd.ADR_LINE_2__c)){
	        employmentLIRefInfoRcrd.ADR_LINE_1__c = employmentLIRefInfoRcrd.ADR_LINE_1__c+' '+employmentLIRefInfoRcrd.ADR_LINE_2__c;
	        component.set("v.employmentLIRefInfoRcrd",employmentLIRefInfoRcrd);
        }
	}
})