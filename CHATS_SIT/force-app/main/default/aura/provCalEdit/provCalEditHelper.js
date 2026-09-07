({
    getPriorDate : function(DaysPrior) {
        var date = new Date();
        var last = new Date(date.getTime() - (DaysPrior * 24 * 60 * 60 * 1000));
        var day =last.getUTCDate();
        var month=last.getMonth()+1;
        if(month<10){
            month='0'+month;
        }
        if(day<10){
           day='0'+day; 
        }
        var year=last.getFullYear();
        return year+'-'+month+'-'+day;
    }
})