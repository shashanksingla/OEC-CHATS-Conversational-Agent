({
    callModal : function(cmp, modalName) {
        
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
	},
    decrementCurrentTabNumber : function(cmp){
        cmp.set("v.currentTabNumber",cmp.get("v.currentTabNumber")-1);
    }
})