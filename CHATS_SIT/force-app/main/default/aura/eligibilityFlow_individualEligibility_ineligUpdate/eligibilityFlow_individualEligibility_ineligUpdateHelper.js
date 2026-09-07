({
	closeIneligReason : function(cmp) {
		cmp.find("overlayLib").notifyClose();
        $A.get('e.force:refreshView').fire();		
	}
})