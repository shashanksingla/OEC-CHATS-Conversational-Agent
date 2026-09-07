({
    doInit : function(component, event, helper) {
        var showUnescapedMsg = component.get("v.isMsgUnescapedHtml");
        if(showUnescapedMsg == true){
            var msg = component.get("v.confirmMsg");
            var msgArr = msg.split("<br />");
            component.set("v.unescapedconfirmMsg", msgArr);
        }
        if(component.get("v.callApexBeforeComponent") == true){
            if(!$A.util.isEmpty(component.get("v.apexMethodName"))){
                var apexMethodName = "c."+component.get("v.apexMethodName");
                helper.callApexMethod(component, apexMethodName, 'EXECUTE_APEX');
            }  
        }
    },
    handleModalButtonClick: function(component, evt, helper) {
        var showConfirmMsgModal = component.get("v.showConfirmMsgModal");
        if(showConfirmMsgModal == 'Always'){
            helper.showConfirmModal(component);
        }else if(showConfirmMsgModal == 'Conditional'){
            helper.callApexMethod(component, 'c.'+component.get("v.showConfirmApexMethodName"), 'CHECK_CONFIRM');
        }else if(showConfirmMsgModal == 'ValidatePriorToRedirecting'){
            helper.callApexMethod(component, 'c.'+component.get("v.showConfirmApexMethodName"), 'CHECK_REDIRECT');
        }else{
            helper.performTheRequiredAction(component);          
        }      
    },
    confirmModalYes: function(component, evt, helper) { 
        
        helper.hideConfirmModal(component);    
        if(component.get("v.callApexMethodOnYesButtonClick")==true){
            helper.callApexMethod(component, 'c.'+component.get("v.apexMethodName"), 'CHECK_REDIRECT');
        }else{
	        helper.performTheRequiredAction(component); 
        }
    },
    hideConfirmModal: function(component, evt, helper){
        helper.hideConfirmModal(component);
    }
})