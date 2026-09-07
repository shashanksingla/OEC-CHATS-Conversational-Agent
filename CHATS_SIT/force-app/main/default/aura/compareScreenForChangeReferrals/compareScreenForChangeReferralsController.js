({
    doInit : function(component, event, helper) {
        if(component.get('v.countyNote')){
            let refList = component.get('v.caseRefList') ||[];
            let newCountyId;
            refList.forEach(val => {
                if(val.Field_API_Name__c=='CDE_COUNTY__c'){
                newCountyId = val.New_Value__c;
            }});
            component.set('v.newCountyId',newCountyId);            
        }
        if(component.get('v.childCareNote')){
            let newList = [];
            let sfId;
            let newObj;
            let refList = component.get('v.caseRefList') ||[];
            if(refList.length >0){                
                sfId =	refList[0].SF_Record_Id__c;
                newObj = {'sfId': sfId,'dataList':[],'childName':'','providerName':''};
                refList.forEach(val => {                    
                    val.sortOrder = helper.getSortOrder(component,helper,val.Field_API_Name__c);
                    if(val.SF_Record_Id__c != sfId )
                    {
                    if(newObj.dataList.length>0){
                    newList.push(newObj);
                }                    
                    sfId = val.SF_Record_Id__c;
                    newObj = {'sfId': sfId,'dataList':[],'childName':'','providerName':''};
                                }
                                if(val.Old_Value__c!=val.New_Value__c){
                    newObj.dataList.push(val);
                }                
                if(newObj.childName=='' && val.Field_API_Name__c=='CHILD_NAME__c')
                    newObj.childName = val.New_Value__c || val.Old_Value__c;
                if(newObj.providerName == '' && val.Field_API_Name__c=='IDN_CBMS_PROVR__c')
                    newObj.providerName = val.New_Value__c || val.Old_Value__c;
            });
            if(newObj.dataList.length>0){
                newList.push(newObj);
            }
            if(newList.length>0){
                newList.forEach(value=>{
                    value.dataList.sort(function(keyA, keyB) {
                    if (keyA.sortOrder < keyB.sortOrder) return -1;
                    if (keyA.sortOrder > keyB.sortOrder) return 1;
                    return 0;});})    
                }
       	}
           component.set('v.childCarelist',newList);
    }
},
    
    handleApproveAction : function(component, event, helper) {
        var selectedReferrals = [];
        var checkvalue = component.find("checkReferrals");
        if(checkvalue != undefined && checkvalue != null && checkvalue != ""){
            if(!Array.isArray(checkvalue)){
                if(checkvalue.get("v.value") == true) {
                    selectedReferrals.push(checkvalue.get("v.text"));
                }
            } else {
                for(var i = 0; i < checkvalue.length; i++) {
                    if(checkvalue[i].get("v.value") == true) {
                        selectedReferrals.push(checkvalue[i].get("v.text"));
                    }
                }
            }
        }
        if(component.get("v.childCareNote")){ // Added by Rishav for CCCAP-7696
            var childCareRefList = component.get("v.caseRefList");
            childCareRefList.forEach(function(refRow) {
                selectedReferrals.push(refRow.Id);
            });
        }
        console.log('selectedReferrals-' + selectedReferrals);
        if($A.util.isEmpty(selectedReferrals)){
            helper.showToast('error', 'Please select atleast one record.');
        } else {
            if(component.get("v.countyNote")){
                component.set("v.countyAccOrRej", true);
                component.set("v.countyChange", true);
                component.set("v.showSpinner", true);
                var action1 = component.get('c.createTask');
                action1.setParams({
                    'caseId':component.get("v.caseIdToRedirect"),
                    'appProcId':component.get("v.recordIdOld")
                });
                action1.setCallback(this, function(response) {
                    var state = response.getState();
                    if(state === "SUCCESS") {
                        var res = response.getReturnValue();
                        if(res.isSuccessful){
                            helper.showToast('success', 'Task Generated Successfully.');
                        } else {                            
                            helper.showToast('error', res.errorMessage);
                        }
                    } else {
                        helper.showToast('error', response.getError()[0].message);
                    } 
                    component.set("v.showSpinner", false);
                });
                $A.enqueueAction(action1); 
                
            } else {
                if(component.get("v.incomeNote")){
                    component.set("v.netIncomeAccOrRej", true);
                }
                if(component.get("v.childCareNote")){
                component.set("v.childCareAccOrRej", true);
                }
                var action1 = component.get('c.updateCHATSObjsInfo');
                action1.setParams({
                    'selectedReferralIds':selectedReferrals
                });
                action1.setCallback(this, function(response) {
                    var state = response.getState();
                    if(component.isValid() && state == 'SUCCESS') {
                        var res =response.getReturnValue();
                        if(res.isSuccessful){
                            helper.showToast('success', 'Updated Successfully.');
                        }else{
                            helper.showToast('error', res.errorMessage);
                        }
                    }else{
                        helper.showToast('error', response.getError()[0].message);
                    }
                });
                $A.enqueueAction(action1); 
            }
        }
    },
    
    discardChanges : function(component, event, helper){
        var selectedReferrals = [];
        var checkvalue = component.find("checkReferrals");
        if(!Array.isArray(checkvalue)){
            if (checkvalue.get("v.value") == true) {
                selectedReferrals.push(checkvalue.get("v.text"));
            }
        } else {
            for(var i = 0; i < checkvalue.length; i++) {
                if(checkvalue[i].get("v.value") == true) {
                    selectedReferrals.push(checkvalue[i].get("v.text"));
                }
            }
        }
        if($A.util.isEmpty(selectedReferrals)) {
            helper.showToast('error', 'Please select atleast one record.');
        } else if($A.util.isEmpty(component.get("v.rejectionComment"))) {
            component.set("v.isRejectedReq",true);
            helper.showToast('error', 'Please enter rejection reason.');
        } else {
            if(component.get("v.countyNote")){
                var updateAppCase = component.get("v.updateCountyAppCase");
                updateAppCase.County_Rejection_Notes__c =component.get("v.rejectionComment");
                component.set("v.updateCountyAppCase",updateAppCase);
                helper.saveAppCountyCase(component, event, helper);
                component.set("v.countyAccOrRej",true);
            } else if(component.get("v.incomeNote")) {
                var updateAppCase = component.get("v.updateIncomeAppCase");
                updateAppCase.Earned_Income_Rejection_Notes__c =component.get("v.rejectionComment");
                component.set("v.updateIncomeAppCase",updateAppCase);
                helper.saveAppIncomeCase(component, event, helper);
                component.set("v.netIncomeAccOrRej",true);
            }
        }
    },
    
    doComplete : function(component, event, helper){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.caseIdToRedirect"),
            "slideDevName": "related"
        });
        navEvt.fire();
    },
    
    handleChange : function(component, event, helper){
        // helper.saveContact(component, event, helper);
    },
    
    handleRecordUpdated : function(component, event, helper){
        // helper.saveContact(component, event, helper);
    },
    
    // Added by Rishav for CCCAP-7696
    goToAuthorization : function(component, event, helper){
        var authId = event.currentTarget.dataset.authid;
        var navService = component.find("navService");
        var pageReference = {
            "type": "standard__recordPage",
            "attributes": {
                "recordId": authId,
                "actionName": "view"
            }
        }
        navService.generateUrl(pageReference)
        .then($A.getCallback(function(url) {
            window.open(url,'_blank');
        }));
    }
})