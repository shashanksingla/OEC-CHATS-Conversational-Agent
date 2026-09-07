({
    doInit : function(component, event, helper) {
        console.log('options--'+component.get('v.options'));
    },
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    },
    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    },
    getRelationship : function(component, event, helper) {
        helper.getRelationshipHlp(component, event, helper);  
    }
})