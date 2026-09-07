({
	callModal : function(cmp, modalName) {
        
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
	},
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
       
        var isValid= true;
              
        return isValid;
        
    }
})