({
	doInit : function(component, event, helper) {
		/*var adjustmentDtlWarp = component.get("v.adjustmentDtlWarp");
        var rateTypeOptionsMap = component.get("v.rateTypeOptionsMap");
       
        if(adjustmentDtlWarp != null && rateTypeOptionsMap != null){
            adjustmentDtlWarp.ajustmentDetails.CDE_TYPE_RATE_ADJD__c= rateTypeOptionsMap[adjustmentDtlWarp.ajustmentDetails.CDE_TYPE_RATE_ADJD__c];
        }*/
    },
    handleMenuSelect : function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        
        var adjustmentDtlWarp = component.get("v.adjustmentDtlWarp").ajustmentDetails;
        // Bug fix 2929
        var adjustmentDetailWrapper = component.get("v.adjustmentDtlWarpArr");
        var rowIndex = component.get("v.rowIndex");
        var subPaymentDetails = [], adjustmentDetails = [];
        
        var isResp = false;
        // subPaymentDetails[0] = adjustmentDetailWrapper[rowIndex].subPaymentDetails;
        adjustmentDetails[0] = adjustmentDetailWrapper[rowIndex].ajustmentDetails;
        subPaymentDetails.push(adjustmentDetailWrapper[rowIndex].subPaymentDetails);
        
        component.set("v.selectedMenuItemValue",selectedMenuItemValue.split("_")[0]);
        var rateTypeOptionsCareDateMap =[];
        // New Code
        var action2 = component.get("c.getRateTypeMap");
        action2.setParams({'subPaymentDetail':subPaymentDetails[0],'adjustmentDetail':adjustmentDetails[0]});
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                isResp =true;
                var res =response.getReturnValue();
                
                if(res.objectData){
                    rateTypeOptionsCareDateMap = res.objectData.rateTypeOptionsCareDateMap;
                }
                
            } else {
                
            }
            if(selectedMenuItemValue && selectedMenuItemValue.split("_")[1] == 'edit') {           
                component.set("v.adjustmentEntryEditMode", true);
                $A.createComponent("c:adjustmentFlow_SubPayment_AddAdjDetailFlow", {
                    currentTabNumber:2,
                    calculateBtn:true,
                    selectedSubPayment:'',
                    adjustment:component.get("v.adjustment"),
                    subPaymentDetails:subPaymentDetails,
                    rateTypeOptions:component.get("v.rateTypeOptions"),
                    careUnitTypeOptions:component.get("v.careUnitTypeOptions"),
                    careLevelOptions:component.get("v.careLevelOptions"),
                    adjustmentDetailList:adjustmentDetails,
                    rateTypeOptionsCareDateMap:rateTypeOptionsCareDateMap,
                    //adjustmentDetailsMap1:'', Not required as it will be taken care from the component
                    //isCurrentPageValid:'', Not required as it will be taken care from the component
                    careLevelOptionsMap:component.get("v.careUnitTypeOptionsMap"),
                    careUnitTypeOptionsMap:component.get("v.careLevelOptionsMap"),
                    rateTypeOptionsMap:component.get("v.rateTypeOptions"),
                    adjustDetailMap:component.get("v.adjustDetailMap"),
                    childCurrentUtilization:component.get("v.childCurrentUtilization"),
                    disabledARTFees :component.get("v.disabledARTFees")
                },function(content, status) {
                    if (status === "SUCCESS") {
                        component.find('overlayLib').showCustomModal({
                            header: "Adjustment Detail Edit",
                            body: content,
                            showCloseButton: true,
                            cssClass: "slds-modal_large",
                            closeCallback: function() {
                                
                            }                                       
                        });
                    }
                });                
            } else if(selectedMenuItemValue && selectedMenuItemValue.split("_")[1] == 'delete') {
                helper.callModal(component,'confirmationModalOnDelete'); 
            }
        });
        $A.enqueueAction(action2);
    },
    confirmDelete :function(component, event, helper) {
        //deleteRecords
        var sObject = {'sobjectType':'T_ADJMT_DETAIL__c',
                       'Id':component.get("v.selectedMenuItemValue")};
        helper.callServer(component,"c.deleteRecords", function(response){
           
            var adjustmentDetailList = component.get("v.adjustmentDtlWarpArr");
            var adjustDetailMap = component.get("v.adjustDetailMap");
            adjustmentDetailList.splice(adjustmentDetailList.indexOf(component.get("v.adjustmentDtlWarp")),1);
            component.set("v.adjustmentDtlWarpArr",adjustmentDetailList);
            
            var subPmtDtlKey =component.get("v.selectedMenuItemValue");
            if(!$A.util.isEmpty(subPmtDtlKey)){
                console.log('key------'+subPmtDtlKey);
                var map = {};
                if(adjustDetailMap!= null){
                    for (var p in adjustDetailMap) {
                        console.log('------p---'+p);
                        if( adjustDetailMap.hasOwnProperty(p) ) {
                            console.log('------1---'+subPmtDtlKey);
                            console.log('------adjustDetailMap[p].Id---'+adjustDetailMap[p][0].Id);
                            if(adjustDetailMap[p][0].Id ==subPmtDtlKey){
                                console.log('----subPmtDtlKey--1---'+subPmtDtlKey);
                                
                            }else{
                                map[p]= adjustDetailMap[p];
                            }
                        } 
                    }   
                    console.log('map---'+JSON.stringify(map));
                    component.set("v.adjustDetailMap",map); 
                }   
            }
        },{deleteObjects:[sObject]}, false, null); 
    },
})