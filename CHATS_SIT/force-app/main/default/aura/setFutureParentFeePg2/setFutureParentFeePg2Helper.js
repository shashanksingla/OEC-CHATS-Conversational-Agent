({
    checkCustomValidations : function(cmp) {
        var isValid = true;
        var firstDayOfNextMonth = this.getFirstDayOfNextMonth();
        var currentDate = this.getDateInUTC(new Date());
        var isSomeAuthTerminated = false;
        var totalAmt = 0;
        var effectiveBeginDateMax = this.getDateInUTC(new Date());
        var authCopayDate;
        var wrapLst = cmp.get('v.authCopayWrapList');
        try {
            for(var i=0; i<wrapLst.length; i++){
                authCopayDate = this.getDateInUTC(wrapLst[i].authCopayEffecBeginDate);
                if($A.util.isEmpty(wrapLst[i].allocatedAuthAmount)){
                    wrapLst[i].errMsg = 'Please enter a value for this field';
                    isValid = false;
                }
                else if(wrapLst[i].allocatedAuthAmount<0){
                    wrapLst[i].errMsg = 'Value must be greater than or equal to 0';
                    isValid = false;
                }
                    else if(wrapLst[i].allocatedAuthAmount%1!=0){
                        wrapLst[i].errMsg = 'Value must be a whole number (no decimal places)';
                        isValid = false;
                    }
                        else{
                            wrapLst[i].errMsg = null;  
                            totalAmt += (Number)(wrapLst[i].allocatedAuthAmount);
                        }
                if(wrapLst[i].authCopayExternalId){
                    if(effectiveBeginDateMax < authCopayDate){
                        effectiveBeginDateMax = authCopayDate;
                        
                    }   
                }
            }
            if(isValid){
                if(((Number)(totalAmt))==((Number)(cmp.get('v.newCaseCopayRec.amt_copay_case_assesd__c')))){
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
            var effAuthCopayDate = this.getDateInUTC(cmp.get('v.newCaseCopayRec.dte_begin_effv__c'));
            cmp.set('v.authCopayWrapList', wrapLst);
        }
        catch (e) {
            console.log("Error Message:"+e.message);
        }
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
        var WrapperList = cmp.get("v.authCopayWrapList");
        var indexInt =fieldIndex;
        console.log('-indexInt---'+indexInt);
        WrapperList[indexInt].allocatedAuthAmount = Math.floor(fieldValue);
        cmp.set('v.authCopayWrapList',WrapperList);
    },
    fetchAuthCopayRecordsHlp :function(component, event, helper) {
        try{
            component.set("v.isSpinner", true);
            component.set("v.authCopayWrapList", []);
            var amount = component.get("v.newCaseCopayRec").amt_copay_case_assesd__c;
            var recommendedCopayUnit =component.get("v.newCaseCopayRec").cde_rec_copay__c;
            var action = component.get('c.getAuthCopayRecords');
            action.setParams({"caseExternalId":component.get("v.caseCopayRec.idn_case__c"),"EffectiveDate": component.get("v.newCaseCopayRec.dte_begin_effv__c"),"caseParentFeeAmt":amount,"recommendedCopayUnit":recommendedCopayUnit});
            action.setCallback(this, function(response) {
                component.set("v.isSpinner", false);
                var res = response.getReturnValue();
                console.log('state: '+response.getState());
                console.log('---'+JSON.stringify(res.objectData));
                if(!$A.util.isEmpty(res.objectData) && !$A.util.isEmpty(res.objectData.title)){
                    component.set("v.noDataReturnedFromServer",true);
                    component.set("v.title",res.objectData.title);
                    component.set("v.description",res.objectData.description);
                }else{
                    component.set("v.authCopayWrapList", res.objectData.caseParentFeeAllocations);
                    var authCopayWrapListCopy =JSON.parse(JSON.stringify( res.objectData.caseParentFeeAllocations));
                    component.set("v.authCopayWrapListCopy",authCopayWrapListCopy );
                    if(!$A.util.isEmpty(res.objectData.privatePayAmtMsg)){
                        component.set("v.showPrivatePayAmtMsg",res.objectData.privatePayAmtMsg)
                    }
                }
            });
            $A.enqueueAction(action);  
        }catch(e){
        component.set("v.isSpinner", false);
            console.log('Exception while getting auth copay record for effective begin date:'+component.get("v.newCaseCopayRec.dte_begin_effv__c"));
        }
    }
})