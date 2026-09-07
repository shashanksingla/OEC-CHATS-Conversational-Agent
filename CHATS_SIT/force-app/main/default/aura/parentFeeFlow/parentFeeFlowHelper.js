({
	callModal : function(cmp, modalName) {
        
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
    },
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(),date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());
    },
})