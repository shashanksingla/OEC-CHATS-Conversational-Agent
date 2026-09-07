({
    doUpdateCurrentTabName: function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==1){
            component.set("v.currentTabName","Bulk Case/FA Transfer");
        }
    },
    doFinish: function(component, event, helper){
        
        var childCmp = component.find("bulkCaseTransfer");
        childCmp.callValidateCurrentPage();
       
       
        if(component.get("v.isCurrentPageValid")){
            
            
            helper.callServerAndHandleError(component,"c.transferItems", 
                                            function(response){
                                                if(response.isSuccessful==true){
                                                    var numberOfRecords= response.objectData.itemTransferred;
                                                    var successMessage;
                                                    if(numberOfRecords > 1000){
                                                        successMessage= 'Only 1000 items may be transferred at a time; '+numberOfRecords+' items have enqueued for transfer. The transfer will be completed shortly.';
                                                    }
                                                    else if(numberOfRecords > 1){
                                                        successMessage= numberOfRecords+' Items Transferred Successfully';
                                                    }
                                                    else if(numberOfRecords== 1){
                                                        successMessage= numberOfRecords+' Item Transferred Successfully';
                                                    }
                                                    helper.fireToast('dismissible', 'success', 'Success', successMessage ) ;
                                                }
                                                else{
                                                    helper.fireToast('dismissible', 'error', 'Error', response.message) ;
                                                }
                                            }, {'countyId':component.get("v.countyId"),
                                                'fromUserId':component.get("v.transferFromUserId"),
                                                'toUserId':component.get("v.transferToUserId"),
                                                'transferType':component.get("v.transferType") }, false, null);
        }
        
    }
})