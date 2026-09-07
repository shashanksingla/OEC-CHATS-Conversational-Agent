({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        var isValid = true;
        var isAllAdjusted = true;
        var atleastOneGreater = false, atleastOneLessser = false;
        var adjustment = cmp.get("v.adjustment");
        var subPaymentDetail = cmp.get("v.subPaymentDetails");
        var adjustmentDetailsMap1 = cmp.get("v.adjustmentDetailsMap1");
        var adjustmentDetailRows = cmp.find('AdjustmentEntryRow');
        var adjustmentDetailsARTFeeMap = cmp.get("v.adjustmentDetailsARTFeeMap");
        var childCurrentUtilization = cmp.get("v.childCurrentUtilization");
        cmp.set("v.pageMessages",[]);
        if(adjustmentDetailRows){
            if(adjustmentDetailRows.length>0){
                isValid = adjustmentDetailRows.reduce(function (validSoFar, parentFeeAllocationRow) {
                    return parentFeeAllocationRow.validateEachRow() && validSoFar;
                }, true);
            }else{
                isValid = adjustmentDetailRows.validateEachRow();
            }
        }
        if(isValid){
            var activityError = false;
            var regisError = false;
            var transError = false;
            if(!$A.util.isEmpty(adjustmentDetailsMap1) && !$A.util.isEmpty(childCurrentUtilization) && (adjustment.CDE_TYPE_ADJMT__c =='Claim') ){
                
                for (var p in adjustmentDetailsMap1) {
                    for(var i=0;i<subPaymentDetail.length;i++){
                        if(subPaymentDetail[i].ExternalId == p && adjustmentDetailsMap1[p].Adjustment_Initiated__c==true){
                            var authVal = subPaymentDetail[i].idn_pmt_sub__r.idn_auth__r;
                            if(typeof authVal !== 'undefined'){ //check for vacant slot contract sub payments CCCAP-7579
                                var key = subPaymentDetail[i].idn_pmt_sub__r.idn_auth__r.IDN_CLIENT__r.IDN_EXTNL__c;// +'-'+subPaymentDetail[i].dte_care__c +'-'+subPaymentDetail[i].idn_pmt_sub__r.idn_auth__r.IDN_PROVR__r.External_ID__c;
                                if( !$A.util.isEmpty(childCurrentUtilization[key])){
                                    var currentVal = childCurrentUtilization[key][0];
                                    
                                    if(adjustmentDetailsMap1[p].Activity_Fee_Paid__c >currentVal.amt_act_remaining__c){
                                        isValid =false;
                                        activityError = true;
                                        cmp.set("v.messageType" , "error");
                                        var pageMessages = cmp.get("v.pageMessages");
                                    }
                                    if(adjustmentDetailsMap1[p].Registration_Fee_Paid__c >currentVal.amt_reg_remaining__c){
                                        isValid = false;
                                        regisError= true;
                                        cmp.set("v.messageType" , "error");
                                        var pageMessages = cmp.get("v.pageMessages");
                                    }
                                    if(adjustmentDetailsMap1[p].Transportation_Fee_Paid__c >currentVal.amt_trans_remaining__c){
                                        isValid =false;
                                        transError = true;
                                        cmp.set("v.messageType" , "error");
                                        var pageMessages = cmp.get("v.pageMessages");
                                    }
                                }
                            }
                        }
                    }
                }
                if(!isValid){
                    if(activityError){
                        pageMessages.push("Adjusted Activity Fee should be less than equals to child activity remaining amount.");
                    }
                    if(regisError){
                        pageMessages.push("Adjusted Registration Fee should be less than equals to child Registration remaining amount.");
                    }
                    if(transError){
                        pageMessages.push("Adjusted Transportation Fee should be less than equals to child Transportation remaining amount.");
                    }
                    cmp.set("v.pageMessages", pageMessages);   
                    return isValid;
                }
            }
            if(adjustment.CDE_TYPE_ADJMT__c =='Claim'){
                if(!$A.util.isEmpty(adjustmentDetailsMap1)){
                    for (var p in adjustmentDetailsMap1) {
                        for(var i=0;i<subPaymentDetail.length;i++){
                            if(subPaymentDetail[i].ExternalId == p && subPaymentDetail[i].ind_adjmt__c != 'Y' && adjustmentDetailsMap1[p].Adjustment_Initiated__c==true /*&& adjustmentDetailsMap1[p].IND_OVERRIDE__c*/){
                                isAllAdjusted = false;
                                if(adjustmentDetailsMap1[p].AMT_PAID_RATE_ADJD__c > subPaymentDetail[i].amt_rate__c){
                                    atleastOneGreater = true;
                                    isValid = true;
                                }
                                else if(adjustmentDetailsMap1[p].AMT_PAID_RATE_ADJD__c == subPaymentDetail[i].amt_rate__c){
                                    isValid = true;           
                                }
                                else{
                                    isValid = false;
                                    cmp.set("v.messageType" , "error");
                                    var pageMessages = cmp.get("v.pageMessages");
                                    
                                    if(!$A.util.isEmpty(pageMessages)){
                                        
                                        if(pageMessages.length <1){
                                            pageMessages.push("Adjusted Rate Amount entered must be greater than Rate Paid for claims");
                                        }
                                        else if(activityError || regisError || transError){
                                            pageMessages.push("Adjusted Rate Amount entered must be greater than Rate Paid for claims");
                                        }
                                    }else{
                                        pageMessages.push("Adjusted Rate Amount entered must be greater than Rate Paid for claims");
                                    }
                                    cmp.set("v.pageMessages", pageMessages);   
                                    return isValid;
                                }
                            }
                        }
                    } 
                    if(isAllAdjusted){
                        return true;
                    }
                    else if(isValid && atleastOneGreater){
                        return true;
                    }else{
                        if(!$A.util.isEmpty(pageMessages)){ 
                            cmp.set("v.messageType" , "error");
                            var pageMessages = cmp.get("v.pageMessages");
                        
                            if(pageMessages.length < 1){
                                pageMessages.push("Adjusted Rate Amount entered must be greater than Rate Paid for claims");
                            }
                            cmp.set("v.pageMessages", pageMessages);  
                            return false;
                        }
                    }
                }
            }else if(adjustment.CDE_TYPE_ADJMT__c == "Recovery"){
                for (var p in adjustmentDetailsMap1) {
                    for(var i=0;i<subPaymentDetail.length;i++){
                        if(subPaymentDetail[i].ExternalId == p && subPaymentDetail[i].ind_adjmt__c != 'Y' && adjustmentDetailsMap1[p].Adjustment_Initiated__c==true /*&& adjustmentDetailsMap1[p].IND_OVERRIDE__c*/){
                            isAllAdjusted= false;
                            if(adjustmentDetailsMap1[p].AMT_PAID_RATE_ADJD__c < subPaymentDetail[i].amt_rate__c){
                                atleastOneLessser = true;
                                isValid= true;
                            }
                            else if(adjustmentDetailsMap1[p].AMT_PAID_RATE_ADJD__c == subPaymentDetail[i].amt_rate__c){
                                isValid = true; 
                            } else{
                                isValid = false;
                                cmp.set("v.messageType" , "error");
                                var pageMessages = cmp.get("v.pageMessages");
                                
                                if(!$A.util.isEmpty(pageMessages)){                      
                                    if(pageMessages.length <1){
                                        pageMessages.push("Adjusted Rate Amount entered must be less than Rate Paid for recoveries");
                                    }
                                }else{
                                    pageMessages.push("Adjusted Rate Amount entered must be less than Rate Paid for recoveries");
                                }
                                cmp.set("v.pageMessages", pageMessages);   
                                return isValid;
                            }
                        }
                    }
                } 
                if(isAllAdjusted){
                    return true;
                }
                else if(isValid && atleastOneLessser){
                    return true;
                }else{
                    if(!$A.util.isEmpty(pageMessages)){ 
                        cmp.set("v.messageType" , "error");
                        var pageMessages = cmp.get("v.pageMessages");
                    
                        if(pageMessages.length < 1){
                            pageMessages.push("Adjusted Rate Amount entered must be less than Rate Paid for recoveries");
                        }
                        cmp.set("v.pageMessages", pageMessages);  
                        return false;
                    }
                }
            }
        }else{
            return isValid;
        }
        return isValid;
    },
})