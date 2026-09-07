({
	saveAppCountyCase : function(component, event, helper) {
        debugger;
		component.find("appCaseRecord1").saveRecord($A.getCallback(function(saveResult) {
        if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
            var toastEvent1 = $A.get("e.force:showToast");
                                toastEvent1.setParams({
                                    "title": "Success!",
                                    "message": "Updated Successfully.",
                                    "type" : "success"
                                });
                                toastEvent1.fire();
            //alert("Save completed successfully.");
            component.find("appCaseRecord1").reloadRecord();
        } else if (saveResult.state === "INCOMPLETE") {
           // component.set("v.recordSaveError","User is offline, device doesn't support drafts.");
        } else if (saveResult.state === "ERROR") { 
            var errMsg = "";
            // saveResult.error is an array of errors, 
            // so collect all errors into one message
            for (var i = 0; i < saveResult.error.length; i++) {
                errMsg += saveResult.error[i].message + "\n";
            }
            component.set("v.recordSaveError", errMsg);

        } else {
            component.set("v.recordSaveError",'Unknown problem, state: ' + saveResult.state + ', error: ' + 
              JSON.stringify(saveResult.error));
        }
    }));

	},
    saveAppIncomeCase : function(component, event, helper) {
        debugger;
		component.find("appCaseRecord").saveRecord($A.getCallback(function(saveResult) {
        if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
           // alert("Save completed successfully.");
           var toastEvent1 = $A.get("e.force:showToast");
                                toastEvent1.setParams({
                                    "title": "Success!",
                                    "message": "Updated Successfully.",
                                    "type" : "success"
                                });
                                toastEvent1.fire();
            component.find("appCaseRecord").reloadRecord();
        } else if (saveResult.state === "INCOMPLETE") {
            component.set("v.recordSaveError","User is offline, device doesn't support drafts.");
        } else if (saveResult.state === "ERROR") { 
            var errMsg = "";
            // saveResult.error is an array of errors, 
            // so collect all errors into one message
            for (var i = 0; i < saveResult.error.length; i++) {
                errMsg += saveResult.error[i].message + "\n";
            }
            component.set("v.recordSaveError", errMsg);

        } else {
            component.set("v.recordSaveError",'Unknown problem, state: ' + saveResult.state + ', error: ' + 
              JSON.stringify(saveResult.error));
        }
    }));

	},	
    getSortOrder :function(component,helper,fieldName){
        let sortOrder = {'DTE_BEGIN_EFFV__c':1,
                         'IND_NEED_CHILD_CARE__c':2,
                         'CHILD_NAME__c	':3,
                         'DTE_BEGIN_CARE__c':4,
                         'DTE_END_CARE__c':5,
                         'NAM_FACILITY__c':6,
                         'IDN_CBMS_PROVR__c':7,
                         'IND_PROVIDER_CHANGE__c':8,
                         'DTE_WITH_LAST_PROVIDER__c':9,
                         'CNT_HOUR_ON_MON__c':10,
                         'CNT_HOUR_ON_TUE__c':11,
                         'CNT_HOUR_ON_WED__c':12,
                         'CNT_HOUR_ON_THU__c':13,
                         'CNT_HOUR_ON_FRI__c':14,
                         'CNT_HOUR_ON_SAT__c':15,
                         'CNT_HOUR_ON_SUN__c':16,
                         'IND_SCHOOL_AGE_CARE__c':17
                        };
        return sortOrder[fieldName] || -1;
    }
})