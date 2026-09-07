({
	handleUserChange : function(component, event, helper) {
		var transferFromUser=component.get('v.transferFromUser');
        var transferToUser=component.get('v.transferToUser');
        if (transferFromUser && transferFromUser!=null
            &&transferToUser && transferToUser!=null)
        {
            if(transferFromUser.Owner_County__c != transferToUser.Owner_County__c)
            {
                helper.callModal(component,'confirmationModalOnSameUser');
            }
        }
	},
    actionOnYesButton: function(component, event, helper){
      var modalCall = component.find('confirmationModalOnSameUser');
        modalCall.hideConfirmModal();  
    },
    actionOnNoButton: function(component, event, helper){
       var modalCall = component.find('confirmationModalOnSameUser');
        component.set('v.transferToUser' , null);
        component.set('v.transferToUserId' , null);
        modalCall.hideConfirmModal();
    },
    handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
		helper.validateCurrentPage(component);
    }
})