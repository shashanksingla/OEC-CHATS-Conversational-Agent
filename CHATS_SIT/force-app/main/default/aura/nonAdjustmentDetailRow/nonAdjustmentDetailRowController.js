({
    doInit : function(component, event, helper) {
        component.set("v.deleteAdjustment",$A.get("$Label.c.FMFlow_DeleteAdjustmentMessage"));
    },
    handleMenuSelect : function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        
        component.set("v.selectedMenuItemValue",selectedMenuItemValue.split("_")[0]);
        
        if(selectedMenuItemValue && selectedMenuItemValue.split("_")[1] == 'edit') {
            component.set("v.adjustmentEntryEditMode", true);
            $A.createComponent("c:adjustmentFlow_AdjustmentEntry_NonSub", {
                adjustmentEntryEditMode:component.get("v.adjustmentEntryEditMode"),
                nonAdjustmentDetail:component.get("v.nonAdjustmentDetailRec"),
                nonAdjustmentDetailObj:component.get("v.nonAdjustmentDetailLst"),
                individualObj:component.get("v.nonAdjustmentDetailAssocIndiv"),
                adjustmentObj:component.get("v.adjustmentObj")
            },function(content, status) {
                if (status === "SUCCESS") {
                    component.find('overlayLib').showCustomModal({
                        header: "Adjustment Entry",
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
    },
    confirmDelete : function(component, event, helper) {
        //deleteRecords
        var sObject = {'sobjectType':'T_NON_ADJMT_DETAIL__c',
                       'Id':component.get("v.selectedMenuItemValue")};
        helper.callServer(component,"c.deleteRecords", function(response){
           
           
            var nonAdjustmentDetailLst = component.get("v.nonAdjustmentDetailLst");
            nonAdjustmentDetailLst.splice(nonAdjustmentDetailLst.indexOf(component.get("v.nonAdjustmentDetailRec")),1);
            component.set("v.nonAdjustmentDetailLst",nonAdjustmentDetailLst);
        },{deleteObjects:[sObject]}, false, null);
        
    }
})