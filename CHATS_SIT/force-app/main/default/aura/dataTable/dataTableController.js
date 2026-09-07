({
	openRecordDetail :function(component,event,helper){
        var subPaymentId = event.currentTarget.dataset.item;
        helper.callServerAndHandleError(component,"c.doSearchSubpymntId", function(response){
            if(response.objectData.subPaymntSfId){
                window.open('/one/one.app#/sObject/' + response.objectData.subPaymntSfId + '/view');                
            }            
        }, {'subPaymentId':subPaymentId.toString()}, false, null);
    }
})