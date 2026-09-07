({
  doInit: function(component, event, helper) {
    helper.setRequired(component);
  },
  handleFieldLevelValidation : function(component, event, helper) {
		helper.handleFieldLevelValidation(component);
    helper.setRequired(component);
  },
    handleValidateCurrentPage : function(component, event, helper) {
		helper.validateCurrentPage(component);
  },
    handleSetRequired : function(component, event, helper){
      helper.setRequired(component);
  }
})