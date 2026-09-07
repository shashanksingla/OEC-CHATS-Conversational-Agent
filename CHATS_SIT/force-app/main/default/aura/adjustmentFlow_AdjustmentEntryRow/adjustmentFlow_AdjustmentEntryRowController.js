({
    doInit : function(component, event, helper) {
        var adjustmentDetail = component.get("v.adjustmentDetail");
        var subPaymentDetail = component.get("v.subPaymentDetail");
        var adjustDetailMap = component.get("v.adjustDetailMap");
        var childCurrentUtilization = component.get("v.childCurrentUtilization");
        var rateTypeOptionsMap = component.get("v.rateTypeOptionsMap");
        var careUnitTypeOptionsMap = component.get("v.careUnitTypeOptionsMap");
        var careLevelOptionsMap = component.get("v.careLevelOptionsMap");
        var rateTypeOptionsCareDateMap = component.get("v.rateTypeOptionsCareDateMap");
        if(rateTypeOptionsCareDateMap != null){
            component.set("v.rateTypeOptions",rateTypeOptionsCareDateMap[subPaymentDetail.ExternalId]);
        }
        //Bug fix 2929
        var adjustmentDetailList = component.get("v.adjustmentDetailList");
        if($A.util.isEmpty(adjustmentDetailList)){
            adjustmentDetail.NBR_HOURS_AUTH_ADJD__c = 0;
            adjustmentDetail.NBR_HOURS_ATTND_ADJD__c = 0;
            adjustmentDetail.IND_OVERRIDE__c= false;
            if($A.util.isEmpty(subPaymentDetail.amt_rate__c)){
                subPaymentDetail.amt_rate__c = 0;
            }
            adjustmentDetail.AMT_PAID_RATE_ADJD__c =0;
            adjustmentDetail.AMT_DETAIL_ADJMT__c = 0;
            if(!$A.util.isEmpty(component.get("v.rateTypeOptions"))){
                adjustmentDetail.CDE_TYPE_RATE_ADJD__c = subPaymentDetail.cde_type_unit_care__c;
            }
            if(component.get("v.slotCntcheckbox") == true){
                if(!$A.util.isEmpty(component.get("v.careUnitTypeOptions"))){
                    adjustmentDetail.CDE_TYPE_UNIT_ADJD__c = subPaymentDetail.cde_time_trdnl__c;
                }
                if(!$A.util.isEmpty(component.get("v.careLevelOptions"))){
                    adjustmentDetail.CDE_CARE_LEVEL_ADJD__c = subPaymentDetail.cde_level_care__c;
                }
            }
            if(!$A.util.isEmpty(rateTypeOptionsMap[subPaymentDetail.cde_type_unit_care__c]))
                subPaymentDetail.cde_type_unit_care__c = rateTypeOptionsMap[subPaymentDetail.cde_type_unit_care__c];
            if(!$A.util.isEmpty(careUnitTypeOptionsMap[subPaymentDetail.cde_time_trdnl__c]))
            	subPaymentDetail.cde_time_trdnl__c = careUnitTypeOptionsMap[subPaymentDetail.cde_time_trdnl__c];
            if(careLevelOptionsMap != null)
                subPaymentDetail.cde_level_care__c = careLevelOptionsMap[subPaymentDetail.cde_level_care__c];
            component.set("v.adjustmentDetail", adjustmentDetail);
            // Showing existing values
        }
        else{
            var rateTypeOptionsMap = component.get("v.rateTypeOptionsMap");
            var map = {};
            for (var p in rateTypeOptionsMap) {
                map[rateTypeOptionsMap[p].label]=rateTypeOptionsMap[p].value;               
            }
            if(subPaymentDetail.amt_slot_paid__c != null){
                adjustmentDetailList[0].AMT_DETAIL_ADJMT__c = adjustmentDetailList[0].AMT_PAID_RATE_ADJD__c - subPaymentDetail.amt_slot_paid__c;
            } else {
            	adjustmentDetailList[0].AMT_DETAIL_ADJMT__c = adjustmentDetailList[0].AMT_PAID_RATE_ADJD__c - subPaymentDetail.amt_rate__c;    
            }
            
            if(!$A.util.isEmpty(map[adjustmentDetailList[0].CDE_TYPE_RATE_ADJD__c])){
                adjustmentDetailList[0].CDE_TYPE_RATE_ADJD__c = map[adjustmentDetailList[0].CDE_TYPE_RATE_ADJD__c];              
            }
            var rateType = adjustmentDetailList[0].CDE_TYPE_RATE_ADJD__c;
            if(rateType == '13' || rateType == '19' || rateType == '25'){
                component.set("v.disableCareLevel", true);           
            } else {
                component.set("v.disableCareLevel", false);
            }
            component.set("v.adjustmentDetail", adjustmentDetailList[0]);
            component.set("v.adjustmentDetailTemp", adjustmentDetailList[0]);
        }

        var existAdjWrap = component.get("v.existAdjWrap")|| {};
        var existingAdj = existAdjWrap[subPaymentDetail.ExternalId] || {};
        component.set("v.existingAdj",existingAdj);

        // firing app event to add to adjustment detail map
        helper.fireEventHlp(component, event, helper);
    },
    fireEvent :function(component, event, helper) {
        var adjustmentDetail = component.get("v.adjustmentDetail");
        if(component.get("v.slotCntcheckbox") == true){
            var rateType = adjustmentDetail.CDE_TYPE_RATE_ADJD__c;
            if(rateType == '13' || rateType == '19' || rateType == '25'){
                if(adjustmentDetail.CDE_CARE_LEVEL_ADJD__c != '8'){
                    adjustmentDetail.CDE_CARE_LEVEL_ADJD__c = '8';
                    component.set("v.adjustmentDetail", adjustmentDetail);
                }
                component.set("v.disableCareLevel", true);           
            } else {
                component.set("v.disableCareLevel", false);
            }
        }
        helper.fireEventHlp(component, event, helper);
    },
    handlecalculateAmountPaid : function(component, event, helper){
        var slotCheckbox = component.get("v.slotCntcheckbox");
        var adjustmentDetail = component.get("v.adjustmentDetail");
        if(adjustmentDetail.Adjustment_Initiated__c == true){
            var adjustmentDetailsMapUpdated = event.getParam('adjustmentDetailsMapUpdated');
            var subPaymentDetail = component.get("v.subPaymentDetail");
            for (var p in adjustmentDetailsMapUpdated) {
                if(subPaymentDetail.ExternalId == p){
                    adjustmentDetail.AMT_PAID_RATE_ADJD__c =  adjustmentDetailsMapUpdated[p].AMT_PAID_RATE_ADJD__c;
                }
            }
            if(!$A.util.isEmpty(adjustmentDetail.AMT_PAID_RATE_ADJD__c)){
                var amtRate = slotCheckbox == true ? subPaymentDetail.amt_slot_paid__c : subPaymentDetail.amt_rate__c;
                if(adjustmentDetail.AMT_PAID_RATE_ADJD__c > amtRate){
                    adjustmentDetail.AMT_DETAIL_ADJMT__c = adjustmentDetail.AMT_PAID_RATE_ADJD__c - amtRate;
                }else{
                    adjustmentDetail.AMT_DETAIL_ADJMT__c =  amtRate - adjustmentDetail.AMT_PAID_RATE_ADJD__c ;
                } 
                for (var p in adjustmentDetailsMapUpdated) {
                    if(subPaymentDetail.ExternalId == p){
                        var ARTFeeAmount = parseFloat(adjustmentDetailsMapUpdated[p].Activity_Fee_Paid__c) + parseFloat(adjustmentDetailsMapUpdated[p].Registration_Fee_Paid__c) + parseFloat(adjustmentDetailsMapUpdated[p].Transportation_Fee_Paid__c);
                        adjustmentDetail.AMT_DETAIL_ADJMT__c =  ARTFeeAmount +adjustmentDetail.AMT_DETAIL_ADJMT__c;
                    }
                }
            }
        }else{
            adjustmentDetail.AMT_DETAIL_ADJMT__c = 0;
            adjustmentDetail.AMT_PAID_RATE_ADJD__c = 0;
            adjustmentDetail.NBR_HOURS_AUTH_ADJD__c = 0;
            adjustmentDetail.NBR_HOURS_ATTND_ADJD__c = 0;
            adjustmentDetail.IND_OVERRIDE__c= false;
        }
        component.set("v.adjustmentDetail",adjustmentDetail);
    },
    validateAdjustmentAmount: function (cmp, event) {
        var validity =true;
        if(cmp.find("adjustAmount")){
            validity = cmp.find("adjustAmount").get("v.validity").valid;
            console.log('--amount validatity---'+validity.valid); //returns true
            cmp.find("adjustAmount").reportValidity();
            
        }
        return validity;
    },
    setARTFeeFlag : function (cmp, event,helper) {
        var adjustmentDetailsARTFeeMap = cmp.get("v.adjustmentDetailsARTFeeMap");
        var adjustmentDetailId = cmp.get("v.adjustmentDetailId");
        var adjustmentDetailTemp = cmp.get("v.adjustmentDetailTemp");
        var adjustmentDetail =cmp.get("v.adjustmentDetail");
       if(adjustmentDetailsARTFeeMap!= null && !$A.util.isEmpty(adjustmentDetailsARTFeeMap) && !$A.util.isEmpty(adjustmentDetailTemp) && !$A.util.isEmpty(adjustmentDetail)){
            for (var p in adjustmentDetailsARTFeeMap) {
                if(p == adjustmentDetailId){
                    if(adjustmentDetailsARTFeeMap[p].Adjustment_Initiated__c ){
                        adjustmentDetailTemp.Adjustment_Initiated__c = true;
                        adjustmentDetail.Adjustment_Initiated__c = true;
                    }else{
                        adjustmentDetailTemp.Adjustment_Initiated__c = false;
                         adjustmentDetail.Adjustment_Initiated__c = false;
                    }
                    cmp.set("v.adjustmentDetailTemp",adjustmentDetailTemp);  
                    cmp.set("v.adjustmentDetail",adjustmentDetail); 
                    
                }
            }
            
        }
        
    },
    
})