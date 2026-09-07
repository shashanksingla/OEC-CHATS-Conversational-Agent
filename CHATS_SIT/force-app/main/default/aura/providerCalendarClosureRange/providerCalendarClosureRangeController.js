({
    handleModalButtonClick: function(component, evt, helper) {
        component.set("v.showcomp2",true);
        helper.showConfirmModal(component);
    },
	hideConfirmModal : function(component, event, helper) {
		helper.hideConfirmModal(component);
	},
    actionOnCancel : function(component, event, helper){
        var modalCall = component.find("warningModal");
        modalCall.hideConfirmModal();
    },
    handleCancelClick : function(component, event, helper) {
        
        component.set("v.showcomp2",false);
		helper.hideConfirmModal(component);
        
        component.set("v.provClosure",undefined);
	},
    handleSaveClick : function(component, event, helper) {
        component.set("v.spinner", true); 
        var nineDaysAgo=$A.localizationService.formatDate(new Date((new Date()).valueOf() - 1000*60*60*24*9), "YYYY-MM-DD"); // Added as part of CCCAP-10618
        component.set("v.nineDaysAgo", nineDaysAgo);
        var today = $A.localizationService.formatDate(new Date(), 'YYYY-MM-DD');
        component.set("v.today", today);
     	
		helper.checkValidity(component,helper);
	},
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for displaying loading spinner 
        component.set("v.spinner", true); 
    },
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hiding loading spinner    
        component.set("v.spinner", false);
    },
    actionOnNoAttendanceFound : function(component, event, helper){
        component.set("v.hasPastDate", false);
        var modalCall = component.find("attendanceFoundWarningMsgModal");
        modalCall.hideConfirmModal();
    },
    actionOnYesAttendanceFound : function(component, event, helper){  
        component.set("v.attendanceChecked", true);
        var modalCall = component.find('attendanceFoundWarningMsgModal');
        modalCall.hideConfirmModal();
        helper.checkValidity(component,helper);
    }
})