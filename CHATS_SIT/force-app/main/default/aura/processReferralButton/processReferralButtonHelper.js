({
    showConfirmModal: function(component){  
        $A.util.addClass(component.find('confirmMsgModal'), 'slds-fade-in-open');
        $A.util.addClass(component.find('backDrop'), 'slds-backdrop--open');
    },
    hideConfirmModal: function(component){
        $A.util.removeClass(component.find('backDrop'),'slds-backdrop--open');
        $A.util.removeClass(component.find('confirmMsgModal'), 'slds-fade-in-open');        
    }
})