({
	doInit : function(component, event, helper) {        
        var recId = component.get("v.recordId");       
        let countyPlan = component.get('v.countyPlan');
        const july_01_23 = new Date($A.get("$Label.c.Date_1July2023"));
        const April_09_26 =  new Date('2026-04-09T00:00:00.000Z');
        let vfPageName = 'countyPlanPDF';
        if(countyPlan.IND_COUNTY_PLAN_TEMPLT__c == true){
             vfPageName = 'countyPlanTemplate_v2'; // latest template
        } else {
            let beginDate = new Date(countyPlan.DTE_BEGIN_EFFEV__c);
            if(beginDate >= April_09_26){
                vfPageName = 'countyPlanTemplate_v2';
            }else if(beginDate >= july_01_23){
                vfPageName = 'countyPlanTemplate';
            }
        }
        var pdfWin= window.open("/apex/"+vfPageName+"?countyPlanId="+recId+" ", "", "height=650,width=840");
        var navigationSObject = $A.get("e.force:navigateToSObject");
        navigationSObject.setParams({
            "recordId": component.get("v.recordId")
        });
        navigationSObject.fire();
	}
})