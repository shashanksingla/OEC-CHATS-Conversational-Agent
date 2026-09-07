({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        var isValid=true;
        /*
        
        var countyRatePlanRec = cmp.get("v.countyRatePlanRec");
         console.log("Checkbox value"+countyRatePlanRec.ROO_Q1_1_1__c)
        if(countyRatePlanRec.ROO_Q1_1_1__c== false && 
           countyRatePlanRec.ROO_Q1_1_2__c == false &&
           countyRatePlanRec.ROO_Q1_1_3__c == false &&
           countyRatePlanRec.ROO_Q1_1_4__c == false &&
           countyRatePlanRec.ROO_Q1_1_5__c == false &&
           countyRatePlanRec.ROO_Q1_1_6__c == false &&
           countyRatePlanRec.ROO_Q1_1_7__c == false &&
           countyRatePlanRec.ROO_Q1_1_8__c == false &&
           countyRatePlanRec.ROO_Q1_1_9__c == false)
        {
            isValid= false;
            cmp.set("v.messageType" , "error");
            var pageMessages = cmp.get("v.pageMessages");
            pageMessages.push('There are errors on this page. Please correct them to proceed.'); 
            pageMessages.push("At least one of Q1.1.1, Q1.1.2, Q1.1.3, Q1.1.4, Q1.1.5, Q1.1.6, Q1.1.7, Q1.1.8 and Q1.1.9 must be checked ");
            cmp.set("v.pageMessages", pageMessages);
        }*/
        return isValid;
    },
    setRequired : function(cmp){
        var countyRatePlanRec = cmp.get("v.countyRatePlanRec") || {};
        if(countyRatePlanRec.CFS_Q1__c !='Y'){
            cmp.set('v.countyRatePlanRec.CFS_Q1_1__c','');
            cmp.set('v.countyRatePlanRec.CFS_Q1_2__c','');
            cmp.set('v.countyRatePlanRec.CFS_Q1_3__c','');
            cmp.set('v.countyRatePlanRec.CFS_Q1_4__c','');
        }
        if(countyRatePlanRec.CFS_Q1_3__c && countyRatePlanRec.CFS_Q1__c=='Y' && countyRatePlanRec.CFS_Q1_3__c.indexOf('6;')!=-1){
            cmp.set("v.isCFS_Q1_4__cRequired", true);
        }else{
            cmp.set("v.isCFS_Q1_4__cRequired", false);  
        }
        
    }
})