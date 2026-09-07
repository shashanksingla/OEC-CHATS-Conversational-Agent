({
	getDaysInAMonth : function(seletedMonth, seletedYear, component) {
		var weeksOfAMonth = [];
        var nextMonth = parseInt(seletedMonth) + 1;
        var noOfDaysInAMonth = new Date(seletedYear, nextMonth , 0).getDate();
        //var noOfDaysInAMonth = new Date(seletedYear, seletedMonth, 0).getDate();
        //arrange days in week format
        var daysInCurrentWeek = [];
        var emptyDatesAdded = false;
        for(var day = 1; day <= noOfDaysInAMonth; day++) {
            var currentDay = new Date(seletedYear, seletedMonth, day);
            if(!emptyDatesAdded) {
                /*
                 * for tuesday push one empty day to daysInCurrentWeek 
                 * for wednesday push two empty days to daysInCurrentWeek and so on
                 * 2 = tuesday .... 6 = Sat, 0 = sunday*/
                if(currentDay.getDay() == 2){
                    daysInCurrentWeek.push({});
                } else if(currentDay.getDay() == 3){
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                } else if(currentDay.getDay() == 4){
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                } else if(currentDay.getDay() == 5){
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                } else if(currentDay.getDay() == 6){
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                } else if(currentDay.getDay() == 0){
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                    daysInCurrentWeek.push({});
                } 
                emptyDatesAdded = true;
            }
            daysInCurrentWeek.push({
                Day : currentDay
            });
            //if a week is formed then add that week to month
            if(daysInCurrentWeek.length == 7 || day == noOfDaysInAMonth) {
                if(day == noOfDaysInAMonth) {
                    for(var i = 0; i < 7 - daysInCurrentWeek.length; i++)
                        daysInCurrentWeek.push({});
                }
                weeksOfAMonth.push({
                    DaysInAWeek : daysInCurrentWeek
                });
                daysInCurrentWeek = [];
            }
        }
        component.set("v.weeksInAMonth", weeksOfAMonth);
	}
})