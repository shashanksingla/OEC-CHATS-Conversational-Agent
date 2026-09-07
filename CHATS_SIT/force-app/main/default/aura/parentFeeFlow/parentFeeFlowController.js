({
    doInit : function(component, event, helper) {
        
        var currentTabNumber= component.get("v.currentTabNumber");
        component.set("v.existingCopayError",$A.get("$Label.c.Existing_Case_Copay_Error"));
        if (currentTabNumber == '1'){
            component.set("v.updateParFee",true);
        }
        
        if (currentTabNumber == '2'){
            component.set('v.currentTabNumber', 2);
            component.set("v.updateParFee",false);
        }
       
        helper.callServerAndHandleError(component,"c.getInitData", function(response){
        	
            
            if(response.objectData.caseCopayRecord){
                component.set("v.caseCopayRec", response.objectData.caseCopayRecord);
            }
            else if(response.objectData.caseExternalId){
                component.set("v.isFirstCaseCopayRec",true);
                var caseCopayRec = component.get("v.caseCopayRec");
                caseCopayRec.idn_case__c = response.objectData.caseExternalId;
                component.set("v.caseCopayRec", caseCopayRec);
                            }
            if(response.objectData.eligDetail) {
                component.set("v.eligRunDate", response.objectData.eligDetail[0].dte_begin_effv__c);  
            }
            if(response.objectData.householdEligity) {
                var caseCopayRec = component.get("v.caseCopayRec");
                if(!$A.util.isEmpty(response.objectData.householdEligity.amt_copay_pt__c)){
                    caseCopayRec.amt_copay_case_pt__c=response.objectData.householdEligity.amt_copay_pt__c;
                }else{
                    caseCopayRec.amt_copay_case_pt__c=0;
                }
                if(!$A.util.isEmpty(response.objectData.householdEligity.amt_copay_ft__c)){
                    caseCopayRec.amt_copay_case_ft__c=response.objectData.householdEligity.amt_copay_ft__c;
                    
                }else{
                    caseCopayRec.amt_copay_case_ft__c=0;
                }
                component.set("v.caseCopayRec", caseCopayRec);  
            }else{
                var caseCopayRec1 = component.get("v.caseCopayRec");
                caseCopayRec1.amt_copay_case_pt__c=0;
                caseCopayRec1.amt_copay_case_ft__c=0;
                component.set("v.caseCopayRec", caseCopayRec1); 
            }
            if(component.get("v.currentTabNumber")==1) {
                if(response.objectData.futureCaseCopayRecordPresent==true) {
                    component.set("v.existingCopayError",$A.get("$Label.c.Existing_Case_Copay_Error"));
                    helper.callModal(component,"confirmationModalOnExistingCopay");
                }
                else if(response.objectData.pastCaseCopayRecord==true) {
                    component.set("v.existingCopayError",$A.get("$Label.c.Past_Case_Copay_Error"));
                    helper.callModal(component,"confirmationModalOnExistingCopay");
                }
            } 
            
        },{'caseCopayRec' : component.get("v.recordId")},false, null);
        
        component.set('v.prevButtonFlag', component.get("v.showPrevButton"));
       
    },
    doFinish : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var childCmp = component.find("assessParentFee");
        childCmp.callValidateCurrentPage();
        if(component.get("v.isCurrentPageValid")){
        	var effAuthDate = helper.getDateInUTC(childCmp.get('v.effAuthCopayDate'));
           
            var key = effAuthDate.getFullYear()+'-'+(effAuthDate.getMonth()+1)+'-'+effAuthDate.getDate();
           
            
            helper.callServerAndHandleError(component,"c.saveAuthCopay", function(response){
               
                if(response.isSuccessful){
                   
                    helper.goToRecord(recordId);
                }
            },{'wrapLstStr' : JSON.stringify(childCmp.get('v.WrapperList')),
            	'effDtStr':key}, false, null);
        }else{
           
        }
    },
    doCancel : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var recordIdToDelete;
        
        var currentCaseCopayRecord = component.get("v.caseCopayRec");
        if(currentCaseCopayRecord){
           recordIdToDelete = currentCaseCopayRecord.Id; 
        }
        if(component.get("v.isCaseCopayCreated")){
            helper.callServerAndHandleError(component,"c.deleteCaseCopayRecord", function(response){
               helper.goToRecord(recordId);
            },{'caseCopayRec' : recordIdToDelete},false, null);
        }else{
            helper.goToRecord(recordId);
        }
    },      
    doPrevious : function(component, event, helper) {
        component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
    },
    doNext : function(component, event, helper) {
        if(component.get("v.currentTabNumber")==1) {
            var childCmp = component.find("updateParentFee");
            childCmp.callValidateCurrentPage();
          
            
            if(component.get("v.isCurrentPageValid")==true){
                helper.callServerAndHandleError(component,"c.upsertCaseCopay", function(response){
                    
                    component.set("v.isCaseCopayCreated", true);
                    component.set("v.compcaseCopayRecId", response.objectData.caseCopayRecExtIdCreated);
                    component.set("v.caseCopayRec",response.objectData.caseCopayRecCreated);
                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                },{'caseCopayRec' : component.get("v.caseCopayRec"),
                   'parentFee':component.get("v.parentFee"),
                   'effectiveDate':component.get("v.effectiveDate"),
                   'overrideReason':component.get("v.overrideReason"),
                   'isFirstCaseCopayRec':component.get("v.isFirstCaseCopayRec"),
                   'compcaseCopayRecId': component.get("v.isCaseCopayCreated")?component.get("v.compcaseCopayRecId"):null},false, null);
            } 
        }
        else {
            
            component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);    
        }
    },
    returnToRecord : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId);
    }
})