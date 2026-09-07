({
    getCountyPlanRecord : function(component, helper) {
        var action = component.get('c.getCountyPlanRecord');
        action.setParams({"countyPlanId":component.get("v.recordId"),
                         });
        action.setCallback(this, function(actionResult) {
            var returnValue = actionResult.getReturnValue();
            var returnedRecord = returnValue.objectData['countyPlanRecord'];
            component.set("v.originalTemplate", returnedRecord.CDE_COUNTY_PLAN_TEMPLT__c);
            if(returnedRecord.CDE_STATUS__c && returnedRecord.CDE_STATUS__c !=null && returnedRecord.CDE_STATUS__c == 'APV' && !returnedRecord.IND_COUNTY_PLAN_TEMPLT__c ){
                    helper.redirectToRecord(component.get("v.recordId"));
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Warning!",
                        "message": "Approved Plans Cannot be Revised",
                        "type":"error",
                        "mode":"sticky"
                    });
                    toastEvent.fire();
                }
            if(returnValue!=null && returnValue.isSuccessful){
                returnedRecord.Flow_Completed__c= false;
                component.set("v.countyPlanRec", returnedRecord);
                component.set("v.showSpinner",false);
            }else if(returnValue!=null && !returnValue.isSuccessful ){
                component.set("v.showSpinner",false);
                component.set("v.recordError", returnValue.errorMessage )
            }
        });
        $A.enqueueAction(action);	
    },
    getCountyPlanRecordForTemplate : function(component, helper) {
        var action = component.get('c.getCountyPlanRecordForTemplate');
        var countyPlanRecord = component.get("v.countyPlanRec");
        var template= countyPlanRecord.CDE_COUNTY_PLAN_TEMPLT__c;
        action.setParams({"templateName":template,
                         "countyId":component.get("v.countyId")
                         });
        action.setCallback(this, function(actionResult) {
            var returnValue = actionResult.getReturnValue();
            if(returnValue.isSuccessful){
                var returnedCountyPlan=returnValue.objectData['countyPlanRecord'];
                returnedCountyPlan.IND_COUNTY_PLAN_TEMPLT__c= false;
                returnedCountyPlan.CDE_STATUS__c='PEN';
                if(countyPlanRecord.Id && countyPlanRecord.Id !=null){
                returnedCountyPlan.Id= countyPlanRecord.Id.substring(0,15);
                }
                if(countyPlanRecord.CDE_COUNTY__c && countyPlanRecord.CDE_COUNTY__c !=null){
                returnedCountyPlan.CDE_COUNTY__c= countyPlanRecord.CDE_COUNTY__c.substring(0,15);
                }
                if(countyPlanRecord.DTE_BEGIN_EFFEV__c && countyPlanRecord.DTE_BEGIN_EFFEV__c !=null){
                    returnedCountyPlan.DTE_BEGIN_EFFEV__c= countyPlanRecord.DTE_BEGIN_EFFEV__c;
                }
                if(countyPlanRecord.Name && countyPlanRecord.Name !=null){
                    returnedCountyPlan.Name= countyPlanRecord.Name;
                }
                if(countyPlanRecord.CDE_COUNTY_PLAN_TEMPLT__c && countyPlanRecord.CDE_COUNTY_PLAN_TEMPLT__c !=null){
                    returnedCountyPlan.CDE_COUNTY_PLAN_TEMPLT__c= countyPlanRecord.CDE_COUNTY_PLAN_TEMPLT__c;
                }
                component.set("v.countyPlanRec", returnedCountyPlan );
                helper.callServerAndHandleError(component,"c.upsertRecords", 
                                                function(response){
                                                    if(component.get("v.isCurrentPageValid")==true){
                                                        component.set("v.countyPlanRec", helper.merge(component.get("v.countyPlanRec"),response.objectData.upsertedRecords[0]));
                                                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                    }
                                                }, {'lstSObject':[component.get("v.countyPlanRec")]}, false, null);
            }
            else if(returnValue!=null && !returnValue.isSuccessful ){
                var countyPlanDraftRecord = component.get("v.countyPlanRecDraft");
                countyPlanDraftRecord.IND_COUNTY_PLAN_TEMPLT__c= false;
                countyPlanDraftRecord.CDE_STATUS__c='PEN';
                if(countyPlanRecord.Id && countyPlanRecord.Id !=null){
                countyPlanDraftRecord.Id= countyPlanRecord.Id.substring(0,15);
                }
                if(countyPlanRecord.CDE_COUNTY__c && countyPlanRecord.CDE_COUNTY__c !=null){
                countyPlanDraftRecord.CDE_COUNTY__c= countyPlanRecord.CDE_COUNTY__c.substring(0,15);
                }
                if(countyPlanRecord.DTE_BEGIN_EFFEV__c && countyPlanRecord.DTE_BEGIN_EFFEV__c !=null){
                    countyPlanDraftRecord.DTE_BEGIN_EFFEV__c= countyPlanRecord.DTE_BEGIN_EFFEV__c;
                }
                if(countyPlanRecord.Name && countyPlanRecord.Name !=null){
                    countyPlanDraftRecord.Name= countyPlanRecord.Name;
                }
                if(countyPlanRecord.CDE_COUNTY_PLAN_TEMPLT__c && countyPlanRecord.CDE_COUNTY_PLAN_TEMPLT__c !=null){
                    countyPlanDraftRecord.CDE_COUNTY_PLAN_TEMPLT__c= countyPlanRecord.CDE_COUNTY_PLAN_TEMPLT__c;
                }
                
                component.set("v.countyPlanRec" , countyPlanDraftRecord );
                component.set("v.recordError", returnValue.errorMessage );
                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
            }
            else{
            	component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
            }
        });
        $A.enqueueAction(action);	
    },
    validateCountyForNewCountyPlan : function (component, helper){
        var action1 = component.get('c.getCountyValidatedForNewCountyPlan');
        action1.setParams({"countyID":component.get("v.countyId")});
        action1.setCallback(this, function(actionResult) {
            var returnValue = actionResult.getReturnValue();
            if(returnValue.Id != null ){
                var showToast = $A.get("e.force:showToast"); 
				showToast.setParams({ 
				'title' : 'Error', 
				'message' : 'County already has an unapproved County Plan',
                "type" : "error"
				});
                showToast.fire();
                
                var navigationSObject = $A.get("e.force:navigateToSObject");
				navigationSObject.setParams({
    			"recordId": component.get("v.countyId")
				});
				navigationSObject.fire();
            }else if(returnValue == null ){
                component.set("v.recordError", returnValue.errorMessage )
            }
        });
        $A.enqueueAction(action1);
    },
    callModal : function(cmp, modalName) {
        var modalCall = cmp.find(modalName);
        if(modalCall){
	        modalCall.openModal();
        }else{
            this.redirectToRecord(cmp.get("v.recordId"));
        }
    },
    updateFPGValue : function(component) {
        var countyPlanRecord = component.get("v.countyPlanRec");
        var template= countyPlanRecord.CDE_COUNTY_PLAN_TEMPLT__c;
        var action = component.get('c.updateFPGValueFromTemplate');
        action.setParams({"templateName":template,
                         "countyId":countyPlanRecord.CDE_COUNTY__c,
                         "recordId":countyPlanRecord.Id
                         });
        action.setCallback(this, function(actionResult) {
            var returnValue = actionResult.getReturnValue();
            if(returnValue.isSuccessful && returnValue.successMessage=='Success'){
                console.log('FPG Value updated');
            }
        });
        $A.enqueueAction(action);
    },
    redirectToRecord : function(recordId){ //added as part of CCCAP-10471 to store history when redirecting
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recordId,
            "slideDevName": "detail",
            "isredirect" : true
        });
        navEvt.fire();
    }
})