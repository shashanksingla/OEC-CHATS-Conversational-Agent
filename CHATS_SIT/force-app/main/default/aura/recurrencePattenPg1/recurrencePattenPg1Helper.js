({
    checkCustomValidations : function(component) {
        var scheduleRecurrObj = component.get("v.authSchRecurrObj");
        var isValid=false;
        debugger;
        var todayDate = new Date();
        console.log('todayDate--'+todayDate);
      //  console.log('helper--'+helper);
        var todayDateUTC = this.getDateInUTC(todayDate);
        debugger;
        var todayDateMinus9Days = todayDateUTC;
        debugger;
        todayDateMinus9Days = todayDateMinus9Days.setDate(todayDateMinus9Days.getDate() - 9);
        debugger;
        var endDate = component.find("endDate").get('v.value');
        var validityEndDate =  this.checkValidity(component, event, this,endDate,"endDate");
        var validity;
        debugger;
        console.log('endDate--'+endDate);
        debugger;
        console.log('validityEndDate--'+validityEndDate);
        debugger;
        if(validityEndDate){
            var endDate1 = this.getDateInUTC(endDate);
            var authEndDate = component.get("v.authEndDate");
            debugger;
            
            if(endDate1>authEndDate){
                debugger;
                var formattedAuthEndDate =  this.padNumber(authEndDate.getMonth() + 1) + '/' + this.padNumber(authEndDate.getDate()) +'/'+authEndDate.getFullYear();
                var endMsg= "End date cannot be greater than authorization end date, "+formattedAuthEndDate;
                component.find("endDate").set("v.errors",[{"message":endMsg}]);
                validityEndDate =false;
            }
        }
       /* if(scheduleRecurrObj.Recur_Type__c ==='Monthly'){
            if(validityEndDate && validity.valid){
                isValid = true;
                component.set("v.valid",isValid);
                debugger;
            }
        }else*/ if(validityEndDate){
            isValid = true;
            component.set("v.valid",isValid);
            debugger;
        }
        
        console.log('isValid before return--'+isValid);
        
        component.set("v.isValid",isValid);
        console.log('isValid before return--'+component.get("v.isValid"));
        return isValid;
    },
    checkValidity: function(component, event, helper,date,auraId) {
        var valid = true;
        var validity = true;
        var dateStr = date;
        var dateArr;
        var dayStr;
        var monthStr;
        debugger;
        if(!$A.util.isEmpty(date)){
            dateArr = date.split("/");
            if(!$A.util.isEmpty(dateArr)){
                if(dateArr.length>1){
                    dayStr = dateArr[1];
                    monthStr = dateArr[0];
                }
            }
        }
        
        if( $A.util.isEmpty(date)){
            debugger;
            validity = false;
            component.set("v.validity",{'valid':false});
            component.find(auraId).set("v.errors",[{"message":"Please enter a value."}]);
        }else if(!$A.util.isEmpty(date)){
            if(date.length <8){
                valid = false; 
            }
            date = this.getDateInUTC(new Date(date));
            
            var month = parseInt(date.getMonth());
            var day   = parseInt(date.getDate());
            var year  = parseInt(date.getFullYear());
            if(isNaN(month) || isNaN(day) || isNaN(year))  valid = false;
            
            var yearSt = year.toString();
            if(yearSt.length >3){
                var dateYrArr = dateStr.split("-");
                if(!$A.util.isEmpty(dateYrArr)){
                    if(dateYrArr.length>1){
                        var yearStr =dateYrArr[0];
                        dayStr = dateYrArr[2];
                        monthStr = dateYrArr[1];
                        var yearInt  =parseInt(yearStr);
                        
                        if((!$A.util.isEmpty(yearInt)) && (yearInt< 1000 || yearInt >9999) ){
                            valid = false;   
                        }
                    }
                }
            }
            
            if((month < 0) || (month > 11)) {
                
                valid = false;
            }
            else if((dayStr < 1) || (dayStr > 31)) {valid = false;}
                else if(((monthStr == 6) || (monthStr == 4) || (monthStr == 9) || (monthStr == 11)) && (dayStr > 30)){   
                    
                    valid = false;
                }
                    else if((month == 1 || monthStr == 2) && (((year % 400) == 0) || ((year % 4) == 0)) && ((year % 100) != 0) && (dayStr > 29)) {
                        
                        
                        valid = false;}
                        else if((month == 1 || monthStr == 2) && ((year % 100) == 0) && (dayStr > 29)) {valid = false;}
                            else if((month == 1 || monthStr == 2) && (dayStr > 28)){
                                var isLeapYear = this.leapYear(year);
                                if(!isLeapYear){
                                    valid = false; 
                                }
                            }
                                else if( (year <1000 || year >9999)){ valid = false; }
                                    else if(!$A.util.isEmpty(dateArr)){
                                        if(dateArr.length>1){
                                            var yearStr =dateArr[2];
                                            var yearInt  =parseInt(yearStr);
                                            
                                            if((!$A.util.isEmpty(yearStr)) && yearStr.length <4){
                                                valid = false; 
                                            }
                                            if((!$A.util.isEmpty(yearInt)) && yearInt< 1000){
                                                valid = false;   
                                            }
                                        }
                                    }
            
            if(!valid){
                debugger;
                component.find(auraId).set("v.errors",[{"message":"Please enter valid date format(MM/DD/YYYY) or valid date."}]);
                component.set("v.validity",{'valid':false});
                component.set("v.valid",false);
                validity = false;
            }else{
                component.find(auraId).set("v.errors",[]);
                debugger;
                component.set("v.valid",true);
                validity = true;
                component.set("v.validity",{'valid':true});
            }
        }else{
            debugger;
            validity = true;
            component.set("v.validity",{'valid':true});
            component.find(auraId).set("v.errors",[]);
        }
        return validity;
    },
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    leapYear :function(year)
    {
        return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    },
    padNumber : function(number) {
        var string  = '' + number;
        string      = string.length < 2 ? '0' + string : string;
        return string;
    },
})