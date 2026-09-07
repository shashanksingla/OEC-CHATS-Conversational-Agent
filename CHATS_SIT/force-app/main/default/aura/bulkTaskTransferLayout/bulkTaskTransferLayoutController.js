({
    doUpdateCurrentTabName: function(component, event, helper) {
        var currentTabNumber = component.get("v.currentTabNumber");
        if(currentTabNumber==1){
            component.set("v.currentTabName","Bulk Task Transfer");
        }
    },
    doFinish: function(component, event, helper){
        
        var childCmp = component.find("bulkTaskTransfer");
        childCmp.callValidateCurrentPage();
        console.log('hi', JSON.stringify(component.get("v.subject")));
        //component.set("v.subject", 'T208 - Provider\'s Location/Relation has been changed on the authorization');
        if(component.get("v.isCurrentPageValid")){
            helper.callServerAndHandleError(component,"c.transferItems", 
                                            function(response){
                                                if(response.isSuccessful==true){
                                                    var numberOfSuccess= response.objectData.itemTransferred;
                                                    var numberOfFailures=response.objectData.failedUpdates;
                                                    var successMessage;
                                                    var toastType ='success';
                                                    var toastTitle='Success';
                                                    if(numberOfSuccess > 1000){
                                                        successMessage= 'Only 1000 items may be transferred at a time; '+numberOfSuccess+' items have enqueued for transfer. The transfer will be completed shortly.';
                                                    }
                                                    else if(numberOfSuccess > 1){
                                                        successMessage= numberOfSuccess+' Tasks Transferred Successfully. ';
                                                        if(numberOfFailures>0){
                                                         successMessage =+numberOfFailures+' Tasks Transfer Failed.'
                                                        }
                                                    }
                                                    else if(numberOfSuccess== 1){
                                                        successMessage= numberOfSuccess+' Task Transferred Successfully. ';
                                                        if(numberOfFailures>0){
                                                         successMessage =+numberOfFailures+' Tasks Transfer Failed.'
                                                        }
                                                    }
                                                    else if(numberOfSuccess== 0){
                                                        successMessage= numberOfSuccess+' Task Transferred Successfully. ';
                                                        if(numberOfFailures>0){
                                                         successMessage =+numberOfFailures+' Tasks Transfer Failed.'
                                                        toastType ='error';
                                                    	toastTitle='Error';
                                                        }
                                                    }
                                                    helper.fireToast('dismissible', toastType, toastTitle, successMessage ) ;
                                                }
                                                else{
                                                    helper.fireToast('dismissible', 'error', 'Error', response.message) ;
                                                }
                                            }, {'countyId':component.get("v.countyId"),
                                                'fromUserId':component.get("v.transferFromUserId"),
                                                'toUserId':component.get("v.transferToUserId"),
                                                'transferType':"3",
                                                'subject': component.get("v.subject")}, false, null);
        }
        
    }
})