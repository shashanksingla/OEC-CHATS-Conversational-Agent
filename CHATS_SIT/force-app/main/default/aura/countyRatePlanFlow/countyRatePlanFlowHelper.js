({
    getCountyRatePlanRecord : function(component, helper) {
        var action = component.get('c.getCountyRatePlanRecord');
        action.setParams({"countyRatePlanId":component.get("v.recordId"),
                         });
        action.setCallback(this, function(actionResult) {
            var returnValue = actionResult.getReturnValue();
            
            if(returnValue!=null && returnValue.isSuccessful){
                var returnedRecord = returnValue.objectData['countyRatePlanRecord'];
                component.set("v.originalTemplate", returnedRecord.CDE_RATE_PLAN_TEMPLT__c);
				if(returnedRecord.CDE_STATUS__c && returnedRecord.CDE_STATUS__c !=null && returnedRecord.CDE_STATUS__c == 'APV' && !returnedRecord.IND_RATE_PLAN_TEMPLT__c){
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
                returnedRecord.Flow_Completed__c = false;
                component.set("v.countyRatePlanRec",returnedRecord );
                component.set("v.showSpinner",false);
            }else if(returnValue!=null && !returnValue.isSuccessful ){
                component.set("v.showSpinner",false);
                component.set("v.recordError", returnValue.errorMessage )
            }
        });
        $A.enqueueAction(action);
    },
    getCountyRatePlanRecordForTemplate : function(component, helper) {
        var action = component.get('c.getCountyRatePlanRecordForTemplate');
        var countyRatePlanRecord= component.get("v.countyRatePlanRec")
        var templateName= countyRatePlanRecord.CDE_RATE_PLAN_TEMPLT__c;
        action.setParams({"templateName":templateName,
                          "countyId":component.get("v.countyId"),
                         });
        action.setCallback(this, function(actionResult) {
            var returnValue = actionResult.getReturnValue();
            if( returnValue.isSuccessful){//returnValue!=null &&
                var returnedCountyRatePlan= returnValue.objectData['countyRatePlanRecord'];
                returnedCountyRatePlan.CDE_STATUS__c= 'PEN';
                returnedCountyRatePlan.IND_RATE_PLAN_TEMPLT__c= 'false';
                if(countyRatePlanRecord.IDN_COUNTY__c && countyRatePlanRecord.IDN_COUNTY__c!=null){
                    returnedCountyRatePlan.IDN_COUNTY__c = countyRatePlanRecord.IDN_COUNTY__c.substring(0,15);
                }
                if(countyRatePlanRecord.DTE_BEGIN_EFFV_RATE__c && countyRatePlanRecord.DTE_BEGIN_EFFV_RATE__c !=null){
                    returnedCountyRatePlan.DTE_BEGIN_EFFV_RATE__c = countyRatePlanRecord.DTE_BEGIN_EFFV_RATE__c;
                }
                if(countyRatePlanRecord.Id && countyRatePlanRecord.Id!=null){
                    returnedCountyRatePlan.Id = countyRatePlanRecord.Id.substring(0,15);
                }
                if(countyRatePlanRecord.Name && countyRatePlanRecord.Name !=null){
                    returnedCountyRatePlan.Name= countyRatePlanRecord.Name;
                }
                if(returnedCountyRatePlan.CFS_Q1__c == 'N'){
                    returnedCountyRatePlan.CFS_Q1_1__c = null;
                    returnedCountyRatePlan.CFS_Q1_2__c = null;
                    returnedCountyRatePlan.CFS_Q1_3__c = null;
                    returnedCountyRatePlan.CFS_Q1_4__c = null;
                }
                if(returnedCountyRatePlan.RATE_TYPE__c && returnedCountyRatePlan.RATE_TYPE__c!=null){
                    if(returnedCountyRatePlan.RATE_TYPE__c.indexOf('1')!=-1){
                        component.set("v.templateRateType", returnedCountyRatePlan.RATE_TYPE__c );}
                    else{
                        component.set("v.templateRateType", '1;'+returnedCountyRatePlan.RATE_TYPE__c );
                    }
                    returnedCountyRatePlan.RATE_TYPE__c=component.get("v.templateRateType");
                }
                else{
                    component.set("v.templateRateType", '1;' );
                    returnedCountyRatePlan.RATE_TYPE__c = component.get("v.templateRateType");
                }
                component.set("v.countyRatePlanRec", returnedCountyRatePlan);
                helper.callServerAndHandleError(component,"c.upsertRecords", 
                function(response){
                    if(component.get("v.isCurrentPageValid")==true){
                        component.set("v.countyRatePlanRec", helper.merge(component.get("v.countyRatePlanRec"),response.objectData.upsertedRecords[0]));
                    }
                }, {'lstSObject':[component.get("v.countyRatePlanRec")]}, false, null);
                component.set("v.crpHolidays", returnedCountyRatePlan.PAYMENT_Q13_1__c);
                component.set("v.showSpinner",false);
            }else if(returnValue!=null && !returnValue.isSuccessful ){
                var countyRatePlanRecDraft = component.get("v.countyRatePlanRecDraft");
                countyRatePlanRecDraft.CDE_STATUS__c= 'PEN';
                countyRatePlanRecDraft.IND_RATE_PLAN_TEMPLT__c= 'false';
                if(countyRatePlanRecord.IDN_COUNTY__c && countyRatePlanRecord.IDN_COUNTY__c!=null){
                    countyRatePlanRecDraft.IDN_COUNTY__c = countyRatePlanRecord.IDN_COUNTY__c.substring(0,15);
                }
                if(countyRatePlanRecord.DTE_BEGIN_EFFV_RATE__c && countyRatePlanRecord.DTE_BEGIN_EFFV_RATE__c !=null){
                    countyRatePlanRecDraft.DTE_BEGIN_EFFV_RATE__c = countyRatePlanRecord.DTE_BEGIN_EFFV_RATE__c;
                }
                if(countyRatePlanRecord.Id && countyRatePlanRecord.Id!=null){
                    countyRatePlanRecDraft.Id = countyRatePlanRecord.Id.substring(0,15);
                }
                if(countyRatePlanRecord.Name && countyRatePlanRecord.Name !=null){
                    countyRatePlanRecDraft.Name= countyRatePlanRecord.Name;
                }
                if(countyRatePlanRecDraft.RATE_TYPE__c && countyRatePlanRecDraft.RATE_TYPE__c!=null){
                    if(countyRatePlanRecDraft.RATE_TYPE__c.indexOf('1;')!=-1){
                        component.set("v.templateRateType", countyRatePlanRecDraft.RATE_TYPE__c );
                    }else{
                       component.set("v.templateRateType", '1;'+countyRatePlanRecDraft.RATE_TYPE__c ); 
                    }
                    countyRatePlanRecDraft.RATE_TYPE__c=component.get("v.templateRateType");
                }
                else{
                    component.set("v.templateRateType", '1;' );
                    countyRatePlanRecDraft.RATE_TYPE__c = component.get("v.templateRateType");
                }
                component.set("v.countyRatePlanRec", countyRatePlanRecDraft);
                component.set("v.showSpinner",false);
                component.set("v.recordError", returnValue.errorMessage );
                
            }
            //added for CCCAP-9294 to double check that care not offered is not selected or defaulted from approved records.
            let crpRecord = component.get("v.countyRatePlanRec") || {};
            if(crpRecord.RATE_TYPE__c && crpRecord.RATE_TYPE__c.includes('100')){
                crpRecord.RATE_TYPE__c = crpRecord.RATE_TYPE__c.split(';').filter(val=>val!='100').join(';');
            	component.set('v.countyRatePlanRec',crpRecord);
            }
            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
        });
        $A.enqueueAction(action);	
    },
    validateCountyForNewRatePlan : function (component, helper){
        var action1 = component.get('c.getCountyValidatedForNewRatePlan');
        action1.setParams({"countyID":component.get("v.countyId")});
        action1.setCallback(this, function(actionResult) {
            var returnValue = actionResult.getReturnValue();
            if(returnValue.Id != null ){
                var showToast = $A.get("e.force:showToast"); 
                showToast.setParams({ 
                    'title' : 'Error', 
                    'message' : 'County already has an unapproved County Rate Plan',
                    'type' : 'error' 
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
    getUpdatedRatePlanRecord : function(component){
        var countyRatePlanRecord = component.get("v.countyRatePlanRec") ;
        var rateType = countyRatePlanRecord.RATE_TYPE__c || '';
        let types = rateType.split(';') || [];
        if(rateType!= null&& rateType!= '' && rateType!=undefined && rateType!=""){
           if(types.findIndex(val=> ['13'].includes(val)) == -1){
               	countyRatePlanRecord.RT_Q2__c = '';}
            if(types.findIndex(val=> ['19'].includes(val))==-1){
               	countyRatePlanRecord.RT_Q2_a__c = '';}
            if(types.findIndex(val=> ['25'].includes(val))==-1){
                countyRatePlanRecord.RT_Q2_b__c = '';}
            if(types.findIndex(val=> ['31'].includes(val))==-1){
                countyRatePlanRecord.isRT_Q2_3__c = '';}
            if(types.findIndex(val=> ['37'].includes(val))==-1){
                countyRatePlanRecord.RT_Q2_c__c = '';}
            if(types.findIndex(val=> ['43'].includes(val))==-1){
                countyRatePlanRecord.RT_Q2_d__c = '';}
            if(types.findIndex(val=> ['55'].includes(val))==-1){
                countyRatePlanRecord.RT_Q2_e__c = '';}
            if(types.findIndex(val=> ['91'].includes(val))==-1){
                countyRatePlanRecord.RT_Q2_f__c = '';}
        }
        return countyRatePlanRecord;
    },
    redirectToRecord : function(recordId){ //added as part of CCCAP-10471 to store history when redirecting
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recordId,
            "slideDevName": "detail",
            "isredirect" : true
        });
        navEvt.fire();
    },
    redirectToLightningComponent : function(componentName, params){ //added as part of CCCAP-10471 to store history when redirecting
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : componentName,
            componentAttributes: params,
            isredirect : true
        });
        evt.fire();   
    }
})