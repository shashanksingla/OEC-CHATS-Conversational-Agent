({
	doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        let countyPlan = component.get('v.countyPlan');
        const july_01_23 = new Date($A.get("$Label.c.Date_1July2023"));
        let vfPageName = 'CompareCountyPlanTemplate';
        let beginDate = new Date(countyPlan.DTE_BEGIN_EFFEV__c);
        if( beginDate>=july_01_23){
            vfPageName = 'CompareCountyPlanNew';
        }
        var pdfWin= window.open("/apex/"+vfPageName+"?countyPlanId="+recId+" ", "", "height=650,width=840");
        var navigationSObject = $A.get("e.force:navigateToSObject");
        navigationSObject.setParams({
            "recordId": component.get("v.recordId")
        });
        navigationSObject.fire();
	}
})