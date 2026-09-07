({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        
        var isValid= true;
        cmp.find('endDate').set('v.message', '') ;
        cmp.find('beginDate').set('v.message', '') ;
        var beginDate= new Date(cmp.get('v.beginDate'));
        var endDate= new Date(cmp.get('v.endDate'));
        var currentDate =  this.getCurrentSystemDate();
        
        if(beginDate > endDate) 
        {
            cmp.find('endDate').set('v.message', 'End Date must be after Start Date') ;
        	isValid = false;
        }
        if(beginDate > currentDate) 
        {
            cmp.find('beginDate').set('v.message', 'Date Range cannot include future dates') ;
        	isValid = false;
        }
        if(endDate > currentDate) 
        {
            cmp.find('endDate').set('v.message', 'Date Range cannot include future dates') ;
        	isValid = false;
        }
        if(Math.round((endDate-beginDate)/(1000*60*60*24)) >= 31) 
        {
            cmp.find('endDate').set('v.message', 'Date Range cannot be more than 31 days') ;
        	isValid = false;
        }
        return isValid;
        
    },getCurrentSystemDate : function(addDays,addMonths,addYears){
        
        var today = new Date();
        var dd = addDays?today.getDate()+addDays:today.getDate();
        var MM = addMonths?today.getMonth()+1+addMonths:today.getMonth()+1;
        var yyyy = addYears?today.getFullYear()+addYears:today.getFullYear();
        if(dd<10){
            dd='0'+dd;
        } 
        if(MM<10){
            MM='0'+MM;
        } 
        return yyyy+'-'+MM+'-'+dd;
    },getPriorDate : function(DaysPrior) {
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
}
)