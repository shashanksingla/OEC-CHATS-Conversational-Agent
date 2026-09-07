({
    doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        
        let countyRate = component.get('v.countyRate');
        const july_01_23 = new Date($A.get("$Label.c.Date_1July2023"));
        let vfPageName = 'CompareCountyRatePlanTemplate';
        let beginDate = new Date(countyRate.DTE_BEGIN_EFFV_RATE__c);
        if( beginDate>=july_01_23){
            vfPageName = 'CompareCountyRatePlanNew';
        }
        var pdfWin= window.open("/apex/"+vfPageName+"?countyRatePlanId="+recId+" ", "", "height=650,width=840");
        var navigationSObject = $A.get("e.force:navigateToSObject");
        navigationSObject.setParams({
            "recordId": component.get("v.recordId")
        });
        navigationSObject.fire();
    }
})