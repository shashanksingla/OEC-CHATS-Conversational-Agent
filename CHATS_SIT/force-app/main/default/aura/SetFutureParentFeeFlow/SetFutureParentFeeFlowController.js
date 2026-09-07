({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var currentTabNumber= component.get("v.currentTabNumber");
        helper.callServerAndHandleError(component,"c.getInitData", function(response){
            if(response.objectData.isAdamCounty){
                component.set("v.isAdamCounty", response.objectData.isAdamCounty);
           }
            if(response.objectData.isReadOnlyUser){
                component.set("v.isReadOnlyUser", response.objectData.isReadOnlyUser);
            }
            if(response.objectData.caseCopayRecord){
                component.set("v.caseCopayRec", response.objectData.caseCopayRecord);
            } else if(response.objectData.caseExternalId){
                component.set("v.isFirstCaseCopayRec",true);
                var caseCopayRec = component.get("v.caseCopayRec");
                caseCopayRec.idn_case__c = response.objectData.caseExternalId;
                component.set("v.caseCopayRec", caseCopayRec);
                var newCaseCopayRec = component.get("v.newCaseCopayRec");
                newCaseCopayRec.idn_case__c = response.objectData.caseExternalId;
                component.set("v.newCaseCopayRec", newCaseCopayRec);
            }
            if(response.objectData.recommendedCopayUnit){
                var newCaseCopayRec = component.get("v.newCaseCopayRec");
                newCaseCopayRec.cde_rec_copay__c = response.objectData.recommendedCopayUnit;
                component.set("v.newCaseCopayRec", newCaseCopayRec);
            }
            if(response.objectData.eligDetail){
                component.set("v.eligRunDate", response.objectData.eligDetail[0].dte_begin_effv__c);  
            }
            console.log('eligibility date--'+component.get("v.eligRunDate"));
            if(response.objectData.householdEligity) {
                var newCaseCopayRec = component.get("v.newCaseCopayRec");
                if(!$A.util.isEmpty(response.objectData.householdEligity.amt_copay_pt__c)){
                    newCaseCopayRec.amt_copay_case_pt__c=response.objectData.householdEligity.amt_copay_pt__c;
                } else {
                    newCaseCopayRec.amt_copay_case_pt__c=0;
                }
                if(!$A.util.isEmpty(response.objectData.householdEligity.amt_copay_ft__c)){
                    newCaseCopayRec.amt_copay_case_ft__c=response.objectData.householdEligity.amt_copay_ft__c;
                    
                } else {
                    newCaseCopayRec.amt_copay_case_ft__c=0;
                }
                component.set("v.newCaseCopayRec", newCaseCopayRec);  
            } else {
                var newCaseCopayRec = component.get("v.newCaseCopayRec");
                newCaseCopayRec.amt_copay_case_pt__c=0;
                newCaseCopayRec.amt_copay_case_ft__c=0;
                component.set("v.newCaseCopayRec", newCaseCopayRec); 
            }
        },{'caseRecId' : component.get("v.recordId")},false, null);
        /* helper.callServerAndHandleError(component,"c.getAuthWeight", function(response){
            if(response.objectData){
                if(response.objectData.recommendedCopayUnit){
                    var newCaseCopayRec = component.get("v.newCaseCopayRec");
                    newCaseCopayRec.cde_rec_copay__c = response.objectData.recommendedCopayUnit;
                    component.set("v.newCaseCopayRec", newCaseCopayRec);
                }
            }
        },{'caseRecId' : component.get("v.recordId")},false, null);*/
        var newCaseCopayObj = component.get("v.newCaseCopayRec");
        if(newCaseCopayObj.cde_rec_copay__c == 'FT'){
            if(newCaseCopayObj.ind_qlty__c =='Y'){
                component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",Math.floor(newCaseCopayObj.amt_copay_case_ft_qlty__c));
                component.set("v.isParentFeeSetDefault",true);
            } else {
                component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",Math.floor(newCaseCopayObj.amt_copay_case_ft__c));
                component.set("v.isParentFeeSetDefault",true);
            }
        } else if(newCaseCopayObj.cde_rec_copay__c == 'PT'){
            if(newCaseCopayObj.ind_qlty__c =='Y'){
                component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",Math.floor(newCaseCopayObj.amt_copay_case_pt_qlty__c));
                component.set("v.isParentFeeSetDefault",true);
            } else {
                component.set("v.newCaseCopayRec.amt_copay_case_assesd__c",Math.floor(newCaseCopayObj.amt_copay_case_pt__c));
                component.set("v.isParentFeeSetDefault",true);
            }
        }
    },
    
    doPrevious : function(component, event, helper) {
        component.set("v.currentTabNumber", component.get("v.currentTabNumber")-1);
        component.set("v.noDataReturnedFromServer",false);
        component.set("v.title",'');
        component.set("v.description",'');
    },
    
    confirmYes : function(component, event, helper){
        var cmp = component.find('cfrmtnModalOnQltyRtdProvider');
        cmp.hideConfirmModal();
        var newCaseCopayRec = component.get("v.newCaseCopayRec");
        var newEffectiveDate =newCaseCopayRec.dte_begin_effv__c;
        var effectiveDate = helper.getDateInUTC(newEffectiveDate);
        if((helper.getDateInUTC(component.get("v.caseCopayRec").dte_begin_effv__c)).getTime() === effectiveDate.getTime() &&
           component.get("v.caseCopayRec").amt_copay_case_assesd__c == component.get("v.newCaseCopayRec").amt_copay_case_assesd__c){
            // Error message condition
            var caseParentFeeMsg = $A.get("$Label.c.ParentFeeErrorMsg");
            helper.fireToast("dismissible","error","",caseParentFeeMsg);
            component.set("v.showSpinner", false);
        } else {
            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
        }
    },
    
    doNext : function(component, event, helper) {
        if(component.get("v.currentTabNumber")==1) {
            var childCmp = component.find("setFutureParentFeePg1");
            childCmp.callValidateCurrentPage();
            if(component.get("v.isCurrentPageValid")==true){
                var caseCopayRec1 = component.get("v.caseCopayRec");
                if(component.get("v.newCaseCopayRec").ind_qlty__c=='Y' &&
                   ((component.get("v.newCaseCopayRec").cde_rec_copay__c=='FT' && component.get("v.newCaseCopayRec").amt_copay_case_ft_qlty__c != component.get("v.newCaseCopayRec").amt_copay_case_assesd__c) 
                    || (component.get("v.newCaseCopayRec").cde_rec_copay__c=='PT' && component.get("v.newCaseCopayRec").amt_copay_case_pt_qlty__c != component.get("v.newCaseCopayRec").amt_copay_case_assesd__c))
                   && 
                   (component.get("v.newCaseCopayRec").amt_copay_case_ft_qlty__c!=0 || component.get("v.newCaseCopayRec").amt_copay_case_pt_qlty__c!=0)){
                    component.set("v.qltyRtdPrvdrFullORPartMessage","A provider affiliated with the case is a high quality provider and qualifies for a discounted parent fee. Would you like to continue with the non-discounted fee?");
                    helper.callModal(component,'cfrmtnModalOnQltyRtdProvider');
                } else {
                    var newCaseCopayRec = component.get("v.newCaseCopayRec");
                    var newEffectiveDate =newCaseCopayRec.dte_begin_effv__c;
                    var effectiveDate = helper.getDateInUTC(newEffectiveDate);
                    if((helper.getDateInUTC(component.get("v.caseCopayRec").dte_begin_effv__c)).getTime() === effectiveDate.getTime() &&
                       component.get("v.caseCopayRec").amt_copay_case_assesd__c == component.get("v.newCaseCopayRec").amt_copay_case_assesd__c){
                        // Error message condition
                        var caseParentFeeMsg = $A.get("$Label.c.ParentFeeErrorMsg");
                        helper.fireToast("dismissible","error","",caseParentFeeMsg);
                        component.set("v.showSpinner", false);
                    } else {
                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                    }
                }
            }
        } else {
            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);    
        }
    },
    
    returnToRecord : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId);
    },
    
    doCancel : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        helper.doDeleteParentFee(component, event, helper);
        helper.goToRecord(recordId);
    },
    
    doFinish : function(component, event, helper) {
        helper.doValidateParentFeeChange(component, event, helper);
    },
    
    doCancelParentFeeChange : function(component, event, helper) {
        // var recordId = component.get("v.recordId");
        // helper.goToRecord(recordId);
        component.set("v.disablecConfirmationModalYesButton", false);
        var cmp = component.find('confirmationModalOnParentFeeChange');
        if(!$A.util.isEmpty(cmp)){
            component.set("v.showSpinner", false);
            cmp.hideConfirmModal();
        }
    },
    
    confirmParentFeeChangeYes : function(component, event, helper) {
        component.set("v.disablecConfirmationModalYesButton", true);
        // var amount = component.get("v.newCaseCopayRec").amt_copay_case_assesd__c;
        // var msg ='The parent fee allocated to child '+amount+' exceeds the cost of care. Please contact the caretaker to determine if it is most beneficial to close their CCCAP case.'
        var msg ='The assessed Parent Fee exceeds the cost of care. Please contact the adult caretaker/teen parent to provide case management and discuss their options.'
        component.set("v.parentFeeExceedPrvPayMsg",msg);
        if(component.get("v.showPrivatePayAmtMsg")){
            component.set("v.disablecConfirmationModalYesButton", false);
            helper.callModal(component,'confirmationModalOnParentFeeExceedPrvPay');
        } else {
            helper.doFinishHlp(component, event, helper);
        }
    },
    
    doCancelParentFeeExceedChange :function(component, event, helper) {
        component.set("v.disablecConfirmationModalYesButton", false);
        var cmp1 = component.find('confirmationModalOnParentFeeChange');
        if(!$A.util.isEmpty(cmp1)){
            component.set("v.showSpinner", false);
            cmp1.hideConfirmModal();
        }
        var cmp = component.find('confirmationModalOnParentFeeExceedPrvPay');
        if(!$A.util.isEmpty(cmp)){
            component.set("v.showSpinner", false);
            cmp.hideConfirmModal();
        }
    },
    
    confirmParentFeeExceedPrvPayYes : function(component, event, helper) {
        component.set("v.disablecConfirmationModalYesButton", true);
        helper.doFinishHlp(component, event, helper);
    }
})