({
	helperMethod : function() {
		
	},
    callModal : function(cmp, modalName) {
        
        var modalCall = cmp.find(modalName);
        if(modalCall){
	        modalCall.openModal();
        }
    },
    
    confirmFinishHlp : function(component, event, helper){
        var adjustment = component.get("v.adjustment");
        var rateTypeOptionsMap = component.get("v.rateTypeOptionsMap");
        var childCmp = component.find("adjustmentFlow_AdjustmentEntry");
        var subPaymentDetail = component.get("v.subPaymentDetails")[0];
        var subPaymentDetails =component.get("v.subPaymentDetails");
        var selectedSubPayment = component.get("v.selectedSubPayment");
        var adjustDetailMap = component.get("v.adjustDetailMap");
        var isCalculateClicked = component.get("v.calculateBtnClicked");
        var adjustmentDetailsMap = component.get("v.adjustmentDetailsMap");
        var sObjectList = [];
        var map ={};
        var adjustedAmount = 0;
        for(var p in rateTypeOptionsMap) {
            map[rateTypeOptionsMap[p].label]=rateTypeOptionsMap[p].value;
        }
        var cmp1 = component.find('confirmationModal_SubPayment_ARTFees');
        if(!$A.util.isEmpty(cmp1)){
            cmp1.hideConfirmModal(); 
        }
        console.log('adjustmentDetailsMap--in finish--'+JSON.stringify(adjustmentDetailsMap));
        if(adjustmentDetailsMap!= null){
            for(var p in adjustmentDetailsMap) {
                var isAdjustedDetail = false;
                for(var j=0;j<subPaymentDetails.length;j++){
                    if(subPaymentDetails[j].ExternalId == p && subPaymentDetails[j].ind_adjmt__c != 'Y' && adjustmentDetailsMap[p].Adjustment_Initiated__c==true){
                        isAdjustedDetail = true;
                        if(subPaymentDetails[j].amt_rate__c == 'undefined'){
                            subPaymentDetails[j].amt_rate__c =0;
                        }
                        if(adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c == 'undefined' || adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c == undefined){
                            adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c =0;
                        }
                        // Bug fix 2930 - adding care date to adjustment detail
                        adjustmentDetailsMap[p].DTE_CARE__c = subPaymentDetails[j].dte_care__c;
                        //adjustmentDetailsMap[p].CDE_TYPE_RATE_ADJD__c = map[adjustmentDetailsMap[p].CDE_TYPE_RATE_ADJD__c];
                        var sub1 = parseFloat(adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c);
                        var sub2 = parseFloat(subPaymentDetails[j].amt_rate__c);
                        var result=0;
                        if(sub1>sub2){
                            result = sub1-sub2;
                        }else{
                            result = sub2-sub1;
                        }
                        var ARTFeeAmount = parseFloat(adjustmentDetailsMap[p].Activity_Fee_Paid__c) + parseFloat(adjustmentDetailsMap[p].Registration_Fee_Paid__c) + parseFloat(adjustmentDetailsMap[p].Transportation_Fee_Paid__c);
                        console.log('ARTFeeAmount---'+ARTFeeAmount);  
                        result =result+ARTFeeAmount;
                        adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c = result;
                        adjustmentDetailsMap[p].IDN_PROG_FNDG__c =subPaymentDetails[j].idn_prog_fndg__c;
                        adjustmentDetailsMap[p].DTE_CARE__c =subPaymentDetails[j].dte_care__c;
                        adjustmentDetailsMap[p].NBR_HOURS_ATNDT_ORIG__c =subPaymentDetails[j].cde_unit_care_actual__c;
                        adjustmentDetailsMap[p].NBR_HOURS_AUTH_ORIG__c =subPaymentDetails[j].cde_unit_care_exptd__c;
                        adjustmentDetailsMap[p].AMT_PAID_RATE_ORIG__c =subPaymentDetails[j].amt_rate__c;
                    }
                }
                if(adjustDetailMap != null){
                    var currentAdjustment = adjustDetailMap[p];
                    if(!$A.util.isEmpty(currentAdjustment)){
                        adjustmentDetailsMap[p].Id = currentAdjustment[0].Id;
                    }
                }
                adjustmentDetailsMap[p].IDN_ADJMT__c = adjustment.Id;
                // adjustmentDetailsMap[p].CDE_TYPE_RATE_ADJD__c = map[adjustmentDetailsMap[p].CDE_TYPE_RATE_ADJD__c];
                adjustmentDetailsMap[p].IDN_DETAIL_PMT_SUB__c =p;
                adjustmentDetailsMap[p].sobjectType ='T_ADJMT_DETAIL__c';
                console.log('adjustmentDetailsMap--just--'+JSON.stringify(adjustmentDetailsMap));
                // Bug fix 3553 - adding code to exclude adjustment detail lines where adjusted amount = 0
                if(adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c > 0 && isAdjustedDetail && adjustmentDetailsMap[p].Adjustment_Initiated__c){
                    sObjectList.push(adjustmentDetailsMap[p]);    
                }
                adjustedAmount= adjustedAmount+adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c;
            }
        }
        console.log('before final save-sObjectList-'+JSON.stringify(sObjectList));
        // Added below logic and 'if' part by Rishav for CCCAP-6051
        var currentAdjAmount = component.get("v.adjustment").AMT_ADJMT__c;
        var newAdjAmount = currentAdjAmount - Math.abs(component.get("v.oldAdjustedAmount")) + adjustedAmount;
        var totalPaidAmount = parseFloat(component.get("v.totalPaidAmount"));
        if(newAdjAmount < totalPaidAmount){
            component.set("v.pageMessages", $A.get("$Label.c.adjustment_error_totalPaidAmount") + " $" + totalPaidAmount.toFixed(2));
            component.set("v.messageType", "error");
        } else {
            // This code section was put inside 'else' by Rishav for CCCAP-6051
            helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
                component.set("v.isARTFeeChanged",false);
                if(response.isSuccessful){
                    var adjustmentId = component.get("v.adjustment").Id;
                    helper.callServerAndHandleError(component,"c.adjustmentDetails", function(response){
                        if(response.objectData.adjustmentDtlWarp){
                            var appEvent = $A.get("e.c:adjustmentDetailSummaryEvent");
                            appEvent.setParams({ "adjustmentDtlWarp" : response.objectData.adjustmentDtlWarp ,"adjustmentAmount":adjustedAmount,"subPaymentDetail":subPaymentDetail, "rateTypeOptions":rateTypeOptionsMap,"selectedSubPayment":selectedSubPayment });
                            appEvent.fire(); 
                            component.find("overlayLib").notifyClose();
                        }else{
                            component.find("overlayLib").notifyClose();
                        }   
                    },{'adjustmentId':adjustmentId}, false, null);
                }
            },{'lstSObject':sObjectList,"isFinalStep":true}, false, null);
        }
    },
    
    confirmDoSaveAndNewHlp : function(component, event, helper){
        var adjustment = component.get("v.adjustment");
        var rateTypeOptionsMap = component.get("v.rateTypeOptionsMap");
        var childCmp = component.find("adjustmentFlow_AdjustmentEntry");
        var subPaymentDetail = component.get("v.subPaymentDetails")[0];
        var subPaymentDetails =component.get("v.subPaymentDetails");
        var selectedSubPayment = component.get("v.selectedSubPayment");
        var adjustmentDetailsMap = component.get("v.adjustmentDetailsMap");
        var adjustDetailMap = component.get("v.adjustDetailMap");
        var isCalculateClicked = component.get("v.calculateBtnClicked");
        var sObjectList = [];
        var map ={};
        var adjustedAmount =0;
        for (var p in rateTypeOptionsMap) {
            map[rateTypeOptionsMap[p]]=p;
        }
	    var cmp1 = component.find('confirmationModal_SubPayment_ARTFeesSaveAndNew');
         
         if(!$A.util.isEmpty(cmp1)){
             cmp1.hideConfirmModal(); 
         }
        if(adjustmentDetailsMap!= null){
            for (var p in adjustmentDetailsMap) {
                if(adjustmentDetailsMap[p].Adjustment_Initiated__c==true){
                    var isAdjustedDetail = false;
                    for(var j=0;j<subPaymentDetails.length;j++){
                        if(subPaymentDetails[j].ExternalId == p && subPaymentDetails[j].ind_adjmt__c != 'Y'){
                            isAdjustedDetail = true;
                            if(subPaymentDetails[j].amt_rate__c == 'undefined'){
                                subPaymentDetails[j].amt_rate__c =0;
                            }
                            if(adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c == 'undefined' || adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c == undefined){
                                adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c =0;
                            }
                            var sub1 = parseFloat(adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c);
                            var sub2 = parseFloat(subPaymentDetails[j].amt_rate__c);
                            var result=0;
                            if(sub1>sub2){
                                result = sub1-sub2;
                            }else{
                                result = sub2-sub1;
                            }
                            var ARTFeeAmount = parseFloat(adjustmentDetailsMap[p].Activity_Fee_Paid__c) +parseFloat(adjustmentDetailsMap[p].Registration_Fee_Paid__c) + parseFloat(adjustmentDetailsMap[p].Transportation_Fee_Paid__c);
                            console.log('ARTFeeAmount--'+ARTFeeAmount);
                            result =result+ARTFeeAmount;
                            adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c = result;
                            adjustmentDetailsMap[p].IDN_PROG_FNDG__c =subPaymentDetails[j].idn_prog_fndg__c;
                            adjustmentDetailsMap[p].DTE_CARE__c =subPaymentDetails[j].dte_care__c;
                            adjustmentDetailsMap[p].NBR_HOURS_ATNDT_ORIG__c =subPaymentDetails[j].cde_unit_care_actual__c;
                            adjustmentDetailsMap[p].NBR_HOURS_AUTH_ORIG__c =subPaymentDetails[j].cde_unit_care_exptd__c;
                            adjustmentDetailsMap[p].AMT_PAID_RATE_ORIG__c =subPaymentDetails[j].amt_rate__c;
                        }                        
                    }
                    if(adjustDetailMap != null){
                        var currentAdjustment = adjustDetailMap[p];
                        if(!$A.util.isEmpty(currentAdjustment)){
                            console.log("---p---for setting ids---"+p);
                            adjustmentDetailsMap[p].Id = currentAdjustment[0].Id;
                        }
                    }
                    adjustmentDetailsMap[p].IDN_ADJMT__c = adjustment.Id;
                    //adjustmentDetailsMap[p].CDE_TYPE_RATE_ADJD__c = map[adjustmentDetailsMap[p].CDE_TYPE_RATE_ADJD__c];
                    adjustmentDetailsMap[p].IDN_DETAIL_PMT_SUB__c =p;
                    adjustmentDetailsMap[p].sobjectType ='T_ADJMT_DETAIL__c';
                    // Bug fix 3553 - adding code to exclude adjustment detail lines where adjusted amount = 0
                    if(adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c > 0 && isAdjustedDetail && adjustmentDetailsMap[p].Adjustment_Initiated__c){
                        sObjectList.push(adjustmentDetailsMap[p]);    
                    }
                    adjustedAmount= adjustedAmount+adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c;
                }
            }   
        }
        helper.callServerAndHandleError(component,"c.upsertRecords", function(response){
		component.set("v.isARTFeeChanged",false);
            component.set("v.calculateBtnClicked",false);
            if(response.isSuccessful){
                var adjustmentId = component.get("v.adjustment").Id;
                helper.callServerAndHandleError(component,"c.adjustmentDetails", function(response){
			if(response.objectData.adjustDetailMap){
                        component.set("v.adjustDetailMap",response.objectData.adjustDetailMap);
                    }
                    if(response.objectData.adjustmentDtlWarp){
                        var appEvent = $A.get("e.c:adjustmentDetailSummaryEvent");
                        appEvent.setParams({ "adjustmentDtlWarp" : response.objectData.adjustmentDtlWarp ,"adjustmentAmount":adjustedAmount,"subPaymentDetail":subPaymentDetail, "rateTypeOptions":rateTypeOptionsMap,"selectedSubPayment":selectedSubPayment });
                        appEvent.fire(); 
                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
                    }  else{
                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
                    } 
                    //START Bug-fix CHATS-5356
                    var mapTemp = {};
                    component.set("v.selectedSubPayment",null);
                    component.set("v.adjustmentDetailList",[]);
                    component.set("v.adjustmentDetailsMap",mapTemp);
                    //END Bug-fix CHATS-5356
                },{'adjustmentId':adjustmentId}, false, null);
            }
            
        },{'lstSObject':sObjectList,"isFinalStep":true}, false, null);
        
        //START Bug-fix CHATS-5356
        component.set("v.selectedSubPayment",null);
        //END Bug-fix CHATS-5356
        
    },

    // Added by Rishav for CCCAP-2873
    validateARTFeeRestriction : function(component){
        var adjustmentDetailsARTFeeMap = component.get("v.adjustmentDetailsARTFeeMap"); // Map type
        var subPaymentDetails = component.get("v.subPaymentDetails"); // List type
        var activeARTFeeRecords = component.get("v.activeARTFeeRecords"); // List type
        var ARTFeeValidationSuccess = true;
        var subPaymentDateMap = new Map();
        
        for(var i=0; i<subPaymentDetails.length; i++){
            subPaymentDateMap.set(subPaymentDetails[i].ExternalId, subPaymentDetails[i].dte_care__c);
        }
        if(subPaymentDateMap && activeARTFeeRecords){
            for(var j in adjustmentDetailsARTFeeMap){
                if(adjustmentDetailsARTFeeMap[j].Adjustment_Initiated__c){
                    var careDateString = subPaymentDateMap.get(j);
                    var careDate = new Date(careDateString);
                    var careMonth = careDate.getMonth() + 1; // 1 = Jan, 12 = Dec
                    for(var k in activeARTFeeRecords){
                        var beginDate = new Date(activeARTFeeRecords[k].IDN_FISCAL_SCH__r.DTE_BEGIN_EFFV__c);
                        var endDate = (activeARTFeeRecords[k].IDN_FISCAL_SCH__r.DTE_END_EFFV__c) ? new Date(activeARTFeeRecords[k].IDN_FISCAL_SCH__r.DTE_END_EFFV__c) : null;
                        if(careDate >= beginDate && (careDate <= endDate || endDate == null)){
                            if(activeARTFeeRecords[k].TXT_ACT_MONTH__c){
                                if(activeARTFeeRecords[k].TXT_ACT_MONTH__c.includes(careMonth) && adjustmentDetailsARTFeeMap[j].Activity_Fee_Paid__c > 0){ 
                                    ARTFeeValidationSuccess = false;
                                }
                            }
                            if(activeARTFeeRecords[k].TXT_REG_MONTH__c){
                                if(activeARTFeeRecords[k].TXT_REG_MONTH__c.includes(careMonth) && adjustmentDetailsARTFeeMap[j].Registration_Fee_Paid__c > 0){ 
                                    ARTFeeValidationSuccess = false;
                                }
                            }
                            if(activeARTFeeRecords[k].TXT_TRANS_MONTH__c){
                                if(activeARTFeeRecords[k].TXT_TRANS_MONTH__c.includes(careMonth) && adjustmentDetailsARTFeeMap[j].Transportation_Fee_Paid__c > 0){ 
                                    ARTFeeValidationSuccess = false;
                                }
                            }
                        }
                    }
                }
            }
        }
        if(!ARTFeeValidationSuccess){ // Any ART fee added for a restricted month
            component.set("v.pageMessages", $A.get("$Label.c.adjustment_error_ARTFee"));
            component.set("v.messageType", "error");
        }
        return  ARTFeeValidationSuccess;
    }
})