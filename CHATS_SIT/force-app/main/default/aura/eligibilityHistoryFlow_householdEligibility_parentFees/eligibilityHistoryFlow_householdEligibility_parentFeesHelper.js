({
	getFirstDayOfNextMonth: function() {
        var now = new Date();
        var current;
        if (now.getMonth() == 11) {
            current = new Date(now.getFullYear() + 1, 0, 1);
        } else {
            current = new Date(now.getFullYear(), now.getMonth() + 1, 1);
        }
       
        return current;
    },
    
    getFirstDayOfNexToNexttMonth: function() {
        var now = new Date();
        var current;
        if (now.getMonth() == 10) {
            current = new Date(now.getFullYear() + 1, 0, 1);
        }
        else if(now.getMonth() == 11) {
            current = new Date(now.getFullYear(), 1, 1);
        }
            else {
                current = new Date(now.getFullYear(), now.getMonth() + 2, 1);
            }
        return current;
        
    }
})