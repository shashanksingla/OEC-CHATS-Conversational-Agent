({
	doInit : function(component, event, helper) {
		var activityRcrd = component.get("v.activityRcrd");
        
        var EMPCodes = component.get("v.EMPCodes");
        var GEDCodes = component.get("v.GEDCodes");
        var JSCodes = component.get("v.JSCodes");
        var POSCodes = component.get("v.POSCodes");
        if(!$A.util.isEmpty(activityRcrd.CDE_TYPE_ACTV__c)){
            
            if(EMPCodes.includes(activityRcrd.CDE_TYPE_ACTV__c)){
                activityRcrd.CDE_TYPE_ACTV__c = 'Employment/Self Employment';
            } else if(GEDCodes.includes(activityRcrd.CDE_TYPE_ACTV__c)){
                activityRcrd.CDE_TYPE_ACTV__c = 'GED/ESL/ABE(max 12 months)';
            } else if(JSCodes.includes(activityRcrd.CDE_TYPE_ACTV__c)){
                activityRcrd.CDE_TYPE_ACTV__c = 'Job Search';
            } else if(POSCodes.includes(activityRcrd.CDE_TYPE_ACTV__c)){
                activityRcrd.CDE_TYPE_ACTV__c = 'Post Secondary Education / Job Skills';
            } 
            component.set("v.activityRcrd", activityRcrd);
        }
	}
})