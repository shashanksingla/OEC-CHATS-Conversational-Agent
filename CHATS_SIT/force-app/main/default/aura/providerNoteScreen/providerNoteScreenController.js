({
    getInitData : function(component, event, helper){
        helper.getInitData(component); 
    },
    onLoad : function(component, event, helper){
       component.set("v.showSpinner", false);  
    },
    handleSubmit : function(component, event, helper){
       helper.handleSubmit(component, event, helper); 
    },
    handleSuccess : function(component, event, helper){
       helper.handleSuccess(component, event, helper); 
    },
    handleCancel : function(component, event, helper){
       helper.redirectToRecord(component.get("v.recordId")); 
    }
})