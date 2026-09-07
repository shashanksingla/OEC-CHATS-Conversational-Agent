({
    doNext : function(component, event, helper) {
        if(component.get("v.currentTabNumber")==1) {
            var map = {};
            component.set("v.adjustmentDetailsMap",map); 
            if(component.get("v.selectedSubPayment")){
                helper.callServerAndHandleError(component,"c.doSearchSubPaymentDetails", function(response){
                    if(response.objectData.subPaymentDetails){
                        component.set("v.subPaymentDetails", response.objectData.subPaymentDetails);    
                    }
                    if(response.objectData.existAdjWrap){
                        component.set("v.existAdjWrap", response.objectData.existAdjWrap);   
                    }
                    if(response.objectData.rateTypeOptions){
                        component.set("v.rateTypeOptions", response.objectData.rateTypeOptions);    
                    }
                    if(response.objectData.rateTypeOptionsMap){
                        component.set("v.rateTypeOptionsMap", response.objectData.rateTypeOptionsMap);  
                    }
                    if(response.objectData.currentUtilizationMap){
                        component.set("v.childCurrentUtilization", response.objectData.currentUtilizationMap);  
                    }
                    if(response.objectData.careUnitTypeOptions){
                        component.set("v.careUnitTypeOptions", response.objectData.careUnitTypeOptions);  
                    }
                    if(response.objectData.careUnitTypeOptionsMap){
                        component.set("v.careUnitTypeOptionsMap", response.objectData.careUnitTypeOptionsMap);  
                    }
                    if(response.objectData.careLevelOptions){
                        component.set("v.careLevelOptions", response.objectData.careLevelOptions);  
                    }
                    if(response.objectData.careLevelOptionsMap){
                        component.set("v.careLevelOptionsMap", response.objectData.careLevelOptionsMap);  
                    }
                    if(response.objectData.rateTypeOptionsCareDateMap){
                        component.set("v.rateTypeOptionsCareDateMap", response.objectData.rateTypeOptionsCareDateMap);  
                    }
                    if(response.objectData.activeARTFeeRecords) { // Added by Rishav for CCCAP-2873
                        component.set("v.activeARTFeeRecords", response.objectData.activeARTFeeRecords);  
                    }
                    if(response.objectData.error){
                        component.set("v.pageMessages",[response.objectData.error]);
                        component.set("v.messageType","error");
                    }
                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                    if(component.get("v.currentTabNumber") == 1){
                        component.set("v.tabHeaderTitle","Select a sub payment  record for the child  and service period which the adjustment is applied for.");
                        component.set("v.tabHeaderName","Sub Payment Selection");
                    }
                    if(component.get("v.currentTabNumber") == 2){
                        component.set("v.tabHeaderTitle","");
                        component.set("v.tabHeaderName","Sub Payment Details");
                    }
                }, {'subPaymentId':component.get("v.selectedSubPayment").subPymtId,'selectedSubPayment':JSON.stringify(component.get("v.selectedSubPayment")),'adjustmentInfo':component.get("v.adjustment")}, false, null);   
            }else{
                component.set("v.pageMessages","Please select sub payment record");
                component.set("v.messageType","error");
            }
        }
    },
    
    handlecreateAdjustDetails : function(component, event, helper) {
        var adjustmentDetailObj = event.getParam("adjustmentDetailObj");
        var adjustmentDetailTemp = event.getParam("adjustmentDetailTemp");
        var mapkey = event.getParam("key");
        var isARTFee = event.getParam("isARTFee");
        
        if(!isARTFee){
            var map = {};
            var adjustmentDetailsMap = component.get("v.adjustmentDetailsMap"); 
            if(adjustmentDetailsMap != null){
                for (var p in adjustmentDetailsMap) {
                    map[p]= adjustmentDetailsMap[p];
                    if(adjustmentDetailsMap.hasOwnProperty(p) ) {
                        if(p==mapkey){
                            map[p]= adjustmentDetailsMap[p];
                        }
                    } 
                }   
                map[mapkey] = adjustmentDetailObj;
                component.set("v.adjustmentDetailsMap",map); 
            }else{                
                map[mapkey]=adjustmentDetailObj;
                component.set("v.adjustmentDetailsMap",map); 
            } 
            var adjustmentDetailsARTFeeMap = component.get("v.adjustmentDetailsARTFeeMap");
            if(adjustmentDetailObj!= null && adjustmentDetailsARTFeeMap != null && !$A.util.isEmpty(adjustmentDetailsARTFeeMap) && !$A.util.isEmpty(adjustmentDetailObj) && !$A.util.isEmpty(adjustmentDetailsARTFeeMap[mapkey])){
                
                if(adjustmentDetailObj.Adjustment_Initiated__c){
                    adjustmentDetailsARTFeeMap[mapkey].Adjustment_Initiated__c = adjustmentDetailObj.Adjustment_Initiated__c;
                }else{
                    adjustmentDetailsARTFeeMap[mapkey].Adjustment_Initiated__c = adjustmentDetailObj.Adjustment_Initiated__c;
                }
                
                component.set("v.adjustmentDetailsARTFeeMap",adjustmentDetailsARTFeeMap);
            }
        }
        else{           
            var mapARTFee = {};
            var adjustmentDetailsARTFeeMap= component.get("v.adjustmentDetailsARTFeeMap"); 
            if(adjustmentDetailsARTFeeMap!= null){
                for (var p in adjustmentDetailsARTFeeMap) {
                    mapARTFee[p]= adjustmentDetailsARTFeeMap[p];
                    if( adjustmentDetailsARTFeeMap.hasOwnProperty(p) ) {
                        if(p==mapkey){
                            mapARTFee[p]= adjustmentDetailsARTFeeMap[p];
                            component.set("v.isARTFeeCalculated",true);
                        }
                    } 
                }   
                mapARTFee[mapkey]= adjustmentDetailTemp;
                component.set("v.adjustmentDetailsARTFeeMap",mapARTFee); 
            }else{
                component.set("v.isARTFeeCalculated",true);
                mapARTFee[mapkey]=adjustmentDetailTemp;
                component.set("v.adjustmentDetailsARTFeeMap",mapARTFee); 
            } 
            var adjustmentDetailsARTFeeMap = component.get("v.adjustmentDetailsARTFeeMap");
            if(adjustmentDetailTemp!= null && adjustmentDetailsARTFeeMap != null && !$A.util.isEmpty(adjustmentDetailsARTFeeMap) && !$A.util.isEmpty(adjustmentDetailTemp) && !$A.util.isEmpty(adjustmentDetailsARTFeeMap[mapkey])){
                
                if(adjustmentDetailTemp.Adjustment_Initiated__c){
                    adjustmentDetailsARTFeeMap[mapkey].Adjustment_Initiated__c = adjustmentDetailTemp.Adjustment_Initiated__c;
                }else{
                    adjustmentDetailsARTFeeMap[mapkey].Adjustment_Initiated__c = adjustmentDetailTemp.Adjustment_Initiated__c;
                }
                
                component.set("v.adjustmentDetailsARTFeeMap",adjustmentDetailsARTFeeMap);
            }
        }
        component.set("v.calculateBtnClicked",false);
    },
    
    doPrevious : function(component, event, helper) {
        //START Bug-fix CHATS-5356
        var map = {};
        component.set("v.isARTFeeCalculated",false);
        component.set("v.isARTFeeChanged",false);
        component.set("v.isFirstCalculate",false);
        component.set("v.adjustmentDetailList",[]);
        component.set("v.adjustmentDetailsMap",map);
        component.set("v.adjustmentDetailsARTFeeMap",map);
        component.set("v.adjustmentDetailsMapClone",map);
        component.set("v.adjustDetailMapClone",map);
        component.set("v.selectedSubPayment",null);
        component.set("v.pageMessages",[]); 
        //END Bug-fix CHATS-5356
        if(component.get("v.currentTabNumber") == 1){
            component.set("v.tabHeaderTitle","Select a sub payment record for the child  and service period which the adjustment is applied for.");
            component.set("v.tabHeaderName","Sub Payment Selection");
        }
        if(component.get("v.currentTabNumber") == 2){
            component.set("v.tabHeaderTitle","");
            component.set("v.tabHeaderName","Sub Payment Details");
        }
        helper.callModal(component,'confirmationModal_SubPayment_Previous');
    },
    
    doCancel : function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        helper.callModal(component,'confirmationModal_SubPayment_EntryModal_'+currentTabNumber);
    },
    
    doSearch : function(component, event, helper) {
        var slotCheckbox = component.get("v.searchBySlotCntId");
        var errorMsg ="Over "+$A.get("$Label.c.Subpayment_Search_Limit") +" records have been returned, please refine the search criteria";
        component.set("v.errorMessageText",errorMsg);
        component.set("v.subPaymentSearchLst",[]);
        var adjustment = component.get("v.adjustment")
        if(!$A.util.isEmpty(adjustment.IDN_CASE__c)){
            if(!$A.util.isEmpty(component.get("v.caseId"))){
                if(component.get("v.caseId") != adjustment.IDN_CASE__c){
                    var pageMessages = component.get("v.pageMessages");
                    if(!$A.util.isEmpty(pageMessages)){
                        console.log('pageMessages---'+pageMessages.length);
                        if(pageMessages.length <1){
                            pageMessages.push("Adjustment case cannot can not match with selected Case Id.");
                        }
                    }else{
                        pageMessages.push("Adjustment case cannot can not match with selected Case Id.");
                    }                 
                    component.set("v.pageMessages",pageMessages);
                    component.set("v.messageType","error");
                }else{
                    
                    //paymentObjId, String subPaymentObjId, String subPaymentObjNAMFIRST, String servicePeriodObjDTEBEGINEFFV, String subPaymentObjNAMLAST, String servicePeriodObjDTEENDEFFV
                    helper.callServerAndHandleError(component,"c.doSearchSubPayment", function(response){
                        component.set("v.slotCntcheckbox", slotCheckbox);
                        //    component.set("v.subPaymentSearchLst",response.objectData.SubpaymentSearchResults);
                        var newResult=response.objectData.SubpaymentSearchResults || [];
                        if(slotCheckbox==true)
                        {   
                            newResult=newResult.filter(x => x.slotCountySFID==adjustment.CDE_COUNTY__c);
                            console.log('newResult -> '+JSON.stringify(newResult));
                        }
                        component.set("v.subPaymentSearchLst",newResult); 
                        
                        
                    }, {'paymentObjId':component.get("v.paymentObjId"),
                        'subPaymentObjId':component.get("v.subPaymentObj_Id"),
                        'subPaymentObjNAMFIRST':component.get("v.subPaymentObj_NAM_FIRST"),
                        'servicePeriodObjDTEBEGINEFFV':component.get("v.servicePeriodObj_DTE_BEGIN_EFFV"),
                        'subPaymentObjNAMLAST':component.get("v.subPaymentObj_NAM_LAST"),
                        'servicePeriodObjDTEENDEFFV':component.get("v.servicePeriodObj_DTE_END_EFFV"),
                        'adjustmentInfo': component.get("v.adjustment"),
                        'selectedAuthId': component.get("v.authId"),
                        'selectedCaseId': component.get("v.caseId"),
                        'selectedSlotCntId': component.get("v.slotCntId"),
                        'slotCntcheckbox': slotCheckbox
                       }, false, null);
                }
            }else{
                component.set("v.subPaymentSearchLst",[]);
                //paymentObjId, String subPaymentObjId, String subPaymentObjNAMFIRST, String servicePeriodObjDTEBEGINEFFV, String subPaymentObjNAMLAST, String servicePeriodObjDTEENDEFFV
                helper.callServerAndHandleError(component,"c.doSearchSubPayment", function(response){
                    component.set("v.slotCntcheckbox", slotCheckbox);
                    //  component.set("v.subPaymentSearchLst",response.objectData.SubpaymentSearchResults);
                    var newResult=response.objectData.SubpaymentSearchResults || [];
                    if(slotCheckbox==true)
                    {
                        newResult=newResult.filter(x => x.slotCountySFID==adjustment.CDE_COUNTY__c);
                        console.log('newResult -> '+JSON.stringify(newResult));
                    }
                    component.set("v.subPaymentSearchLst",newResult); 
                }, {'paymentObjId':component.get("v.paymentObjId"),
                    'subPaymentObjId':component.get("v.subPaymentObj_Id"),
                    'subPaymentObjNAMFIRST':component.get("v.subPaymentObj_NAM_FIRST"),
                    'servicePeriodObjDTEBEGINEFFV':component.get("v.servicePeriodObj_DTE_BEGIN_EFFV"),
                    'subPaymentObjNAMLAST':component.get("v.subPaymentObj_NAM_LAST"),
                    'servicePeriodObjDTEENDEFFV':component.get("v.servicePeriodObj_DTE_END_EFFV"),
                    'adjustmentInfo': component.get("v.adjustment"),
                    'selectedAuthId': component.get("v.authId"),
                    'selectedCaseId': component.get("v.caseId"),
                    'selectedSlotCntId': component.get("v.slotCntId"),
                    'slotCntcheckbox': slotCheckbox
                   }, false, null);
            }
        }else{
            component.set("v.subPaymentSearchLst",[]);
            //paymentObjId, String subPaymentObjId, String subPaymentObjNAMFIRST, String servicePeriodObjDTEBEGINEFFV, String subPaymentObjNAMLAST, String servicePeriodObjDTEENDEFFV
            helper.callServerAndHandleError(component,"c.doSearchSubPayment", function(response){
                component.set("v.slotCntcheckbox", slotCheckbox);
                //    component.set("v.subPaymentSearchLst",response.objectData.SubpaymentSearchResults);
                var newResult=response.objectData.SubpaymentSearchResults || [];
                if(slotCheckbox==true)
                {
                    newResult=newResult.filter(x => x.slotCountySFID==adjustment.CDE_COUNTY__c);
                    console.log('newResult -> '+JSON.stringify(newResult));
                }
                component.set("v.subPaymentSearchLst",newResult); 
            }, {'paymentObjId':component.get("v.paymentObjId"),
                'subPaymentObjId':component.get("v.subPaymentObj_Id"),
                'subPaymentObjNAMFIRST':component.get("v.subPaymentObj_NAM_FIRST"),
                'servicePeriodObjDTEBEGINEFFV':component.get("v.servicePeriodObj_DTE_BEGIN_EFFV"),
                'subPaymentObjNAMLAST':component.get("v.subPaymentObj_NAM_LAST"),
                'servicePeriodObjDTEENDEFFV':component.get("v.servicePeriodObj_DTE_END_EFFV"),
                'adjustmentInfo': component.get("v.adjustment"),
                'selectedAuthId': component.get("v.authId"),
                'selectedCaseId': component.get("v.caseId"),
                'selectedSlotCntId': component.get("v.slotCntId"),
                'slotCntcheckbox': slotCheckbox
               }, false, null);
        }        
    },
    
    doHandleTabNumberChange : function(component, event, helper){
        if(component.get("v.currentTabNumber")==2){
            component.set("v.calculateBtn",true);
            component.set("v.showCustomButton",true);
        }
        if(component.get("v.currentTabNumber")==1){
            component.set("v.calculateBtn",false);
            component.set("v.showCustomButton",false);
        }
    },
    
    confirmPrevious : function(component, event, helper){
        var map = {};
        component.set("v.adjustmentDetailList",[]);
        component.set("v.adjustmentDetailsMap",map);
        component.set("v.subPaymentDetails",[]);
        component.set("v.adjustmentDetailsMapClone",map);
        component.set("v.adjustDetailMapClone",map);
        component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
        // component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
    },
    
    confirmCancel : function(component, event, helper){
        component.find("overlayLib").notifyClose();	
        // component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
    },
    
    // Onclick of calculate button
    doCalculate : function(component, event, helper) {
        //paymentObjId, String subPaymentObjId, String subPaymentObjNAMFIRST, String servicePeriodObjDTEBEGINEFFV, String subPaymentObjNAMLAST, String servicePeriodObjDTEENDEFFV
        /* helper.callServerAndHandleError(component,"c.createAdjustDetailRecord", function(response){
            component.set("v.upsertRecords",response.objectData.SubpaymentSearchResults);
        }, {'selectedSubPayment':component.get("v.selectedSubPayment"),
            'adjustment':component.get("v.adjustment"),
            'subPaymentDetails':component.get("v.subPaymentDetails"),
            'adjustmentDetail':component.get("v.adjustmentDetail")
           }, false, null); */
        var rateTypeOptionsMap = component.get("v.rateTypeOptionsMap");
        var map ={};
        for (var p in rateTypeOptionsMap) {
            map[rateTypeOptionsMap[p].label]=rateTypeOptionsMap[p].value;
        }
        component.set("v.isARTFeeChanged",false);
        var isARTFeesAdjusted = false;
        var adjustDetailMap = component.get("v.adjustDetailMap");
        
        var adjustmentDetailsARTFeeMap = component.get("v.adjustmentDetailsARTFeeMap");
        if(!component.get("v.isFirstCalculate")){           
            if(component.get("v.adjustmentDetailsMap")!= null && !$A.util.isEmpty(component.get("v.adjustmentDetailsMap")) && !$A.util.isEmpty(adjustmentDetailsARTFeeMap)){
                var adjustmentDetailsMapCopy = JSON.parse(JSON.stringify( component.get("v.adjustmentDetailsMap")));
                component.set("v.adjustmentDetailsMapClone",adjustmentDetailsMapCopy);
            }
            if(!$A.util.isEmpty(adjustDetailMap)){             
                if($A.util.isEmpty(component.get("v.adjustmentDetailsMap"))){
                    var map2 = {};
                    for (var p in adjustDetailMap) {
                        map2[p]=adjustDetailMap[p][0];
                    }
                    component.set("v.adjustmentDetailsMapClone",JSON.parse(JSON.stringify(map2)));
                }
                var adjustDetailMapCopy =JSON.parse(JSON.stringify(component.get("v.adjustDetailMap")));
                component.set("v.adjustDetailMapClone",adjustDetailMapCopy);                 
            }
            component.set("v.isFirstCalculate",true);
        }
        var adjustmentDetailsMapClone = component.get("v.adjustmentDetailsMapClone");
        var adjustDetailMapClone = component.get("v.adjustDetailMapClone");
        if(component.get("v.adjustmentDetailsMap")!= null && !$A.util.isEmpty(component.get("v.adjustmentDetailsMap")) && !$A.util.isEmpty(adjustmentDetailsARTFeeMap)){
            var adjustmentDetailsMap = component.get("v.adjustmentDetailsMap");
            
            for (var p in adjustmentDetailsMap) {
                if(adjustmentDetailsMap[p].Adjustment_Initiated__c){
                    if(!$A.util.isEmpty(adjustmentDetailsMapClone) && component.get("v.isFirstCalculate") && !$A.util.isEmpty(adjustmentDetailsARTFeeMap[p]) &&  !$A.util.isEmpty(adjustmentDetailsMapClone[p])){
                        if((parseFloat(adjustmentDetailsARTFeeMap[p].Transportation_Fee_Paid__c) != parseFloat(adjustmentDetailsMapClone[p].Transportation_Fee_Paid__c)) || (parseFloat(adjustmentDetailsARTFeeMap[p].Registration_Fee_Paid__c) != parseFloat(adjustmentDetailsMapClone[p].Registration_Fee_Paid__c)) || (parseFloat(adjustmentDetailsARTFeeMap[p].Activity_Fee_Paid__c) != parseFloat(adjustmentDetailsMapClone[p].Activity_Fee_Paid__c))){
                            isARTFeesAdjusted = true;
                            component.set("v.isARTFeeChanged",true);
                        }  
                    }
                    adjustmentDetailsMap[p].Transportation_Fee_Paid__c = adjustmentDetailsARTFeeMap[p].Transportation_Fee_Paid__c;
                    adjustmentDetailsMap[p].Registration_Fee_Paid__c = adjustmentDetailsARTFeeMap[p].Registration_Fee_Paid__c;
                    adjustmentDetailsMap[p].Activity_Fee_Paid__c = adjustmentDetailsARTFeeMap[p].Activity_Fee_Paid__c;
                    //adjustmentDetailsMap[p].Adjustment_Initiated__c  =  adjustmentDetailsARTFeeMap[p].Adjustment_Initiated__c;                    
                }
                else if(adjustmentDetailsARTFeeMap[p].Adjustment_Initiated__c ){
                    if(!$A.util.isEmpty(adjustmentDetailsMapClone) && component.get("v.isFirstCalculate")  && !$A.util.isEmpty(adjustmentDetailsARTFeeMap[p]) &&  !$A.util.isEmpty(adjustmentDetailsMapClone[p])){
                        if((parseFloat(adjustmentDetailsARTFeeMap[p].Transportation_Fee_Paid__c) != parseFloat(adjustmentDetailsMapClone[p].Transportation_Fee_Paid__c)) || (parseFloat(adjustmentDetailsARTFeeMap[p].Registration_Fee_Paid__c) != parseFloat(adjustmentDetailsMapClone[p].Registration_Fee_Paid__c)) || (parseFloat(adjustmentDetailsARTFeeMap[p].Activity_Fee_Paid__c) != parseFloat(adjustmentDetailsMapClone[p].Activity_Fee_Paid__c))){
                            isARTFeesAdjusted = true;
                            component.set("v.isARTFeeChanged",true);
                        }  
                    }
                    adjustmentDetailsMap[p].Transportation_Fee_Paid__c = adjustmentDetailsARTFeeMap[p].Transportation_Fee_Paid__c;
                    adjustmentDetailsMap[p].Registration_Fee_Paid__c = adjustmentDetailsARTFeeMap[p].Registration_Fee_Paid__c;
                    adjustmentDetailsMap[p].Activity_Fee_Paid__c = adjustmentDetailsARTFeeMap[p].Activity_Fee_Paid__c;
                    adjustmentDetailsMap[p].Adjustment_Initiated__c  =  adjustmentDetailsARTFeeMap[p].Adjustment_Initiated__c;
                }
            }
            component.set("v.adjustmentDetailsMap",adjustmentDetailsMap);
        }
        else if(!$A.util.isEmpty(adjustDetailMap) && $A.util.isEmpty(component.get("v.adjustmentDetailsMap")) && !$A.util.isEmpty(adjustmentDetailsARTFeeMap)){
            var i=0;           
            var map1 = {};
            for (var p in adjustDetailMap) {                
                if(!$A.util.isEmpty(adjustDetailMap[p][0]) && adjustDetailMap[p][0].Adjustment_Initiated__c==true && adjustmentDetailsARTFeeMap.hasOwnProperty(p)){
                    adjustDetailMapClone = component.get("v.adjustDetailMapClone");
                    if(!$A.util.isEmpty(adjustDetailMapClone) && component.get("v.isFirstCalculate")  && !$A.util.isEmpty(adjustmentDetailsARTFeeMap[p]) &&  !$A.util.isEmpty(adjustDetailMapClone[p][0])){
                        
                        if((parseFloat(adjustmentDetailsARTFeeMap[p].Transportation_Fee_Paid__c) != parseFloat(adjustDetailMapClone[p][0].Transportation_Fee_Paid__c)) || (parseFloat(adjustmentDetailsARTFeeMap[p].Registration_Fee_Paid__c) != parseFloat(adjustDetailMapClone[p][0].Registration_Fee_Paid__c)) || (parseFloat(adjustmentDetailsARTFeeMap[p].Activity_Fee_Paid__c) != parseFloat(adjustDetailMapClone[p][0].Activity_Fee_Paid__c))){
                            isARTFeesAdjusted = true;
                            component.set("v.isARTFeeChanged",true);
                        } 
                    }
                    adjustDetailMap[p][0].Transportation_Fee_Paid__c = adjustmentDetailsARTFeeMap[p].Transportation_Fee_Paid__c;
                    adjustDetailMap[p][0].Registration_Fee_Paid__c = adjustmentDetailsARTFeeMap[p].Registration_Fee_Paid__c;
                    adjustDetailMap[p][0].Activity_Fee_Paid__c = adjustmentDetailsARTFeeMap[p].Activity_Fee_Paid__c;
                    adjustDetailMap[p][0].Adjustment_Initiated__c = adjustmentDetailsARTFeeMap[p].Adjustment_Initiated__c;
                    adjustDetailMap[p][0].CDE_TYPE_RATE_ADJD__c = map[adjustDetailMap[p][0]];
                    map1[p]=adjustDetailMap[p][0];
                }
                i++;
            }
            component.set("v.adjustmentDetailsMap",map1);
        }
        var adjustmentDetailsMap = component.get("v.adjustmentDetailsMap");
        var adjustmentDetail = [];
        var sObjectList = [];
        var wrappers = new Array();
        var selectedSubPayment = component.get("v.selectedSubPayment");
        var adjustment = component.get("v.adjustment");
        var subPaymentDetails = component.get("v.subPaymentDetails");
        var adjustmentWrapper = component.get("v.adjustDlWarpper");
        var oldAdjustedAmount = 0;
        if(adjustmentDetailsMap != null){
            for (var p in adjustmentDetailsMap) {
                if(adjustmentDetailsMap[p].Adjustment_Initiated__c){
                    // Added below 'oldAdjustedAmount' logic by Rishav for CCCAP-6051
                    if(adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c != 'undefined' && adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c != undefined && adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c != null){
                        oldAdjustedAmount = oldAdjustedAmount + adjustmentDetailsMap[p].AMT_DETAIL_ADJMT__c;
                    }
                    for(var j=0;j<subPaymentDetails.length;j++){
                        if(subPaymentDetails[j].ExternalId == p){
                            if(adjustmentDetailsMap[p].IND_OVERRIDE__c != true){
                                var wrapper = {'subPaymentDetails' :subPaymentDetails[j],'ajustmentDetails' :adjustmentDetailsMap[p]};
                                wrappers.push(wrapper);
                            }
                        }
                    }
                    sObjectList.push(adjustmentDetailsMap[p]);
                }
            }   
        }
        if(component.get("v.isOldAdjustedAmountSet") == false){ // Added by Rishav for CCCAP-6051
            component.set("v.oldAdjustedAmount", oldAdjustedAmount);
            component.set("v.isOldAdjustedAmountSet", true);
        }
        // Added by Rishav for CCCAP-2873
        var ARTFeeValidationSuccess = helper.validateARTFeeRestriction(component);
        if(!ARTFeeValidationSuccess){
            return;
        }
        helper.callServerAndHandleError(component,"c.calculateAdjustDetail", function(response){
            component.set("v.calculateBtnClicked",true);
            var rateTypeOptionsMap = component.get("v.rateTypeOptionsMap");
            if(response.objectData.adjustmentDetailUpdated){
                component.set("v.adjustmentDetailList",response.objectData.adjustmentDetailUpdated);                
            }
            if(response.objectData.totalPaidAmount){ // Added by Rishav for CCCAP-6051
                component.set("v.totalPaidAmount",response.objectData.totalPaidAmount);                
            }
            if(response.objectData.listToUpdated){
                var updatedList = response.objectData.listToUpdated;
                if(adjustmentDetailsMap != null){
                    for (var p in adjustmentDetailsMap) {
                        for(var j=0;j<updatedList.length;j++){
                            if(updatedList[j].subPaymentDetails.ExternalId == p){
                                adjustmentDetailsMap[p] = updatedList[j].ajustmentDetails; 
                                // adjustmentDetailsMap[p].CDE_TYPE_RATE_ADJD__c = rateTypeOptionsMap[adjustmentDetailsMap[p].CDE_TYPE_RATE_ADJD__c];
                            }
                        }
                    }   
                }
            }
            component.set("v.adjustmentDetailsMap",adjustmentDetailsMap);
            var appEvent = $A.get("e.c:calculateAmountRateEvent");
            appEvent.setParams({ "adjustmentDetailsMapUpdated" : component.get("v.adjustmentDetailsMap")});
            appEvent.fire();            
        },{'selectedSubPayment':JSON.stringify(selectedSubPayment),'adjustment':adjustment,'subPaymentDetails':subPaymentDetails,'adjustmentDetail':adjustmentDetail,'adjustmentWrap':JSON.stringify(wrappers)}, false, null);
    },
    
    doSaveAndNew :function(component, event, helper) {
        var adjustment = component.get("v.adjustment");
        var rateTypeOptionsMap = component.get("v.rateTypeOptionsMap");
        var childCmp = component.find("adjustmentFlow_AdjustmentEntry");
        var subPaymentDetail = component.get("v.subPaymentDetails")[0];
        var subPaymentDetails =component.get("v.subPaymentDetails");
        var selectedSubPayment = component.get("v.selectedSubPayment");
        var adjustmentDetailsMap = component.get("v.adjustmentDetailsMap");
        var adjustDetailMap = component.get("v.adjustDetailMap");
        var isCalculateClicked = component.get("v.calculateBtnClicked");
        if(isCalculateClicked){
            var isSave = childCmp.callValidateCurrentPage();
            if(adjustment.CDE_TYPE_ADJMT__c == "Recovery" && adjustmentDetailsMap!= null){
                for (var p in adjustmentDetailsMap) {
                    for(var j=0;j<subPaymentDetails.length;j++){
                        if(subPaymentDetails[j].ExternalId == p && subPaymentDetails[j].ind_adjmt__c != 'Y' && adjustmentDetailsMap[p].Adjustment_Initiated__c){
                            if(adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c<subPaymentDetails[j].amt_copay__c){
                                var pageMessages = component.get("v.pageMessages");
                                if(!$A.util.isEmpty(pageMessages)){
                                    console.log('pageMessages---'+pageMessages.length);
                                    if(pageMessages.length <1){
                                        pageMessages.push("Adjusted Rate Amount cannot be less than Parent Fee");
                                    }
                                }else{
                                    pageMessages.push("Adjusted Rate Amount cannot be less than Parent Fee");
                                }
                                //pageMessages.push("Adjusted Rate Amount cannot be less than Parent Fee");
                                component.set("v.pageMessages",pageMessages);
                                component.set("v.messageType","error");
                                isSave = false;
                                break;
                            }
                        }
                    }
                }
            }
            
            if(isSave){
                if(component.get("v.isARTFeeChanged")){
                    helper.callModal(component,'confirmationModal_SubPayment_ARTFeesSaveAndNew');
                }else{
                    helper.confirmDoSaveAndNewHlp(component, event, helper);
                }
            }
        } else{
            component.set("v.pageMessages",["Please click on Calculate before saving records."]);
            component.set("v.messageType","error");
        }
    },
    
    confirmDoSaveAndNew : function(component, event, helper){
        helper.confirmDoSaveAndNewHlp(component, event, helper);
    },
    
    confirmFinish : function(component, event, helper){
        helper.confirmFinishHlp(component, event, helper);
    },
    
    // onclick of Save button
    doFinish :function(component, event, helper) {
        var adjustment = component.get("v.adjustment");
        var rateTypeOptionsMap = component.get("v.rateTypeOptionsMap");
        var childCmp = component.find("adjustmentFlow_AdjustmentEntry");
        var subPaymentDetail = component.get("v.subPaymentDetails")[0];
        var subPaymentDetails =component.get("v.subPaymentDetails");
        var selectedSubPayment = component.get("v.selectedSubPayment");
        var adjustDetailMap = component.get("v.adjustDetailMap");
        var isCalculateClicked = component.get("v.calculateBtnClicked");
        var adjustmentDetailsMap = component.get("v.adjustmentDetailsMap");
        if(isCalculateClicked){
            var isSave = childCmp.callValidateCurrentPage();
            if(adjustment.CDE_TYPE_ADJMT__c == "Recovery" && adjustmentDetailsMap!= null){
                for (var p in adjustmentDetailsMap) {
                    console.log(adjustmentDetailsMap[p]);
                    if(adjustmentDetailsMap[p].Adjustment_Initiated__c){
                        for(var j=0;j<subPaymentDetails.length;j++){
                            if(subPaymentDetails[j].ExternalId == p && subPaymentDetails[j].ind_adjmt__c != 'Y'){
                                if(adjustmentDetailsMap[p].AMT_PAID_RATE_ADJD__c<subPaymentDetails[j].amt_copay__c){
                                    var pageMessages = component.get("v.pageMessages");
                                    if(!$A.util.isEmpty(pageMessages)){
                                        console.log('pageMessages---'+pageMessages.length);
                                        if(pageMessages.length <1){
                                            pageMessages.push("Adjusted Rate Amount cannot be less than Parent Fee");
                                        }
                                    }else{
                                        pageMessages.push("Adjusted Rate Amount cannot be less than Parent Fee");
                                    }
                                    // pageMessages.push("Adjusted Rate Amount cannot be less than Parent Fee");
                                    component.set("v.pageMessages",pageMessages);
                                    component.set("v.messageType","error");
                                    isSave = false;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            if(isSave){
                if(component.get("v.isARTFeeChanged")){
                    helper.callModal(component,'confirmationModal_SubPayment_ARTFees');
                }else{
                    helper.confirmFinishHlp(component, event, helper);
                }
                
                
            }
        }else{
            component.set("v.pageMessages",["Please click on Calculate before saving records."]);
            component.set("v.messageType","error");  
        }
    },
})