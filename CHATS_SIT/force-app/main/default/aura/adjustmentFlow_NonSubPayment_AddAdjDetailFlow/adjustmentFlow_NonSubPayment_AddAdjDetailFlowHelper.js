({
	helperMethod : function() {
		
	},
    callModal : function(cmp, modalName) {
        var modalCall = cmp.find(modalName);
        if(modalCall){
	        modalCall.openModal();
        }
    }   
})