({
	closeIneligReason : function(cmp, refreshView) {
		cmp.find("overlayLib").notifyClose();
        if(refreshView) {
        	$A.get('e.force:refreshView').fire();    
        }
        		
	}
})