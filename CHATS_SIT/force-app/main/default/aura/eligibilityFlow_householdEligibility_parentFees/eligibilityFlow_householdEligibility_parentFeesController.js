({
    doInit : function(component, event, helper) {
        
        var casePayment = component.get("v.casePayment");
        var currentDate = new Date();
        if(casePayment && casePayment.length>0) {
            if(casePayment.length>1) {
                var i=0;
                if(casePayment[i].amt_copay_case_assesd__c < casePayment[i+1].amt_copay_case_assesd__c) {
                    var date = helper.getFirstDayOfNextMonth();
                   
                    component.set("v.dteBeginEffective",(date.getMonth() + 1) + '/' + date.getDate() + '/' +  date.getFullYear());
                } else if(casePayment[i].amt_copay_case_assesd__c > casePayment[i+1].amt_copay_case_assesd__c && currentDate.getDate()>=1 && currentDate.getDate()<=15) {
                    var date = helper.getFirstDayOfNextMonth();
                    component.set("v.dteBeginEffective",(date.getMonth() + 1) + '/' + date.getDate() + '/' +  date.getFullYear());
                } else if(casePayment[i].amt_copay_case_assesd__c > casePayment[i+1].amt_copay_case_assesd__c && 16<=currentDate.getDate() && currentDate.getDate()<=31) {
                    var date = helper.getFirstDayOfNexToNexttMonth();
                    component.set("v.dteBeginEffective",(date.getMonth() + 1) + '/' + date.getDate() + '/' +  date.getFullYear());
                } 
            } else {
                var date = helper.getFirstDayOfNextMonth();
                component.set("v.dteBeginEffective",(date.getMonth() + 1) + '/' + date.getDate() + '/' +  date.getFullYear());
            }
        }
        if(component.get("v.caseEligibility") && !$A.util.isEmpty(component.get("v.caseEligibility.amt_copay_ft__c"))) {
            component.set("v.amt_copay_ft__c",parseInt(component.get("v.caseEligibility.amt_copay_ft__c")));
        }
        if(component.get("v.caseEligibility") && !$A.util.isEmpty(component.get("v.caseEligibility.amt_copay_pt__c"))) {
	        component.set("v.amt_copay_pt__c",parseInt(component.get("v.caseEligibility.amt_copay_pt__c")));
        }
        
    }
})