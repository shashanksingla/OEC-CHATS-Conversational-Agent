({
	callModal: function (cmp, modalName) {
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
    },
    toastMessage: function (state, msg) {
        var showToast = $A.get("e.force:showToast");
        showToast.setParams({
            'title': state,
            'type': state.toLowerCase(),
            'message': msg
        });
        showToast.fire();
    },
    saveAddendumRecord: function(component, helper){
        helper.callServerAndHandleError(component,"c.saveSlotContractAddendum", 
                                        function(response){
                                            if(response.isSuccessful == true) {
                                                var mode = component.get("v.isCreate") == true ? 'created' : 'updated';
                                                helper.toastMessage('Success', 'Slot Contract Addendum has been '+mode+' successfully!');
                                                helper.goToRecord(response.objectData.addendumId,'detail');
                                            } else {
                                                helper.toastMessage('Error', response.errorMessage);
                                            }
                                        },
                                        {'slotContractAddendum':component.get("v.addendumRec")}, false, null);
    }
})