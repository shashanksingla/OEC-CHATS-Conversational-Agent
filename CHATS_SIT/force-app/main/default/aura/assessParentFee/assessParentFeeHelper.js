({
	getAuthCopayRecords : function(component) {
        var currentDate = new Date().toISOString().slice(0,10);
		var action = component.get('c.getAuthCopayRecords');
        action.setParams({"caseId":component.get("v.caseCopayRec.idn_case__c")});
        action.setCallback(this, function(response) {
            var returnValue = response.getReturnValue();
            if(returnValue!=null && response.getState() === 'SUCCESS'){
                var jsonStr = JSON.stringify(returnValue);
                for(var i=0;i<returnValue.length;i++) {
                    if(returnValue[i].CDE_STATUS_AUTH == 'Terminated' &&
                       returnValue[i].AUTH_Effective_BGN_Date <= currentDate) {
                        component.set("v.validAmount",false);
                        break;
                    }
                }
                component.set("v.WrapperList", returnValue);
            }else if(returnValue!=null && response.getState() === 'ERROR' ){
                var errors = action.getError();
                component.set("v.pageMessages",[errors[0].message]);
                component.set("v.messageType","error");
                component.set("v.recordError", errors[0].message);
            }
        });
        $A.enqueueAction(action);
	},
    checkCustomValidations : function(cmp) {
        var isValid = true;
        var firstDayOfNextMonth = this.getFirstDayOfNextMonth();
        var currentDate = this.getDateInUTC(new Date());
        var isSomeAuthTerminated = false;
        var totalAmt = 0;
        var effectiveBeginDateMax = this.getDateInUTC(new Date());
        var authCopayDate;
        var wrapLst = cmp.get('v.WrapperList');
        for(var i=0; i<wrapLst.length; i++){
            authCopayDate = this.getDateInUTC(wrapLst[i].AUTH_Effective_BGN_Date);
            if(wrapLst[i].AMT_COPAY_AUTH == undefined || wrapLst[i].AMT_COPAY_AUTH =='undefined' || wrapLst[i].AMT_COPAY_AUTH==null){
                wrapLst[i].errMsg = 'Please enter a value for this field';
                isValid = false;
            }
            else if(wrapLst[i].AMT_COPAY_AUTH<0){
                wrapLst[i].errMsg = 'Value must be greater than or equal to 0';
                isValid = false;
            }
            else if(wrapLst[i].AMT_COPAY_AUTH%1!=0){
                wrapLst[i].errMsg = 'Value must be a whole number (no decimal places)';
                isValid = false;
            }
            else{
                wrapLst[i].errMsg = null;  
                totalAmt += (Number)(wrapLst[i].AMT_COPAY_AUTH);
            }
            if(wrapLst[i].authCopayId){
                    if(effectiveBeginDateMax < authCopayDate){
                        effectiveBeginDateMax = authCopayDate;
                        
                    }   
            }
        }
        if(isValid){
            if(((Number)(totalAmt))==((Number)(cmp.get('v.caseCopayRec.amt_copay_case_assesd__c')))){
                cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_FT__c").set("v.message",null);
            }
            else{
                cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_FT__c").set("v.message","Sum of all authorization fee amounts does not equal the total case parent fee");
                isValid = false;
            }
        }
        else{
            cmp.find("batchsit_t_sbsd_case_copay__x-AMT_COPAY_CASE_FT__c").set("v.message",null);
        }
         var effAuthCopayDate = this.getDateInUTC(cmp.get('v.effAuthCopayDate'));
       
        if(cmp.get('v.effAuthCopayDate')=='' || cmp.get('v.effAuthCopayDate')==undefined || cmp.get('v.effAuthCopayDate')==null || cmp.get('v.effAuthCopayDate')=='undefined') {
            cmp.find("batchsit_t_auth_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Please enter a value for this field");
            isValid = false;
        }
        else if((effAuthCopayDate).getDate()!=1){
            cmp.find("batchsit_t_auth_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Invalid Date! Must be 1st day of the month");
            isValid = false;
        }
        else if((effAuthCopayDate)<= currentDate){
            cmp.find("batchsit_t_auth_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Invalid Date! Date must not be before the 1st of next month");
            isValid = false;
        }
        else if((effAuthCopayDate)<= effectiveBeginDateMax){
            cmp.find("batchsit_t_auth_copay__x-DTE_BEGIN_EFFV__c").set("v.message","Please enter an Effective Date that is after the latest assessed authorization parent fee effective date.");
            isValid = false;
        }
        else {
            cmp.find("batchsit_t_auth_copay__x-DTE_BEGIN_EFFV__c").set("v.message",null);
        }
        cmp.set('v.WrapperList', wrapLst);
        return isValid;

    },
    getFirstDayOfNextMonth: function() {
        var now = new Date();
        var current;
        if (now.getMonth() == 11) {
            current = new Date(now.getFullYear() + 1, 0, 1);
        } else {
            current = new Date(now.getFullYear(), now.getMonth() + 1, 1);
        }
        return current;
    },
     getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    checkAmountFieldValidity : function(cmp, fieldIndex, fieldValue) {
        var WrapperList = cmp.get("v.WrapperList");
        var indexInt =fieldIndex;
       
        WrapperList[indexInt].AMT_COPAY_AUTH = Math.floor(fieldValue);
        cmp.set('v.WrapperList',WrapperList);
    }
})